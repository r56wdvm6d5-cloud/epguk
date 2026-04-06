#!/usr/bin/env python3
"""
TV2 Multi-XML Processor with Auto-Date Update
Fetches and combines multiple XML sources into one EPG file
Supports dual sources: KSTV bulk XML (fetched once + cached) and epg.pw per-channel
"""

import argparse
import xml.etree.ElementTree as ET
import requests
import requests.adapters
import re
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import logging
from typing import List, Dict, Tuple
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

KSTV_EPG_URL = "http://kstv.us:8080/xmltv.php?type=xml"

class TV2MultiXMLProcessor:
    """Process multiple XML sources and combine them into one EPG file.
    Supports KSTV bulk XML (fetched once, cached) and epg.pw per-channel sources.
    """

    def __init__(self):
        self.max_programs = 900                 # Global programme cap
        self.max_programs_per_channel = 100     # Per-channel early limit
        self.current_time = datetime.now(timezone.utc)

        # Setup connection pooling for faster HTTP requests
        self.session = requests.Session()
        adapter = requests.adapters.HTTPAdapter(
            pool_connections=20,
            pool_maxsize=20,
            max_retries=3,
            pool_block=False
        )
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)

    # -------------------------------------------------------------------------
    # Config loading — detects kstv vs epg.pw sources automatically
    # -------------------------------------------------------------------------

    def load_config(self, config_file: str) -> Tuple[Dict[str, str], List[Dict[str, str]]]:
        """Load configuration from file.
        Returns:
            kstv_channels : dict  {channel_id: display_name}  for kstv.us sources
            epgpw_sources : list  [{channel_id, url, display_name}] for epg.pw sources
        """
        kstv_channels = {}
        epgpw_sources = []

        try:
            with open(config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#') or line.startswith('='):
                        continue
                    # Split on first 2 pipes — display name may contain pipes
                    parts = line.split('|', 2)
                    if len(parts) < 3:
                        continue
                    channel_id   = parts[0].strip()
                    url          = parts[1].strip()
                    display_name = parts[2].strip()

                    # Detect source type:
                    # - kstv.us in URL               -> kstv bulk source
                    # - numeric ID or epg.pw in URL  -> epg.pw per-channel source
                    # - anything else                -> treat as epg.pw per-channel
                    if 'kstv.us' in url:
                        if channel_id not in kstv_channels:  # first display name wins
                            kstv_channels[channel_id] = display_name
                    elif channel_id.isdigit() or 'epg.pw' in url:
                        epgpw_sources.append({
                            'channel_id':   channel_id,
                            'url':          url,
                            'display_name': display_name
                        })
                    else:
                        epgpw_sources.append({
                            'channel_id':   channel_id,
                            'url':          url,
                            'display_name': display_name
                        })

        except FileNotFoundError:
            logger.error(f"Config file not found: {config_file}")

        logger.info(f"Loaded {len(kstv_channels)} KSTV channels, {len(epgpw_sources)} epg.pw channels")
        return kstv_channels, epgpw_sources

    # -------------------------------------------------------------------------
    # KSTV bulk XML — fetch once, cache, filter by channel ID
    # -------------------------------------------------------------------------

    def fetch_full_kstv_epg(self, cache_file: str = 'tv2_kstv_cache.xml', cache_hours: float = 6) -> ET.Element:
        """Fetch the full KSTV EPG XML once, cache it locally."""
        if os.path.exists(cache_file):
            age_hours = (time.time() - os.path.getmtime(cache_file)) / 3600
            if age_hours < cache_hours:
                logger.info(f"Using cached KSTV EPG ({age_hours:.1f}h old, limit {cache_hours}h)")
                try:
                    tree = ET.parse(cache_file)
                    return tree.getroot()
                except Exception as e:
                    logger.warning(f"Cache read failed: {e} — re-fetching")

        logger.info(f"Fetching full KSTV EPG from {KSTV_EPG_URL} ...")
        try:
            response = self.session.get(KSTV_EPG_URL, timeout=120)
            response.raise_for_status()
            with open(cache_file, 'wb') as f:
                f.write(response.content)
            logger.info(f"KSTV EPG cached to {cache_file}")
            root = ET.fromstring(response.content)
            logger.info("Successfully fetched full KSTV EPG")
            return root
        except Exception as e:
            logger.error(f"Failed to fetch KSTV EPG: {e}")
            if os.path.exists(cache_file):
                logger.warning("Using stale KSTV cache as fallback")
                try:
                    tree = ET.parse(cache_file)
                    return tree.getroot()
                except Exception:
                    pass
            return None

    def filter_kstv_channels(self, root: ET.Element, wanted_channels: Dict[str, str]) -> Tuple[Dict, List]:
        """Filter only wanted channels and their programmes from the full KSTV EPG."""
        out_channels = {}
        out_programmes = []

        for channel in root.findall('.//channel'):
            ch_id = channel.get('id')
            if ch_id in wanted_channels:
                disp = channel.find('display-name')
                if disp is not None:
                    disp.text = wanted_channels[ch_id]
                out_channels[ch_id] = channel

        # Deduplicate by display name + start + title + desc
        seen_keys = set()
        for programme in root.findall('.//programme'):
            ch_id = programme.get('channel')
            if ch_id in wanted_channels:
                display_name = wanted_channels[ch_id]
                title_el = programme.find('title')
                desc_el  = programme.find('desc')
                title = title_el.text if title_el is not None else ''
                desc  = desc_el.text  if desc_el  is not None else ''
                key = f"{display_name}|{programme.get('start')}|{title}|{desc}"
                if key not in seen_keys:
                    seen_keys.add(key)
                    out_programmes.append(programme)

        logger.info(f"KSTV filter: {len(out_channels)} channels, {len(out_programmes)} programmes (deduplicated)")
        return out_channels, out_programmes

    # -------------------------------------------------------------------------
    # epg.pw per-channel fetch (parallel)
    # -------------------------------------------------------------------------

    def fetch_epgpw_source(self, source: Dict[str, str]) -> Tuple[ET.Element, List[ET.Element]]:
        """Fetch a single epg.pw channel XML and return channel element + programmes."""
        url          = source['url']
        display_name = source['display_name']
        channel_id   = source['channel_id']

        # Update date in URL to today
        today = datetime.now().strftime("%Y%m%d")
        url = re.sub(r'date=\d{8}', f'date={today}', url)

        try:
            logger.info(f"Fetching epg.pw: {display_name}")
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            root = ET.fromstring(response.content)

            channel = root.find('.//channel')
            if channel is not None:
                channel.set('id', channel_id)
                disp = channel.find('display-name')
                if disp is not None:
                    disp.text = display_name
                else:
                    disp = ET.SubElement(channel, 'display-name')
                    disp.set('lang', 'en')
                    disp.text = display_name

            programmes = []
            for prog in root.findall('.//programme'):
                prog.set('channel', channel_id)
                programmes.append(prog)

            return channel, programmes

        except Exception as e:
            logger.error(f"Failed to fetch epg.pw source {display_name}: {e}")
            return None, []

    # -------------------------------------------------------------------------
    # Time filtering
    # -------------------------------------------------------------------------

    def parse_time(self, time_str: str):
        """Parse EPG time string to UTC datetime."""
        try:
            time_str = time_str.strip()
            if len(time_str) > 14 and ('+' in time_str[14:] or '-' in time_str[14:]):
                return datetime.strptime(time_str, '%Y%m%d%H%M%S %z').astimezone(timezone.utc)
            return datetime.strptime(time_str[:14], '%Y%m%d%H%M%S').replace(tzinfo=timezone.utc)
        except Exception:
            return None

    def filter_future_programs(self, programmes: List[ET.Element]) -> List[ET.Element]:
        """Keep future programmes and currently-airing ones, drop fully past ones."""
        original_count = len(programmes)
        kept = []

        logger.info(f"Time filter: keeping programmes at/after {self.current_time.strftime('%Y-%m-%d %H:%M:%S UTC')} or currently airing")

        for program in programmes:
            start_str = program.get('start')
            stop_str  = program.get('stop')

            if not start_str:
                kept.append(program)
                continue

            start_time = self.parse_time(start_str)
            if start_time is None:
                kept.append(program)
                continue

            if stop_str:
                stop_time = self.parse_time(stop_str)
                if stop_time and stop_time <= self.current_time:
                    continue  # Fully aired — skip
            else:
                if start_time < self.current_time:
                    continue

            kept.append(program)

        logger.info(f"Time filter: {original_count} -> {len(kept)} programmes (removed {original_count - len(kept)} past)")
        return kept

    # -------------------------------------------------------------------------
    # Programme limiting
    # -------------------------------------------------------------------------

    def limit_programs_per_channel(self, programmes: List[ET.Element]) -> List[ET.Element]:
        """Cap each channel at max_programs_per_channel programmes."""
        channel_programs: Dict[str, list] = {}
        for prog in programmes:
            channel_programs.setdefault(prog.get('channel'), []).append(prog)

        limited = []
        for ch_id, progs in channel_programs.items():
            if len(progs) > self.max_programs_per_channel:
                logger.info(f"Per-channel limit [{ch_id}]: {len(progs)} -> {self.max_programs_per_channel}")
                limited.extend(progs[:self.max_programs_per_channel])
            else:
                limited.extend(progs)

        logger.info(f"Per-channel limiting: {len(programmes)} -> {len(limited)} programmes")
        return limited

    def limit_programs_equally(self, programmes: List[ET.Element], num_channels: int) -> List[ET.Element]:
        """Global 900 cap distributed equally across channels."""
        if len(programmes) <= self.max_programs:
            logger.info(f"Total programmes ({len(programmes)}) under global cap ({self.max_programs}), no limiting needed")
            return programmes

        programs_per_channel = self.max_programs // num_channels
        remaining = self.max_programs % num_channels
        logger.info(f"Global cap: {len(programmes)} -> {self.max_programs} (~{programs_per_channel} per channel)")

        channel_programs: Dict[str, list] = {}
        for prog in programmes:
            channel_programs.setdefault(prog.get('channel'), []).append(prog)

        limited = []
        extra = remaining
        for ch_id, progs in channel_programs.items():
            limit  = programs_per_channel + (1 if extra > 0 else 0)
            if extra > 0:
                extra -= 1
            actual = min(limit, len(progs))
            limited.extend(progs[:actual])
            logger.info(f"Global cap [{ch_id}]: {len(progs)} -> {actual} programmes")

        logger.info(f"Final total programmes: {len(limited)}")
        return limited

    # -------------------------------------------------------------------------
    # XML output
    # -------------------------------------------------------------------------

    def create_combined_xml(self, channels: Dict, programmes: List[ET.Element]) -> ET.Element:
        """Build combined XML output."""
        root = ET.Element("tv")
        root.set('date', datetime.now().strftime("%Y%m%d%H%M%S %z"))
        root.set('generator-info-name', 'TV2-Multi-XML-Processor')
        root.set('generator-info-url', 'https://github.com/r56wdvm6d5-cloud/epguk')
        root.set('source-info-name', 'TV2-Source-EPG')

        for channel in channels.values():
            if isinstance(channel, ET.Element):
                root.append(channel)
        for programme in programmes:
            root.append(programme)

        return root

    def format_xml_output(self, root: ET.Element, pretty: bool = True) -> str:
        """Format XML output — always consistent indentation + XML declaration.

        Both KSTV and epg.pw elements are re-serialised from the in-memory tree,
        so the output is uniform regardless of the original source formatting.
        The 'pretty' flag controls indentation (default True for readability).
        """
        if pretty:
            # ET.indent requires Python 3.9+ — strips any pre-existing tail whitespace
            # then re-indents the whole tree uniformly
            ET.indent(root, space="  ")

        xml_body = ET.tostring(root, encoding='unicode', method='xml')
        return '<?xml version="1.0" encoding="utf-8" ?>\n' + xml_body

    # -------------------------------------------------------------------------
    # Main processing
    # -------------------------------------------------------------------------

    def process_multiple_sources(self, config_file: str, output_file: str,
                                  cache_file: str = 'tv2_kstv_cache.xml',
                                  cache_hours: float = 6) -> bool:
        """Main processing — handles both KSTV bulk XML and epg.pw per-channel sources."""
        try:
            kstv_channels, epgpw_sources = self.load_config(config_file)

            if not kstv_channels and not epgpw_sources:
                logger.error("No valid sources found in configuration")
                return False

            all_channels: Dict   = {}
            all_programmes: List = []

            # --- KSTV: fetch once, filter by channel ID ---
            if kstv_channels:
                logger.info(f"Processing {len(kstv_channels)} KSTV channels (single fetch + cache)...")
                kstv_root = self.fetch_full_kstv_epg(cache_file, cache_hours)
                if kstv_root is not None:
                    channels, programmes = self.filter_kstv_channels(kstv_root, kstv_channels)
                    all_channels.update(channels)
                    all_programmes.extend(programmes)
                    logger.info(f"KSTV: added {len(channels)} channels, {len(programmes)} programmes")
                else:
                    logger.warning("KSTV EPG fetch failed — skipping KSTV channels")

            # --- epg.pw: fetch each channel in parallel ---
            if epgpw_sources:
                max_workers = min(10, len(epgpw_sources))
                logger.info(f"Fetching {len(epgpw_sources)} epg.pw channels in parallel (workers={max_workers})")
                with ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = {executor.submit(self.fetch_epgpw_source, src): src for src in epgpw_sources}
                    for future in as_completed(futures):
                        src = futures[future]
                        try:
                            channel, programmes = future.result()
                            if channel is not None:
                                all_channels[src['channel_id']] = channel
                                all_programmes.extend(programmes)
                        except Exception as e:
                            logger.error(f"Failed: {src['display_name']}: {e}")

            if not all_channels:
                logger.warning("No matching channels found!")
                return False

            logger.info(f"Before filtering: {len(all_channels)} channels, {len(all_programmes)} programmes")
            logger.info(f"Current UTC time: {self.current_time.strftime('%Y-%m-%d %H:%M:%S UTC')}")

            # Filter past programmes
            all_programmes = self.filter_future_programs(all_programmes)

            # Per-channel cap (100 per channel)
            all_programmes = self.limit_programs_per_channel(all_programmes)

            # Global 900 cap with equal distribution
            all_programmes = self.limit_programs_equally(all_programmes, len(all_channels))

            # Build and write output
            combined_root    = self.create_combined_xml(all_channels, all_programmes)
            formatted_output = self.format_xml_output(combined_root)

            os.makedirs(os.path.dirname(output_file) or '.', exist_ok=True)
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(formatted_output)

            logger.info(f"Combined EPG XML saved to: {output_file}")
            logger.info(f"Total channels: {len(all_channels)}, Total programmes: {len(all_programmes)}")
            return True

        except Exception as e:
            logger.error(f"Error processing sources: {e}")
            return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='TV2 Multi-XML Processor — KSTV bulk XML + epg.pw per-channel with auto-date update'
    )
    parser.add_argument('--config', '-c', default='TV2_multi_xml_config.txt',
                        help='Configuration file with XML sources')
    parser.add_argument('--output', '-o', required=True,
                        help='Output EPG XML file path')
    parser.add_argument('--cache', default='tv2_kstv_cache.xml',
                        help='KSTV cache file path (default: tv2_kstv_cache.xml)')
    parser.add_argument('--cache-hours', type=float, default=6,
                        help='KSTV cache expiry in hours (default: 6)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Enable verbose logging')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if not os.path.exists(args.config):
        logger.error(f"Configuration file not found: {args.config}")
        return 1

    processor = TV2MultiXMLProcessor()
    success = processor.process_multiple_sources(
        args.config, args.output, args.cache, args.cache_hours
    )
    return 0 if success else 1


if __name__ == "__main__":
    exit(main())

##!/usr/bin/env python3
"""
KSTV Sports EPG Processor
Fetches full XML from kstv.us ONCE, then filters only channels listed in config
Features: Airtime merging for consecutive programmes with same title and description
"""

import argparse
import xml.etree.ElementTree as ET
import requests
import requests.adapters
import os
import logging
from datetime import datetime, timezone, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

KSTV_EPG_URL = "http://kstv.us:8080/xmltv.php?type=xml"

class KSTVSportsProcessor:

    def __init__(self):
        self.current_time = datetime.now(timezone.utc)
        self.max_programs = 900                  # Global cap across all channels
        self.max_programs_per_channel = 100      # Per-channel early limit
        self.session = requests.Session()
        adapter = requests.adapters.HTTPAdapter(
            pool_connections=5,
            pool_maxsize=5,
            max_retries=3
        )
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)

    def load_config(self, config_file):
        """Load channel list from config file.
        Returns:
            kstv_channels: dict {channel_id: display_name} for kstv sources
            epgpw_sources: list of {channel_id, url, display_name} for epg.pw sources
        """
        kstv_channels = {}
        epgpw_sources = []
        try:
            with open(config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and not line.startswith('='):
                        # Split on first 2 pipes only - display name may contain pipes
                        parts = line.split('|', 2)
                        if len(parts) >= 3:
                            channel_id = parts[0].strip()
                            url = parts[1].strip()
                            display_name = parts[2].strip()
                            # Detect epg.pw by numeric channel_id or epg.pw in URL
                            if channel_id.isdigit() or 'epg.pw' in url:
                                epgpw_sources.append({
                                    'channel_id': channel_id,
                                    'url': url,
                                    'display_name': display_name
                                })
                            else:
                                # kstv source - first display name wins
                                if channel_id not in kstv_channels:
                                    kstv_channels[channel_id] = display_name
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_file}")
        logger.info(f"Loaded {len(kstv_channels)} kstv channels, {len(epgpw_sources)} epg.pw channels")
        return kstv_channels, epgpw_sources

    def fetch_full_epg(self, cache_file='kstv_cache.xml', cache_hours=6):
        """Fetch the full KSTV EPG XML with local caching."""
        import time

        # Check if valid cache exists
        if os.path.exists(cache_file):
            age_hours = (time.time() - os.path.getmtime(cache_file)) / 3600
            if age_hours < cache_hours:
                logger.info(f"Using cached EPG ({age_hours:.1f}h old, limit {cache_hours}h)")
                try:
                    tree = ET.parse(cache_file)
                    return tree.getroot()
                except Exception as e:
                    logger.warning(f"Cache read failed: {e} — re-fetching")

        # Fetch fresh
        logger.info(f"Fetching full EPG from kstv.us (public URL)...")
        try:
            response = self.session.get(KSTV_EPG_URL, timeout=120)
            response.raise_for_status()

            # Save to cache
            with open(cache_file, 'wb') as f:
                f.write(response.content)
            logger.info(f"EPG cached to {cache_file}")

            root = ET.fromstring(response.content)
            logger.info("Successfully fetched full EPG")
            return root
        except Exception as e:
            logger.error(f"Failed to fetch EPG: {e}")
            # Try stale cache as fallback
            if os.path.exists(cache_file):
                logger.warning("Using stale cache as fallback")
                try:
                    tree = ET.parse(cache_file)
                    return tree.getroot()
                except:
                    pass
            return None

    def parse_time(self, time_str):
        """Parse EPG time string to UTC datetime, respecting timezone offset."""
        try:
            time_str = time_str.strip()
            if len(time_str) > 14 and ('+' in time_str[14:] or '-' in time_str[14:]):
                # Has timezone offset e.g. "20260404060000 -0400"
                dt = datetime.strptime(time_str, '%Y%m%d%H%M%S %z')
                return dt.astimezone(timezone.utc)
            else:
                return datetime.strptime(time_str[:14], '%Y%m%d%H%M%S').replace(tzinfo=timezone.utc)
        except Exception:
            return None

    def format_time(self, dt):
        """Format datetime back to EPG time string."""
        return dt.strftime('%Y%m%d%H%M%S') + ' +0000'

    def get_programme_key(self, programme):
        """Get title and description for comparison."""
        title_el = programme.find('title')
        desc_el = programme.find('desc')
        title = title_el.text.strip() if title_el is not None and title_el.text else ''
        desc = desc_el.text.strip() if desc_el is not None and desc_el.text else ''
        return title, desc

    def merge_programmes(self, programmes):
        """Merge consecutive programmes with same title and description per channel."""
        if not programmes:
            return programmes

        # Group by channel
        channel_programmes = {}
        for prog in programmes:
            ch_id = prog.get('channel')
            if ch_id not in channel_programmes:
                channel_programmes[ch_id] = []
            channel_programmes[ch_id].append(prog)

        merged_all = []
        total_merged = 0

        for ch_id, progs in channel_programmes.items():
            # Sort by start time
            progs.sort(key=lambda p: p.get('start', ''))

            merged = []
            current = progs[0]
            current_title, current_desc = self.get_programme_key(current)

            for next_prog in progs[1:]:
                next_title, next_desc = self.get_programme_key(next_prog)

                # Check if consecutive and same title+desc
                current_stop = self.parse_time(current.get('stop', ''))
                next_start = self.parse_time(next_prog.get('start', ''))

                if (current_title == next_title and
                    current_desc == next_desc and
                    current_desc != '' and
                    current_stop is not None and
                    next_start is not None and
                    current_stop == next_start):
                    # Merge — extend stop time of current
                    current.set('stop', next_prog.get('stop', current.get('stop')))
                    total_merged += 1
                    logger.debug(f"Merged: [{ch_id}] {current_title} → extended to {current.get('stop')}")
                else:
                    merged.append(current)
                    current = next_prog
                    current_title, current_desc = next_title, next_desc

            merged.append(current)
            merged_all.extend(merged)

        logger.info(f"Airtime merging: {len(programmes)} → {len(merged_all)} programmes ({total_merged} merged)")
        return merged_all

    def filter_channels(self, root, wanted_channels):
        """Filter only wanted channels and their programmes from full EPG."""
        out_channels = {}
        out_programmes = []

        # Extract matching channels
        for channel in root.findall('.//channel'):
            ch_id = channel.get('id')
            if ch_id in wanted_channels:
                disp = channel.find('display-name')
                if disp is not None:
                    disp.text = wanted_channels[ch_id]
                out_channels[ch_id] = channel

        # Extract ALL matching programmes WITHOUT time filter
        # Time filter happens AFTER merging to preserve currently airing content
        # Deduplicate by display name + start time + title + description
        seen_keys = set()
        for programme in root.findall('.//programme'):
            ch_id = programme.get('channel')
            if ch_id in wanted_channels:
                display_name = wanted_channels[ch_id]
                title_el = programme.find('title')
                desc_el = programme.find('desc')
                title = title_el.text if title_el is not None else ''
                desc = desc_el.text if desc_el is not None else ''
                key = f"{display_name}|{programme.get('start')}|{title}|{desc}"
                if key not in seen_keys:
                    seen_keys.add(key)
                    out_programmes.append(programme)

        logger.info(f"Filtered: {len(out_channels)} channels, {len(out_programmes)} programmes (deduplicated)")
        return out_channels, out_programmes

    def filter_past_programmes(self, programmes):
        """Filter out programmes that have completely aired. Run AFTER merging."""
        filtered = []
        for programme in programmes:
            stop_str = programme.get('stop', '')
            try:
                stop_time = self.parse_time(stop_str)
                if stop_time is not None and stop_time > self.current_time:
                    filtered.append(programme)
                elif stop_time is None:
                    filtered.append(programme)
            except Exception:
                filtered.append(programme)
        logger.info(f"Time filter: kept {len(filtered)} programmes (removed {len(programmes) - len(filtered)} past)")
        return filtered

    def limit_programs_per_channel(self, programmes):
        """Early per-channel limit: cap each channel at max_programs_per_channel."""
        channel_programs = {}
        for program in programmes:
            ch_id = program.get('channel')
            if ch_id not in channel_programs:
                channel_programs[ch_id] = []
            channel_programs[ch_id].append(program)

        limited = []
        for ch_id, progs in channel_programs.items():
            if len(progs) > self.max_programs_per_channel:
                logger.info(f"Per-channel limit [{ch_id}]: {len(progs)} -> {self.max_programs_per_channel} programmes")
                limited.extend(progs[:self.max_programs_per_channel])
            else:
                limited.extend(progs)

        logger.info(f"Per-channel limiting: {len(programmes)} -> {len(limited)} programmes")
        return limited

    def limit_programs_equally(self, programmes, num_channels):
        """Global 900 cap with equal distribution across channels."""
        if len(programmes) <= self.max_programs:
            logger.info(f"Total programmes ({len(programmes)}) under global cap ({self.max_programs}), no limiting needed")
            return programmes

        programs_per_channel = self.max_programs // num_channels
        remaining = self.max_programs % num_channels

        logger.info(f"Global cap: {len(programmes)} -> {self.max_programs} ({programs_per_channel} per channel)")

        channel_programs = {}
        for program in programmes:
            ch_id = program.get('channel')
            if ch_id not in channel_programs:
                channel_programs[ch_id] = []
            channel_programs[ch_id].append(program)

        limited = []
        extra = remaining
        for ch_id, progs in channel_programs.items():
            limit = programs_per_channel + (1 if extra > 0 else 0)
            if extra > 0:
                extra -= 1
            actual = min(limit, len(progs))
            limited.extend(progs[:actual])
            logger.info(f"Global cap [{ch_id}]: {len(progs)} -> {actual} programmes")

        logger.info(f"Final total programmes: {len(limited)}")
        return limited

    def build_output(self, channels, programmes):
        """Build output XML with proper formatting."""
        root = ET.Element("tv")
        root.set('date', datetime.now().strftime("%Y%m%d%H%M%S"))
        root.set('generator-info-name', 'KSTV-Sports-Processor')
        root.set('generator-info-url', 'https://github.com/r56wdvm6d5-cloud/epguk')
        root.set('source-info-name', 'KSTV-Sports-EPG')

        for channel in channels.values():
            # channels dict can contain ET.Element or string (display name)
            if isinstance(channel, ET.Element):
                root.append(channel)
        for programme in programmes:
            root.append(programme)

        # Pretty print with proper indentation and XML declaration
        ET.indent(root, space="  ")
        xml_body = ET.tostring(root, encoding='unicode', method='xml')
        return '<?xml version="1.0" encoding="utf-8" ?>\n' + xml_body

    def fetch_epgpw_source(self, source):
        """Fetch a single epg.pw channel XML and extract channel + programmes."""
        import re
        from datetime import datetime
        url = source['url']
        display_name = source['display_name']
        channel_id = source['channel_id']

        # Update date in URL to today
        today = datetime.now().strftime("%Y%m%d")
        url = re.sub(r'date=\d{8}', f'date={today}', url)

        try:
            logger.info(f"Fetching epg.pw: {display_name}")
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            root = ET.fromstring(response.content)

            # Get channel element and override display name
            channel = root.find('.//channel')
            if channel is not None:
                channel.set('id', channel_id)
                disp = channel.find('display-name')
                if disp is not None:
                    disp.text = display_name
                else:
                    disp = ET.SubElement(channel, 'display-name')
                    disp.text = display_name

            # Get programmes and update channel ref
            programmes = []
            for prog in root.findall('.//programme'):
                prog.set('channel', channel_id)
                programmes.append(prog)

            return channel, programmes
        except Exception as e:
            logger.error(f"Failed to fetch epg.pw source {display_name}: {e}")
            return None, []

    def process(self, config_file, output_file, cache_file='kstv_cache.xml', cache_hours=6):
        """Main processing function - handles both kstv and epg.pw sources."""
        kstv_channels, epgpw_sources = self.load_config(config_file)

        if not kstv_channels and not epgpw_sources:
            logger.error("No channels in config")
            return False

        all_channels = {}
        all_programmes = []

        # --- Process KSTV channels ---
        if kstv_channels:
            root = self.fetch_full_epg(cache_file, cache_hours)
            if root is not None:
                channels, programmes = self.filter_channels(root, kstv_channels)
                all_channels.update(channels)
                all_programmes.extend(programmes)
                logger.info(f"KSTV: {len(channels)} channels, {len(programmes)} programmes")

        # --- Process epg.pw channels in parallel ---
        if epgpw_sources:
            max_workers = min(10, len(epgpw_sources))
            logger.info(f"Fetching {len(epgpw_sources)} epg.pw channels in parallel (workers={max_workers})")
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                futures = {executor.submit(self.fetch_epgpw_source, source): source for source in epgpw_sources}
                for future in as_completed(futures):
                    source = futures[future]
                    try:
                        channel, programmes = future.result()
                        if channel is not None:
                            all_channels[source['channel_id']] = channel
                            all_programmes.extend(programmes)
                    except Exception as e:
                        logger.error(f"Failed: {source['display_name']}: {e}")

        if not all_channels:
            logger.warning("No matching channels found!")
            return False

        # Merge FIRST - preserves currently airing content
        all_programmes = self.merge_programmes(all_programmes)

        # Filter past AFTER merging
        all_programmes = self.filter_past_programmes(all_programmes)

        # Per-channel limit (100 per channel)
        all_programmes = self.limit_programs_per_channel(all_programmes)

        # Global 900 cap with equal distribution
        all_programmes = self.limit_programs_equally(all_programmes, len(all_channels))

        output = self.build_output(all_channels, all_programmes)

        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(output)

        logger.info(f"Output saved to: {output_file}")
        logger.info(f"Total channels: {len(all_channels)}, Total programmes: {len(all_programmes)}")
        return True


def main():
    parser = argparse.ArgumentParser(description='KSTV Sports EPG Processor')
    parser.add_argument('--config', '-c', required=True, help='Config file path')
    parser.add_argument('--output', '-o', required=True, help='Output XML file path')
    parser.add_argument('--cache', default='kstv_cache.xml', help='Cache file path (default: kstv_cache.xml)')
    parser.add_argument('--cache-hours', type=float, default=6, help='Cache expiry in hours (default: 6)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    processor = KSTVSportsProcessor()
    success = processor.process(args.config, args.output, args.cache, args.cache_hours)
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())

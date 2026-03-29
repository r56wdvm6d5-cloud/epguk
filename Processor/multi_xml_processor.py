#!/usr/bin/env python3
"""
Multi-XML Processor with Auto-Date Update
Fetches and combines multiple XML sources into one EPG file
"""

import argparse
import xml.etree.ElementTree as ET
import xml.dom.minidom
import requests
import re
from datetime import datetime
import os
import logging
from typing import List, Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MultiXMLProcessor:
    """Process multiple XML sources and combine them into one EPG file."""
    
    def __init__(self):
        self.channels = {}
        self.programs = []
    
    def load_config(self, config_file: str) -> List[Dict[str, str]]:
        """Load configuration from file."""
        sources = []
        
        try:
            with open(config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        parts = line.split('|')
                        if len(parts) == 3:
                            sources.append({
                                'channel_id': parts[0].strip(),
                                'url': parts[1].strip(),
                                'display_name': parts[2].strip()
                            })
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_file}")
        
        logger.info(f"Loaded {len(sources)} XML sources from config")
        return sources
    
    def fetch_xml(self, url: str) -> ET.Element:
        """Fetch XML from URL."""
        try:
            logger.info(f"Fetching XML from: {url}")
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            
            # Parse XML
            root = ET.fromstring(response.content)
            return root
            
        except requests.RequestException as e:
            logger.error(f"Failed to fetch XML from {url}: {e}")
            return None
        except ET.ParseError as e:
            logger.error(f"Failed to parse XML from {url}: {e}")
            return None
    
    def extract_channel_data(self, root: ET.Element, source_info: Dict[str, str]) -> None:
        """Extract channel information from XML."""
        channel = root.find(".//channel")
        if channel is not None:
            channel_id = source_info['channel_id']
            display_name = source_info['display_name']
            
            # Use provided display name or fall back to XML
            existing_display = channel.find(".//display-name")
            if existing_display is not None:
                existing_display.text = display_name
            else:
                # Add display-name element if missing
                display_elem = ET.SubElement(channel, "display-name")
                display_elem.set('lang', 'en')
                display_elem.text = display_name
            
            # Ensure channel ID matches
            channel.set('id', channel_id)
            self.channels[channel_id] = channel
    
    def extract_program_data(self, root: ET.Element, source_info: Dict[str, str]) -> None:
        """Extract program data from XML."""
        channel_id = source_info['channel_id']
        
        programs = root.findall(".//programme")
        for program in programs:
            # Update channel ID to match our config
            program.set('channel', channel_id)
            self.programs.append(program)
        
        logger.info(f"Extracted {len(programs)} programs for channel {channel_id}")
    
    def process_source(self, source_info: Dict[str, str]) -> bool:
        """Process a single XML source."""
        # Update date parameter to current date
        current_date = datetime.now().strftime("%Y%m%d")
        url = source_info['url']
        
        # Replace date in URL with current date
        if 'date=' in url:
            url = re.sub(r'date=\d{8}', f'date={current_date}', url)
            logger.info(f"Updated date in URL: {url}")
        
        root = self.fetch_xml(url)
        if root is None:
            return False
        
        self.extract_channel_data(root, source_info)
        self.extract_program_data(root, source_info)
        return True
    
    def create_combined_xml(self) -> ET.Element:
        """Create combined XML output."""
        # Create root element
        root = ET.Element("tv")
        root.set('date', datetime.now().strftime("%Y%m%d%H%M%S %z"))
        root.set('generator-info-name', 'Multi-XML-Processor')
        root.set('generator-info-url', 'https://github.com/r56wdvm6d5-cloud/epguk')
        root.set('source-info-name', 'Multi-Source-EPG')
        
        # Add all channels
        for channel_id, channel in self.channels.items():
            root.append(channel)
        
        # Add all programs
        for program in self.programs:
            root.append(program)
        
        return root
    
    def format_xml_output(self, root: ET.Element) -> str:
        """Format XML output with proper indentation."""
        rough_string = ET.tostring(root, encoding='unicode')
        reparsed = xml.dom.minidom.parseString(rough_string)
        pretty_xml = reparsed.toprettyxml(indent="  ")
        
        # Remove empty lines
        lines = [line for line in pretty_xml.split('\n') if line.strip()]
        return '\n'.join(lines)
    
    def process_multiple_sources(self, config_file: str, output_file: str) -> bool:
        """Main processing function."""
        try:
            # Load configuration
            sources = self.load_config(config_file)
            if not sources:
                logger.error("No valid sources found in configuration")
                return False
            
            # Process each source
            success_count = 0
            for source in sources:
                if self.process_source(source):
                    success_count += 1
            
            logger.info(f"Successfully processed {success_count}/{len(sources)} sources")
            
            # Create combined output
            combined_root = self.create_combined_xml()
            formatted_output = self.format_xml_output(combined_root)
            
            # Ensure output directory exists
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            
            # Write to file
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(formatted_output)
            
            logger.info(f"Combined EPG XML saved to: {output_file}")
            logger.info(f"Total channels: {len(self.channels)}")
            logger.info(f"Total programs: {len(self.programs)}")
            
            return True
            
        except Exception as e:
            logger.error(f"Error processing multiple sources: {e}")
            return False

def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Process multiple XML sources into one EPG file with auto-date update')
    parser.add_argument('--config', '-c', default='multi_xml_config.txt', 
                       help='Configuration file with XML sources')
    parser.add_argument('--output', '-o', required=True, 
                       help='Output EPG XML file path')
    parser.add_argument('--verbose', '-v', action='store_true', 
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Validate config file exists
    if not os.path.exists(args.config):
        logger.error(f"Configuration file not found: {args.config}")
        return 1
    
    # Process multiple sources
    processor = MultiXMLProcessor()
    success = processor.process_multiple_sources(args.config, args.output)
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())

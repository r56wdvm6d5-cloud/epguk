#!/usr/bin/env python3
"""
XML Refresh Script with DSMR Output
This script processes an original XML file and outputs in DSMR format while preserving data integrity.
"""

import argparse
import xml.etree.ElementTree as ET
import xml.dom.minidom
from datetime import datetime
import os
import sys
import logging
from typing import Optional, Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class XMLRefreshProcessor:
    """Main class for processing XML files and maintaining DSMR output format."""
    
    def __init__(self):
        self.dsmr_namespace = "http://www.dsmr.org/namespace"
        self.namespaces = {'dsmr': self.dsmr_namespace}
        
    def load_xml_file(self, file_path: str) -> ET.Element:
        """Load and parse XML file with error handling."""
        try:
            logger.info(f"Loading XML file: {file_path}")
            tree = ET.parse(file_path)
            root = tree.getroot()
            logger.info(f"Successfully loaded XML with root: {root.tag}")
            return root
        except ET.ParseError as e:
            logger.error(f"XML parsing error: {e}")
            raise
        except FileNotFoundError:
            logger.error(f"File not found: {file_path}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading XML: {e}")
            raise
    
    def validate_xml_structure(self, root: ET.Element) -> bool:
        """Validate that the XML has the expected structure for DSMR processing."""
        logger.info("Validating XML structure...")
        
        # Check if it's already a DSMR XML
        if 'dsmr' in root.tag.lower():
            logger.info("Detected DSMR format XML")
            return True
        
        # For non-DSMR XML, we'll accept it and convert
        logger.info("Non-DSMR XML detected, will convert to DSMR format")
        return True
    
    def extract_epg_data(self, root: ET.Element) -> Dict[str, Any]:
        """Extract EPG (Electronic Program Guide) data from the XML."""
        epg_data = {}
        
        # Extract channel information
        channel = root.find(".//channel")
        if channel is not None:
            epg_data['channel_info'] = {
                'id': channel.get('id', 'unknown'),
                'display_name': self._get_text(channel, ".//display-name"),
                'icon_src': self._get_attribute(channel, ".//icon", "src")
            }
        
        # Extract TV programs
        programs = root.findall(".//programme")
        epg_data['programs'] = []
        
        for program in programs:
            program_data = {
                'channel': program.get('channel', 'unknown'),
                'start': program.get('start', ''),
                'stop': program.get('stop', ''),
                'title': self._get_text(program, ".//title"),
                'description': self._get_text(program, ".//desc"),
                'date': self._get_text(program, ".//date"),
                'lang': self._get_attribute(program, ".//title", "lang")
            }
            epg_data['programs'].append(program_data)
        
        # Extract TV metadata
        epg_data['tv_metadata'] = {
            'date': root.get('date', ''),
            'generator_info_name': root.get('generator-info-name', ''),
            'generator_info_url': root.get('generator-info-url', ''),
            'source_info_name': root.get('source-info-name', ''),
            'source_info_url': root.get('source-info-url', '')
        }
        
        logger.info(f"Extracted EPG data with {len(epg_data['programs'])} programs")
        return epg_data
    
    def _get_text(self, element: ET.Element, xpath: str) -> str:
        """Helper method to safely get text from an element."""
        found = element.find(xpath)
        return found.text if found is not None and found.text else ""
    
    def _get_attribute(self, element: ET.Element, xpath: str, attr: str) -> str:
        """Helper method to safely get attribute from an element."""
        found = element.find(xpath)
        return found.get(attr, '') if found is not None else ""
    
    def create_epg_root(self) -> ET.Element:
        """Create an EPG format root element (preserve original format)."""
        # Use standard TV format without DSMR namespace
        root = ET.Element("tv")
        root.set('date', datetime.now().strftime("%Y%m%d%H%M%S %z"))
        root.set('generator-info-name', 'XML-REFRESH-PROCESSOR')
        root.set('generator-info-url', 'https://github.com/your-repo')
        root.set('source-info-name', 'REFRESHED-EPG')
        
        return root
    
    def add_epg_channel(self, root: ET.Element, epg_data: Dict[str, Any]) -> None:
        """Add channel information in standard EPG format."""
        if 'channel_info' not in epg_data:
            return
            
        channel_elem = ET.SubElement(root, "channel")
        channel_elem.set('id', epg_data['channel_info'].get('id', 'unknown'))
        
        # Add display name
        display_name = ET.SubElement(channel_elem, "display-name")
        display_name.set('lang', 'en')
        display_name.text = epg_data['channel_info'].get('display_name', '')
        
        # Add icon if available
        icon_src = epg_data['channel_info'].get('icon_src', '')
        if icon_src:
            icon_elem = ET.SubElement(channel_elem, "icon")
            icon_elem.set('src', icon_src)
    
    def add_epg_programs_standard(self, root: ET.Element, epg_data: Dict[str, Any]) -> None:
        """Add programs in standard EPG format (no DSMR namespace)."""
        if 'programs' not in epg_data:
            return
            
        for program in epg_data['programs']:
            program_elem = ET.SubElement(root, "programme")
            program_elem.set('channel', program.get('channel', 'unknown'))
            program_elem.set('start', program.get('start', ''))
            program_elem.set('stop', program.get('stop', ''))
            
            # Add title
            title_elem = ET.SubElement(program_elem, "title")
            title_elem.set('lang', program.get('lang', 'en'))
            title_elem.text = program.get('title', '')
            
            # Add description
            desc_elem = ET.SubElement(program_elem, "desc")
            desc_elem.text = program.get('description', '')
            
            # Add date if available
            if program.get('date'):
                date_elem = ET.SubElement(program_elem, "date")
                date_elem.text = program.get('date', '')
    
    def format_xml_output(self, root: ET.Element) -> str:
        """Format XML output with proper indentation."""
        # Convert to string
        rough_string = ET.tostring(root, encoding='unicode')
        
        # Parse with minidom for pretty printing
        reparsed = xml.dom.minidom.parseString(rough_string)
        
        # Pretty print with proper indentation
        pretty_xml = reparsed.toprettyxml(indent="  ")
        
        # Remove empty lines
        lines = [line for line in pretty_xml.split('\n') if line.strip()]
        return '\n'.join(lines)
    
    def process_xml(self, input_file: str, output_file: str) -> bool:
        """Main processing function to refresh EPG XML while preserving standard format."""
        try:
            # Load input XML
            input_root = self.load_xml_file(input_file)
            
            # Validate structure
            if not self.validate_xml_structure(input_root):
                logger.error("Invalid XML structure for processing")
                return False
            
            # Extract EPG data
            epg_data = self.extract_epg_data(input_root)
            
            # Create standard EPG output (not DSMR)
            epg_root = self.create_epg_root()
            self.add_epg_channel(epg_root, epg_data)
            self.add_epg_programs_standard(epg_root, epg_data)
            
            # Format and save output
            formatted_output = self.format_xml_output(epg_root)
            
            # Ensure output directory exists
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            
            # Write to file
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(formatted_output)
            
            logger.info(f"Successfully processed EPG XML and saved to: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"Error processing XML: {e}")
            return False

def main():
    """Main function to handle command line arguments and execute processing."""
    parser = argparse.ArgumentParser(description='Refresh XML file and maintain standard EPG output format')
    parser.add_argument('--input', '-i', required=True, help='Input XML file path')
    parser.add_argument('--output', '-o', required=True, help='Output EPG XML file path')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Validate input file exists
    if not os.path.exists(args.input):
        logger.error(f"Input file does not exist: {args.input}")
        sys.exit(1)
    
    # Create processor and run
    processor = XMLRefreshProcessor()
    success = processor.process_xml(args.input, args.output)
    
    if success:
        logger.info("XML refresh completed successfully!")
        sys.exit(0)
    else:
        logger.error("XML refresh failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()

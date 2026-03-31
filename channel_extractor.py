#!/usr/bin/env python3
"""
Channel Information Extractor
Extracts channel_id, link, and channel name from EPG XML URLs
"""

import xml.etree.ElementTree as ET
import urllib.parse
import urllib.request
import sys
import re

def extract_channel_info(url):
    """
    Extract channel information from EPG XML URL
    Returns: channel_id|link|channel_name format
    """
    try:
        # Extract channel_id from URL
        parsed_url = urllib.parse.urlparse(url)
        query_params = urllib.parse.parse_qs(parsed_url.query)
        
        if 'channel_id' not in query_params:
            return "Error: channel_id not found in URL"
        
        channel_id = query_params['channel_id'][0]
        
        # Fetch and parse XML
        with urllib.request.urlopen(url) as response:
            xml_content = response.read().decode('utf-8')
        
        # Parse XML
        root = ET.fromstring(xml_content)
        
        # Find channel element
        channel_elem = root.find(f".//channel[@id='{channel_id}']")
        if channel_elem is None:
            return f"Error: Channel {channel_id} not found in XML"
        
        # Get display-name (channel name)
        display_name_elem = channel_elem.find('display-name')
        if display_name_elem is None:
            channel_name = f"Channel_{channel_id}"
        else:
            channel_name = display_name_elem.text or f"Channel_{channel_id}"
        
        # Create the base URL for the channel
        base_url = f"https://epg.pw/api/epg.xml?channel_id={channel_id}"
        
        # Format output
        result = f"{channel_id}|{base_url}|{channel_name}"
        return result
        
    except Exception as e:
        return f"Error: {str(e)}"

def extract_from_m3u_line(line):
    """
    Extract channel info from M3U line format
    Example: #EXTINF:-1 group-title="TV SHOWS",Citytv Calgary
    """
    # Extract channel name from M3U line
    match = re.search(r'#EXTINF:-1.*?,(.+)', line)
    if match:
        channel_name = match.group(1).strip()
        return channel_name
    return None

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 channel_extractor.py <epg_url>")
        print("  python3 channel_extractor.py <epg_url> <m3u_line>")
        print("\nExample:")
        print("  python3 channel_extractor.py 'https://epg.pw/api/epg.xml?lang=en&timezone=QXNpYS9LYXJhY2hp&date=20260325&channel_id=470612'")
        print("  python3 channel_extractor.py 'https://epg.pw/api/epg.xml?lang=en&timezone=QXNpYS9LYXJhY2hp&date=20260325&channel_id=470612' '#EXTINF:-1 group-title=\"TV SHOWS\",Citytv Calgary'")
        return
    
    url = sys.argv[1]
    
    if len(sys.argv) == 3:
        # With M3U line provided
        m3u_line = sys.argv[2]
        channel_name = extract_from_m3u_line(m3u_line)
        
        # Extract channel_id from URL
        parsed_url = urllib.parse.urlparse(url)
        query_params = urllib.parse.parse_qs(parsed_url.query)
        channel_id = query_params.get('channel_id', [''])[0]
        
        if channel_id and channel_name:
            base_url = f"https://epg.pw/api/epg.xml?channel_id={channel_id}"
            result = f"{channel_id}|{base_url}|{channel_name}"
            print(result)
        else:
            print("Error: Could not extract channel_id or channel_name")
    else:
        # Extract from XML only
        result = extract_channel_info(url)
        print(result)

if __name__ == "__main__":
    main()

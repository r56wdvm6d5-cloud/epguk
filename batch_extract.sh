#!/bin/bash

# Navigate to the directory
cd "/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"

# Check if urls.txt exists
if [ ! -f "urls.txt" ]; then
    echo "Error: urls.txt not found. Please create urls.txt with your URLs (one per line)"
    exit 1
fi

echo "Processing URLs from urls.txt..."

# Clear previous output and process all URLs
> channels.txt
while read url; do 
    if [ ! -z "$url" ]; then
        echo "Processing: $url"
        python3 channel_extractor.py "$url" >> channels.txt
    fi
done < urls.txt

echo "Results saved to channels.txt:"
cat channels.txt
echo "Total channels processed: $(wc -l < channels.txt)"

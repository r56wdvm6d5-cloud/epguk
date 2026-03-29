#!/bin/bash
cd "/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Doc2/Doc2 multi_processor"
python3 Doc2_multi_xml_processor.py --config "../Doc2 config_txt/Doc2_multi_xml_config.txt" --output "../Doc2 Github/Doc2_Doc2_epg.xml"
cd "/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"
cp "/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Doc2/Doc2 Github/Doc2_Doc2_epg.xml" "./Doc2_Doc2_epg.xml"
git add "Doc2_Doc2_epg.xml"
git commit -m "Update DOC2 EPG XML file"
git push --force origin main

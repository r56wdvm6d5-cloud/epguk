#!/bin/bash

# Usage: ./add_tv_source.sh TV7
# Place this script in the ROOT of your repo and run it from there

NEXT="$1"

if [ -z "$NEXT" ]; then
    echo "Usage: ./add_tv_source.sh TV7"
    exit 1
fi

SH_FILE="GITHUB ACTIIONS CORE/C0MBINE PROCESSOR/process_all_epg_sources.sh"

# Step 1: Create folder and copy files from TV5 (known working)
echo "Creating $NEXT folder..."
mkdir -p "GITHUB ACTIIONS CORE/$NEXT"
cp "GITHUB ACTIIONS CORE/TV5/TV5_multi_xml_processor.py" "GITHUB ACTIIONS CORE/$NEXT/${NEXT}_multi_xml_processor.py"
cp "GITHUB ACTIIONS CORE/TV5/TV5.txt" "GITHUB ACTIIONS CORE/$NEXT/${NEXT}.txt"
echo "✅ Folder and files created"

# Step 2-4: Use Python to reliably edit the .sh file
echo "Editing process_all_epg_sources.sh..."
python3 - << PYEOF
import re

sh_file = "GITHUB ACTIIONS CORE/C0MBINE PROCESSOR/process_all_epg_sources.sh"
next_tv = "$NEXT"

with open(sh_file, 'r') as f:
    content = f.read()

# --- Add variables after last TV*_OUTPUT= line ---
last_output = list(re.finditer(r'TV\d+_OUTPUT="GITHUB ACTIIONS CORE/TV\d+_epg\.xml"', content))
if last_output:
    insert_pos = last_output[-1].end()
    new_vars = (
        "\n\n"
        + next_tv + '_PROCESSOR_DIR="GITHUB ACTIIONS CORE/' + next_tv + '"\n'
        + next_tv + '_CONFIG="GITHUB ACTIIONS CORE/' + next_tv + '/' + next_tv + '.txt"\n'
        + next_tv + '_OUTPUT="GITHUB ACTIIONS CORE/' + next_tv + '_epg.xml"'
    )
    content = content[:insert_pos] + new_vars + content[insert_pos:]
    print("Variables added for " + next_tv)
else:
    print("ERROR: Could not find output variable block")
    exit(1)

# --- Add process call after last process_xml_source line ---
last_process = list(re.finditer(r'process_xml_source.*\|\| exit 1', content))
if last_process:
    insert_pos = last_process[-1].end()
    new_process = (
        '\nprocess_xml_source "$' + next_tv + '_PROCESSOR_DIR"'
        + '    "$' + next_tv + '_CONFIG"'
        + '    "$' + next_tv + '_OUTPUT"'
        + '    "' + next_tv + '"'
        + '                "' + next_tv + '_multi_xml_processor.py"'
        + '          || exit 1'
    )
    content = content[:insert_pos] + new_process + content[insert_pos:]
    print("Process call added for " + next_tv)
else:
    print("ERROR: Could not find process_xml_source block")
    exit(1)

with open(sh_file, 'w') as f:
    f.write(content)

print("process_all_epg_sources.sh updated successfully")
PYEOF

# Step 5: Commit and push safely
echo "Committing and pushing..."
git add "GITHUB ACTIIONS CORE/$NEXT/" "$SH_FILE"
git commit -m "Add $NEXT EPG source"
git fetch origin main
git rebase origin/main || git rebase --abort
git push origin HEAD:main

echo ""
echo "Done! $NEXT added successfully!"
echo "Remember to edit: GITHUB ACTIIONS CORE/$NEXT/${NEXT}.txt with your actual source URLs"
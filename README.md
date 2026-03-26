# XML Refresh with DSMR Output

This project provides shell and Python scripts to refresh from an original XML file while keeping the output in DSMR (Dutch Smart Meter Requirements) format.

## Files

- `refresh_xml.sh` - Main shell script for orchestrating the refresh process
- `xml_refresh.py` - Python script for XML processing and DSMR conversion
- `original.xml` - Sample input XML file for testing
- `README.md` - This documentation file

## Features

- **XML Validation**: Validates input XML structure before processing
- **DSMR Format Output**: Converts any XML format to standardized DSMR format
- **Backup System**: Automatically backs up previous outputs
- **Error Handling**: Comprehensive error handling and logging
- **Flexible Configuration**: Command-line options for custom input/output paths

## Requirements

- Python 3.6+
- Bash shell
- Standard XML libraries (xml.etree.ElementTree, xml.dom.minidom)

## Usage

### Quick Start

1. Make the shell script executable:
   ```bash
   chmod +x refresh_xml.sh
   ```

2. Run the refresh process:
   ```bash
   ./refresh_xml.sh
   ```

### Advanced Usage

#### Using Custom Input File
```bash
./refresh_xml.sh --input my_data.xml
```

#### Using Custom Output Directory
```bash
./refresh_xml.sh --output custom_output
```

#### Both Custom Input and Output
```bash
./refresh_xml.sh --input my_data.xml --output custom_output
```

#### Direct Python Usage
```bash
python3 xml_refresh.py --input original.xml --output output/dsmr_output.xml
```

#### Verbose Logging
```bash
python3 xml_refresh.py --input original.xml --output output/dsmr_output.xml --verbose
```

## Output Structure

The script generates DSMR-formatted XML with the following structure:

```xml
<dsmr xmlns="http://www.dsmr.org/namespace" version="1.0" timestamp="2024-03-26T...">
  <header>
    <timestamp>2024-03-26T...</timestamp>
    <version>1.0</version>
    <equipment_identifier>XML-REFRESH-PROCESSOR</equipment_identifier>
  </header>
  <meter_readings>
    <reading>
      <value>12345.67</value>
      <timestamp>2024-03-26T...</timestamp>
      <unit>kWh</unit>
      <type>electricity</type>
    </reading>
    <!-- More readings... -->
  </meter_readings>
  <device>
    <id>SMART-001</id>
    <type>smart_meter</type>
    <manufacturer>Generic</manufacturer>
  </device>
</dsmr>
```

## Directory Structure

After running the script, you'll have:

```
project/
├── refresh_xml.sh          # Main shell script
├── xml_refresh.py          # Python processing script
├── original.xml            # Input XML file
├── output/                 # Output directory
│   └── dsmr_output.xml    # Generated DSMR output
├── backup/                 # Backup directory
│   └── dsmr_output_*.xml  # Timestamped backups
└── README.md               # This file
```

## Error Handling

The scripts include comprehensive error handling:

- **Missing Input Files**: Clear error messages if input XML doesn't exist
- **Invalid XML**: Parsing errors are caught and reported
- **Permission Issues**: Directory creation and file write errors are handled
- **Python Dependencies**: Checks for required Python version and modules

## Logging

- Shell script provides colored output (green for info, yellow for warnings, red for errors)
- Python script uses standard logging with timestamps
- Verbose mode available for detailed debugging information

## Customization

### Modifying DSMR Namespace

Edit the `dsmr_namespace` variable in `xml_refresh.py`:

```python
self.dsmr_namespace = "http://your.custom.namespace"
```

### Adding Custom XML Parsing

Modify the `extract_meter_data()` method in `xml_refresh.py` to handle your specific XML structure.

### Changing Output Format

Edit the `create_dsmr_root()` and related methods to customize the DSMR output structure.

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure the shell script is executable (`chmod +x refresh_xml.sh`)
2. **Python Not Found**: Ensure Python 3 is installed and in your PATH
3. **XML Parse Errors**: Check that your input XML is well-formed
4. **Output Directory Issues**: The script creates directories automatically, but check write permissions

### Debug Mode

Run with verbose logging for detailed information:

```bash
./refresh_xml.sh
python3 xml_refresh.py --input original.xml --output output/dsmr_output.xml --verbose
```

## License

This project is provided as-is for educational and practical use. Feel free to modify and distribute according to your needs.

## Support

For issues or questions, please check the logging output and ensure all requirements are met before seeking additional support.

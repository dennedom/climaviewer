#!/usr/bin/env bash

# Settings
VENDOR_ID="0483"
PRODUCT_ID="5750"
CHANNELS=5
CHANNEL1="Wohnzimmer"
CHANNEL2="Keller"
CHANNEL3="Schlafzimmer"
CHANNEL4="Dachboden"
CHANNEL5="Garten"
CHANNEL6=""
CHANNEL7=""
CHANNEL8=""
DEFAULT_PORT=8010

# Init Vars
DEBUG=0
CSV_FILE=""
JSON_FILE=""
XML_FILE=""
PORT=$DEFAULT_PORT
WEB_MODE=0

# Utils
calc() { awk "BEGIN { print $*}"; }
showHelp() {
    echo "ClimaViewer Version 0.1"
    echo "Usage: $0 [-v] [-h] [-c <filename>] [-j <filename>] [-x <filename>] [-w [port]]"
    echo ""
    echo "Options:"
    echo "  -v        Enable verbose mode (debugging)."
    echo "  -h        Show this help message."
    echo "  -c        Write CSV output to the specified file."
    echo "  -j        Write JSON output to the specified file."
    echo "  -x        Write XML output to the specified file."
    echo "  -w        Start a webserver. Optionally specify the port (default: $PORT)."
    exit 0
}
debug() {
    [[ $DEBUG -eq 1 ]] && printf "%s - %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$@"
}

# Process command line options
while getopts "vhcjxw" opt; do
    case "$opt" in
        v) DEBUG=1 ;;
        h) showHelp ;;
        c) eval nextopt=${!OPTIND}
           if [[ -n $nextopt && $nextopt != -* ]] ; then
		       CSV_FILE="$nextopt"
           else
               CSV_FILE="."
           fi ;;
        j) eval nextopt=${!OPTIND}
           if [[ -n $nextopt && $nextopt != -* ]] ; then
		       JSON_FILE="$nextopt"
           else
               JSON_FILE="."
           fi ;;
        x) eval nextopt=${!OPTIND}
           if [[ -n $nextopt && $nextopt != -* ]] ; then
		       XML_FILE="$nextopt"
           else
               XML_FILE="."
           fi ;;		
        w) WEB_MODE=1
           # Check if the next positional parameter is a port number
           eval nextopt=${!OPTIND}
           if [[ -n $nextopt && $nextopt =~ ^[0-9]+$ ]] ; then
               if [[ $nextopt -ge 1 && $nextopt -le 65535 ]]; then
                   PORT=$nextopt
                   OPTIND=$((OPTIND + 1))
               else
                   echo "Invalid Port specified (not between 1 and 65535)"
                   exit 1
               fi
           else
               PORT="${OPTARG:-$DEFAULT_PORT}"
           fi ;;
        *) showHelp ;;
    esac
done

# Check for required tools
for tool in find udevadm xxd hexdump column jq awk nc; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: $tool is required but not installed."
        exit 1
    fi
done

# Find the device
DEVICE=$(find /dev -name 'hidraw*' -exec udevadm info -q property --name={} \; | grep -A 1 "$VENDOR_ID" | grep -A 1 "$PRODUCT_ID" | grep DEVNAME | awk -F= '{print $2}')

if [ -z "$DEVICE" ]; then
    echo "Error: Device not found!"
    exit 1
fi

debug "Found Device: $DEVICE"

# USB-HID-Report Header
HEADER_HEX="00"

# 64-Byte-Packet as Hex-Values (Payload)
PAYLOAD_HEX="7b 03 40 7d 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"

# Full Report (Header + Payload)
REPORT_HEX="${HEADER_HEX} ${PAYLOAD_HEX}"

# Convert Hex-values into binary data and save it in file
echo "$REPORT_HEX" | xxd -r -p > report.bin

if [[ ! -s report.bin ]]; then
    echo "Error: Failed to create report.bin"
    exit 1
fi

# Ensure cleanup on exit
trap 'rm -f report.bin; exec 3>&-' EXIT

# Open device for r/w in non-blocking mode
					
exec 3<> "$DEVICE" || { echo "Error: Failed to open device $DEVICE"; exit 1; }
sudo cat report.bin >&3
															   
					  
							 
 

# Read answer from device (non-blocking)
# Read max. 64 Bytes, - default size of HID Reports
RESPONSE=$(head -c 64 <&3 | hexdump -e '64/1 "%02X " "\n"')
				 

DATA=(${RESPONSE})
exec 3>&-  # Close Device
								
										

# Show response
debug "Response from device:"
debug "$RESPONSE"
								  
		  

CSVHELPER=""
JSONARRAY=()
XMLBODY=""
HTMLBODY=""
for (( counter=0; counter<CHANNELS; counter++ )); do
    T1=${DATA[1+3*$counter]}
    T2=${DATA[2+3*$counter]}
    HUM=$((0x${DATA[3+3*$counter]}))

    if [[ "$T1" == "FF" ]]; then
        TEMP=$((0x${T1}${T2} - 0xFFFF - 0x1))
    else
        TEMP=$((0x${T1}${T2}))
    fi

    TEMP=$(calc "$TEMP/10")
    CHANNEL_NAME_VAR="CHANNEL$((counter+1))"
    CHANNEL_NAME=${!CHANNEL_NAME_VAR}

    debug "-------------"
    debug "Channel $((counter+1)) - $CHANNEL_NAME"
    debug "Temperature: ${TEMP}°C"
    debug "Humidity: ${HUM}%"
    debug "-------------"
    
    # Check if Temperature is out of range
    if awk "BEGIN {exit !($TEMP >= 100 || $TEMP <= -100)}"; then
        TEMP="n/a"
        debug "Invalid Data: Temperature out of range"
    fi

    # Check if Humidity is out of range
    if awk "BEGIN {exit !($HUM >= 100 || $HUM <= 0)}"; then
        HUM="n/a"
        debug "Invalid Data: Humidity out of range"												   
    fi
    
    CSVHELPER+="$((counter+1));$CHANNEL_NAME;$TEMP;$HUM\n"

    # Prepare JSON array
    JSONARRAY+=("{\"Channel\":$((counter+1)),\"Name\":\"$CHANNEL_NAME\",\"Temperature\":\"$TEMP\",\"Humidity\":\"$HUM\"}")
    
    # Prepare XML data
    XMLBODY+=$(printf '<Channel number="%d"><Name>%s</Name><Temperature>%s</Temperature><Humidity>%s</Humidity></Channel>\n' $((counter+1)) "$CHANNEL_NAME" "$TEMP" "$HUM")

    # Prepare HTML data
    HTMLBODY+=$(printf "<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td></tr>\n" $((counter+1)) "$CHANNEL_NAME" "$TEMP" "$HUM")
done

# Output CSV
if [[ -n "$CSV_FILE" && "$CSV_FILE" != "." ]]; then
    echo -e "$CSVHELPER" > "$CSV_FILE"
    echo "CSV output written to $CSV_FILE"
elif [[ "$CSV_FILE" == "." ]]; then
    echo -e "$CSVHELPER"
fi

# Output JSON
if [[ -n "$JSON_FILE" && "$JSON_FILE" != "." ]]; then
    # Correct JSON format
    JSON_OUTPUT=$(printf "[%s]" "$(IFS=,; echo "${JSONARRAY[*]}")")
    echo "$JSON_OUTPUT" | jq . > "$JSON_FILE"
    echo "JSON output written to $JSON_FILE"
elif [[ "$JSON_FILE" == "." ]]; then
    # Correct JSON format
    JSON_OUTPUT=$(printf "[%s]" "$(IFS=,; echo "${JSONARRAY[*]}")")
    echo "$JSON_OUTPUT" | jq .
fi

# Output XML
if [[ -n "$XML_FILE" && "$XML_FILE" != "." ]]; then
    XML_HEADER="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    XML_ROOT="<Channels>$XMLBODY</Channels>"
    printf "%s\n%s\n" "$XML_HEADER" "$XML_ROOT" > "$XML_FILE"
    echo "XML output written to $XML_FILE"
elif [[ "$XML_FILE" == "." ]]; then
    XML_HEADER="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    XML_ROOT="<Channels>$XMLBODY</Channels>"
    printf "%s\n%s\n" "$XML_HEADER" "$XML_ROOT"
fi

# If web mode is enabled, start a simple web server
if [[ $WEB_MODE -eq 1 ]]; then
    echo "Starting web server on port $PORT..."
    while true; do
        # Update sensor data
        exec 3<> "$DEVICE" || { echo "Error: Failed to open device $DEVICE"; exit 1; }
        sudo cat report.bin >&3
        RESPONSE=$(head -c 64 <&3 | hexdump -e '64/1 "%02X " "\n"')
        DATA=(${RESPONSE})
        exec 3>&-

        HTMLBODY=""
        for (( counter=0; counter<CHANNELS; counter++ )); do
            T1=${DATA[1+3*$counter]}
            T2=${DATA[2+3*$counter]}
            HUM=$((0x${DATA[3+3*$counter]}))

            if [[ "$T1" == "FF" ]]; then
                TEMP=$((0x${T1}${T2} - 0xFFFF - 0x1))
            else
                TEMP=$((0x${T1}${T2}))
            fi

            TEMP=$(calc "$TEMP/10")

            if awk "BEGIN {exit !($TEMP >= 100 || $TEMP <= -100)}"; then
                TEMP="n/a"
            fi

            if awk "BEGIN {exit !($HUM >= 100 || $HUM <= 0)}"; then
                HUM="n/a"
            fi

            CHANNEL_NAME_VAR="CHANNEL$((counter+1))"
            CHANNEL_NAME=${!CHANNEL_NAME_VAR}
            
            HTMLBODY+=$(printf "<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td></tr>\n" $((counter+1)) "$CHANNEL_NAME" "$TEMP" "$HUM")
        done

        # Serve HTML content
        { echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <meta http-equiv='refresh' content='60'>
    <title>Sensor Data</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            padding: 0;
            color: #333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: center;
            border: 1px solid #ddd;
        }
        th {
            background-color: #f4f4f4;
        }
    </style>
</head>
<body>
    <h1>Sensor Data</h1>
    <table>
        <thead>
            <tr>
                <th>Channel</th>
                <th>Location</th>
                <th>Temperature [°C]</th>
                <th>Humidity [%]</th>
            </tr>
        </thead>
        <tbody>
            $HTMLBODY
        </tbody>
    </table>
</body>
</html>"; } | nc -l -p "$PORT" -q 1

        sleep 60
    done
fi

# If neither CSV, JSON, XML, nor web mode is specified, print the data to stdout
if [[ -z "$CSV_FILE" && -z "$JSON_FILE" && -z "$XML_FILE" && $WEB_MODE -eq 0 ]]; then
    echo -e "$CSVHELPER" | column -ts\; -o$'\t' -N "Channel,Location,Temperature [°C],Humidity [%]"
fi

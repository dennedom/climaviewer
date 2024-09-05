#!/usr/bin/env bash

# Configuration
DATABASE="/home/pi/ClimaViewer/sensor_data.db"
TABLE_NAME="sensor_readings"

# Function to create the SQLite database and table
create_database() {
    sqlite3 "$DATABASE" <<EOF
CREATE TABLE IF NOT EXISTS "$TABLE_NAME" (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    channel INTEGER,
    name TEXT,
    temperature REAL,
    humidity REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to create the table."
        exit 1
    fi
}

# Function to insert data into the database
insert_data() {
    local json_input="$1"

    # Use transaction to optimize multiple inserts
    sqlite3 "$DATABASE" <<EOF
BEGIN TRANSACTION;
$(echo "$json_input" | jq -c '.[]' | while read -r record; do
    local channel=$(echo "$record" | jq -r '.Channel')
    local name=$(echo "$record" | jq -r '.Name')
    local temperature=$(echo "$record" | jq -r '.Temperature')
    local humidity=$(echo "$record" | jq -r '.Humidity')

								 
    echo "INSERT INTO \"$TABLE_NAME\" (channel, name, temperature, humidity) VALUES ($channel, '$name', $temperature, $humidity);"
done)
COMMIT;
EOF

    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to insert data into the database."
        exit 1
    fi
}

# Main script
JSON_INPUT=""

# Check if JSON data is provided via stdin
if [ -p /dev/stdin ]; then
    JSON_INPUT=$(cat /dev/stdin)
elif [ -n "$1" ]; then
    # Check if a file path is provided as a parameter
    if [ -f "$1" ]; then
        JSON_INPUT=$(cat "$1")
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: The file '$1' does not exist."
        exit 1
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No input provided. Provide JSON data via stdin or as a file parameter."
    exit 1
fi

# Create the database and table
create_database

# Insert the data into the database
insert_data "$JSON_INPUT"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Data successfully inserted into the database."

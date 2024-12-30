<?php
header('Content-Type: application/json');

try {
    // Set timezone to CET/CEST
    date_default_timezone_set('Europe/Vienna');

    // Connect to the SQLite database
    $db = new SQLite3('/home/pi/ClimaViewer/sensor_data.db');

    // Begin a transaction to perform all operations as a single atomic unit
    $db->exec('BEGIN TRANSACTION;');

    // Delete records older than 72 hours
    $db->exec('DELETE FROM sensor_readings WHERE timestamp < datetime(\'now\', \'-72 hours\');');

    // Query to select all data ordered by timestamp in ascending order
    // $result = $db->query('SELECT * FROM sensor_readings ORDER BY timestamp ASC');
    $result = $db->query('SELECT id, channel, name, temperature, humidity, timestamp FROM sensor_readings WHERE id IN (SELECT MIN(id) FROM sensor_readings GROUP BY name, strftime(\'%Y-%m-%d %H:%M\', timestamp)) ORDER BY timestamp ASC;');      

    // Commit the transaction after all operations
    $db->exec('COMMIT;');

    // Fetch data
    $data = [];
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        // Convert timestamp to the correct timezone
        $date = new DateTime($row['timestamp'], new DateTimeZone('UTC'));
        $date->setTimezone(new DateTimeZone('Europe/Vienna'));
        $row['timestamp'] = $date->format('Y-m-d H:i:s');
        $data[] = $row;
    }

    // Output data as JSON
    echo json_encode($data);

} catch (Exception $e) {
    // Rollback the transaction if an error occurs
    if ($db) {
        $db->exec('ROLLBACK;');
    }
    // Output a JSON error message in case of an exception
    echo json_encode(['error' => $e->getMessage()]);

} finally {
    // Ensure the database connection is closed
    if ($db) {
        $db->close();
    }
}
?>

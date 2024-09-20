# ClimaViewer

ClimaViewer is a Linux-based tool designed to visualize and export temperature and humidity data from the DNT Raumklimastation RoomLogg PRO. It allows users to display real-time climate data and trends via a user-friendly web interface or in the console.

## Features
* Real-time monitoring of temperature and humidity via both web browser and console
* Data export for further analysis
* Visualized trends over time with graphs
* Runs out-of-the-box with basic shell commands – no need for additional environments like Python or Node.js
* Basic web view (without a web server) and extended web view (requires web server)

## Requirements
* Linux-based system (e.g., Raspbian on a Raspberry Pi)

## Configuration
1) Adjust the number and the names of channels in `cw.sh` (line 6-14)
2) Update the names of your channels in `web/climaviewer.php` (line 250-254)
3) Update the path to the SQLite DB in `db.sh` (line 4) and `web/get_data.php` (line 9)

Attach the USB cable to your device (e.g., Raspberry Pi or computer).

## Web View Setup
Create a cron job to fetch data every 5 minutes (`sudo crontab -e`):

```
*/5 * * * * /home/pi/ClimaViewer/cw.sh -j | /home/pi/ClimaViewer/db.sh >> /home/pi/ClimaViewer/logs/$(date '+\%Y-\%m')_ClimaViewer.log 2>&1
```
Update the paths according to your environment.

Copy the files from the web subfolder to a directory accessible by your web server (e.g., lighttpd). Example path: `/var/www/html/`.
![grafik](https://github.com/user-attachments/assets/a090c133-d87d-499c-afda-903b78d1f84a)

## Usage

```
Usage:
sudo ./cw.sh -h
ClimaViewer Version 0.1
Usage: ./cw.sh [-v] [-h] [-c <filename>] [-j <filename>] [-x <filename>] [-w [port]]

Options:
  -v        Enable verbose mode (debugging).
  -h        Show this help message.
  -c        Write CSV output to the specified file.
  -j        Write JSON output to the specified file.
  -x        Write XML output to the specified file.
  -w        Start a webserver. Optionally specify the port (default: 8010).
```
### Example console output
```
sudo ./cw.sh
Channel Location        Temperature [°C]        Humidity [%]
1       Wohnzimmer      24.9                    61
2       Keller          22.5                    64
3       Schlafzimmer    25.9                    56
4       Dachboden       26.9                    44
5       Garten          27.7                    49
```

### Example CSV Output
```
sudo ./cw.sh -c
1;Wohnzimmer;24.9;61
2;Keller;22.5;64
3;Schlafzimmer;25.9;56
4;Dachboden;26.9;44
5;Garten;27.7;49
```

### Example JSON Output
```
sudo ./cw.sh -j
[
  {
    "Channel": 1,
    "Name": "Wohnzimmer",
    "Temperature": "24.9",
    "Humidity": "61"
  },
  {
    "Channel": 2,
    "Name": "Keller",
    "Temperature": "22.5",
    "Humidity": "64"
  },
  {
    "Channel": 3,
    "Name": "Schlafzimmer",
    "Temperature": "26",
    "Humidity": "56"
  },
  {
    "Channel": 4,
    "Name": "Dachboden",
    "Temperature": "27",
    "Humidity": "44"
  },
  {
    "Channel": 5,
    "Name": "Garten",
    "Temperature": "27.7",
    "Humidity": "50"
  }
]
```

### Example XML Output
```
sudo ./cw.sh -x
<?xml version="1.0" encoding="UTF-8"?>
<Channels>
	<Channel number="1">
		<Name>Wohnzimmer</Name>
		<Temperature>24.9</Temperature>
		<Humidity>61</Humidity>
	</Channel>
	<Channel number="2">
		<Name>Keller</Name>
		<Temperature>22.5</Temperature>
		<Humidity>64</Humidity>
	</Channel>
	<Channel number="3">
		<Name>Schlafzimmer</Name>
		<Temperature>26</Temperature>
		<Humidity>56</Humidity>
	</Channel>
	<Channel number="4">
		<Name>Dachboden</Name>
		<Temperature>27</Temperature>
		<Humidity>44</Humidity>
	</Channel>
	<Channel number="5">
		<Name>Garten</Name>
		<Temperature>27.7</Temperature>
		<Humidity>50</Humidity>
	</Channel>
</Channels>
```
  
## Built-in Mini Webserver
```
sudo ./cw.sh -w
Starting web server on port 8010...
```
Output in Browser:
![grafik](https://github.com/user-attachments/assets/94c69249-af74-47de-9cc0-3b5b945a613b)

## Acknowledgment
Special thanks to [Jürgen](https://github.com/juergen-rocks/raumklima) for the foundational work that inspired this project.

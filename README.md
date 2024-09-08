# ClimaViewer

ClimaViewer is a Linux-based tool designed to visualize and export temperature and humidity data from the DNT Raumklimastation RoomLogg PRO. It allows users to display real-time climate data and trends via a user-friendly web interface or in the console.

## Features
* Temperature and humidity monitoring via web browser and console
* Data export functionality for further analysis
* Graphical representation of trends over time
* runs out-of-the box with basic shell commands – no need to install additional environments like python or nodejs
* basic Web-View (no extra webserver required) and extended Web-View (webserver required)

## Requirements
* Linux (e.g., Raspbian on Raspberry Pi)

## Configuration
1) Modify the amount and the names of your channels in cw.sh (line 6-14)
2) Modify the names of your channels in web/climaviewer.php (line 250-254)
3) Modify the path to the SQLite DB in db.sh (line 4) and web/get_data.php (line 9)

Attach USB-Cable to your device (computer, Raspberry Pi, ...)

## Web View
Create a crontab entry (__sudo crontab -e__):
```
*/5 * * * * /home/pi/ClimaViewer/cw.sh -j | /home/pi/ClimaViewer/db.sh >> /home/pi/ClimaViewer/logs/$(date '+\%Y-\%m')_ClimaViewer.log 2>&1
```
This entry fetches data every 5 minutes. Paths have to be adapted to your environment.

Files from web-Subfolder have to be placed in a folder accessible by an already installed webserver (e.g., lighttpd). Example: /var/www/html/
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
```
sudo ./cw.sh
Channel Location        Temperature [°C]        Humidity [%]
1       Wohnzimmer      24.9                    61
2       Keller          22.5                    64
3       Schlafzimmer    25.9                    56
4       Dachboden       26.9                    44
5       Garten          27.7                    49
```

### CSV Output
```
sudo ./cw.sh -c
1;Wohnzimmer;24.9;61
2;Keller;22.5;64
3;Schlafzimmer;25.9;56
4;Dachboden;26.9;44
5;Garten;27.7;49
```

### JSON Output
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

### XML Output
```
sudo ./cw.sh -x
<?xml version="1.0" encoding="UTF-8"?>
<Channels><Channel number="1"><Name>Wohnzimmer</Name><Temperature>24.9</Temperature><Humidity>61</Humidity></Channel><Channel number="2"><Name>Keller</Name><Temperature>22.5</Temperature><Humidity>64</Humidity></Channel><Channel number="3"><Name>Schlafzimmer</Name><Temperature>26</Temperature><Humidity>56</Humidity></Channel><Channel number="4"><Name>Dachboden</Name><Temperature>27</Temperature><Humidity>44</Humidity></Channel><Channel number="5"><Name>Garten</Name><Temperature>27.7</Temperature><Humidity>50</Humidity></Channel></Channels>
```
  
## Build-in Mini Webserver
```
sudo ./cw.sh -w
Starting web server on port 8010...
```
Output in Browser:
![grafik](https://github.com/user-attachments/assets/94c69249-af74-47de-9cc0-3b5b945a613b)


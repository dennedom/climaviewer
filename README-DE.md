# ClimaViewer

ClimaViewer ist ein Linux-basiertes Tool zur Visualisierung und zum Export von Temperatur- und Feuchtigkeitsdaten der DNT Raumklimastation RoomLogg PRO. Es ermöglicht Benutzern, Echtzeit-Klimadaten und Trends über eine benutzerfreundliche Weboberfläche oder in der Konsole anzuzeigen.

## Features
* Echtzeitüberwachung von Temperatur und Feuchtigkeit über Webbrowser und Konsole
* Datenexport zur weiteren Analyse
* Visualisierte Trends über Zeit mit Diagrammen
* Funktioniert mit standard Shell-Befehlen – keine Notwendigkeit für zusätzliche Umgebungen wie Python oder Node.js
* Basis Webansicht (ohne Webserver) und erweiterte Webansicht (erfordert Webserver)

## Anforderungen
* Linux-basiertes System (z.B. Raspbian auf einem Raspberry Pi)

## Konfiguration
1) Die Anzahl und die Namen der Kanäle muss in der Datei `cw.sh` angepasst werden (Zeile 6-14)
2) Die Namen der Kanäle muss in der Datei `web/climaviewer.php` angepasst werden (Zeile 250-254)
3) Die Pfade zur SQLite Datenbank muss in der Datei `db.sh` (Zeile 4) und `web/get_data.php` angepasst werden (Zeile 9)

Schließe das USB-Kabel an dein Gerät (z.B. Raspberry Pi oder Computer) an.

## Web View Setup
Erstelle einen Cron-Job, um alle 5 Minuten Daten abzurufen (`sudo crontab -e`):

```
*/5 * * * * /home/pi/ClimaViewer/cw.sh -j | /home/pi/ClimaViewer/db.sh >> /home/pi/ClimaViewer/logs/$(date '+\%Y-\%m')_ClimaViewer.log 2>&1
```
Passe die Pfade entsprechend deiner Umgebung an.

Kopiere die Dateien aus dem `web`-Unterordner in ein Verzeichnis, auf das ein Webserver (z.B. lighttpd) zugreifen kann. Beispielpfad: `/var/www/html/`.
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
### Beispiel Konsolenausgabe
```
sudo ./cw.sh
Channel Location        Temperature [°C]        Humidity [%]
1       Wohnzimmer      24.9                    61
2       Keller          22.5                    64
3       Schlafzimmer    25.9                    56
4       Dachboden       26.9                    44
5       Garten          27.7                    49
```

### Beispiel CSV Output
```
sudo ./cw.sh -c
1;Wohnzimmer;24.9;61
2;Keller;22.5;64
3;Schlafzimmer;25.9;56
4;Dachboden;26.9;44
5;Garten;27.7;49
```

### Beispiel JSON Output
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

### Beispiel XML Output
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
Ansicht im Browser:
![grafik](https://github.com/user-attachments/assets/94c69249-af74-47de-9cc0-3b5b945a613b)

## Danksagung
Besonderer Dank geht an [Jürgen](https://github.com/juergen-rocks/raumklima) für die grundlegende Arbeit, die dieses Projekt inspiriert hat.

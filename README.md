# Caster
Meet Caster, a podcast app purely written in Swift running on iOS.

## User Interface
* Custom TableViewController for transparent navigation bar and sizable list view's header (bounce effect)
* Different types of table cell for UITableView
* CollectionView inside TableView
* UIVisualEffectView over podcast artwork
* Auto-layout using UIStackView, auto-height table view...
* Custom presentation controller to display non-full menus and dialogs as well as slide in animations
* Draggable “Now Playing Mini Bar” always resides at the bottom of the screen

## Networking Handling and Concurrent Programming
*	Retrieve the top post cast list from iTunes (XML web service)
*	Lookup podcast information based on podcast id (JSON web service) to get particular feed URL
*	Retrieve feed URL to parse for detail podcast info and episodes list
*	Download all of those files and artwork images
* Use "semaphore" to collaborate Operation and URLSession tasks
* Load artworks asynchronously

## Media Streaming
* KVOs (key value observers) and the media states
*	KVOs progress and buffer duration
*	The difference between AVPlayer.rate (requested rate) and AVPlayerItem.timebase (actual rate)

## Data Parsing (XML and JSON)
Caster has two parsers (based on NSXMLParser) to parse XML data from top podcast list (ATOM format) and podcast feed RSS (RSS format).

## System Integration
* Display the artwork and handle play/pause/skip forward/skip backward from system’s control center and lock screen
*	Enable background audio playing
*	Enable the app to continue to work in background mode for around 3 mins, so that media event will be received event when the app is in the background.
*	Handle remote events from control center and lock screen

*Screenshots*

### Main
![Main](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/1_main.png)
![Main](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/2_main.png)
![Main](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/3_main.png)

### Drawer
![Drawer](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/4_drawer.png)

### Countries
![Countries](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/5_countries.png)

### Top podcasts
![Top podcasts](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/6_top_podcasts.png)

### Search
![Search](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/7_search.png)

### Podcast details
![Podcast details](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/8_podcast_details.png)

### Podcast Info
![Podcast Info](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/9_podcast_info.png)

### Now Playing
![Now Playing](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/10_now_playing.png)

### Item Info
![Item Info](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/11_item_info.png)

### Draggable Now Playing Mini Bar
![Now Playing Mini Bar](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/12_mini_now_playing.png)

### Control Center
![Control Center](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/13_control_center.png)

### Lockscreen
![Lockscreen](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/14_lock_screen.png)

### Video Playing
![Video Playing](https://raw.githubusercontent.com/conqtc/Caster/master/Screenshots/15_video_playing.png)

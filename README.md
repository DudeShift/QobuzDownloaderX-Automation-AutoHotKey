# QobuzDownloaderX-Automation-AutoHotKey
HotHotKey V2 Script / Exe to automate using QobuzDownloaderX

Verios
Features:
- Queue mulitple albums to download through QobuzDownloaderX
- Add an artist page to queue only highest quality albums
- After downloading, saves a CSV file of queue for future database use
- "Cleans" / Removes the FLAC (##bit-##kHz) folders that QobuzDownloaderX creates

## Instructions:
### To Add:
Please use the link as shown in your browser:
- Album:   https://www.qobuz.com/us-en/album/
- Artist:  https://www.qobuz.com/us-en/interpreter/
- Award:   https://www.qobuz.com/us-en/award/
- Label:   https://www.qobuz.com/us-en/label/
- AlbumID on its own

The program search and get the artist / album infomation on the page and will be shown in the queue. Only the highest quailty verison of an album on the artist page will be queued.

The artist and album name shown is not what is saved, but just for the user to see. I have tried to filter out most HTML special character codes.

You can just copy-paste into the edit box and press enter without having to click "Add Link".

### To View an Album Link
Double click on a row to have the link open in your web browser.

### To Remove:
Select which albums to remove with the checkbox and click "Remove Checked Albums" or just use "Clear Queue".

### To Start Download Queue
Open QobuzDownloaderX, login, set a folder to download.
Click "Start Download Queue of #".

During the automation, your mouse should stay on the "Download" button in QobuzDownloaderX.
If you need to pause, press "CTRL + Numpad 0" but remember to return your mouse after un-pausing.

### Clean "FLAC FOLDER" File Structure:
QobuzDownloaderX will download an album as `\ARTIST\ALBUM\FLAC (##bit-##kHZ)\...` because on Qobuz there will be mulitple verisons of the same album but different quailty (they have different Album ID). 

Point to your QobuzDownloaderX download folder and the program will (within the given directory) move all files within a folder that starts with "FLAC (" up one level (to the album folder) and remove the "FLAC (" folder.

### Save Queue to CSV
If checked before started, the queue will be saved to a CSV file at "CurrentDirectory\Queue_CSV". This is inteneded for future program use to get full artist discography

# QobuzDownloaderX-Automation-AutoHotKey
HotHotKey V2 Script / Exe to automate using [QobuzDownloaderX](https://github.com/ImAiiR/QobuzDownloaderX) or the [fork Mod](https://github.com/DJDoubleD/QobuzDownloaderX-MOD)

<p style="align:center;">
  <a href="./Screenshot Version 0.3.PNG?raw=true">
    <img src="./Screenshot Version 0.3.PNG?raw=true" />
  </a>
</p>

Features:
- Queue mulitple albums to download through QobuzDownloaderX
- When an artist, award, label page is queue, only highest quality albums are added
- Automates the interaction with QobuzDownloaderX for the queued albums
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

# Disclaimer & Legal
I will not be responsible for how you use QBDLX (QobuzDownloaderX). 

This program DOES NOT include...
- Code to bypass Qobuz's region restrictions.
- Qobuz app IDs or secrets.

QBDLX does not publish any of Qobuz's private secrets or app IDs. It contains regular expressions and other code to dynamically grab them from Qobuz's web player's *publicly available*  JavaScript, which is not rehosted, but grabbed client side. Scraping public data is not a violation of the Computer Fraud and Abuse Act (USA) according to the Ninth Court of Appeals, [case # 17-16783](http://cdn.ca9.uscourts.gov/datastore/opinions/2019/09/09/17-16783.pdf) (see page 29). 

QBDLX uses the Qobuz API, but is not endorsed, certified or otherwise approved in any way by Qobuz.

Qobuz brand and name is the registered trademark of its respective owner.

QBDLX has no partnership, sponsorship or endorsement with Qobuz.

By using QBDLX, you agree to the following: http://static.qobuz.com/apps/api/QobuzAPI-TermsofUse.pdf

# QobuzDownloaderX-Automation-AutoHotKey
AutoHotKey V2 Script / Exe to automate using [QobuzDownloaderX](https://github.com/ImAiiR/QobuzDownloaderX) or the [fork Mod](https://github.com/DJDoubleD/QobuzDownloaderX-MOD)

<p style="align:center;">
  <a href="./Screenshots/Screenshot Version 0.4.2.PNG?raw=true">
    <img src="./Screenshots/Screenshot Version 0.4.2.PNG?raw=true" />
  </a>
</p>

## Features:
- Queue multiple albums to download through QobuzDownloaderX
- When an artist, award, label page is queue, only highest quality albums are added
- Automates the interaction with QobuzDownloaderX for the queued albums
- Allows for multiple "parallel" QobuzDownloaderX instances
- "Cleans" / Removes the FLAC (##bit-##kHz) folders that QobuzDownloaderX creates

## Instructions:
1. At least once: Open QobuzDownloaderX, login, set the download folder, and close. You will not need to open QobuzDownloaderX again. 
2. Move the released automation exe or current ahk script build to inside your QobuzDownloaderX folder next to QobuzDownloaderX.exe
3. Open the automation exe or current ahk script build. Don't open QobuzDownloaderX.

## How to use:
### To Add to Queue:
Please view the Qobuz site in your browser and view one of the following link types:
- Album:   https://www.qobuz.com/us-en/album/
- Artist:  https://www.qobuz.com/us-en/interpreter/
- Award:   https://www.qobuz.com/us-en/award/
- Label:   https://www.qobuz.com/us-en/label/
- AlbumID on its own

Press the hotkey `CTRL+Numpad 0` to auto add the link. Or you can enter it into the textbox on the UI.

The program will get the artist / album information from page (and multiple) and will be shown in the queue. Only the highest quality version of an album on the artist page will be queued.

You can just copy-paste into the edit box and press enter without having to click "Add Link".

Please Note: The artist and album name shown is just for the user to see the queue and has no effect on the file structure created by QobuzDownloaderX HOWEVER they do when creating a CSV. I have tried to filter out most HTML special character codes.

### To View an Album Link:
Double click on a row to have the link open in your web browser.

### To Remove:
Select which albums to remove with the checkbox and click "Remove Checked Albums". Or just use "Clear Queue".

### Set Download Instances:
Select how many "parallel" instances of QobuzDownloaderX to run. Max is the Queue amount. AHK isn't multi-threaded however the script cycles between the instances to preform checks to act as parallel. You can only set to the total amount in queue or 100. Although not tested with that much, I figured that was plenty.

### To Start Download Queue:
Open QobuzDownloaderX, login, set a folder to download.
Click "Start Download Queue of #".

Your set amount of instances of QobuzDownloaderX will login and start working on your queue.

During the automation, you won't be able to use your mouse or keyboard as its needed to interact with QobuzDownloaderX
If you need to pause, press `"CTRL + Numpad 0"` but you **MUST** make the correct instance the active window before resuming. 

The tooltip will have the Process ID of which QobuzDownloader to return to, which is in the title bar for each window.

Another way is on the windows task bar, hover over the QobuzDownloaderX icon to show each window. At the top each should have a window name "PID: #"

Match the PID with the one given in the pause tooltip, click on an empty space to make it the active window, and then use the hotkey again to resume.

### Clean "FLAC FOLDER" File Structure:
QobuzDownloaderX will download an album as `\ARTIST\ALBUM\FLAC (##bit-##kHZ)\...` because on Qobuz there will be multiple versions of the same album but different quality (they have different Album ID). 

Point to your QobuzDownloaderX download folder and the program will (within the given directory) move all files within a folder named "FLAC (##bit-##kHz)" up one level (to the album folder) and remove the now empty FLAC folder.

Warning: When cleaning, your albums must only have one quality type folder inside (the "FLAC (##bit-##kHz)"). That is if you manually downloaded a lower quality type album. 

### Save Queue to CSV and Loading CSV:
If checked before started, the queue will be saved to a CSV file at "CurrentDirectory\Queue_CSV". This is intended for future program use to get full artist discography. What you see in the queue format is what will be saved. I have tried to filter out most HTML special character codes.

You can also load a CSV into the queue. 

Warning: One CSV queue file will be made per day. This means that if you start a queue and start the same queue again, the same queue will be appended.

## Issues or Questions:
Please view the wiki or current issues if you have any problems or questions. I will be adding the wiki soon.

# Disclaimer & Legal
I will not be responsible for how you use QBDLX (QobuzDownloaderX) or "QobuzDownloaderX Automation" (this script / program). 

This program DOES NOT include...
- Code to bypass Qobuz's region restrictions.
- Qobuz app IDs or secrets.

"QobuzDownloaderX Automation" does not publish any of Qobuz's private secrets or app IDs. It contains regular expressions and other code to dynamically grab Artist, Album, Quality, and Album Page Links information from Qobuz's *publicly available* HTML webpage or HTML redirects, which is not rehosted, but grabbed client side. Scraping public data is not a violation of the Computer Fraud and Abuse Act (USA) according to the Ninth Court of Appeals, [case # 17-16783](http://cdn.ca9.uscourts.gov/datastore/opinions/2019/09/09/17-16783.pdf) (see page 29). 

QobuzDownloaderX Automation uses the Qobuz HTML webpages, but is not endorsed, certified or otherwise approved in any way by Qobuz.

Qobuz brand and name is the registered trademark of its respective owner.

QobuzDownloaderX Automation has no partnership, sponsorship or endorsement with Qobuz.

By using QobuzDownloaderX Automation, you agree to the following: http://static.qobuz.com/apps/api/QobuzAPI-TermsofUse.pdf

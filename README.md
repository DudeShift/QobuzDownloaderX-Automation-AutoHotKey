# QobuzDownloaderX-Automation-AutoHotKey
AutoHotKey V2 Script to automate using [QobuzDownloaderX](https://github.com/ImAiiR/QobuzDownloaderX) or the [fork Mod](https://github.com/DJDoubleD/QobuzDownloaderX-MOD). View releases for compiled exe 

![Screenshot Version 0 5](https://user-images.githubusercontent.com/90281465/233743941-93fdf257-9130-4052-8b31-c0e122ac2005.PNG)


## **Features:**
- Queue multiple albums to download automatically through QobuzDownloaderX
- User defined Hotkey to add to queue while on web browser page
- When an artist, award, label page is queue, only highest quality albums are added
- Automates the interaction with QobuzDownloaderX for the queued albums
- Allows for multiple "parallel" QobuzDownloaderX instances
- "Cleans" / Removes the FLAC (##bit-##kHz) folders that QobuzDownloaderX creates
- CSV for queue logs

## **Demo Video:**

[Video Version 0.5.webm](https://user-images.githubusercontent.com/90281465/233743962-d247a686-5328-4f92-8d34-1cf0b03e6d7b.webm)


## **Install Instructions:**
1. At least once: Open QobuzDownloaderX, login with your account, set the download folder, and close. You will not need to open QobuzDownloaderX again. 
2. Move the released automation exe or current ahk script build to inside your QobuzDownloaderX folder next to QobuzDownloaderX.exe
3. Open the automation exe or current ahk script build. Don't open QobuzDownloaderX.

# **Basic Instructions:**
## **To Add to Queue:**
Please view the Qobuz site in your browser and view one of the following link types:
- Album:   https://www.qobuz.com/us-en/album/
- Artist:  https://www.qobuz.com/us-en/interpreter/
- Award:   https://www.qobuz.com/us-en/award/
- Label:   https://www.qobuz.com/us-en/label/
- AlbumID on its own

Press the user defined hotkey (default is `CTRL+Numpad 0` and changed in Advance Settings) to auto add the link your currently browsing. Or you can enter it into the textbox on the UI.

The program will get the artist / album information from page (and multiple) and will be shown in the queue. Only the highest quality version of an album on the artist page will be queued.

*Note: You can just copy-paste into the edit box and press enter without having to click "Add Link".*

## **To View an Album Link:**
Double click on a row to have the link open in your web browser.

## **To Remove:**
Select which albums to remove with the checkbox and click "Remove Checked Albums". Or just use "Clear Queue".

## **Set Download Instances:**
Select how many "parallel" instances of QobuzDownloaderX to run. Max is the Queue amount. AHK isn't multi-threaded however the script cycles between the instances to preform checks to act as parallel. Recommend to stay under 10.

## **To Start Download Queue:**
Open QobuzDownloaderX, login, set a folder to download.
Click "Start Download Queue of #".

Your set amount of instances of QobuzDownloaderX will open, login, and start working on your queue.

During the automation, you won't be able to use your mouse or keyboard as its needed to interact with QobuzDownloaderX. 
If you need to pause, press your user defined hotkey but you **MUST** return to the correct instance before resuming. 

The tooltip will have the Process ID of which QobuzDownloaderX to return to, which is in the title bar for each window.

Another way is on the windows task bar, hover over the QobuzDownloaderX icon to show each window. At the top each should have a window name "PID: #"

Match the PID with the one given in the pause tooltip, click on an empty space to make it the active window, move your mouse over the download button, and then use the hotkey again to resume.

## **Clean "FLAC FOLDER" File Structure:**
QobuzDownloaderX will download an album as `\ARTIST\ALBUM\FLAC (##bit-##kHZ)\...` because on Qobuz there will be multiple versions of the same album but different quality (they have different Album ID). 

Point to your QobuzDownloaderX download folder and the program will (within the given directory) move all files within a folder named "FLAC (##bit-##kHz)" up one level (to the album folder) and remove the now empty FLAC folder.

After completion, QobuzDownloaderX will not be able to detect if an album has already been downloaded in the specified directory. 

This script does not deal with an album folder having multiple qualities and will throw an error. 

Please use caution and ensure that you have a backup of any files you wish to keep at the directory your going to give before running this script

# Advance Features or Questions:
Please view the wiki for more details and possible issues when using the QobuzDownloaderX Automation. I will be adding the wiki soon.

# Disclaimer & Legal
*This was heavily inspired / copied from the QobuzDownloaderX legal section, however:*

I will not be responsible for how you use QBDLX (QobuzDownloaderX) or "QobuzDownloaderX Automation" (this script / program). 

This program DOES NOT include...
- Code to bypass Qobuz's region restrictions.
- Qobuz app IDs or secrets.
- Qobuz User Account information

"QobuzDownloaderX Automation" does not publish any of Qobuz's private secrets or app IDs. It contains regular expressions and other code to dynamically grab Artist, Album, Quality, and Album Page Links information from Qobuz's *publicly available* HTML webpage or HTML redirects, which is not rehosted, but grabbed client side. Scraping public data is not a violation of the Computer Fraud and Abuse Act (USA) according to the Ninth Court of Appeals, [case # 17-16783](http://cdn.ca9.uscourts.gov/datastore/opinions/2019/09/09/17-16783.pdf) (see page 29). 

QobuzDownloaderX Automation uses the Qobuz HTML webpages, but is not endorsed, certified or otherwise approved in any way by Qobuz.

Qobuz brand and name is the registered trademark of its respective owner.

QobuzDownloaderX Automation has no partnership, sponsorship or endorsement with Qobuz.

By using QobuzDownloaderX Automation, you agree to the following: http://static.qobuz.com/apps/api/QobuzAPI-TermsofUse.pdf

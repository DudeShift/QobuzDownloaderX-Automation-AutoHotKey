#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input") ; Recommend for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir) ; Current Directory
Suspend(true) ; Disable hotkeys, only enabled during Automation (StartProcess)

Version := "0.4.1" ; Current Version Number

; Split Text of Instructions
_Instructions_Set_Left := "
(    
Instructions Summary (View Github Above For More Details):
Pre-Req: Open QobuzDownloaderX, Login, set Download Folder, and Close at least once.

- To Add:
Paste + Press Enter into the text box any of the following formats:
- Album:   https://www.qobuz.com/us-en/album/
- Artist:  https://www.qobuz.com/us-en/interpreter/
- Award:   https://www.qobuz.com/us-en/award/
- Label:   https://www.qobuz.com/us-en/label/
- AlbumID on its own

The program will detected if the album is already queued and also queue the highest quality version
)"
_Instructions_Set_Right := "
(
- To Remove: Select checkboxes and use remove or use clear queue

- Set "Parallel" Downloads: Set how many Instances of QobuzDownloaderX to create.
    
- To Start: Click "Start Download Queue" to start process. DON'T move your mouse till complete
    
- You can use hotkey CTRL + Numpad 0 to pause the process.
However, return the mouse to the QobuzDownloaderX PID: #'s download button before resuming
    
- Use "Clean FLAC File Structure" to remove the FLAC file sturcture created by QobuzDownloaderX
)"

; ### GUI Creation ###
; Gui is split into sections based on layout starting at 0,0. 
MyGui := Gui()
MyGui.Title := "QobuzDownloaderX Automation"
MyGui.OnEvent("Close", GuiClose)

ButtonStartProcess := MyGui.Add("Button", "x+5 yp w175 section vButtonStartProcess", "Start Download Queue of 0")
ButtonStartProcess.OnEvent("Click", StartProcess)
MyGui.Add("Text", "x+5 yp+5 w100", "Download Instances:")
TextBoxChoiceParallel := MyGui.Add("Edit", "x+5 yp-5 w50 Limit3 Number")
ChoiceParallel := MyGui.Add("UpDown", "Range1-100", 1)
ButtonSetParallelMax := MyGui.Add("Button", "x+5 yp w100 vButtonSetParallelMax", "Queue Amount")
ButtonSetParallelMax.OnEvent("Click", SetParallelMax)

ChoiceParallel.OnEvent("Change", checkParallelAmount)
CheckBoxSaveToCSV := MyGui.Add("CheckBox", "x+15 yp+5 w180 vSaveToCSV", "Save to CSV after Automation?")
ButtonCleanFLACFileStructure := MyGui.Add("Button", "x+5 yp-5 w150 vButtonCleanFLACFileStructure", "Clean FLAC File Structure")
ButtonCleanFLACFileStructure.OnEvent("Click", CleanFLACFileStructure)

MyListView := MyGui.Add("ListView", "xs ys+30 w1000 h400 Grid Checked Sort -LV0x10 vMyListView", ["", "Artist", "Album", "Quality", "Link"])
MyListView.OnEvent("DoubleClick", ListViewOpenLink)

TextBoxLink := MyGui.Add("Edit", "section w300 vTextBoxLink")
ButtonAddItem := MyGui.Add("Button", "x+5 yp w100 Default", "Add Link")
ButtonAddItem.OnEvent("Click", AddItem)
ButtonRemoveItem := MyGui.Add("Button", "x+5 yp w150", "Remove Checked Albums")
ButtonRemoveItem.OnEvent("Click", RemoveItem)
ButtonClearQueue := MyGui.Add("Button", "x+5 yp w135", "Clear Queue")
ButtonClearQueue.OnEvent("Click", ClearQueue)
ButtonLoadCSV := MyGui.Add("Button", "x+5 yp w150 vLoadCSV", "Load CSV To Queue")
ButtonLoadCSV.OnEvent("Click", LoadCSV)
TextWhichCSV := MyGui.Add("Text", "x+5 yp+5 w150 vTextWhichCSV", "")

MyGui.Add("Link", "xs ys+30", 'Version ' . Version . ' <a href="https://github.com/DudeShift/QobuzDownloaderX-Automation-AutoHotKey">https://github.com/DudeShift/QobuzDownloaderX-Automation-AutoHotKey</a>')
TextUpdateAvailable := MyGui.Add("Text", "x+5 yp w500 vTextUpdateAvaible", "")
MyGui.Add("Text", "xs y+10", _Instructions_Set_Left)
MyGui.Add("Text", "xs+500 yp+20", _Instructions_Set_Right)

MyGui.Show()

; Set Default state of buttons
changeButtonEnableState(false)
ButtonAddItem.Enabled := true
ButtonCleanFLACFileStructure.Enabled := true

; ### Error / Warning Checks
if (!FileExist(A_ScriptDir . "\QobuzDownloaderX.exe")) {
    MsgBox("Exiting: QobuzDownloaderX.exe not found in " . A_ScriptDir . "`nPlease move program / script into your QobuzDownloaderX.exe folder", "QobuzDownloaderX.exe Not Found", 16)
    GuiClose()
}

while (WinExist("QobuzDownloaderX", , "Automation") || WinExist("QobuzDLX | Login", , "Automation")) {
    MsgBox("Error: All instances of QobuzDownloaderX.exe to be closed`nPlease close all of them before you continue", "QobuzDownloaderX.exe is open", 16)
}

; Check if new version is released on github
checkForUpdate(Version)

MsgBox("Warning: Make sure to have logged into and set download folder in QobuzDownloaderX.exe at least once before continuing", "QobuzDownloaderX.exe Pre-Check", 32)

; global var for the hotkey pause tooltip to figure out which window to return to
global pidInUse := 0

return

;### HotKey to Pause Downloading ###
^Numpad0::
{
    Pause -1
    if (A_IsPaused) {
        ToolTip("Automation Paused:`nPress Ctrl + Numpad 0 to resume when:`nQobuzDownloaderX PID: " . pidInUse "`nIs the active window and mouse is on `"download`"")
    } else {
        ToolTip("Automation Resumed:`nWaiting for current album out of " . MyListView.GetCount() . " queued")
    }
}

;### GUI Handling ###

; Making sure Download Instances never goes above Queue Total (MyListView.GetCount) or 100
checkParallelAmount(UpDown, info) {
    NewValue := UpDown.Value
    if (NewValue >= 100) {
        NewValue := 100
        MsgBox("Warning: Setting Instances to 100`n`nReason: Honestly haven't tested that many")
    }
    if (NewValue > MyListView.GetCount()) {
        NewValue := MyListView.GetCount()
    } else if (NewValue <= 0) {
        NewValue := 1
    }
    UpDown.Value := NewValue
    return
}

; Quickly change the stata of GUI elements 
changeButtonEnableState(state) {
    ButtonStartProcess.Enabled := state
    ButtonCleanFLACFileStructure.Enabled := state
    ButtonClearQueue.Enabled := state
    ButtonAddItem.Enabled := state
    ButtonRemoveItem.Enabled := state
    ButtonSetParallelMax.Enabled := state
    TextBoxChoiceParallel.Enabled := state
    ChoiceParallel.Enabled := state
    return
}

; Double Click on a row to open in browser
ListViewOpenLink(LV, Row) {
    Run(LV.GetText(row, 5))
    return
}

; Button to quickly set the Queue Total to Download Instances
SetParallelMax(*) {
    if(MyListView.GetCount() > 100) {
        MsgBox("Warning: Setting Instances to 100`n`nReason: Honestly haven't tested that many")
        ChoiceParallel.Value := 100
    } else {
    ChoiceParallel.Value := MyListView.GetCount()
    }
    return
}

; Handles link input, figures out what type of link, and passes it to its function type
AddItem(*) {
    ; Input could be a: Full Album Link, Link with Album ID at end, Artist Link. Thus named dataLink
    dataLink := TextBoxLink.Text
    if (StrCompare(dataLink, "") == 0) {
        MsgBox("No Link Provided: Please enter a link into the textbox")
    } else {
        changeButtonEnableState(false)
        parts := StrSplit(dataLink, "/")
        if((parts.Length == 9)) && (StrCompare(parts[8], "page") == 0) {
            partsWithoutPage := StrSplit(dataLink, "/page")
            dataLink := partsWithoutPage[1]
            parts := StrSplit(dataLink, "/")
        }
        if (parts.Length == 7) {
            if ((StrCompare(parts[3], "www.qobuz.com") == 0) && (StrCompare(parts[5], "interpreter") == 0)) {
                isAlreadyQueued := artistAddAlbums(dataLink, 1) ; artist link, page 1 for a counter
                if (isAlreadyQueued != 0) {
                    MsgBox("Warning: Mulitple Albums ingored due to already being queued")
                }
            } else if ((StrCompare(parts[3], "www.qobuz.com") == 0) && (StrCompare(parts[5], "album") == 0)) {
                isAlreadyQueued := isAlbumLinkInList(dataLink)
                if (isAlreadyQueued != 0) {
                    MsgBox("Album Already Queued: " . MyListView.GetText(isAlreadyQueued, 3) . " by " . MyListView.GetText(isAlreadyQueued, 2))
                } else {
                    addAlbum(dataLink)
                }
            } else {
                MsgBox("Invalid Link: Please enter a valid Qobuz link")
            }
        } else if ((parts.Length == 8) && ((StrCompare(parts[5], "awards") == 0) || (StrCompare(parts[5], "label") == 0))) {
            artistAddAlbums(datalink, 1) ; award or label link so send it

        } else {
            possibleAlbumLink := searchQobuzForAlbum(parts[parts.Length]) ; Either a album ID or play link
            if (possibleAlbumLink != "") {
                isAlreadyQueued := isAlbumLinkInList(dataLink)
                if (isAlreadyQueued != 0) {
                    MsgBox ("Searched Album Already Queued: " . MyListView.GetText(isAlreadyQueued, 3) . " by " . MyListView.GetText(isAlreadyQueued, 2))
                }
                addAlbum(possibleAlbumLink)
            } else {
                MsgBox ("Invalid Link, Invalid Album ID, or Link has page number: Please view instructions") ; no redirect when searching for album id directly
            }
        }
    }
    changeButtonEnableState(true)

    ButtonAddItem.Text := "Add Link"
    TextboxLink.Text := "" ; Empty the textbox
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    MyListView.ModifyCol
    MyListView.ModifyCol(3, "Sort")
    MyListView.ModifyCol(2, "Sort")
    return
}

; Remove all checked rows from the queue
RemoveItem(*) {
    changeButtonEnableState(false)
    if (MyListView.GetCount() == 0) {
        return ; do nothing
    }
    ; Loop through MyListView to find checked rows
    ; Setting max loops as safety feature
    RowNumber := 0
    Loop MyListView.GetCount() {
        RowNumber := MyListView.GetNext(, "Checked")
        if (RowNumber == 0) {
            ; No more checked rows
            break
        } else {
            ; Checked Row Found, remove from queue and list view
            MyListView.Delete(RowNumber)
        }
    }
    changeButtonEnableState(true)
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    return
}

; Clear the whole Queue
ClearQueue(*) {
    if (MyListView.GetCount() == 0) {
        return ; do nothing
    }
    msgResult := MsgBox("Are you sure you want to clear the queue?`n`nClick Yes to continue, or No to go back.", "Clear Queue Warning", 4)
    if (msgResult = "Yes") {
        MyListView.Delete()
        ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
        changeButtonEnableState(false)
        ButtonAddItem.Enabled := true
        ButtonCleanFLACFileStructure.Enabled := true
    }
    return
}

; Start Automation Process
StartProcess(*) {
    if (MyListView.GetCount() == 0) {
        MsgBox("Nothing in queue, add an album or artist")
    } else {
        changeButtonEnableState(false)
        Suspend(false)
        CoordMode("Pixel", "Window")
        SetTitleMatchMode(2)
        ; before Parallel

        howManyInstances := ChoiceParallel.Value
        if(howManyInstances > MyListView.GetCount()) {
            howManyInstances := MyListView.GetCount()
        }
        ToolTip("Please Wait: Opening " . howManyInstances . " Download Instances...`nDon't move anything")
        ; Create PID array
        downloadInstancePIDArray := Array()
        ; Open QobuzDownloaderX.exe and login
        Loop howManyInstances {
            try {
                Run("QobuzDownloaderX.exe", A_ScriptDir, , &tempPID)
            } catch {
                ToolTip()
                MsgBox("Exiting: QobuzDownloaderX.exe not found in " . A_ScriptDir . "`nPlease move program / script into your QobuzDownloaderX.exe folder", "QobuzDownloaderX.exe Not Found", 16)
                changeButtonEnableState(true)
                Suspend(true)
                return
            }
            if (tempPID == 0) {
                ToolTip()
                MsgBox("Critical Error: Couldn't get PID for Instance # " . A_Index, 16)
                changeButtonEnableState(true)
                Suspend(true)
                return
            }
            WinWaitActive("ahk_pid " tempPID " QobuzDLX | Login ",, 1, "ahk_class AutoHotkeyGUI Automation")
            WinActivate("ahk_pid " tempPID " QobuzDLX | Login ",, "ahk_class AutoHotkeyGUI Automation")
            downloadInstancePIDArray.Push(tempPID)
            Send("{Enter}")
            Sleep(100)
        }
        if (CheckBoxSaveToCSV.Value == 1) {
            DirCreate "Queue_CSV"
            csvFilePath := A_ScriptDir . "\Queue_CSV\" . FormatTime(, "yyyy-MM-dd") . " Queue.csv"
            if (!FileExist(csvFilePath)) {
                FileAppend "`"" . MyListView.GetText(0, 2) . "`",`"" . MyListView.GetText(0, 3) . "`",`"" . MyListView.GetText(0, 4) . "`",`"" . MyListView.GetText(0, 5) . "`"", csvFilePath
            }
        }

        secondsToWait := 30
        Loop secondsToWait {
            ToolTip("Waiting for First Login to Complete`nTimeout in: " . A_Index - 1 . " out of " . secondsToWait . " seconds")
            try {
                currentTitle := WinGetTitle("ahk_pid " downloadInstancePIDArray[1])
                if(StrCompare(currentTitle, "QobuzDownloaderX") == 0) {
                    break
                }
            } catch {
                ToolTip()
                MsgBox("Error: First Instance stuck on Login Screen. Stopping Queue Process`n`nDid you forget to login first?")
                changeButtonEnableState(true)
                Suspend(true)
                return
            } 
            sleep(1000)
        }
        ToolTip()

        currentRowPointer := 1 ; Data starts a 1, and loop is going to add 1
        flagQueueEmpty := false ; flag for if at end of queue, to deal with currentRowPointer = 26
        ;this doesn't work
        timeOutCounter := 0
        while howManyInstances > 0 {
            donePIDArray := Array()
            Loop downloadInstancePIDArray.Length {
                if (!downloadInstancePIDArray.Has(A_Index)) {
                    continue ; null, skip pid since its been removed
                }
                currentPID := downloadInstancePIDArray[A_Index]
                WinWaitActive("ahk_pid " currentPID " QobuzDownloaderX ",, 1, "ahk_class AutoHotkeyGUI Automation")
                WinActivate("ahk_pid " currentPID " QobuzDownloaderX",, "ahk_class AutoHotkeyGUI Automation")
                global pidInUse := currentPID
                WinSetTitle("QobuzDownloaderX PID: " . currentPID, "ahk_pid " currentPID " QobuzDownloaderX",,"ahk_class AutoHotkeyGUI Automation")
                WinMove(0, 0, , ,"ahk_pid " currentPID " QobuzDownloaderX",, "ahk_class AutoHotkeyGUI Automation" )

                ToolTip("Don't move the mouse:`nDownloading " . currentRowPointer - 1 . " out of " . MyListView.GetCount() . " queued`nViewing " . currentPID . " (" . A_Index . " of " . howManyInstances . ") download instance running`nTo pause use CTRL + Numpad 0")

                ; Get the color at the specified window coordinate
                ; Mouse has to under pixel to get color, I know the docs say otherwise.
                MouseMove 615, 95
                color := PixelGetColor(615, 95, "RGB")
                if (color = 0x0086FF) {
                    if (currentRowPointer > MyListView.GetCount()) {
                        donePIDArray.Push(A_Index)
                        continue ; skip loop, removing pid since no more to queue
                    } else {
                        parts := StrSplit(MyListView.GetText(currentRowPointer, 5), "/")
                        playLink := "https://play.qobuz.com/album/" . parts[parts.Length]
                        MouseClick("Left", 500, 95, 1, 0)
                        Click("500, 95")
                        Send("^a")
                        Send("{Backspace}")
                        Send (playLink)
                        MouseClick("Left", 500, 95, 1, 0)
                        Click("615, 95")
                        if (CheckBoxSaveToCSV.Value == 1) {
                            artist := htmlString := StrReplace(MyListView.GetText(currentRowPointer, 2), "`"", "`"`"")
                            album := htmlString := StrReplace(MyListView.GetText(currentRowPointer, 3), "`"", "`"`"")
                            FileAppend "`n`"" . artist . "`",`"" . album .  "`",`"" . MyListView.GetText(currentRowPointer, 4) .  "`",`"" . MyListView.GetText(currentRowPointer, 5) . "`"", csvFilePath
                        }
                        ToolTip("Don't move the mouse:`nDownloading " . currentRowPointer . " out of " . MyListView.GetCount() . " queued`nViewing " . currentPID . " (" . A_Index . " of " . howManyInstances . ") download instance running`nTo pause use CTRL + Numpad 0")
                        currentRowPointer++
                    }
                }
                Sleep(100)
            }
            Loop donePIDArray.Length {
                indexPID := donePIDArray.Pop()
                WinClose("ahk_pid " downloadInstancePIDArray[indexPID] " QobuzDownloaderX:",,, "ahk_class AutoHotkeyGUI Automation")
                downloadInstancePIDArray.Delete(indexPID)
                howManyInstances--
                ToolTip("Don't move the mouse:`nDownloading " . currentRowPointer - 1 . " out of " . MyListView.GetCount() . " queued`nWith " . howManyInstances . " download instances in use`nTo pause use CTRL + Numpad 0")
            }
        }
        ; After Parallel, when complete
        ToolTip()
        totalQueue := MyListView.GetCount()
        MyListView.Delete()
        changeButtonEnableState(true)
        ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
        Suspend(true)
        if (CheckBoxSaveToCSV.Value == 1) {
            MsgBox("Finsihed Downloading: CSV of Queue of " . totalQueue . " at: " . csvFilePath)
        } else {
            MsgBox("Finsihed Downloading: Queue of " . totalQueue)
        }
        TextWhichCSV.Text := ""
    }
    return
}

; Based on a directory, will find any folder named "FLAC (", move files inside up a directory, and detete the "FLAC (" folder
CleanFLACFileStructure(*) {
    MsgBox("Warning: This script was not made for checking if an album has multiple qualities`n`nThis is only an issue if you have manually downloaded a lower quality album in the past")
    dirToClean := DirSelect(, 0, "Please select your QobuzDownloaderX downloads folder")
    if (dirToClean == "") {
        return 0
    }
    msgResult := MsgBox("Please confirm the directory: " . dirToClean . "`n`n If incorrect click cancel to go back", "", 1)
    if (msgResult = "Cancel") {
        return 0
    }
    ; Save the current working directory
    current_directory := A_WorkingDir

    ; Change to the specified working directory
    SetWorkingDir(dirToClean)
    ; Loop through directories whose names start with "FLAC ("
    Loop Files, "FLAC (*", "DR" {
        ; Now loop through each file
        Loop Files, A_LoopFileFullPath . "\*.*", "F" {
            ; Get the full path and directory of the current file
            full_path := A_LoopFileFullPath
            if (InStr(full_path, dirToClean) == 0) {
                MsgBox("Critical Error: Outside of Working Directory: " . A_WorkingDir . "`nEnding cleanFileStructureFLAC at Moving Files")
                return 2
            }
            directory := A_LoopFileDir

            ; Move the file to the parent directory
            FileMove full_path, directory . "\.."
        }
    }

    ; Loop through all directories whose names start with "FLAC"
    Loop Files, "FLAC (*", "DR"
    {
        ; Get the full path of the current directory
        full_path := A_LoopFileFullPath

        ; Attempt to remove the directory, and show error message if failed
        try {
            DirDelete full_path, 0
        } catch {
            MsgBox("Critical Error: " . A_LoopFileFullPath . "was not empty when trying to delete`n`nReason: There were two or more FLAC qualities of the album`n`nSolution: Manually move the verison you want, delete others, and re-run")
            return 3
        }

    }
    ; Restore the original working directory
    SetWorkingDir(current_directory)
    return 1
}
; Load a CSV Queue file into the Queue
LoadCSV(*) {
    whichCSV := FileSelect(1,, "Select a Queue CSV To Load - " . A_ScriptName, "(*.csv)")
    if (whichCSV = "") {
        return ; do nothing, no file selected
    } else if (InStr(whichCSV, ".csv") == 0) {
        MsgBox("Critical Error: File type not .csv was selected")
        return
    } else {
        Loop read, whichCSV {
            LineNumber := A_Index
            parts := Array()
            Loop Parse, A_LoopReadLine, "CSV" {
;                MsgBox(LineNumber . " - " . A_Index " is: " . A_LoopField . " | " . MyListView.GetText(0,A_Index+1) . " | " . StrCompare(A_LoopField, MyListView.GetText(0,A_Index + 1)))
                if (A_Index > 4) {
                    MsgBox("Error: Data outside the four columns which are:`n`n`"Artist`",`"Album`",`"Quality`",`"Link`"")
                    return
                } else if (LineNumber == 1) {
                    if (StrCompare(A_LoopField, MyListView.GetText(0,A_Index + 1)) != 0) {
                    MsgBox("Error: Incorrect CSV Column Header which are:`n`n`"Artist`",`"Album`",`"Quality`",`"Link`"")
                    return
                    }
                 }  else {
                    parts.Push(A_LoopField)
                }
            }
            if (LineNumber != 1) {
                extractQuality := parts[3]
                RegExMatch(extractQuality, "S)(\d+(?=-))", &new_bit)
                RegExMatch(extractQuality, "S)(\d+(\.\d+)?)(?=\s+kHz)", &new_kHz)
                if((parts[1] == "") || (parts[2] == "") || (new_bit == "") || (new_kHz == "") || (parts[4] == "")) {
                    MsgBox("Error: Line " . LineNumber . " has an empty cell or incorrect formated data`n`n" . parts[1] . "," . parts[2] . "," . extractQuality . "," . parts[4])
                }   
                processAlbumInfo(parts[1], parts[2], new_bit[], new_kHz[], parts[4])
            }
        }
    }
    parts := StrSplit(whichCSV, "\")
    TextWhichCSV.Text := "Loaded: " . parts[parts.Length]
    changeButtonEnableState(true)

    ButtonAddItem.Text := "Add Link"
    TextboxLink.Text := "" ; Empty the textbox
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    MyListView.ModifyCol
    MyListView.ModifyCol(3, "Sort")
    MyListView.ModifyCol(2, "Sort")
    return
}


GuiClose(*) {
    ExitApp()
}

; Artist, Award, or Label link function handle
artistAddAlbums(artistLink, pageCounter) {
    ToolTip("Please wait: Searching Page " . pageCounter)
    ButtonAddItem.Text := "Please Wait"
    ; Download Album HTML to temp file
    tempArtistFilePath := A_ScriptDir . "\tempArtist.html"
    ; Build Page Link based on pageCounter
    artistLinkPageCounter := artistLink . "/page/" . pageCounter
    Download(artistLinkPageCounter, tempArtistFilePath)

    ; Read the temporary HTML file
    htmlSource := Fileread(tempArtistFilePath)
    ; Clean up - Delete the temporary file
    FileDelete(tempArtistFilePath)

    ; Loop through html to search for Album Title and Album Link
    postionRegEx := 1 ; Set a default reading postion at start for hopefully faster RegEx
    alreadyQueued := 0 ; Var to set a msgbox later insetad of saying which were already queued.
    loop {
        ; Get the album link. Sometime album link parts with qobuz or us-en, so just capture the us-en
        postionRegEx := RegExMatch(htmlSource, "S)(?<=<a href=`")[^`"]+(?=`" style)", &partAlbumLink, postionRegEx)
        if (postionRegEx == 0) {
            break
        }
        ;albumLink := SubStr(partAlbumLink[], StrLen("<a href=`""))
        if (InStr(partAlbumLink[], "https://www.qobuz.com") == 0) {
            albumLink := "https://www.qobuz.com" . partAlbumLink[]
        }

        ; Get album name and clean it
        postionRegEx := RegExMatch(htmlSource, "S)(?<=role=`"tooltip`">)[^<]+(?=<\/h3>)", &albumName, postionRegEx)
        albumName := ReplaceHtmlCharacterCodes(albumName[])

        ; Get artist name and clean it
        postionRegEx := RegExMatch(htmlSource, "S)<a\s+href=`"[^`"]*\/interpreter\/[^`"]*`">(?<artist>[^<]+)<\/a>", &artistName, postionRegEx)
        ;RegExMatch(htmlSource, "(?<=<title>    )(.*?)+(?= Discography - Download Albums in Hi-Res - Qobuz)", &artistName)
        artistName := ReplaceHtmlCharacterCodes(artistName.artist)

        ; Get album qual
        postionRegEx := RegExMatch(htmlSource, "S)(?<=<span class=`"store-quality__info`">)[^-\s]+(?=-)", &newBit, postionRegEx)
        RegExMatch(htmlSource, "S)(?<=<span class=`"store-quality__info`">)\s?[^\s]+(?=\s+kHz)", &newkHz, postionRegEx)
        newkhz := StrReplace(newKhz[], " ", "")

        processAlbumInfo(artistName, albumName, newBit[], newkHz, albumLink)
    }
    ; Check if there is a next page
    ; Can't just get href due to "lookbehind assertion is not fixed length" for when href either space or on new line
    ; So keeping a Page Counter
    ; Also can't use postionRegEx since its 0 from the loop
    postionRegEx := RegExMatch(htmlSource, "S)<a class=`"store-paginator__button next `"", &nextPageLinkButton)
    if (postionRegEx == 0) {
        ToolTip
        return alreadyQueued
    } else {
        pageCounter++ ; Increase pageCounter
        alreadyQueued := alreadyQueued + artistAddAlbums(artistLink, pageCounter)
    }
    return alreadyQueued
}

; Single Album function handle
addAlbum(albumLink) {
    ButtonAddItem.Text := "Please Wait"
    ; Download Album HTML to temp file
    tempAlbumFilePath := A_ScriptDir . "\tempAlbum.html"

    Download(albumLink, tempAlbumFilePath)
    ; Read the temporary HTML file

    htmlSource := Fileread(tempAlbumFilePath)
    ; Clean up - Delete the temporary file
    FileDelete(tempAlbumFilePath)

    ; Find the Album Name & Clean it, and save the postion
    posAlbumName := RegExMatch(htmlSource, "S)(?<=<p class=`"player__name`" data-name=`")[^`"]+(?=`")", &albumName)
    ; Get the postion after the album name
    posAfterAlbumName := posAlbumName + StrLen(albumName[])
    albumName := ReplaceHtmlCharacterCodes(albumName[])

    ; Find the artist name & Clean it, (which is after album so using posAfterAlbumName to save time searching)
    RegExMatch(htmlSource, "S)(?<=<p class=`"player__artist`" data-artist=`")[^`"]+(?=`")", &artistName, posAfterAlbumName)
    artistName := ReplaceHtmlCharacterCodes(artistName[])

    ; Get albumLink quality
    posFirstQuality := RegExMatch(htmlSource, "S)(?<=<span class=`"album-quality__info`">)[^-\s]+(?=-)", &newBit)
    RegExMatch(htmlSource, "S)(?<=<span class=`"album-quality__info`">)\s?[^\s]+(?=\s+kHz)", &newkHz, posFirstQuality)
    newkhz := StrReplace(newKhz[], " ", "")

    ; Send album info for processing
    return processAlbumInfo(artistName, albumName, newBit[], newkhz, albumLink)
}

; Based on album info, check to add it to the list if:
; - If its not already in the queue
; - If its a higher quality
processAlbumInfo(artist, album, new_bit, new_kHz, albumLink) {
    ; return 0 - album was already in queue with better qual
    ; return 1 - album wasn't in queue so added
    ; return 2 - album was already in queue but had worse qual so this one was added
    ; return 3 - empty item

    if((artist == "") || (album == "") || (new_bit == "") || (new_kHz == "") || (albumLink == "")) {
        MsgBox("Error Parsing HMTL: Please make an issue on github with the following:`n" . artist ", " . album ", " . new_bit ", " . new_kHz ", " . albumLink)
        return 3
    }

    queuedRow := isAlbumQueued(artist, album)
    if (queuedRow != 0) {
        ; Get queued quality
        queuedQuality := MyListView.GetText(queuedRow, 4)
        RegExMatch(queuedQuality, "S)(\d+(?=-))", &queuedBit)
        RegExMatch(queuedQuality, "S)(\d+(\.\d+)?)(?=\s+kHz)", &queuedkHz)

        if ((new_bit > queuedBit[]) || (new_kHz > queuedkHz[])) {
            ; new bit is probably 24 while queued bit is 16
            ; new kHz is higher, 16Bit max mhz is 24bit min mhz.
            MyListView.Delete(queuedRow)
            newQualityString := new_bit . "-Bit " . new_kHz . " kHz"
            MyListView.Add(, "", artist, album, newQualityString, albumLink)
            return 2
        } else {
            ; Do Nothing since higher qual album already queued
            return 0
        }
    } else {
        newQualityString := new_bit . "-Bit " . new_kHz . " kHz"
        MyListView.Add(, "", artist, album, newQualityString, albumLink)
        return 1
    }
}

; Clean string from parsed HTML characters
ReplaceHtmlCharacterCodes(htmlString) {
    ;   Mappings:
    ;   Character   | Decimal Entity | Description
    ;   ------------+-----------------+--------------------
    ;   <           | &#60;           | Less than
    ;   >           | &#62;           | Greater than
    ;   &           | &#38;           | Ampersand
    ;   &           | &amp;           | Ampersand
    ;   '           | &#039;          | Apostrophe or single quote
    ;   '           | &#39;           | Apostrophe or single quote
    ;   "           | &#34;           | Quotation mark or double quote
    ;   "           | &quot;          | Quotation mark or double quote
    ;   ’           | â€™             | Apostrophe or single quote
    ;   “           | â€œ             | Quotation mark or double quote
    ;   ”           | â€              | Quotation mark or double quote

    htmlCharCodes := ["&#60;", "&#62;", "&#38;", "&amp;" "&#34;", "&#039;", "&#39;", "&quot;", "â€™", "â€œ", "â€"]
    htmlChars := ["<", ">", "&", "&", "`"", "'", "'", "`"", "'", "`"", "`"",]

    ; Loop through each mapping and replace HTML character codes with their corresponding characters
    ; Using StrReplace to match (haystack, needle, replacement) if needle found.
    Loop htmlCharCodes.Length {
        htmlCharCode := htmlCharCodes[A_Index]
        htmlChar := htmlChars[A_Index]
        htmlString := StrReplace(htmlString, htmlCharCode, htmlChar)
    }

    ; Return the updated string
    return htmlString
}

; Is the albumlink in the Queue
isAlbumLinkInList(albumLink) {
    loop MyListView.GetCount() {
        if (StrCompare(albumLink, MyListView.GetText(A_Index, 5)) == 0) {
            return A_Index
        }
    }
    return 0
}

; Is the artist and album in the Queue
isAlbumQueued(artist, album) {
    loop MyListView.GetCount() {
        if ((StrCompare(artist, MyListView.GetText(A_Index, 2)) == 0) && (StrCompare(album, MyListView.GetText(A_Index, 3)) == 0)) {
            return A_Index
        }
    }
    return 0
}

; Search on Qobuz for the albumID
searchQobuzForAlbum(albumID) {
    ButtonAddItem.Text := "Please Wait"
    ; Try to get the location header from the returned html when searching 302 redirect for full album link
    searchLink := "https://www.qobuz.com/us-en/search?q=" . albumID
    req := Request(searchLink)
    if (req.Status == 302) {
        ; Gets the location header from the returned html
        fullLink := "https://www.qobuz.com" . req.GetResponseHeader("location")
        return fullLink
    } else {
        ; Did not get a redirect to an album page
        return ; null
    }
}

; Handles the 302 redirects when searching
Request(url) {
    WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Option[6] := False ; No redirects
    WebRequest.Open("GET", url, false)
    WebRequest.Send()
    Return WebRequest
}

; Check github for new release version
checkForUpdate(curVersion) {
    tempFilePath := A_ScriptDir . "\tempCheckUpdate.html"
    
    Download("https://github.com/DudeShift/QobuzDownloaderX-Automation-AutoHotKey/releases/latest", tempFilePath)
    
    ; Read the temporary HTML file
    htmlSource := Fileread(tempFilePath)
    
    ; Clean up - Delete the temporary file
    FileDelete(tempFilePath)

    ; Find the lastest released version from title
    RegExMatch(htmlSource, "(?<=<title>Release Version )[\d.]+", &lastestVersion)
    try {
        a := lastestVersion[]
    } catch {
        MsgBox("Error: Couldn't find latest Github Version Number for update check")
        return
    }
    partsLastestVersion := StrSplit(lastestVersion[], ".")
    partscurVersion := StrSplit(curVersion, ".")
    flagNewVersion := false
    
    if (partsLastestVersion.Length > partscurVersion.Length) {
        howManyZeros := partsLastestVersion.Length - partscurVersion.Length
        Loop howManyZeros {
            partscurVersion.Push("0")
        }
    }
    Loop partsLastestVersion.Length {
        if (partsLastestVersion[A_Index] > partscurVersion[A_Index]) {
            flagNewVersion := true 
            TextUpdateAvailable.Text := "New Version " . lastestVersion[] . " Available!"
            break
        }
    }
    return
}
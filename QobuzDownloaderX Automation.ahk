#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input") ; Recommend for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir) ; Current Directory
;Suspend(true) ; Disable hotkeys, only enabled during Automation (StartProcess)
KeyHistory(0) ; Disable AutoHotKey key history meant only for debug https://www.autohotkey.com/docs/v2/lib/KeyHistory.htm
ListLines(0) ; Disbale AutoHotKey script line debug

; ### Set Default Values ###
global Version := "0.4.2" ; Current Version Number
global pidInUse := 0 ; global var for the hotkey pause tooltip to figure out which window to return to
global flagAutomationActive := false ; flag used to switch hotkey states
global scriptHotKey := ""

; Split Text of Instructions
_Instructions_Set_Left_1 := "
(    
Instructions Summary (View Github Above For More Details):
Pre-Req: Open QobuzDownloaderX, Login, set Download Folder, and Close at least once.

- To Add: While on Qobuz pages press 
)"
_Instructions_Set_Left_2 := "
(
to auto add, or copy url the edit box:
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

; ####################
; ### GUI Creation ###
; ####################

; ################
; ### Main GUI ###
; ################
; Gui is split into sections based on layout
MyGui := Gui()
MyGui.Title := "QobuzDownloaderX Automation"
MyGui.OnEvent("Close", MyGuiClose)

ButtonStartProcess := MyGui.Add("Button", "x+5 yp w175 section vButtonStartProcess", "Start Download Queue of 0")
ButtonStartProcess.OnEvent("Click", StartProcess)
MyGui.Add("Text", "x+5 yp w50", "Download Instances:")
TextBoxChoiceParallel := MyGui.Add("Edit", "x+5 yp w50 Limit3 Number")
ChoiceParallel := MyGui.Add("UpDown", "Range1-100", 1)
ChoiceParallel.OnEvent("Change", checkParallelAmount)
ButtonSetParallelMax := MyGui.Add("Button", "x+5 yp vButtonSetParallelMax", "Queue Total")
ButtonSetParallelMax.OnEvent("Click", SetParallelMax)
myGui.Add("Text", "x+15 yp w25", "Auto Sort:")
DropDownAutoSort := MyGui.Add("DropDownList", "x+5 yp Choose1 w100 vDropDownAutoSort", ["Artist/Album", "Release", "Quality", "Add to Top", "Add to Bottom"])
DropDownAutoSort.OnEvent("Change", changeSorting)
CheckBoxAutoAdjust := MyGui.Add("CheckBox", "x+15 yp w80 h25 Checked vAutoAdjust", "Auto Adjust Columns")
CheckBoxAutoAdjust.OnEvent("Click", changeSorting)

CheckBoxSaveToCSV := MyGui.Add("CheckBox", "x+5 yp w125 Checked vSaveToCSV", "Save Queue to CSV after Automation?")
ButtonCleanFLACFileStructure := MyGui.Add("Button", "x+5 yp w140 vButtonCleanFLACFileStructure", "Clean FLAC File Structure")
ButtonCleanFLACFileStructure.OnEvent("Click", CleanFLACFileStructure)
ButtonAdvanceSettings := MyGui.Add("Button", "x+5 yp w110 vAdvanceSettings", "Advance Settings")
ButtonAdvanceSettings.OnEvent("Click", AdvanceSettings)

MyListView := MyGui.Add("ListView", "xs ys+30 w1000 h400 Grid Checked -LV0x10 vMyListView", ["", "Artist", "Album", "Release Date", "Bit ", "kHz ", "Link"])
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
TextWhichCSV := MyGui.Add("Text", "x+5 yp+5 w145 vTextWhichCSV", "")

MyGui.Add("Link", "xs ys+30", 'Version ' . Version . ' <a href="https://github.com/DudeShift/QobuzDownloaderX-Automation-AutoHotKey">https://github.com/DudeShift/QobuzDownloaderX-Automation-AutoHotKey</a>')
TextUpdateAvailable := MyGui.Add("Text", "x+5 yp w500 vTextUpdateAvaible", "")
TextInstructions_Set_Left := MyGui.Add("Text", "xs y+10", _Instructions_Set_Left_1 . " " . _Instructions_Set_Left_2)
MyGui.Add("Text", "xs+500 yp+20", _Instructions_Set_Right)

; ####################
; ### Settings GUI ###
; ####################

SettingsGui := Gui("+Owner" MyGui.Hwnd, A_ScriptName . " Settings")

CheckBoxDisableCheckMsgBox := SettingsGui.Add("CheckBox", "xm+5 ym+5 Checked vPreCheckMsgBox", "Enable Pre-Check Message Box at Startup")
CheckBoxAutoAddStart := SettingsGui.Add("Checkbox", "xp y+5 w400 vAutoStart", "Enable AutoAddStart: When using the hotkey to auto add to queue, the queue will automatically start processing")
SettingsGui.Add("Text", "xp + y+10", "Set a New Hotkey: Click in the box below, press a hotkey, and click Save. Hotkey rules:`nAllowed Modifiers: CTRL, ALT, SHIFT`nCannot use: CTRL + {A, L, V} or Mouse")
EditHotkey := SettingsGui.Add("Hotkey", "xp + y+5 w200 vEditHotKey", "^Numpad0")
ButtonHotKeySave := SettingsGui.Add("Button", "x+5 yp vButtonHotKeySave", "Bind")
ButtonHotKeySave.OnEvent("Click", setHotKey)
;TextCurrentHotKey := SettingsGui.Add("Text", "x+5 + yp+5", "Current Hotkey: ")
;CheckBoxWinHotKey := SettingsGui.Add("CheckBox", "xm+5 y+5  vCheckBoxWinHotKey", "Add WIN key as hotkey modifier?")

ButtonSettingsSave := SettingsGui.Add("Button", "xm+5 + y+25 vButtonSettingSave", "Save Settings (also main window view settings) and close")
ButtonSettingsSave.OnEvent("Click", SettingsSave)


; ##################
; ### Set Values ###
; ##################

; If settings ini is found
if (FileExist(A_ScriptDir . "\QobuzDownloaderX Automation.ini")) {
    SettingsLoad()
}

; Set Hotkey
Hotkey(EditHotKey.Value, hotkeyFunction, "On")

; Set Default state of gui elements
changeButtonEnableState(false)
ButtonAddItem.Enabled := true
ButtonCleanFLACFileStructure.Enabled := true
ButtonLoadCSV.Enabled := true
TextBoxLink.Enabled := true
TextInstructions_Set_Left.Text := _Instructions_Set_Left_1 . " " . getHotKeyString() . " " . _Instructions_Set_Left_2

; Start showing GUI
MyGui.Show()

; ### Error / Warning Checks ###
if (!FileExist(A_ScriptDir . "\QobuzDownloaderX.exe")) {
    MsgBox("Exiting: QobuzDownloaderX.exe not found in " . A_ScriptDir . "`nPlease move program / script into your QobuzDownloaderX.exe folder", "QobuzDownloaderX.exe Not Found", 16)
}

while (WinExist("QobuzDownloaderX", , "Automation") || WinExist("QobuzDLX | Login", , "Automation")) {
    MsgBox("Error: All instances of QobuzDownloaderX.exe to be closed`nPlease close all of them before you continue", "QobuzDownloaderX.exe is open", 16)
}

if (CheckBoxDisableCheckMsgBox.Value) {
    MsgBox("Warning: Make sure to have logged into and set download folder in QobuzDownloaderX.exe at least once before continuing`n`nYou can disable this warning in Advance Settings", "QobuzDownloaderX.exe Pre-Check", 32)
}

; Check if new version is released on github
checkForUpdate(Version)

return

; #######################
; ### HotKey Function ###
; #######################

; Using one hotkey for auto add and pausing to make it easier on the user
; TODO Use HotIf to divide hotkey actions up. However isn't an excude WinTitle so shrug
; HotIfWinNotactive wasn't working for GUI
hotkeyFunction(*) {
    if (flagAutomationActive) {
        Pause -1
        if (A_IsPaused) {
            ToolTip("Automation Paused:`nPress " . getHotKeyString() . " to resume when cursor is on `nPID: " . pidInUse " `"download`" button")
        } else {
            ToolTip("Automation Resuming:`nWaiting update loop for " . MyListView.GetCount() . " queued")
        }
    } else if (WinActive("Automation ahk_class AutoHotkeyGUI")) {
        return ; script window found, no hotkey
    } else {
        A_Clipboard := ""
        Send("^l")
        Sleep(100)
        Send("^c")
        ClipWait
        Send("{Escape}")
        TextBoxLink.Text := A_Clipboard
        flagAddSuccessful := AddItem()
        tempString := "Added:"
        if (CheckBoxAutoAddStart.Value){
            tempString := "AutoAddStart:"
        }
        Switch flagAddSuccessful {
            Case 0:
                TrayTip(A_Clipboard, "Invalid Link Format:", 16)
            Case 1:
                TrayTip(A_Clipboard, "Album " . tempString, 16)
            Case 2:
                TrayTip(A_Clipboard, "Artist " . tempString, 16)
            Case 3:
                TrayTip(A_Clipboard, "Award / Label " . tempString, 16)
            Case 4:
                TrayTip(A_Clipboard, "Album Search " . tempString, 16)
            Default:
                TrayTip(A_Clipboard, "Invalid Link Format:", 16)
        }
        if (CheckBoxAutoAddStart.Value) {
            StartProcess()
        }
    }
}

; ####################
; ### GUI Handling ###
; ####################

; ### On Events ###

; Sets how the Queue List View is sorted
changeSorting(*) {
    MyListView.Enabled := false
    if (CheckBoxAutoAdjust.Value == true) {
        MyListView.ModifyCol(1, "25 Integer")
        MyListView.ModifyCol(2, "AutoHdr")
        MyListView.ModifyCol(3, "AutoHdr")
        MyListView.ModifyCol(4, "AutoHdr")
        MyListView.ModifyCol(5, "AutoHdr")
        MyListView.ModifyCol(6, "AutoHdr")
        MyListView.ModifyCol(7, "AutoHdr")
    }
    Switch DropDownAutoSort.Value {
        Case 1: ; artist/album
            MyListView.ModifyCol(3, "Sort")
            MyListView.ModifyCol(2, "Sort")

        Case 2: ; release date
            MyListView.ModifyCol(4, "Logical SortDesc")

        Case 3: ; Quality
            MyListView.ModifyCol(5, "Float SortDesc")
            MyListView.ModifyCol(6, "Float SortDesc")

        Case 4: ; Add to Top
            MyListView.ModifyCol(1, "25 Integer Sort")

        Case 5: ; Add to Bottom
            MyListView.ModifyCol(1, "25 Integer SortDesc")

        Default:
            MyListView.ModifyCol(3, "Sort")
            MyListView.ModifyCol(2, "Sort")

    }
    MyListView.Enabled := true
    return
}

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
    TextBoxChoiceParallel.Enabled := state
    ChoiceParallel.Enabled := state
    ButtonSetParallelMax.Enabled := state
    DropDownAutoSort.Enabled := state
    CheckBoxAutoAdjust.Enabled := state
    ButtonCleanFLACFileStructure.Enabled := state
    TextBoxLink.Enabled := state
    ButtonAddItem.Enabled := state
    ButtonRemoveItem.Enabled := state
    ButtonClearQueue.Enabled := state
    ButtonLoadCSV.Enabled := state
    TextWhichCSV.Text := ""
    return
}

; Double Click on a row to open in browser
ListViewOpenLink(LV, Row) {
    Run(LV.GetText(row, 5))
    return
}

; ### GUI Buttons ###

; Button to quickly set the Queue Total to Download Instances
SetParallelMax(*) {
    if (MyListView.GetCount() > 100) {
        MsgBox("Warning: Setting Instances to 100`n`nReason: Honestly haven't tested that many")
        ChoiceParallel.Value := 100
    } else {
        ChoiceParallel.Value := MyListView.GetCount()
    }
    return
}

; Handles link input, figures out what type of link, and passes it to its function type
AddItem(*) {
    flagAddSuccessful := 0
    ; Input could be a: Full Album Link, Link with Album ID at end, Artist Link. Thus named dataLink
    dataLink := TextBoxLink.Text
    if (StrCompare(dataLink, "") == 0) {
        MsgBox("No Link Provided: Please enter a link into the textbox")
    } else {
        changeButtonEnableState(false)
        parts := StrSplit(dataLink, "/")
        if ((parts.Length > 2)) && (StrCompare(parts[parts.Length - 1], "page") == 0) {
            partsWithoutPage := StrSplit(dataLink, "/page")
            dataLink := partsWithoutPage[1]
            parts := StrSplit(dataLink, "/")
        }
        if (parts.Length == 7) {
            if ((StrCompare(parts[3], "www.qobuz.com") == 0) && (StrCompare(parts[5], "interpreter") == 0)) {
                isAlreadyQueued := artistAddAlbums(dataLink, 1) ; artist link, page 1 for a counter
                flagAddSuccessful := 2
                if (isAlreadyQueued != 0) {
                    MsgBox("Warning: Mulitple Albums ingored due to already being queued")
                }
            } else if ((StrCompare(parts[3], "www.qobuz.com") == 0) && (StrCompare(parts[5], "album") == 0)) {
                isAlreadyQueued := isAlbumLinkInList(dataLink)
                if (isAlreadyQueued != 0) {
                    MsgBox("Album Already Queued: " . MyListView.GetText(isAlreadyQueued, 3) . " by " . MyListView.GetText(isAlreadyQueued, 2))
                } else {
                    addAlbum(dataLink)
                    flagAddSuccessful := 1
                }
            } else {
                MsgBox("Invalid Link: Please enter a valid Qobuz link")
            }
        } else if ((parts.Length == 8) && ((StrCompare(parts[5], "awards") == 0) || (StrCompare(parts[5], "label") == 0))) {
            artistAddAlbums(datalink, 1) ; award or label link so send it
            flagAddSuccessful := 3

        } else {
            possibleAlbumLink := searchQobuzForAlbum(parts[parts.Length]) ; Either a album ID or play link
            if (possibleAlbumLink != "") {
                isAlreadyQueued := isAlbumLinkInList(dataLink)
                if (isAlreadyQueued != 0) {
                    MsgBox ("Searched Album Already Queued: " . MyListView.GetText(isAlreadyQueued, 3) . " by " . MyListView.GetText(isAlreadyQueued, 2))
                }
                addAlbum(possibleAlbumLink)
                flagAddSuccessful := 4
            } else {
                MsgBox ("Invalid Link, Invalid Album ID, or Link has page number: Please view instructions") ; no redirect when searching for album id directly
            }
        }
    }
    changeButtonEnableState(true)

    ButtonAddItem.Text := "Add Link"
    TextboxLink.Text := "" ; Empty the textbox
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    changeSorting()
    return flagAddSuccessful
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
        ButtonLoadCSV.Enabled := true
        TextBoxLink.Enabled := true
    }
    return
}

; Start Automation Process
StartProcess(*) {
    if (MyListView.GetCount() == 0) {
        MsgBox("Nothing in queue, add an album or artist")
    } else {
        changeButtonEnableState(false)
        CheckBoxSaveToCSV.Enabled := false
        ;Suspend(false)
        CoordMode("Pixel", "Client")
        SetTitleMatchMode(2)
        ; before Parallel

        howManyInstances := ChoiceParallel.Value
        if (howManyInstances > MyListView.GetCount()) {
            howManyInstances := MyListView.GetCount()
        }
        ToolTip("Please Wait: Opening " . howManyInstances . " download instances...`nDon't move anything")
        ; Create PID array
        downloadInstancePIDArray := Array()
        ; Open QobuzDownloaderX.exe and login
        global flagAutomationActive := true
        Loop howManyInstances {
            try {
                Run("QobuzDownloaderX.exe", A_ScriptDir, , &tempPID)
            } catch {
                ToolTip()
                MsgBox("Exiting: QobuzDownloaderX.exe not found in " . A_ScriptDir . "`nPlease move program / script into your QobuzDownloaderX.exe folder", "QobuzDownloaderX.exe Not Found", 16)
                changeButtonEnableState(true)
                global flagAutomationActive := false
                return
            }
            if (tempPID == 0) {
                ToolTip()
                MsgBox("Critical Error: Couldn't get PID for Instance # " . A_Index, 16)
                changeButtonEnableState(true)
                global flagAutomationActive := false
                return
            }
            WinWaitActive("ahk_pid " tempPID " QobuzDLX | Login ", , 1, "Automation ahk_class AutoHotkeyGUI")
            WinActivate("ahk_pid " tempPID " QobuzDLX | Login ", , "Automation ahk_class AutoHotkeyGUI")
            ;WinMove(0, 0, , ,"ahk_pid " tempPID,, "ahk_class AutoHotkeyGUI Automation" )
            downloadInstancePIDArray.Push(tempPID)
            Send("{Enter}")
            Sleep(100)
        }
        if (CheckBoxSaveToCSV.Value == 1) {
            DirCreate "Queue_CSV"
            csvFilePath := A_ScriptDir . "\Queue_CSV\" . FormatTime(, "yyyy-MM-dd") . " Queue.csv"
            if (!FileExist(csvFilePath)) {
                FileAppend("`"" . MyListView.GetText(0, 2) . "`",`"" . MyListView.GetText(0, 3) . "`",`"" . MyListView.GetText(0, 4) . "`",`"" . MyListView.GetText(0, 5) . "`",`"" . MyListView.GetText(0, 6) . "`",`"" . MyListView.GetText(0, 6) . "`"", csvFilePath)
            }
        }

        ; TODO change from waiting for first to putting this inside the while loop to allow same idea of start while waiting to load next. Waiting to load all might be too slow for some.
        secondsToWait := 15
        currentSeconds := 0
        Loop secondsToWait {
            currentSeconds := A_Index - 1
            ToolTip("Waiting for First Login to Complete`nTimeout in: " . currentSeconds . " out of " . secondsToWait . " seconds")
            try {
                currentTitle := WinGetTitle("ahk_pid " downloadInstancePIDArray[1])
                if (StrCompare(currentTitle, "QobuzDownloaderX") == 0) {
                    break
                }
            } catch {
                ; do nothing, pid might be in-between changing from log-in to QobuzDownloaderX
            }
            sleep(1000)
        }
        ToolTip()
        if (currentSeconds == (secondsToWait - 1)) {
            MsgBox("Error: First Instance stuck on Login Screen. Did you forget to login first?`n`nClick OK to Stop Automation and close QobuzDownloaderX Instances")
            Loop downloadInstancePIDArray.Length {
                WinClose("ahk_pid " downloadInstancePIDArray[A_Index], , , "Automation ahk_class AutoHotkeyGUI")
            }
            changeButtonEnableState(true)
            global flagAutomationActive := false
            return
        }

        currentRowPointer := 1 ; Data starts a 1, and loop is going to add 1
        while howManyInstances > 0 {
            donePIDArray := Array()
            Loop downloadInstancePIDArray.Length {
                if (!downloadInstancePIDArray.Has(A_Index)) {
                    continue ; null, skip pid since its been removed
                }
                currentPID := downloadInstancePIDArray[A_Index]
                WinWaitActive("ahk_pid " currentPID, , 1, "Automation ahk_class AutoHotkeyGUI")
                WinActivate("ahk_pid " currentPID, , "Automation ahk_class AutoHotkeyGUI")
                global pidInUse := currentPID
                WinSetTitle("PID: " . currentPID, "ahk_pid " currentPID, , "Automation ahk_class AutoHotkeyGUI")
                WinSetStyle("+0xC00000", "PID: " . currentPID, , "Automation ahk_class AutoHotkeyGUI")
                WinMove(0, 0, , , "ahk_pid " currentPID, , "Automation ahk_class AutoHotkeyGUI")

                ToolTip("Don't move the mouse:`nQueued " . currentRowPointer - 1 . " out of " . MyListView.GetCount() . " albums`nViewing instance PID " . currentPID . " of " . howManyInstances . " total running`nTo pause use " . getHotKeyString())

                ; Get the color at the specified window coordinate
                ; Mouse has to under pixel to get color, I know the docs say otherwise.
                ; TODO found in 0.4.2, actually to not use the mouse need to find different element on screen
                MouseMove 615, 95
                color := PixelGetColor(615, 95, "RGB")
                if (color = 0x0086FF) {
                    if (currentRowPointer > MyListView.GetCount()) {
                        donePIDArray.Push(A_Index)
                        continue ; skip loop, removing pid since no more to queue
                    } else {
                        parts := StrSplit(MyListView.GetText(currentRowPointer, 7), "/")
                        playLink := "https://play.qobuz.com/album/" . parts[parts.Length]
                        MouseClick("Left", 575, 95, 1, 0)
                        Send("^a")
                        Send("{Backspace}")
                        A_Clipboard := playLink
                        Send ("^v")
                        MouseClick("Left", 615, 95, 1, 0)
                        if (CheckBoxSaveToCSV.Value == 1) {
                            artist := StrReplace(MyListView.GetText(currentRowPointer, 2), "`"", "`"`"")
                            album := StrReplace(MyListView.GetText(currentRowPointer, 3), "`"", "`"`"")
                            FileAppend "`n`"" . artist . "`",`"" . album . "`",`"" . MyListView.GetText(currentRowPointer, 4) . "`",`"" . MyListView.GetText(currentRowPointer, 5) . "`",`"" . MyListView.GetText(currentRowPointer, 6) . "`",`"" . MyListView.GetText(currentRowPointer, 7) . "`"", csvFilePath
                        }
                        ToolTip("Don't move the mouse:`nQueued " . currentRowPointer . " out of " . MyListView.GetCount() . " albums`nViewing instance PID " . currentPID . " of " . howManyInstances . " total running`nTo pause use " . getHotKeyString())
                        currentRowPointer++
                    }
                }
                Sleep(100)
            }
            Loop donePIDArray.Length {
                indexPID := donePIDArray.Pop()
                WinClose("ahk_pid " downloadInstancePIDArray[indexPID] " PID:", , , "ahk_class AutoHotkeyGUI Automation")
                downloadInstancePIDArray.Delete(indexPID)
                howManyInstances--
                ToolTip("Don't move the mouse:`nQueued " . currentRowPointer - 1 . " out of " . MyListView.GetCount() . " albums`nViewing instance PID " . currentPID . " of " . howManyInstances . " total running`nTo pause use " . getHotKeyString())
            }
        }
        ; After Parallel, when complete
        ToolTip()
        totalQueue := MyListView.GetCount()
        MyListView.Delete()
        changeButtonEnableState(false)
        ButtonAddItem.Enabled := true
        ButtonCleanFLACFileStructure.Enabled := true
        ButtonLoadCSV.Enabled := true
        TextBoxLink.Enabled := true
        CheckBoxSaveToCSV.Enabled := true
        ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
        global flagAutomationActive := false
        ;Suspend(true)
        if (CheckBoxSaveToCSV.Value == 1) {
            TrayTip("CSV Saved: " . csvFilePath, "Finished Queue of " . totalQueue, 16)
        } else {
            TrayTip(, "Finished Queue of " . totalQueue, 16)
        }
    }
    return
}

; Based on a directory, will find any folder named "FLAC (", check with regex, move files inside up a directory, and detete the "FLAC (" folder after checking with regex
CleanFLACFileStructure(*) {
    MsgBox("Warning: This script was not made for checking if an album has multiple qualities`n`nThis is only an issue if you have manually downloaded a lower quality album in the past`n`nAfter running, QobuzDownloaderX will not be able to detect an already downloaded album at the directory given")
    dirToClean := DirSelect(, 0, "Please select your QobuzDownloaderX downloads folder")
    if (dirToClean == "") {
        return 0
    }
    msgResult := MsgBox("Please confirm the directory: " . dirToClean . "`n`n If incorrect click cancel to go back to main GUI", "", 1)
    if (msgResult = "Cancel") {
        return 0
    }
    changeButtonEnableState(false)
    ; Save the current working directory
    current_directory := A_WorkingDir

    ; Change to the specified working directory
    SetWorkingDir(dirToClean)
    ; Loop through directories whose names start with "FLAC ("
    Loop Files, "FLAC (*", "DR" {
        if (RegExMatch(A_LoopFileName, "S)FLAC \(\d{2}bit-\d{2,3}\.?\d?kHz\)", &checkedFolderName) == 0) {
            ; Folder not found skip
            continue
        }
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
        if (RegExMatch(A_LoopFileName, "S)FLAC \(\d{2}bit-\d{2,3}\.?\d?kHz\)", &checkedFolderName) == 0) {
            ; Folder not found skip
            continue
        }
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
    changeButtonEnableState(true)
    ;MsgBox("Done cleaning FLAC file structure at: " . dirToClean)
    TrayTip(dirToClean, "FLAC Cleaning Done:", 16)
    SetWorkingDir(current_directory)
    return 1
}
; Load a CSV Queue file into the Queue
LoadCSV(*) {
    whichCSV := FileSelect(1, , "Select a Queue CSV To Load - " . A_ScriptName, "(*.csv)")
    if (whichCSV = "") {
        return ; do nothing, no file selected
    } else if (InStr(whichCSV, ".csv") == 0) {
        MsgBox("Critical Error: File type not .csv was selected")
        return
    } else {
        changeButtonEnableState(false)
        Loop read, whichCSV {
            LineNumber := A_Index
            parts := Array()
            Loop Parse, A_LoopReadLine, "CSV" {
                if (A_Index > 5) {
                    MsgBox("Error: Data outside the five columns which are:`n`n`"Artist`",`"Album`",`"Bit`",`"kHz`",`"Link`"")
                    return
                } else if (LineNumber == 1) {
                    if (StrCompare(A_LoopField, MyListView.GetText(0, A_Index + 1)) != 0) {
                        MsgBox("Error: Incorrect CSV Column Header which are:`n`n`"Artist`",`"Album`",`"Bit`",`"kHz`",`"Link`"")
                        return
                    }
                } else {
                    parts.Push(A_LoopField)
                }
            }
            if (LineNumber != 1) {
                if ((parts[1] == "") || (parts[2] == "") || (parts[3] == "") || (parts[4] == "") || (parts[5] == "") || (parts[5] == "")) {
                    MsgBox("Error: Line " . LineNumber . " has an empty cell or incorrect formated data`n`n" . parts[1] . "," . parts[2] . "," . parts[3] . "," . parts[4] . "," . parts[5])
                }
                processAlbumInfo(parts[1], parts[2], parts[3], parts[4], parts[5], parts[6])
            }
        }
        TrayTip(whichCSV, "CSV Loaded to Queue:", 16)
    }
    parts := StrSplit(whichCSV, "\")
    changeButtonEnableState(true)
    TextWhichCSV.Text := "Loaded: " . parts[parts.Length]
    ButtonAddItem.Text := "Add Link"
    TextboxLink.Text := "" ; Empty the textbox
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    changeSorting()
    return
}


MyGuiClose(*) {
    ExitApp()
}

; #################
; ### Functions ###
; #################

; Artist, Award, or Label link function handle
artistAddAlbums(artistLink, pageCounter) {
    ButtonAddItem.Text := "Searching Page " . pageCounter
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

        ; Get Release Date and clean
        postionRegEx := RegExMatch(htmlSource, "S)(?<=</a> on )[^\n]+(?=\n)", &releaseDate, postionRegEx)
        parts := StrSplit(releaseDate[], " ")
        parts[2] := StrReplace(parts[2], ",", "")
        releaseDate := parts[3] . "/" ReplaceMonthToInt(parts[1]) . "/" . parts[2]

        ; Get album qual
        postionRegEx := RegExMatch(htmlSource, "S)(?<=<span class=`"store-quality__info`">)[^-\s]+(?=-)", &newBit, postionRegEx)
        RegExMatch(htmlSource, "S)(?<=<span class=`"store-quality__info`">)\s?[^\s]+(?=\s+kHz)", &newkHz, postionRegEx)
        newkhz := StrReplace(newKhz[], " ", "")

        processAlbumInfo(artistName, albumName, releaseDate, newBit[], newkHz, albumLink)
    }
    ; Check if there is a next page
    ; Can't just get href due to "lookbehind assertion is not fixed length" for when href either space or on new line
    ; So keeping a Page Counter
    ; Also can't use postionRegEx since its 0 from the loop
    postionRegEx := RegExMatch(htmlSource, "S)<a class=`"store-paginator__button next `"", &nextPageLinkButton)
    if (postionRegEx == 0) {
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

    ; Get Release date
    RegExMatch(htmlSource, "S)(?<=Released on )[^\s]+(?= by)", &releaseDate)
    parts := StrSplit(releaseDate[], "/")
    ; WARN This will make bad csv release date after 2050. Hope Qobuz fixes their pages by then
    if (parts[3] > 50) {
        parts[3] := "19" . parts[3]
    } else {
        parts[3] := "20" . parts[3]
    }
    releaseDate := parts[3] . "/" parts[1] . "/" . parts[2]

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
    return processAlbumInfo(artistName, albumName, releaseDate, newBit[], newkhz, albumLink)
}

; Based on album info, check to add it to the list if:
; - If its not already in the queue
; - If its a higher quality
processAlbumInfo(artist, album, releaseDate, new_bit, new_kHz, albumLink) {
    ; return 0 - album was already in queue with better qual
    ; return 1 - album wasn't in queue so added
    ; return 2 - album was already in queue but had worse qual so this one was added
    ; return 3 - empty item
    parts := StrSplit(releaseDate, "/")
    if ((artist == "") || (album == "") || (parts[1] == 0) || (parts[2] == 0) || (parts[3] == 0) || (new_bit == "") || (new_kHz == "") || (albumLink == "")) {
        MsgBox("Error Parsing HMTL: Please make an issue on github with the following:`n" . artist ", " . album ", " . releaseDate . ", " . new_bit ", " . new_kHz ", " . albumLink)
        return 3
    }

    queuedRow := isAlbumQueued(artist, album)
    if (queuedRow != 0) {
        ; Get queued quality

        if ((new_bit > MyListView.GetText(queuedRow, 5)) || (new_kHz > MyListView.GetText(queuedRow, 6))) {
            ; new bit is probably 24 while queued bit is 16
            ; new kHz is higher, 16Bit max mhz is 24bit min mhz.
            MyListView.Delete(queuedRow)
            MyListView.Add(, "", artist, album, new_bit, new_kHz, albumLink)
            return 2
        } else {
            ; Do Nothing since higher qual album already queued
            return 0
        }
    } else {
        MyListView.Add(, MyListView.GetCount() + 1, artist, album, releaseDate, new_bit, new_kHz, albumLink)
        return 1
    }
}

; TODO This Replace funtions might not be the fastest way to do so

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

    htmlCharCodes := ["&#60;", "&#62;", "&#38;", "&amp;", "&#34;", "&#039;", "&#39;", "&quot;", "â€™", "â€œ", "â€"]
    htmlChars := ["<", ">", "&", "&", "`"", "'", "'", "`"", "'", "`"", "`""]

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

; Converts a three letter month to int
ReplaceMonthToInt(Month) {
    monthCodes := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    Loop monthCodes.Length {
        if (StrCompare(Month, monthCodes[A_Index]) == 0) {
            return A_Index
        }
    }
    return 0
}

; Is the albumlink in the Queue
isAlbumLinkInList(albumLink) {
    loop MyListView.GetCount() {
        if (StrCompare(albumLink, MyListView.GetText(A_Index, 7)) == 0) {
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
    return WebRequest
}

; Check / parse github html for new release version
; Should be able to convert this to an api call once repo is public
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
        TextUpdateAvailable.Text := "Error: Couldn't find latest version number for update check"
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

; ####################
; ### Settings GUI ###
; ####################

AdvanceSettings(*) {
    ;Hotkey(scriptHotKey, "Off")
    SettingsGui.Show()
    return
}

SettingsSave(*) {
    iniFile := A_ScriptDir . "\QobuzDownloaderX Automation.ini"
    IniWrite(ChoiceParallel.Value, iniFile, "MainWindow", "Instances")
    IniWrite(DropDownAutoSort.Value, iniFile, "MainWindow", "AutoSort")
    IniWrite(CheckBoxAutoAdjust.Value, iniFile, "MainWindow", "AutoAdjust")
    IniWrite(CheckBoxSaveToCSV.Value, iniFile, "MainWindow", "SaveCSV")
    IniWrite(CheckBoxDisableCheckMsgBox.Value, iniFile, "SettingsWindow", "PreCheckMsg")
    IniWrite(CheckBoxAutoAddStart.Value, iniFile, "SettingsWindow", "AutoAddStart")
    IniWrite(EditHotkey.Value, iniFile, "SettingsWindow", "Hotkey")
}

SettingsLoad(*) {
    iniFile := A_ScriptDir . "\QobuzDownloaderX Automation.ini"
    TextBoxChoiceParallel.Value := IniRead(iniFile, "MainWindow", "Instances")
    ChoiceParallel.Value := IniRead(iniFile, "MainWindow", "Instances")
    DropDownAutoSort.Value := IniRead(iniFile, "MainWindow", "AutoSort")
    CheckBoxAutoAdjust.Value := IniRead(iniFile, "MainWindow", "AutoAdjust")
    CheckBoxSaveToCSV.Value := IniRead(iniFile, "MainWindow", "SaveCSV")
    CheckBoxDisableCheckMsgBox.Value := IniRead(iniFile, "SettingsWindow", "PreCheckMsg")
    CheckBoxAutoAddStart.Value := IniRead(iniFile, "SettingsWindow", "AutoAddStart")
    EditHotkey.Value := IniRead(iniFile, "SettingsWindow", "Hotkey")
    global scriptHotKey := EditHotkey.Value
}

setHotKey(*) {
    curHotKey := scriptHotKey

    unAllowedHotKey := ["", "^a", "^l", "^v"]
    Loop unAllowedHotKey.Length {
        if (StrCompare(EditHotkey.Value, unAllowedHotKey[A_Index]) == 0) {
            EditHotkey.Value := curHotKey
            return
        }
    }
    HotKey(curHotKey, , "Off")
    global scriptHotKey := EditHotkey.Value
    Hotkey(EditHotKey.Value, hotkeyFunction, "On")
    TextInstructions_Set_Left.Text := _Instructions_Set_Left_1 . " " . getHotKeyString() . " " . _Instructions_Set_Left_2
}

getHotKeyString() {
    curHotKey := scriptHotKey
    specialChar := ["+", "^", "!", "Numpad"]
    replaceString := ["Shift + ", "Ctrl + ", "Alt + ", "Numpad "]
    Loop specialChar.Length {
       curHotKey := StrReplace(curHotKey, specialChar[A_Index], replaceString[A_Index])
    }
    return curHotKey
}


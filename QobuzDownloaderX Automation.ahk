#Requires AutoHotkey v2.0
SendMode("Input") ; Recommend for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)

_Instructions := "
(    
(Verison 0.2) Instructions:
Start QobuzDownloaderX, choose folder, leave open in background

- To Add:
Paste + Press Enter into the text box any of the following formats:
1. https://www.qobuz.com/us-en/album/
2. https://www.qobuz.com/us-en/interpreter/
3. https://www.qobuz.com/us-en/awards/
4. Album ID on its own

The program will detected if the album is already queued and also queue the highest quality version

To Remove: Select checkboxes and click remove or use clear queue 

To Start: Click "Start Download Queue" to start process. DON'T move your mouse till complete

You can use hotkey CTRL + Numpad 0 to pause the process if you need to do something.
If you do, move it back over the "download" button on the QobuzDownloaderX Window when resuming

After complete: 
- A CVS file will be created of the Queue at the currect directory
- Use "Clean FLAC File Structure" to remove the FLAC file sturcture created by QobuzDownloaderX
)"
;"+Resize -MaximizeBox +MinSize"
MyGui := Gui()
MyGui.Title := "QobuzDownloaderX Automation"
MyGui.OnEvent("Close", GuiClose)

ButtonStartProcess := MyGui.Add("Button", "vButtonStartProcess x+5 yp section", "Start Download Queue of 0")
ButtonStartProcess.OnEvent("Click", StartProcess)
ButtonCleanFLACFileStructure := MyGui.Add("Button", "vButtonCleanFLACFileStructure x+5 yp", "Clean FLAC File Structure")
ButtonCleanFLACFileStructure.OnEvent("Click", CleanFLACFileStructure)
ButtonClearQueue := MyGui.Add("Button", "x+55 yp w100 h20", "Clear Queue")
ButtonClearQueue.OnEvent("Click", ClearQueue)
MyListView := MyGui.Add("ListView", "xs ys+25 w700 h600 Grid Checked Sort -LV0x10 vMyListView", ["", "Artist", "Album", "Quality", "Link"])
MyListView.OnEvent("ItemCheck", EnableRemoveButton)
MyListView.OnEvent("DoubleClick", ListViewOpenLink)
TextBox := MyGui.Add("Edit", "section w200 vTextBox")
ButtonAddItem := MyGui.Add("Button", "x+5 yp w100 h20 Default", "Add Link")
ButtonAddItem.OnEvent("Click", AddItem)
ButtonRemoveItem := MyGui.Add("Button", "x+5 yp w150 h20", "Remove Checked Albums")
ButtonRemoveItem.OnEvent("Click", RemoveItem)
ButtonRemoveItem.Enabled := false
MyGui.Add("Text", "xs ys+25" , _Instructions)

MyGui.Show()

Suspend(true)
return

;### HotKey to Pause Downloading ###
^Numpad0::
{
    Pause -1
    if(A_IsPaused) {
        ToolTip("Automation Paused:`nPress Ctrl + Numpad 0 to resume when mouse is on `"download`"")
    } else {
        ToolTip("Automation Resumed:`nWaiting for current album out of " . MyListView.GetCount() . " queued")
    }
}

;### GUI Handling ###
EnableRemoveButton(GuiCtrlObj, Item, Checked) {
    ; Doesn't account for if a item is checked and the unchecked
    ; Would probably need a 2d array
    if (!ButtonRemoveItem.Enabled) {
        ButtonRemoveItem.Enabled := true
    }
    return
}

ListViewOpenLink(LV, Row) {
    Run(LV.GetText(row, 5))
}

AddItem(*) {
    ; Input could be a: Full Album Link, Link with Album ID at end, Artist Link. Thus named dataLink
    ; TODO if someone tries to add an artist link not on page 1
    dataLink := TextBox.Text
    if (StrCompare(dataLink, "") == 0) {
        MsgBox("No Link Provided: Please enter a link into the textbox")
    } else {
        parts := StrSplit(dataLink, "/")
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
        } else if ((parts.Length == 8) && (StrCompare(parts[5], "awards") == 0)) {
            artistAddAlbums(datalink , 1) ; award link so send it

        } else {
            possibleAlbumLink := searchQobuzForAlbum(parts[parts.Length]) ; Either a album ID or play link
            if (possibleAlbumLink != "") {
                isAlreadyQueued := isAlbumLinkInList(dataLink)
                if (isAlreadyQueued != 0) {
                    MsgBox ("Searched Album Already Queued: " . MyListView.GetText(isAlreadyQueued, 3) . " by " . MyListView.GetText(isAlreadyQueued, 2))
                }
                addAlbum(possibleAlbumLink)
            } else {
                MsgBox ("Invalid Link or Album ID: Please enter one of the following:`n`nQobuz artist page link (without page number)`nQobuz album link with Album ID`nAlbumID") ; no redirect when searching for album id directly
            }
        }
    }
    Textbox.Text := "" ; Empty the textbox
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    MyListView.ModifyCol
    MyListView.ModifyCol(3, "Sort")
    MyListView.ModifyCol(2, "Sort")
    ; TODO sort album, then sort artist
    return
}

RemoveItem(*) {
    ; Loop through MyListView to find checked rows
    ; Setting max loops as safety feature
    RowNumber := 0
    Loop MyListView.GetCount() {
        MsgBox("Start Loop, row: " . RowNumber)
        RowNumber := MyListView.GetNext(, "Checked")
        MsgBox("GetNext, row: " . RowNumber)
        if (RowNumber == 0) {
            ; No more checked rows
            MsgBox("break")
            break
        } else {
            ; Checked Row Found, remove from queue and list view
            MsgBox("Deleting row: " . RowNumber)
            MyListView.Delete(RowNumber)
        }
    }
    ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    ButtonRemoveItem.Enabled := false
    return
}

ClearQueue(*) {
    msgResult := MsgBox("Are you sure you want to clear the queue?`n`nClick Yes to continue, or No to go cancel.", "Clear Queue Warning", 4)
    if (msgResult = "Yes") {
        MyListView.Delete()
        ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
    }
    return
}

StartProcess(*) {
    if (MyListView.GetCount() == 0) {
        MsgBox("Nothing in queue, add an album or artist")
    } else {
        Suspend(false)
        CoordMode("Pixel", "Window")
        SetTitleMatchMode(2)
        WinActivate("QobuzDownloaderX", , "Automation")
        if (WinWaitActive("QobuzDownloaderX", , 2, "Automation") == 0) {
            MsgBox("QobuzDownloaderX Not Open: Please open before starting")
            return
        }
        cvsFilePath := A_ScriptDir . "\" . FormatTime(,"yyyy-MM-dd hh-mm-ss") . " Queue.csv"
        FileAppend MyListView.GetText(0,2) . "," . MyListView.GetText(0,3) . "," . MyListView.GetText(0,4) . "," . MyListView.GetText(0,5), cvsFilePath
        Loop MyListView.GetCount() {
            parts := StrSplit(MyListView.GetText(A_Index, 5), "/")
            playLink := "https://play.qobuz.com/album/" . parts[parts.Length]
            Click("500, 95")
            Send("^a")
            Send("{Backspace}")
            Send (playLink)
            Click("615, 95")
            ToolTip("Don't move the mouse:`nDownloading " . A_Index . " out of " . MyListView.GetCount() . " queued`nUse CTRL + Numpad 0 to pause")
            Sleep(100)
            ColorCheck := 0
            Loop {
                ; Get the color at the specified window coordinate
                ;MouseGetPos(&xpos, &ypos)
                color := PixelGetColor(615, 95, "RGB")
                ; Check if the color has changed from 0070EF to 0086FF
                if (color = 0x0086FF) {
                    break
                }
                ColorCheck++
                if (ColorCheck >= 600) {
                    ColorCheck := 0
                    msgResult := MsgBox(playLink " has been downloading over one minute. Do you want to continue?`n`nClick Yes to continue, or No to exit.", "", 4)
                    if (msgResult = "Yes")
                        continue
                    else
                        break
                }
                ; Sleep for a short interval before checking again
                Sleep(100)
            }
            FileAppend "`n" . MyListView.GetText(A_Index,2) . "," . MyListView.GetText(A_Index,3) . "," . MyListView.GetText(A_Index,4) . "," . MyListView.GetText(A_Index,5), cvsFilePath
        }
        ToolTip()
        MyListView.Delete()
        ButtonStartProcess.Text := "Start Download Queue of " . MyListView.GetCount()
        Suspend(true)
        MsgBox("Finsihed Downloading: CSV of Queue at: " . A_ScriptDir)
    }
    return
}

CleanFLACFileStructure(*) {
    dirToClean := DirSelect(, 0, "Please select your QobuzDownloaderX downloads folder")
    msgResult := MsgBox("Please confirm the directory: " . dirToClean . "`n`n If incorrect click cancel to go back", "", 1)
    if (msgResult = "Cancel") {
        return 0
    }
    ; Save the current working directory
    current_directory := A_WorkingDir
    
    ; Change to the specified working directory
    SetWorkingDir(dirToClean)
    MsgBox("Working Dir: " . A_WorkingDir)
    ; Loop through directories whose names start with "FLAC ("
    Loop Files, "FLAC (*", "DR" {
        ; Now loop through each file
        MsgBox("Found flac ( dir at: " . A_LoopFileFullPath)
        Loop Files, A_LoopFileFullPath . "\*.*" , "F" {
            ; Get the full path and directory of the current file
            full_path := A_LoopFileFullPath
            MsgBox("Moving Loop | File: " . full_path)
            if(InStr(full_path, dirToClean) == 0) {
                MsgBox("Critical Error: Outside of Working Directory: " . A_WorkingDir . "`nEnding cleanFileStructureFLAC")
                return 2
            }
            directory := A_LoopFileDir
            MsgBox("Moving Loop | File : " . full_path . " | directory: " . directory)
        
            ; Move the file to the parent directory
                FileMove full_path, directory . "\.."
        }
    }
    
    ; Loop through all directories whose names start with "FLAC"
    Loop Files, "FLAC (*", "DR"
    {
        ; Get the full path of the current directory
        full_path := A_LoopFileFullPath
        MsgBox("Deleting Loop | FilePath: " . full_path)
        
        ; Attempt to remove the directory, and show error message if failed
        try {
            DirDelete full_path, 0
        } catch {
            MsgBox("Critical Error: " . A_LoopFileFullPath . "was not empty when trying to delete`n`nReason: There were two or more FLAC qualities of the album`n`nSolution: Manually move the verison you want, delete others, and re-run" )
            return 3
        }

    }
    ; Restore the original working directory
    SetWorkingDir(current_directory)
    return 1
}

GuiClose(*) {
    ExitApp()
}

;lastPart := parts[parts.Length]
;fullLink := "https://play.qobuz.com/album/" . lastPart
;linkExists := false

artistAddAlbums(artistLink, pageCounter) {
    ToolTip("Please wait: Searching Page " . pageCounter)
    ; Download Album HTML to temp file
    tempArtistFilePath := A_ScriptDir . "\tempArtist.html"
    ; Build Page Link based on pageCounter
    artistLinkPageCounter := artistLink . "/page/" . pageCounter
    Download(artistLinkPageCounter, tempArtistFilePath)

    ; Read the temporary HTML file
    htmlSource := Fileread(tempArtistFilePath)
    ; Clean up - Delete the temporary file
    ;MsgBox("read")
    FileDelete(tempArtistFilePath)

    ; Loop through html to search for Album Title and Album Link
    postionRegEx := 1 ; Set a default reading postion at start for hopefully faster RegEx
    alreadyQueued := 0 ; Var to set a msgbox later insetad of saying which were already queued.
    ;MsgBox("ArtistName: " . artistName[] . " at pos: " . postionRegEx)
    loop {
        ;MsgBox("Start Loop, pos: " . postionRegEx)
        ; Get the album link. Sometime album link parts with qobuz or us-en, so just capture the us-en
        postionRegEx := RegExMatch(htmlSource, "S)(?<=<a href=`")[^`"]+(?=`" style)", &partAlbumLink, postionRegEx)
        if (postionRegEx == 0) {
            ;MsgBox("No more albums found. Pos:" . postionRegEx)
            break
        }
        ;MsgBox("Found album: " . partAlbumLink[] . " | at pos: " . postionRegEx)
        ;albumLink := SubStr(partAlbumLink[], StrLen("<a href=`""))
        if (InStr(partAlbumLink[], "https://www.qobuz.com") == 0) {
            albumLink := "https://www.qobuz.com" . partAlbumLink[]
        }
        ;MsgBox("Fixed link: " . albumLink)

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
    ;MsgBox("posReg before finding next button: " . postionRegEx)
    ; Check if there is a next page
    ; Can't just get href due to "lookbehind assertion is not fixed length" for when href either space or on new line
    ; So keeping a Page Counter
    ; Also can't use postionRegEx since its 0 from the loop
    postionRegEx := RegExMatch(htmlSource, "S)<a class=`"store-paginator__button next `"", &nextPageLinkButton)
    ;MsgBox("Current Page: " . pageCounter . " | Is there a next page? 0 if not: " . postionRegEx)
    if (postionRegEx == 0) {
        ;MsgBox("No more pages, all done: " . alreadyQueued)
        ToolTip
        return alreadyQueued
    } else {
        ;MsgBox("Next Page Time:" . pageCounter . ", " . alreadyQueued)
        pageCounter++ ; Increase pageCounter
        alreadyQueued := alreadyQueued + artistAddAlbums(artistLink, pageCounter)
    }
    return alreadyQueued
}

; MsgBox("Warning: Mulitple Albums ingored due to already being queued")
; MsgBox(MyListView.GetText(indexAlbumQueued, 3) . " by " . MyListView.GetText(indexAlbumQueued, 2) . " is already in queue" . "`nLink Queued: " . MyListView.GetText(indexAlbumQueued, 4))

addAlbum(albumLink) {
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

processAlbumInfo(artist, album, new_bit, new_kHz, albumLink) {
; return 0 - album was already in queue with better qual
; return 1 - album wasn't in queue so added
; return 2 - album was already in queue but had worse qual so this one was added
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

isAlbumLinkInList(albumLink) {
    loop MyListView.GetCount() {
        if (StrCompare(albumLink, MyListView.GetText(A_Index, 5)) == 0) {
            return A_Index
        }
    }
    return 0
}

isAlbumQueued(artist, album) {
    loop MyListView.GetCount() {
        if ((StrCompare(artist, MyListView.GetText(A_Index, 2)) == 0) && (StrCompare(album, MyListView.GetText(A_Index, 3)) == 0)) {
            return A_Index
        }
    }
    return 0
}

searchQobuzForAlbum(albumID) {
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

Request(url) {
    WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Option[6] := False ; No redirects
    WebRequest.Open("GET", url, false)
    WebRequest.Send()
    Return WebRequest
}

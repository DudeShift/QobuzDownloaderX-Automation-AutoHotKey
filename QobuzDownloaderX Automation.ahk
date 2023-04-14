#Requires AutoHotkey v2.0
SendMode("Input") ; Recommend for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)

global Queue := Array() ; Backend array to store Album IDs so user doesn't see them in the list view
MyGui := Gui()
MyGui.Title := "QobuzDownloaderX Automation"
MyGui.OnEvent("Close", GuiClose)

ButtonStartProcess := MyGui.Add("Button", "vButtonStart x+5 yp", "Start Download Queue of 0")
ButtonStartProcess.OnEvent("Click", StartProcess)
MyListView := MyGui.Add("ListView", "w600 h300 Grid Checked Sort vMyListView", ["", "Artist", "Album", "Link"])
MyListView.OnEvent("ItemCheck", EnableRemoveButton)
TextBox := MyGui.Add("Edit", "w200 vTextBox")
ButtonAddItem := MyGui.Add("Button", "x+5 yp w50 h20 Default", "Add")
ButtonAddItem.OnEvent("Click", AddItem)
ButtonRemoveItem := MyGui.Add("Button", "x+5 yp w50 h20", "Remove")
ButtonRemoveItem.OnEvent("Click", RemoveItem)
ButtonRemoveItem.Enabled := false

MyGui.Show()
return

;### GUI Handling ###
EnableRemoveButton(GuiCtrlObj, Item, Checked){
    ; Doesn't account for if a item is checked and the unchecked
    ; Would probably need a 2d array
    if (!ButtonRemoveItem.Enabled) {
        ButtonRemoveItem.Enabled := true
    }
    return
}

AddItem(*){
    ; Input could be a: Full Album Link, Link with Album ID at end, Artist Link. Thus named dataLink
    dataLink := TextBox.Text
    if (StrCompare(dataLink, "") == 0) {
        MsgBox("No Link Provided: Please eneter a link into the textbox")
    } else {
        parts := StrSplit(dataLink, "/")
        if ((StrCompare(parts[3], "www.qobuz.com") == 0) && (StrCompare(parts[5], "interpreter") == 0)) {
            artistAddAlbums(dataLink) ; Most likely a artist page link so treating it as such
        } else {
            albumID := parts[parts.Length] ; text with Album ID a end so treating it as such
            indexAlbumQueued := isAlbumQueued(albumID)
            if (indexAlbumQueued != 0) {
                MsgBox(MyListView.GetText(indexAlbumQueued, 3) . " by " . MyListView.GetText(indexAlbumQueued, 2) . " is already in queue"
                    . "`nLink Queued: " . MyListView.GetText(indexAlbumQueued, 4))
            } else {
                addAlbum(albumID)
            }
        }
    }
    Textbox.Value := "" ; Empty the textbox
    ButtonStartProcess.SetText := "Start Download Queue of " . Queue.Length
    MyListView.ModifyCol
    return
}

RemoveItem(*) {
    ; Loop through MyListView to find checked rows
    ; Setting max loops as safety feature
    RowNumber := 0
    Loop MyListView.GetCount() { 
        RowNumber := MyListView.GetNext(RowNumber, "Checked")
        if (RowNumber == 0) {
            ; No more checked rows
            break
        } else {
            ; Checked Row Found, remove from queue and list view
            Queue.RemoveAt(RowNumber)
            MyListView.Delete(RowNumber)
        }
    }
    ButtonStartProcess.SetText := "Start Download Queue of " . Queue.Length
    ButtonRemoveItem.Enabled := false
    return
}

StartProcess(*) {
    if (Queue.Length == 0) {
        MsgBox("Nothing in queue, add an album or artist")
    } else {
        CoordMode("Pixel", "Window")
	    SetTitleMatchMode(2)
	    WinActivate("QobuzDownloaderX", , "Automation")
	    WinWaitActive("QobuzDownloaderX", , Automation)
        Loop Queue.Length {
            playLinkID := "https://play.qobuz.com/album/" . Queue(A_Index)
            Click("500, 95")
		    Send("^a")
		    Send("{Backspace}")
            Send (playLinkID)
            Click("615, 95")
		    ToolTip("Don't move the mouse, Downloading " . A_Index . " of " . Queue.Length)
		    Sleep(100)
		    ColorCheck := 0
            Loop {
                ; Get the color at the specified window coordinate
                MouseGetPos(&xpos, &ypos)
                color := PixelGetColor(xpos, ypos, "RGB") ;V1toV2: Switched from BGR to RGB values
                ;PixelGetColor, color, 615, 95, RGB
                ; Check if the color has changed from 0070EF to 0086FF
                if (color = 0x0086FF) {
                    break
                }
                ColorCheck++
                if (ColorCheck >= 600) {
                    ColorCheck := 0
                    msgResult := MsgBox(CurItem " has been downloading over one minute. Do you want to continue?`n`nClick Yes to continue, or No to exit.", "", 4)
                    if (msgResult = "Yes")
                        continue
                    else
                         break
                }
                ; Sleep for a short interval before checking again
                Sleep(100)
            }
        }

        ToolTip()
        MyListView.Delete()
        totalQueue := Queue.Length
        Loop totalQueue{
            Queue.Pop()
        }
        ButtonStartProcess.SetText := "Start Download Queue of " . Queue.Length
        MsgBox("Finsihed Downloading Queue of " . totalQueue . "Albums")
    }
    return
}

GuiClose(*) {
    ExitApp()
}

;lastPart := parts[parts.Length]
;fullLink := "https://play.qobuz.com/album/" . lastPart
;linkExists := false

artistAddAlbums(artistLink) {
    ; Download Album HTML to temp file
    tempArtistFilePath := A_ScriptDir . "\tempArtist.html"
    Download(artistLink,tempArtistFilePath)
    
    ; Read the temporary HTML file and match Album IDs
	htmlSource := Fileread(tempArtistFilePath)
    RegExMatch(htmlSource, "i)(?<=<a href=`"/us-en/album/[^/]*/)[^`"]+(?=`")", &ArtistAlbumIDs)
    
    ; Clean up - Delete the temporary file
	FileDelete(tempArtistFilePath)
    
    ; Arrays for catching mulitple RegEx matchs and Album IDs already in Queue
    newAlbumIDs := Array()
    alreadyQueuedAlbumIDIndexes := Array()
    
    ; for each RegEx Match
    loop ArtistAlbumIDs.Count {
        CurrentID := ArtistAlbumIDs[A_Index]
        
        ; Check if the CurrentID is a mulitple RegEx match
        isNewAlbumID := isInArray(newAlbumIDs, CurrentID) 
        if (isNewAlbumID != 0) {
            break ; Already queued
        } else {
            ; Check if the CurrentID is already in Queue
            indexAlbumQueued := isAlbumQueued(CurrentID)
            if (indexAlbumQueued != 0) {
                alreadyQueuedAlbumIDIndexes.Push(indexAlbumQueued)
            } else {
                addAlbum(CurrentID)
            }
        }
    }
    ; If some albums were already in Queue, then message user which albums ingored
    if (alreadyQueuedAlbumIDIndexes.Length != 0) {
        queuedAlbumsMessage := "Already Queued Albums by " . MyListView.GetText(alreadyQueuedAlbumIDIndexes[1], 2) . " Ingored:`n"
        loop alreadyQueuedAlbumIDIndexes.Length {
            queuedAlbumsMessage .= "- " . MyListView.GetText(alreadyQueuedAlbumIDIndexes[A_Index], 3) . " | AlbumID: " . Queue.Get(A_Index) . "`n"
        }
        MsgBox (queuedAlbumsMessage)
    }
    return
}

addAlbum(albumID) {
    searchLink := "https://www.qobuz.com/us-en/search?q=" . albumID
    ; Gets the location header from the returned html when searching 302 redirect for full album link
    fullLink := "https://www.qobuz.com" . Request(searchLink).GetResponseHeader("location")
    ; Download Album HTML to temp file
    tempAlbumFilePath := A_ScriptDir . "\tempAlbum.html"
    Download(fullLink, tempAlbumFilePath)
    ; Read the temporary HTML file
	htmlSource := Fileread(tempAlbumFilePath)
    RegExMatch(htmlSource, "i)(?<=<p class=`"player__name`" data-name=`")(.*?)(?=`")", &albumName)
    RegExMatch(htmlSource, "i)(?<=<p class=`"player__artist`" data-artist=`")(.*?)(?=`")" , &artistName)
    rowIndex := MyListView.Add(,"", artistName[], albumName[], fullLink)
    Queue.InsertAt(rowIndex, albumID) ; Add to array
    ; Clean up - Delete the temporary file
	FileDelete(tempAlbumFilePath)
    return
}

isInArray(searchArray, data){
    loop searchArray.Length {
        if (data == searchArray.Get(A_Index)) {
            return A_Index
        }
    }
    return 0
}

isAlbumQueued(albumID) {
    loop Queue.Length {
        if (albumID == Queue.Get(A_Index)) {
            return A_Index
        }
    }
    return 0
}

Request(url) {
    WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Option[6] := False ; No redirects
    WebRequest.Open("GET", url, false)
    WebRequest.Send() 
    Return WebRequest
}


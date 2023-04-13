#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%

_Instructions = 
(
Instructions:
Start QobuzDownloaderX

To Add:
Paste + Press Enter into the text box any of the following formats:
1. https://www.qobuz.com/us-en/album/
2. https://play.qobuz.com/album/
3. Album ID on its own

To Remove from queue: 
Select a link / row and click "Remove"

To Auto-Add Albums:
Enter the artist page link to add all albums:
https://www.qobuz.com/us-en/interpreter/

Click "Start Download Queue" to start
DON'T move your mouse till complete
)
 
Gui Add, Button, vStartButton x+5 yp gStartProcess, Start Download Queue of 0
Gui Add, ListView, w300 h300 Grid -Hdr NoSortHdr -LV0x10 vMyListview, Item
Gui Add, Edit, w200 vMyEdit
Gui Add, Button, x+5 yp w50 h20 Default gAddItem, Add
Gui Add, Button, x+5 yp w50 h20 gRemoveItem, Remove
Gui Add, Button, x+5 yp w100 h20 gSearchArtist, Auto-Add Artist Albums
Gui Add, Text, x325 y30 w350 h250, %_Instructions%
Gui Show, , QobuzDownloaderX Automation Version 0.2
return

; Subroutine to add an item to the list
AddItem:
GuiControlGet, MyEdit, , MyEdit ; Get the current text in the edit control
if (MyEdit != "")
{
	parts := StrSplit(MyEdit, "/")
	if (parts[5] = "interpreter") && (parts[3] = "www.qobuz.com"){
		MsgBox, % "This is NOT an Album Link (its the Artist):`n" . MyEdit
		return
	}
    lastPart := parts[parts.Length()]
    fullLink := "https://play.qobuz.com/album/" . lastPart
	linkExists := false
	Loop, % LV_GetCount()
	{
		LV_GetText(CurItem, A_Index)
		if (CurItem = fullLink)
		{
			linkExists := true
			break
		}
	}
	if (!linkExists)
	{
	GuiControl, , MyEdit, ; Clear the edit control
	LV_Add(0, fullLink) ; Add the new item to the list
	GuiControl, Text, StartButton, % "Start Download Queue of " . LV_GetCount()
	}
	else
	{
		MsgBox, % "The link " . fullLink . "is already added to the queue"
	}
}
else
{
    MsgBox, Please enter a link into the textbox
}
return

; Subroutine to remove an item from the list
RemoveItem:
SelectedRowNumber := LV_GetNext(0, “Focused”) ; Get the selected row number
if SelectedRowNumber { ; Check if a row is selected
    LV_Delete(SelectedRowNumber) ; Remove the selected item from the list
	GuiControl, Text, StartButton, % "Start Download Queue of " . LV_GetCount()
}
else
{
	MsgBox, No link / row was selected to remove
}
return

; Subroutine for the “Search Artist” button
SearchArtist:
GuiControlGet, MyEdit, , MyEdit ; Get the current text in the edit control
if(MyEdit != ""){
	parts := StrSplit(MyEdit, "/")
	if (parts[5] = "interpreter") && (parts[3] = "www.qobuz.com"){

		ToolTip, Please wait...
		; Download HTML source code to a temporary file
		url := MyEdit ; Replace with the URL you want to scrape
		tempFilePath := A_ScriptDir . "\temp.html"
		URLDownloadToFile, %url%, %tempFilePath%

		; Read the temporary HTML file
		FileRead, htmlSource, %tempFilePath%

		; Extract hyperlinks with base url of "/us-en/album/"
		loop
		{
			RegExMatch(htmlSource, "i)<a href=""/(us-en/album[^""]+)", match)
			if (match = "")
				break
			htmlSource := StrReplace(htmlSource, match, "", 1)
			parts := StrSplit(match1, "/")
			lastPart := parts[parts.Length()]
			fullLink := "https://play.qobuz.com/album/" . lastPart
			linkExists := false
			Loop, % LV_GetCount()
			{
				LV_GetText(CurItem, A_Index)
				if (CurItem = fullLink)
				{
					linkExists := true
					break
				}
			}
			if (!linkExists)
			{
				LV_Add(0, fullLink) ; Add the new item to the list
				GuiControl, Text, StartButton, % "Start Download Queue of " . LV_GetCount()
			}
			else
			{
				MsgBox, % "The link " . fullLink . "is already added to the queue"
			}
		}
		; Clean up - Delete the temporary file
		FileDelete, %tempFilePath%
		GuiControl, , MyEdit, ; Clear the edit control
		ToolTip
	}
	else
	{
		MsgBox,16,, % "This is not an Artist Page Link:`n" . MyEdit
	}
}
else
{
	MsgBox, Please enter a link into the textbox
}
return

; Subroutine for the “Start” button
StartProcess:
if (LV_GetCount() = 0) {
	MsgBox, Nothing in queue, add some music!
}
else
{
	CoordMode, Pixel, Window
	SetTitleMatchMode 2
	WinActivate, QobuzDownloaderX,, Automation
	WinWaitActive, QobuzDownloaderX,, Automation
	Loop, % LV_GetCount()
	{
		LV_GetText(CurItem, A_Index)
		Click, 500, 95
		Send ^a
		Send {Backspace}
		Send, %CurItem%
		;Send, {Tab}
		;Send, {Enter}
		Click, 615, 95
		Tooltip, % "Don't move the mouse, Downloading " . A_Index . " of " . LV_GetCount()
		Sleep, 100
		ColorCheck := 0
		Loop
		{
			; Get the color at the specified window coordinate
			MouseGetPos, xpos, ypos 
			PixelGetColor, color, xpos, ypos, RGB
			;PixelGetColor, color, 615, 95, RGB
			; Check if the color has changed from 0070EF to 0086FF
			if (color = 0x0086FF)
			{
				break
			}
			ColorCheck++
			if (ColorCheck >= 600)
			{
				ColorCheck := 0
				Msgbox, 4,, %CurItem% has been downloading over one minute. Do you want to continue?`n`nClick Yes to continue, or No to exit.
				IfMsgBox Yes
					continue
				else
					break
			}
			; Sleep for a short interval before checking again
			Sleep, 100
		}
	}
	ToolTip
	GuiControl, -Redraw, MyListview  ; Turn off redrawing to avoid flickering
    LV_Delete()
    GuiControl, +Redraw, MyListview  ; Turn on redrawing
	GuiControl, Text, StartButton, % "Start Download Queue of " . LV_GetCount()
	MsgBox Finished Downloading Queue
}
return

; Event handler for the GUI close button
GuiClose:
ExitApp

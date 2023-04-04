GUIFunctions.AddTab("Chests")

Gui, ICScriptHub:Tab, Chests
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x15 y+15 w350, % "Note: Game needs to be open to load user data and read chests into lists."
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "Only open chests while game is closed. (Yes, this is a hassle.)"
Gui, ICScriptHub:Add, GroupBox, x15 y+15 w425 h150 vGroupBoxChestPurchase, Buy Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 hwndChestPurchaserChestPurchaseComboBoxID vChestPurchaserChestPurchaseComboBox gChestPurchaserChestPurchaseCB
Gui, ICScriptHub:Add, Picture, x+35 h18 w18 vButtonRefreshChestPurchaser, %g_ReloadButton%
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x30 y+15 w75 vChestPurchaserPurchaseCount, % "99"
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserBuyChests, Buy

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestPurchase
xyValY += 150
Gui, ICScriptHub:Add, GroupBox, x15 y%xyValY% w425 h150 vGroupBoxChestOpen, Open Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 hwndChestPurchaserChestOpenComboBoxID vChestPurchaserChestOpenComboBox gChestPurchaserChestOpenCB
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, y+15 w75 vChestPurchaserChestOpenCount, % "99"
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserOpenChests, Open

buyChestsFunc := Func("IC_ChestPurchaser_Component.BuyChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserBuyChests, % buyChestsFunc
openChestsFunc := Func("IC_ChestPurchaser_Component.OpenChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserOpenChests, % openChestsFunc
chestPurchaserReadChests := Func("IC_ChestPurchaser_Component.ReadChests")
GuiControl, ICScriptHub: +g, ButtonRefreshChestPurchaser, % chestPurchaserReadChests

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestOpen
xyValY +=150
Gui, ICScriptHub:Add, Text, x15 y%xyValY% w350 vChestPurchaserCurrentChestCount, % "---"

g_SF.Memory.InitializeChestsIndices()
IC_ChestPurchaser_Component.ReadChests()

ChestPurchaserChestPurchaseCB(controlID, mode, key)
{
;     test := value
;     IC_ChestPurchaser_Component.SearchList("ChestPurchaserChestPurchaseComboBox")
}

ControlGet, _List, List, , , ahk_id %ChestPurchaserChestOpenComboBoxID%
_List := "|" . StrReplace(_List, "`n" , "|")
OnMessage( 0x111, Func("WM_COMMAND").Bind(_List) )

WM_COMMAND(list, wp, lp) 
{
    global _List
    static CB_GETCOMBOBOXINFO := 0x0164
         , CB_SETMINVISIBLE   := 0x1701
         , CB_SHOWDROPDOWN    := 0x014F
         , WM_SETCURSOR       := 0x0020
         , EM_SETSEL          := 0x00B1
         , hEdit              := 0
         , CBN_EDITCHANGE     := 5
        
    if (wp >> 16 != CBN_EDITCHANGE)
        Return

    hCombo := lp
    if !hEdit {
        VarSetCapacity(COMBOBOXINFO, size := 40 + A_PtrSize*3)
        NumPut(size, COMBOBOXINFO)
        SendMessage, CB_GETCOMBOBOXINFO,, &COMBOBOXINFO,, ahk_id %hCombo%
        hEdit := NumGet(COMBOBOXINFO, 40 + A_PtrSize)
    }
    items := StrSplit(_List, "|")
    items.Delete(1) ; remove first entry (null)
    newComboList := ""

    
    GuiControlGet, text,, %hCombo%

    count := 0
    Loop, % items.Count()
    {
        
        if(InStr(items[A_Index], text, False))
        {
            newComboList .= "|" . items[A_Index]
            count++
        }
    }
    GuiControl,, %hCombo%, % newComboList = "" ? "|" : newComboList
    bool := !(newComboList = "" || StrLen(text) < 1)
    ;GuiControl, Text, %hEdit%, % text
    SendMessage, CB_SHOWDROPDOWN, bool,,, ahk_id %hCombo%
    SendMessage, CB_SETMINVISIBLE, count = 0 ? 1 : count > 10 ? 10 : count,,, ahk_id %hCombo%
    GuiControl, Text, %hEdit%, % text
    SendMessage, EM_SETSEL, -2, -1,, ahk_id %hEdit%
    SendMessage, WM_SETCURSOR,,,, ahk_id %hEdit%
}

; OnMessage(0x100, "WM_KEYDOWN")

; g_KeyDownControls := {}
; g_KeyDownControls["ChestPurchaserChestPurchaseComboBox"] := True
; g_KeyDownControls["ChestPurchaserChestOpenComboBox"] := True

; WM_KEYDOWN(wParam, lParam, msg, hwnd)  
; {
;     global g_KeyDownControls
;     if(!g_KeyDownControls[A_GuiControl])
;         return
;     ;0x0E = backspace
;     scDec := (lParam >> 16) & 0x1FF
;     ; alphanum - (2-11)
;         ; numbers = 2-11
;         ; letters = 16-25 + 30-38 + 44-50
;     ; bs = 14, del = 83
;     ; space = 57

;     isAlphaNumeric := (scDec >= 2 AND scDec <= 11) OR (scDec >= 16 AND scDec <= 25) OR (scDec >= 30 AND scDec <= 38) OR (scDec >= 44 AND scDec <= 50)
;     sc := Format("{:x}", scDec)
;     keyname := GetKeyName("sc" . sc)
;     guiControlVal := A_GuiControl
;     ToolTip % A_GuiControl "`n" GetKeyName("sc" . sc)
; }

ChestPurchaserChestOpenCB()
{
    ;IC_ChestPurchaser_Component.SearchList("ChestPurchaserChestOpenComboBox")
}
class IC_ChestPurchaser_Component
{
    SearchTerm := ""
    
    SearchList(chestComboBox)
    {
        global ChestPurchaserChestPurchaseComboBox
        global ChestPurchaserChestPurchaseComboBoxID
        global ChestPurchaserChestOpenComboBox
        global ChestPurchaserChestOpenComboBoxID
        
        if(chestComboBox == "ChestPurchaserChestPurchaseComboBox")
        {
            hwndVar := ChestPurchaserChestPurchaseComboBoxID
            itemsVar := ChestPurchaserChestPurchaseComboBox
        }
        else if (chestComboBox == "ChestPurchaserChestOpenComboBox")
        {
            hwndVar := ChestPurchaserChestOpenComboBoxID
            itemsVar := ChestPurchaserChestOpenComboBox
        }
        
    	ControlGetText, boxInput,, ahk_id %hwndVar%
    	ControlGet, items, List, , , ahk_id %hwndVar%
        itemsArray := StrSplit(items, "`n")
        firstWord := StrSplit(boxInput, " ")[1]
        if firstWord is integer
        {
            searchTerm := SubStr(boxInput, 1 + StrLen(firstWord)+StrLen(" "))
            hasMatch := RegExMatch(items, "`nOmi)^(.*\Q" . searchTerm . "\E).*$", Match)
        }
        else
        {
            hasMatch := RegExMatch(items, "`nOmi)^(.*\Q" . boxInput . "\E).*$", Match)
            searchTerm := boxInput
        }
        hasMatch := RegExMatch(Match[0], "i)" . searchTerm)
        foundValue := Match[0]
    	if ( !GetKeyState("Delete") && !GetKeyState("BackSpace") && hasMatch) 
        {
            ControlSetText, , %foundValue%, ahk_id %hwndVar%
            matchParts := StrSplit(foundValue, " ")
            
            ; ---- Selected text control -------
            idVal := StrSplit(foundValue, " ")[1]
            if firstWord is integer
            {
                if(StrLen(firstWord) == StrLen(matchParts[1])) ; test if number has changed
                    Selection := hasMatch+StrLen(searchTerm)-1 | 0xFFFF0000
                else
                    Selection := hasMatch+StrLen(searchTerm)-1 | 0xFFFF0000
            }
            else
            {
                Selection := hasMatch | 0xFFFF0000
            }
            SendMessage, CB_SETEDITSEL := 0x142, , Selection, , ahk_id %hwndVar%
            ; ---- --------------------- -------
    	} 
        else 
        {
            CheckDelKey = 0
            CheckBackspaceKey = 0
    	}
        return
    }

    ReadChests()
    {
        if(WinExist("ahk_exe " . g_userSettings[ "ExeName"])) ; only update when the game is open
            g_SF.Memory.OpenProcessReader()
        else
            return
        g_SF.ResetServerCall()
        size := g_SF.Memory.ReadChestDefinesSize()
        comboBoxOptions := "|"
        if(!size OR size > 3000 OR size < 0)
        {
            comboBoxOptions .= "-- Error Reading Chests --"
            GuiControl,ICScriptHub:, ChestPurchaserChestOpenComboBox, %comboBoxOptions%
            GuiControl,ICScriptHub:, ChestPurchaserChestPurchaseComboBox, %comboBoxOptions%
            return
        }
        loop, %size%
        {
            chestID := g_SF.Memory.GetChestIDBySlot(A_Index)
            chestName := g_SF.Memory.GetChestNameBySlot(A_Index)
            comboBoxOptions .= chestID . " " . chestName . "|"
            this.comboBoxOptions := comboBoxOptions.Clone()
        }
        GuiControl,ICScriptHub:, ChestPurchaserChestOpenComboBox, %comboBoxOptions%
        GuiControl,ICScriptHub:, ChestPurchaserChestPurchaseComboBox, %comboBoxOptions%
    }

    BuyChests()
    {
        global g_ServerCall
        global ChestPurchaserPurchaseCount
        global ChestPurchaserCurrentChestCount
        global ChestPurchaserChestPurchaseComboBox
        Gui,ICScriptHub:Submit, NoHide
        if(g_ServerCall == "")
        {
            MsgBox % "No user data available. Open the game and refresh chest list before continuing."
            return
        }
        splitArray := StrSplit(ChestPurchaserChestPurchaseComboBox, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Buying " . ChestPurchaserPurchaseCount . " of " . chestName . " (ID: " . chestID . ")"
        buyCount := ChestPurchaserPurchaseCount
        while(buyCount > 0)
        {
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Buying " buyCount " chests..."
            response := g_ServerCall.CallBuyChests( chestID, buyCount )
            if(!IsObject(response))
            {
                MsgBox % "Error purchasing chest or parsing response."
                return
            }
            if (!response.okay)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311 )
                buyCount -= 100
            else
                buyCount -= 1
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Done buying!"
        MsgBox % "Done"
    }

    OpenChests()
    {
        global g_ServerCall
        global ChestPurchaserChestOpenCount
        global ChestPurchaserCurrentChestCount
        global ChestPurchaserChestOpenComboBox
        Gui,ICScriptHub:Submit, NoHide
        if(g_ServerCall == "")
        {
            MsgBox % "No user data available. Open the game and refresh chest list before continuing."
            return
        }
        splitArray := StrSplit(ChestPurchaserChestOpenComboBox, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Opening " . ChestPurchaserChestOpenCount . " of " . chestName . " (ID: " . chestID . ") Make sure the game is closed before continuing."
        openCount := ChestPurchaserChestOpenCount
        shinyCount := 0
        while(openCount > 0)
        {
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Opening " openCount " chests..."
            response := g_ServerCall.CallOpenChests( chestID, openCount )
            if(!IsObject(response))
            {
                MsgBox % "Error opening chest(s) or parsing response."
                return
            }
            if (!response.success)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            shinyCount += g_SF.ParseChestResults(response)
            openCount -= 99
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Done opening!"
        shinyString := "No shiny gear found."
        if(shinyCount > 0)
        {
            shinyString := "Shinies found: " . shinyCount . "`n"
            shinyString .= IC_ChestPurchaser_Component.GetShinyCountString()
        }
        MsgBox % "Done`n" . shinyString
    }

    ; Returns a string listing shinies found by champion.
    GetShinyCountString()
    {
        shnieisByChampString := ""
        shiniesByChamp := g_SharedData.ShiniesByChamp
        for champID, slots in shiniesByChamp
        {
            champName := g_SF.Memory.ReadChampNameByID(champID)
            champName := champName ? champName : champID
            shnieisByChampString .= champName . ": Slots ["
            for k,v in slots
            {
                shnieisByChampString .= k . ","
            }
            if(slots != "")
            {
                shnieisByChampString := SubStr(shnieisByChampString,1,StrLen(shnieisByChampString)-1)
            }                
            shnieisByChampString .= "]`n"
        }
        shnieisByChampString := SubStr(shnieisByChampString, 1, StrLen(shnieisByChampString)-1)
        return shnieisByChampString
    }
}
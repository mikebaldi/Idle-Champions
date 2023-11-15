#include %A_LineFile%\..\json.ahk

class GUIFunctions
{
    isDarkMode := false
    CurrentTheme := ""
    FileOverride := ""

    ; Adds a tab to Script Hub's tab control
    AddTab(Tabname){
        addedTabs := Tabname . "|"
        GuiControl,ICScriptHub:,ModronTabControl, % addedTabs
        g_TabList .= addedTabs
        ; Increase UI width to accommodate new tab.
        StrReplace(g_TabList,"|",,tabCount)
        g_TabControlWidth := Min(Max(Max(g_TabControlWidth,475), tabCount * 75), 550)
        GuiControl, ICScriptHub:Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
        Gui, ICScriptHub:show, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
    }

    ; Updates the tab control's size based on global width/height settings
    RefreshTabControlSize()
    {
        GuiControl, ICScriptHub:Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
        Gui, ICScriptHub:show, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
    }

    ; Add a Button across the top of the GUI.
    AddButton(Picture,FunctionToCall,VariableName){
        global
        Gui, ICScriptHub:Tab
        Gui, ICScriptHub:Add, Picture, x%g_MenuBarXPos% y5 h25 w25 g%FunctionToCall% v%VariableName% +0x4000000, %Picture%
        g_MenuBarXPos+=30
    }
    
    ; Add a tooltip message to a control in a specific window.
    AddToolTip(controlVariableName, tipMessage)
    {
        global
        toolTipTarget := this.GetToolTipTarget(controlVariableName)
        g_MouseToolTips[toolTipTarget] := tipMessage
    }

    ; Finds a control ID based on its variable name.
    GetToolTipTarget(controlVariableName)
    {
        global
        WinGet ICScriptHub_ID, ID, A
        GuiControl ICScriptHub:Focus, %controlVariableName%
        ControlGetFocus toolTipTarget, ahk_id %ICScriptHub_ID%
        return ICScriptHub_ID . toolTipTarget
    }

     
    ; Filters a combo box's list based on what is in the edit box. _List must be an unaltered original combobox list.
    FilterList(controlID, _List)
    {
        global g_KeyInputTimer
        global g_KeyInputTimerDelay

        static CB_GETCOMBOBOXINFO := 0x0164
            , CB_SETMINVISIBLE   := 0x1701
            , CB_SHOWDROPDOWN    := 0x014F
            , WM_SETCURSOR       := 0x0020
            , EM_SETSEL          := 0x00B1
            , hEdit              := 0
            , CBN_EDITCHANGE     := 5
            , LastID             := 0
        timeSinceLast := A_TickCount - g_KeyInputTimer
        if (timeSinceLast < g_KeyInputTimerDelay)
            return
        g_KeyInputTimer := A_TickCount
        ; Location of edit box for this control
        if (!hEdit OR LastID != controlID)
        {
            VarSetCapacity(COMBOBOXINFO, size := 40 + A_PtrSize*3)
            NumPut(size, COMBOBOXINFO)
            SendMessage, CB_GETCOMBOBOXINFO,, &COMBOBOXINFO,, ahk_id %controlID%
            hEdit := NumGet(COMBOBOXINFO, 40 + A_PtrSize)
        }
        LastID := controlID

        ControlGet, currList, List, , , ahk_id %controlID%
        currListItems := StrSplit(currList, "`n")
        items := StrSplit(_List, "|")
        items.Delete(1) ; remove first entry (null after split)     
        GuiControlGet, inputText,, %controlID%

        newComboList := ""
        count := 0
        StartTime := A_TickCount
        Loop, % items.Count()
        {
            
            if(items[A_Index] != "" AND InStr(items[A_Index], inputText, False))
            {
                newComboList .= "|" . items[A_Index]
                count++
            }
        }
        if (count != 1)
        {
            GuiControl,, %controlID%, % newComboList = "" ? "|" : newComboList
            bool := !(newComboList = "" || StrLen(inputText) < 1)
            SendMessage, CB_SHOWDROPDOWN, bool,,, ahk_id %controlID%
            SendMessage, CB_SETMINVISIBLE, count = 0 ? 1 : count > 30 ? 30 : count,,, ahk_id %controlID%
            GuiControl, Text, %hEdit%, % inputText
            SendMessage, EM_SETSEL, -2, -1,, ahk_id %hEdit%
            SendMessage, WM_SETCURSOR,,,, ahk_id %hEdit%
        }
        else if (currListItems.Count() == items.Count())
        {
            singleItem := StrSplit(newComboList, "|")
            bool := singleItem[2] != inputText
            if(bool)
            {
                inputText := singleItem[2]
                GuiControl, Text, %hEdit%, % singleItem[2]
                Control, ChooseString, %inputText%,, ahk_id %controlID%
            }
        }
        else
        {
            GuiControl,, %controlID%, % _List
            singleItem := StrSplit(newComboList, "|")
            bool := singleItem[2] != inputText
            itemCount := items.Count()
            SendMessage, CB_SETMINVISIBLE, itemCount > 30 ? 30 : itemCount ,,, ahk_id %controlID%
            SendMessage, CB_SHOWDROPDOWN, False,,, ahk_id %controlID%
            Control, ChooseString, %inputText%,, ahk_id %controlID%
        }
        return
    }

    ; Returns true if string is alphanumeric (can include -) 
    TestInputForAlphaNumericDash(textValue)
    {
        match := RegExMatch(textValue, "i)[^a-z^0-9^\-]")
        return match == 0 ? True : False
    }

    ;=================================
    ; Script Theme Functions
    ;=================================

    ; Gets the current theme from a file and sets it for use when using other theme functions.
    LoadTheme(guiName := "ICScriptHub", fileOverride := "")
    {
        this.GUIName := guiName
        objData := ""
        if(this.CurrentTheme != "" AND fileOverride == "" AND this.FileOverride == "")
            return
        FileName := ""
        if (fileOverride != "")
        {
            FileName := fileOverride
            this.FileOverride := fileOverride
        }
        if (FileName == "" )
        {
            FileName := A_LineFile . "\..\..\Themes\CurrentTheme.json"
            this.FileOverride := ""
        }
        if(FileExist(FileName))
        {
            FileRead, objData, %FileName%
        }
        else
        {
            FileName := A_LineFile . "\..\..\Themes\DefaultTheme.json"
            FileRead, objData, %FileName%
        }
        
        this.CurrentTheme := JSON.parse( objData )
        this.isDarkMode := this.currentTheme["UseDarkThemeGraphics"]
    }

    ; Sets the color/weight for subsequent text based on the theme.
    UseThemeTextColor(textType := "default", weight := 400)
    {  
        guiName := this.GUIName
        if(textType == "default")
            textType := "DefaultTextColor"
        ; if number, convert to hex
        textColor := (this.CurrentTheme[textType] * 1 == "") ? this.CurrentTheme[textType] : Format("{:#x}", this.CurrentTheme[textType])
        Gui, %guiName%:Font, c%textColor% w%weight%
    }

    ; Sets the script GUI background color based on the theme.
    UseThemeBackgroundColor()
    {
        guiName := this.GUIName
        ; if number, convert to hex
        windowColor := (this.CurrentTheme[ "WindowColor" ] * 1 == "") ? this.CurrentTheme[ "WindowColor" ] : Format("{:#x}", this.CurrentTheme[ "WindowColor" ])
        Gui, %guiName%:Color, % windowColor
    }

    ; Sets a listview background color based on the theme.
    UseThemeListViewBackgroundColor(controlID := "")
    {
        guiName := this.GUIName
        ; if number, convert to hex
        bgColor := (this.CurrentTheme[ "TableBackgroundColor" ] * 1 == "") ? this.CurrentTheme[ "TableBackgroundColor" ] : Format("{:#x}", this.CurrentTheme[ "TableBackgroundColor" ])
        GuiControl, %guiName%: +Background%bgColor%, %controlID%
    }

    ; Sets the window title bar to dark if theme is a dark theme. GUI must be shown before calling.
    UseThemeTitleBar(guiName, refresh := true)
    {
        if(this.isDarkMode AND guiName != "")
        {
            if (A_OSVersion >= "10.0.17763" && SubStr(A_OSVersion, 1, 3) = "10.") 
            {
                attr := 19
                if (A_OSVersion >= "10.0.18985") {
                    attr := 20
                }
                Gui, %guiName%: +hwndGuiID
                DllCall("dwmapi\DwmSetWindowAttribute", "ptr", GuiID, "int", attr, "int*", true, "int", 4)
                ; refresh window
                if(refresh)
                {
                    Gui, %guiName%:Hide
                    Gui, %guiName%:Show
                }
            }
        }
    }

    ;------------------------------
    ;
    ; Function: LVM_CalculateSize
    ;
    ; Description:
    ;
    ;   Calculate the width and height required to display a given number of rows of
    ;   a ListView control.
    ;
    ; Parameters:
    ;
    ;   p_NumberOfRows - The number of rows to be displayed in the control.  Set to
    ;       -1 (the default) to use the current number of rows in the ListView
    ;       control.
    ;
    ;   r_Width, r_Height - [Output, Optional] The calculated width and height of
    ;       ListView control.
    ;
    ; Returns:
    ;
    ;   An integer that holds the calculated width (in the LOWORD) and height (in
    ;   the HIWORD) needed to display the rows, in pixels.
    ;
    ;   If the output variables are defined (r_Width and r_Height), the calculated
    ;   values are also returned in these variables.
    ;
    ; The AutoHotkey Method:
    ;
    ;   This function uses the LVM_APPROXIMATEVIEWRECT message to calculate the
    ;   approximate width and height required to display a given number of rows in a
    ;   ListView control.  The AutoHotkey method (extracted from the AutoHotkey
    ;   source) makes minor changes to the data that is passed to the message and to
    ;   the results that are returned from the message.
    ;
    ;   The AutoHotkey method is the following.
    ;
    ;   _Input_: The actual or requested number of row is used minus 1.  For
    ;   example, if 10 rows is requested, 9 is passed to the LVM_APPROXIMATEVIEWRECT
    ;   message instead.
    ;
    ;   _Output_: 4 is added to both the width and height return values.  For
    ;   example, if the message returned a size of 300x200, the size is adjusted to
    ;   304x204.
    ;
    ;   The final result (in most cases) is a ListView control that is the exact
    ;   size needed to show all of the specified rows and columns without showing
    ;   the horizontal or vertical scroll bars.  Exception: If the requested number
    ;   of rows is less than the actual number of rows, the horizontal and/or
    ;   vertical scroll bars may show as a result.
    ;
    ; Remarks:
    ;
    ;   This function should only be used on a ListView control in the Report view.
    ;
    ;-------------------------------------------------------------------------------
    LVM_CalculateSize(hLV,p_NumberOfRows:=-1,ByRef r_Width:="",ByRef r_Height:="")
    {
        Static Dummy67950827

            ;-- Messages
            ,LVM_GETITEMCOUNT       :=0x1004              ;-- LVM_FIRST + 4
            ,LVM_APPROXIMATEVIEWRECT:=0x1040              ;-- LVM_FIRST + 64

        ;-- Collect and/or adjust the number of rows
        if (p_NumberOfRows<0)
            {
            SendMessage LVM_GETITEMCOUNT,0,0,,ahk_id %hLV%
            p_NumberOfRows:=ErrorLevel
            }

        if p_NumberOfRows  ;-- Not zero
            p_NumberOfRows-=1

        ;-- Calculate size
        SendMessage LVM_APPROXIMATEVIEWRECT,p_NumberOfRows,-1,,ahk_id %hLV%

        ;-- Extract, adjust, and return values
        r_Width :=(ErrorLevel&0xFFFF)+4 ;-- LOWORD
        r_Height:=(ErrorLevel>>16)+4    ;-- HIWORD
        Return r_Height<<16|r_Width
    }
    
    ;=========================================
    ; from https://www.autohotkey.com/boards/viewtopic.php?f=6&t=4732
    ; CreateGUID()
    ; {
    ;     VarSetCapacity(pguid, 16, 0)
    ;     if !(DllCall("ole32.dll\CoCreateGuid", "ptr", &pguid)) {
    ;         size := VarSetCapacity(sguid, (38 << !!A_IsUnicode) + 1, 0)
    ;         if (DllCall("ole32.dll\StringFromGUID2", "ptr", &pguid, "ptr", &sguid, "int", size))
    ;             return StrGet(&sguid)
    ;     }
    ;     return ""
    ; }

    ; lexikos's fix for list views populating the wrong views.
    ; https://www.autohotkey.com/boards/viewtopic.php?t=20740
    LV_Scope(gui, lv) {
        return new ListviewScope(gui, lv)
    }
}

    
class ListviewScope {
    __New(gui, lv) {
        ; Save previous default GUI
        this.oldgui := A_DefaultGui
        ; Set new default GUI
        Gui % gui ":Default"
        this.gui := gui
        ; Save previous default LV of new default GUI
        this.lv := A_DefaultListView
        ; Set new default LV
        Gui ListView, % lv
    }
    __Delete() {
        ; Restore settings of our GUI
        Gui % this.gui ":Default"
        if this.lv
            Gui ListView, % this.lv
        ; Restore previous default GUI
        Gui % this.oldgui ":Default"
    }
}
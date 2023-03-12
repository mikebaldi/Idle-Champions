#include %A_LineFile%\..\json.ahk

class GUIFunctions
{
    isDarkMode := false
    CurrentTheme := ""

    AddTab(Tabname){
        addedTabs := Tabname . "|"
        GuiControl,ICScriptHub:,ModronTabControl, % addedTabs
        ; TODO: contain tablist
        g_TabList .= addedTabs
        ; Increase UI width to accommodate new tab.
        StrReplace(g_TabList,"|",,tabCount)
        g_TabControlWidth := Min(Max(Max(g_TabControlWidth,475), tabCount * 75), 550)
        GuiControl, ICScriptHub:Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
        Gui, ICScriptHub:show, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
    }

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

    GetToolTipTarget(controlVariableName)
    {
        global
        WinGet ICScriptHub_ID, ID, A
        GuiControl ICScriptHub:Focus, %controlVariableName%
        ControlGetFocus toolTipTarget, ahk_id %ICScriptHub_ID%
        return toolTipTarget
    }

    LoadTheme(guiName := "ICScriptHub")
    {
        this.GUIName := guiName
        FileName := A_LineFile . "\..\..\Themes\CurrentTheme.json"
        FileRead, objData, %FileName%
        this.CurrentTheme := JSON.parse( objData )
        this.isDarkMode := this.currentTheme["UseDarkThemeGraphics"]
    }

    UseThemeTextColor(textType := "default", weight := 400)
    {  
        guiName := this.GUIName
        if(textType == "default")
            textType := "DefaultTextColor"
        textColor := this.CurrentTheme[textType]
        Gui, %guiName%:Font, c%textColor% w%weight%
    }

    UseThemeBackgroundColor()
    {
        guiName := this.GUIName
        windowColor := this.CurrentTheme[ "WindowColor" ]
        Gui, %guiName%:Color, % windowColor
    }

    UseThemeListViewBackgroundColor(controlID := "")
    {
        guiName := this.GUIName
        bgColor := this.CurrentTheme[ "TableBackgroundColor" ]
        GuiControl, %guiName%: +Background%bgColor%, %controlID%
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
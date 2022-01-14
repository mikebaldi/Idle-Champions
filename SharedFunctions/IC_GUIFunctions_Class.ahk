class GUIFunctions
{
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
}
addedTabs := "Memory View|"
GuiControl,,ModronTabControl, % addedTabs
g_TabList .= addedTabs
StrReplace(g_TabList,"|",,tabCount)
g_TabControlWidth := Max(Max(g_TabControlWidth,450), tabCount * 75)

Gui, Tab, Memory View
Gui, ICScriptHub:Add, Button, x255 y68 w100 gCheck_Clicked, Force Memory Check

Check_Clicked()
{
    Critical, On
    g_SF.Memory.OpenProcessReader()
    if(IsFunc(Func("ReadMemoryFunctionsExtended.CheckReads")))
        ReadMemoryFunctionsExtended.CheckReads()
    else if (IsFunc(Func("ReadMemoryFunctions.CheckReads")))
        ReadMemoryFunctions.CheckReads()
    Critical, Off
    return
}

; Can combine up to 1 primary and up to 1 secondary 
; Primary contains ReadMemoryFunctions class. Secondary contains ReadMemoryFunctionsExtended class.

; Primary
#include *i %A_LineFile%\..\IC_MemoryFunctions_Component_Main.ahk
; Secondary
#include *i %A_LineFile%\..\IC_MemoryFunctions_Component_GameSettings.ahk

GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+35
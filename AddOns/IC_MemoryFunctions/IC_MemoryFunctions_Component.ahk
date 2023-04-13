GUIFunctions.AddTab("Memory View")

Gui, ICScriptHub:Tab, Memory View
Gui, ICScriptHub:Add, Button, x255 y68 w100 gCheck_Clicked, Force Memory Check

Check_Clicked()
{
    g_SF.Memory.OpenProcessReader()
    if(IsFunc(Func("ReadMemoryFunctionsExtended.CheckReads")))
        ReadMemoryFunctionsExtended.CheckReads()
    else if (IsFunc(Func("ReadMemoryFunctions.CheckReads")))
        ReadMemoryFunctions.CheckReads()
    return
}
GUIFunctions.UseThemeTextColor()

; Can combine up to 1 primary and up to 1 secondary 
; Primary contains ReadMemoryFunctions class. Secondary contains ReadMemoryFunctionsExtended class.

; Primary
#include *i %A_LineFile%\..\IC_MemoryFunctions_Component_Main.ahk
; Secondary
#include *i %A_LineFile%\..\IC_MemoryFunctions_Component_CommonlyErrored.ahk


Gui, ICScriptHub:Add, Text, vMemFuncHiddenEnd x+2 Hidden,
GuiControlGet, pos, ICScriptHub:Pos, MemFuncHiddenEnd
g_TabControlHeight := Max(g_TabControlHeight, posY + 30)
GuiControl, ICScriptHub:Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, ICScriptHub:show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight
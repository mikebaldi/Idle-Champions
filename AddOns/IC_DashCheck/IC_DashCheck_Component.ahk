; Add tab to the GUI
addedTabs := "Dash Check|"
GuiControl,,ModronTabControl, % addedTabs
g_TabList .= addedTabs
; Increase UI width to accommodate new tab.
StrReplace(g_TabList,"|",,tabCount)
g_TabControlWidth := Max(Max(g_TabControlWidth,475), tabCount * 75)
GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+40

global g_InventoryView := new IC_InventoryView_Component()

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Dash Check
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, Dash Check. This add on is a test/proof of concept and will only work on Steam.
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+10 w300 vDashCheckStatus, This Addon is not running.

Gui, ICScriptHub:Add, Button, x15 y+15 gDashCheck_Clicked, Check for Dash

DashCheck_Clicked()
{
    GuiControl, ICScriptHub:, DashCheckStatus, This Addon is currently running. Checks: 0
    counter := 0
    g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
    g_SF.Memory.OpenProcessReader()
    while (!g_SF.IsDashActive())
    {
        sleep, 250
        ++counter
        GuiControl, ICScriptHub:, DashCheckStatus, This Addon is currently running. Checks: %counter%
    }
    GuiControl, ICScriptHub:, DashCheckStatus, This Addon is not running. Previous run checks: %counter%
    msgbox, Dash is on.
}
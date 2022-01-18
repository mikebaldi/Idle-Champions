GUIFunctions.AddTab("Dash Check")

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Dash Check
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, This add on is a test/proof of concept and will only work on Steam.
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+10 w300 vDashCheckStatus, This Addon is not running.

;Gui, ICScriptHub:Add, Button, x15 y+15 gDashCheck_Clicked, Check for Dash

Gui, ICScriptHub:Add, Button, x15 y+15 gDashHandler_Clicked, Run Dash Handler Test Script

Gui, ICScriptHub:Add, Button, x15 y+15 gHasteHandler_Clicked, Run Haste Handler Test Script

Gui, ICScriptHub:Add, Button, x15 y+15 gCOHandler_Clicked, Run Contractual Obligations Handler Test Script

DashCheck_Clicked()
{
    g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
    g_SF.Memory.OpenProcessReader()
    GuiControl, ICScriptHub:, DashCheckStatus, This Addon is currently running. Checks: 0
    counter := 0
    
    while (!g_SF.IsDashActive())
    {
        sleep, 250
        ++counter
        GuiControl, ICScriptHub:, DashCheckStatus, This Addon is currently running. Checks: %counter%
    }
    GuiControl, ICScriptHub:, DashCheckStatus, This Addon is not running. Previous run checks: %counter%
    msgbox, Dash is on.
}

DashHandler_Clicked()
{
    scriptLocation := A_LineFile . "\..\IC_DashHandlerTest_Run.ahk"
    Run, %A_AhkPath% "%scriptLocation%"
}

HasteHandler_Clicked()
{
    scriptLocation := A_LineFile . "\..\IC_HasteHandlerTest_Run.ahk"
    Run, %A_AhkPath% "%scriptLocation%"
}

COHandler_Clicked()
{
    scriptLocation := A_LineFile . "\..\IC_COHandlerTest_Run.ahk"
    Run, %A_AhkPath% "%scriptLocation%"
}
addedTabs := "Briv Gem Farm|"
g_TabList := addedTabs . g_TabList
;Removed because GemFarmUnified.ahk has a hack in place to make it unneccessary.
    ;g_TabList .= addedTabs
    ;GuiControl,,ModronTabControl, % addedTabs
StrReplace(g_TabList,"|",,tabCount)
g_TabControlWidth := Max(g_TabControlWidth, tabCount * 75)
GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+40
g_DownAlign := g_DownAlign - 17 ; The line above changes the Y origin by 40. Ajust for it.
;Load user settings
global g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
global g_BrivFarm := new IC_BrivGemFarm_Class

;check if first run
If !IsObject( g_BrivUserSettings )
{
    g_BrivUserSettings := {}
    g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
}

Gui, ICScriptHub:Tab, Briv Gem Farm
Gui, ICScriptHub:Add, Text, x15 y68 w120, User Settings:

if ( g_BrivUserSettings[ "Fkeys" ] == "" )
    g_BrivUserSettings[ "Fkeys" ] := 1
Fkeys := g_BrivUserSettings[ "Fkeys" ]
if ( g_BrivUserSettings[ "AvoidBosses" ] == "" )
    g_BrivUserSettings[ "AvoidBosses" ] := 0
AvoidBosses := g_BrivUserSettings[ "AvoidBosses" ]
if ( g_BrivUserSettings[ "StackFailRecovery" ] == "" )
    g_BrivUserSettings[ "StackFailRecovery" ] := 1
StackFailRecovery := g_BrivUserSettings[ "StackFailRecovery" ]
if ( g_BrivUserSettings[ "StackZone" ] == "" )
    g_BrivUserSettings[ "StackZone" ] := 2000
if ( g_BrivUserSettings[ "RestartStackTime" ] == "" )
    g_BrivUserSettings[ "RestartStackTime" ] := 12000
if ( g_BrivUserSettings[ "DashSleepTime" ] == "" )
    g_BrivUserSettings[ "DashSleepTime" ] := 60000
if ( g_BrivUserSettings[ "SwapSleep" ] == "" )
    g_BrivUserSettings[ "SwapSleep" ] := 2500
if ( g_BrivUserSettings[ "DoChests" ] == "" )
    g_BrivUserSettings[ "DoChests" ] := 1
DoChests := g_BrivUserSettings[ "DoChests" ]
if ( g_BrivUserSettings[ "BuySilvers" ] == "" )
    g_BrivUserSettings[ "BuySilvers" ] := 1
BuySilvers := g_BrivUserSettings[ "BuySilvers" ]
if ( g_BrivUserSettings[ "BuyGolds" ] == "" )
    g_BrivUserSettings[ "BuyGolds" ] := 0
BuyGolds := g_BrivUserSettings[ "BuyGolds" ]
if ( g_BrivUserSettings[ "OpenSilvers" ] == "" )
    g_BrivUserSettings[ "OpenSilvers" ] := 1
OpenSilvers := g_BrivUserSettings[ "OpenSilvers" ]
if ( g_BrivUserSettings[ "OpenGolds" ] == "" )
    g_BrivUserSettings[ "OpenGolds" ] := 1
OpenGolds := g_BrivUserSettings[ "OpenGolds" ]
if ( g_BrivUserSettings[ "MinGemCount" ] == "" )
    g_BrivUserSettings[ "MinGemCount" ] := 0

Gui, ICScriptHub:Add, Checkbox, vFkeysCheck Checked%Fkeys% x15 y+5, Level Champions with Fkeys?
Gui, ICScriptHub:Add, Checkbox, vAvoidBossesCheck Checked%AvoidBosses% x15 y+5, Swap to 'e' formation when `on boss zones?
Gui, ICScriptHub:Add, Checkbox, vStackFailRecoveryCheck Checked%StackFailRecovery% x15 y+5, Enable manual resets to recover from failed Briv stacking?
if(g_isDarkMode)
    Gui, Font, g_CustomColor
Gui, ICScriptHub:Add, Edit, vNewStackZone x15 y+5 w50, % g_BrivUserSettings[ "StackZone" ]
Gui, ICScriptHub:Add, Edit, vNewMinStackZone x15 y+10 w50, % g_BrivUserSettings[ "MinStackZone" ]
Gui, ICScriptHub:Add, Edit, vNewTargetStacks x15 y+10 w50, % g_BrivUserSettings[ "TargetStacks" ]
Gui, ICScriptHub:Add, Edit, vNewRestartStackTime x15 y+10 w50, % g_BrivUserSettings[ "RestartStackTime" ]
Gui, ICScriptHub:Add, Edit, vNewDashSleepTime x15 y+10 w50, % g_BrivUserSettings[ "DashSleepTime" ]
Gui, ICScriptHub:Add, Edit, vNewSwapSleep x15 y+10 w50, % g_BrivUserSettings[ "SwapSleep" ]
if(g_isDarkMode)
    Gui, Font, cSilver
Gui, ICScriptHub:Add, Checkbox, vDoChestsCheck Checked%DoChests% x15 y+20, Enable server calls to buy and open chests during stack restart?
Gui, ICScriptHub:Add, Checkbox, vBuySilversCheck Checked%BuySilvers% x15 y+5, Buy silver chests?
Gui, ICScriptHub:Add, Checkbox, vBuyGoldsCheck Checked%BuyGolds% x15 y+5, Buy gold chests? Will not work if 'Buy Silver Chests?' is checked.
Gui, ICScriptHub:Add, Checkbox, vOpenSilversCheck Checked%OpenSilvers% x15 y+5, Open silver chests?
Gui, ICScriptHub:Add, Checkbox, vOpenGoldsCheck Checked%OpenGolds% x15 y+5, Open gold chests?
if(g_isDarkMode)
    Gui, Font, g_CustomColor
Gui, ICScriptHub:Add, Edit, vNewMinGemCount x15 y+15 w100, % g_BrivUserSettings[ "MinGemCount" ]
if(g_isDarkMode)
    Gui, Font, cSilver

Gui, ICScriptHub:Add, Picture, x15 y+15 h50 w50 gBriv_Run_Clicked vBrivGemFarmPlayButton, %g_PlayButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Run_Stop_Clicked, %g_StopButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Connect_Clicked, %g_ConnectButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Save_Clicked, %g_SaveButton%

; Gui, ICScriptHub:Add, Button, x15 y+15 gBriv_Save_Clicked, Save Settings
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Run_Clicked, `Run
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Connect_Clicked, Connect
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Run_Stop_Clicked, Stop

GuiControlGet, xyVal, Pos, NewStackZone
xyValX += 55
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%+10, Farm SB stacks AFTER this zone
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Minimum zone Briv can farm SB stacks on
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Target Haste stacks for next run
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, `Time (ms) client remains closed to trigger Restart Stacking (0 disables)
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Maximum time (ms) script will wait for Dash (0 disables)
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Briv Jump Timer (ms)
GuiControlGet, xyVal, Pos, NewMinGemCount
xyValX += 105
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%, Maintain this many gems when buying chests.

Gui, Tab, Stats
Gui, ICScriptHub:Font, w700
Gui Add, GroupBox, x6 y%g_DownAlign% w450 h80 vBrivGemFarmStatsID, BrivGemFarm Stats:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, Formation Swaps Made `This `Run:
Gui, ICScriptHub:Add, Text, vSwapsMadeThisRunID x+2 w200, 
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Boss Levels Hit `This `Run:
Gui, ICScriptHub:Add, Text, vBossesHitThisRunID x+2 w200, 
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Boss Levels Hit Since Start:
Gui, ICScriptHub:Add, Text, vTotalBossesHitID x+2 w200, 
GuiControlGet, pos, Pos, BrivGemFarmStatsID
g_DownAlign := g_DownAlign + posH -5

GuiControl, Choose, ModronTabControl, BrivGemFarm

Briv_Run_Clicked()
{
    ;g_BrivGemFarm.GemFarm()
    g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
    g_SF.Memory.OpenProcessReader()
    scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_Run.ahk"
    GuiControl, Choose, ModronTabControl, Stats
    g_BrivFarm.StartTimedFunctions()
    Run, %scriptLocation%
}

Briv_Run_Stop_Clicked()
{
    g_BrivFarm.StopTimedFunctions()
    try
    {
        SharedRunData := ComObjActive("{416ABC15-9EFC-400C-8123-D7D8778A2103}")
        SharedRunData.Close()
    }
}

Briv_Connect_Clicked()
{    
    g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
    g_SF.Memory.OpenProcessReader()
    g_BrivFarm.StartTimedFunctions()
    GuiControl, Choose, ModronTabControl, Stats
}

;Saves Settings associated with BrivGemFarm
Briv_Save_Clicked()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    g_BrivUserSettings[ "Fkeys" ] := FkeysCheck
    g_BrivUserSettings[ "AvoidBosses" ] := AvoidBossesCheck
    g_BrivUserSettings[ "StackFailRecovery" ] := StackFailRecoveryCheck
    g_BrivUserSettings[ "StackZone" ] := NewStackZone
    g_BrivUserSettings[ "MinStackZone" ] := NewMinStackZone
    g_BrivUserSettings[ "TargetStacks" ] := NewTargetStacks
    g_BrivUserSettings[ "RestartStackTime" ] := NewRestartStackTime
    g_BrivUserSettings[ "DashSleepTime" ] := NewDashSleepTime
    g_BrivUserSettings[ "SwapSleep" ] := NewSwapSleep
    g_BrivUserSettings[ "DoChests" ] := DoChestsCheck
    g_BrivUserSettings[ "BuySilvers" ] := BuySilversCheck
    g_BrivUserSettings[ "BuyGolds" ] := BuyGoldsCheck
    g_BrivUserSettings[ "OpenSilvers" ] := OpenSilversCheck
    g_BrivUserSettings[ "OpenGolds" ] := OpenGoldsCheck
    g_BrivUserSettings[ "MinGemCount" ] := NewMinGemCount
    g_BrivUserSettings[ "ExeName"] := g_BrivUserSettings[ "ExeName"] . ""
    g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
    try ; avoid thrown errors when comobject is not available.
    {
        local SharedRunData := ComObjActive("{416ABC15-9EFC-400C-8123-D7D8778A2103}")
        SharedRunData.ReloadSettings("LoadBrivGemFarmSettings")
    }
    return
}

#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
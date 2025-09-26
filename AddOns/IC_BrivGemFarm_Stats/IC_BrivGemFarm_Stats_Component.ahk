#include %A_LineFile%\..\IC_BrivGemFarm_Stats_Functions.ahk

g_TabControlHeight := Max(g_TabControlHeight, 650)
g_TabControlWidth := Max(g_TabControlWidth, 485)

global g_LeftAlign
global g_DownAlign
global g_BrivGemFarmStats := new IC_BrivGemFarm_Stats_Component

GUIFunctions.AddTab("Stats")
Gui, ICScriptHub:Tab, Stats
Gui, ICSCriptHub:Add, Button, x+5 gReset_Briv_Farm_Stats vReset_Briv_Farm_Stats_Button, Reset Stats
if(IsObject(IC_BrivGemFarm_Component))
{
    Gui, ICScriptHub:Add, Picture, x+10 h20 w20 gBriv_Run_Clicked vBrivGemFarmStatsPlayButton, %g_PlayButton%
    Gui, ICScriptHub:Add, Picture, x+5 h20 w20 gBriv_Run_Stop_Clicked vBrivGemFarmStatsStopButton, %g_StopButton%
}
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vWarning_Imports_Bad x+7 y+-17 w500, 
Gui, ICScriptHub:Font, w400

g_BrivGemFarmStats.AddStatsTabMod("AddCurrentRunGroup", "g_BrivGemFarmStats")
g_BrivGemFarmStats.AddStatsTabMod("AddOncePerRunGroup", "g_BrivGemFarmStats")
g_BrivGemFarmStats.AddStatsTabMod("AddBrivGemFarmStatsGroup", "g_BrivGemFarmStats")

g_BrivGemFarmStats.UpdateStatsTabWithMods()
g_BrivGemFarmStats.BuildToolTips()

Reset_Briv_Farm_Stats()
{
    g_BrivGemFarmStats.ResetBrivFarmStats()
}

g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_BrivGemFarmStats, "CreateTimedFunctions"))
g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_BrivGemFarmStats, "StartTimedFunctions"))
g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(g_BrivGemFarmStats, "StopTimedFunctions"))
; Update Com Object and restart it.
; SH_UpdateClass.AddClassFunctions(IC_BrivGemFarm_Coms, IC_BrivGemFarm_Coms_Added)
; g_BrivGemFarmComsObj := new IC_BrivGemFarm_Coms
ObjRegisterActive(g_BrivFarmComsObj, "")
try
{
    ObjRegisterActive(g_BrivFarmComsObj, g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarmComponent.json"))
}

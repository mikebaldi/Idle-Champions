global g_LeftAlign
global g_DownAlign

GUIFunctions.AddTab("Stats")
Gui, ICScriptHub:Tab, Stats
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, x+0 y+15 w450 h130 vCurrentRunGroupID, Current `Run:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vLoopAlignID xp+15 yp+25 , `Loop:
GuiControlGet, pos, ICScriptHub:Pos, LoopAlignID
g_LeftAlign := posX
Gui, ICScriptHub:Add, Text, vLoopID x+2 w400, Not Started
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current Area Time (s):
Gui, ICScriptHub:Add, Text, vdtCurrentLevelTimeID x+2 w200, % dtCurrentLevelTime
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current `Run Time (min):
Gui, ICScriptHub:Add, Text, vdtCurrentRunTimeID x+2 w50, % dtCurrentRunTime

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, SB Stack `Count:
Gui, ICScriptHub:Add, Text, vg_StackCountSBID x+2 w100, % g_StackCountSB
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Haste Stack `Count:
Gui, ICScriptHub:Add, Text, vg_StackCountHID x+2 w100, % g_StackCountH

; Gui, ICScriptHub:Add, Text, x15 y+10, Inputs Sent:
; Gui, ICScriptHub:Add, Text, vg_InputsSentID x+2 w50, % g_InputsSent
GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
g_DownAlign := posY + posH -5
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, x6 y%g_DownAlign% w450 h350 vOnceRunGroupID, Updated Once Per Full Run:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, Previous Run Time (min):
Gui, ICScriptHub:Add, Text, vPrevRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Fastest Run Time (min):
Gui, ICScriptHub:Add, Text, vFastRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Slowest Run Time (min):
Gui, ICScriptHub:Add, Text, vSlowRunTimeID x+2 w50,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Run `Count:
Gui, ICScriptHub:Add, Text, vTotalRunCountID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Total Run Time (hr):
Gui, ICScriptHub:Add, Text, vdtTotalTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Avg. Run Time (min):
Gui, ICScriptHub:Add, Text, vAvgRunTimeID x+2 w50,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Fail Run Time (min):
Gui, ICScriptHub:Add, Text, vFailRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Fail Run Time Total (min):
Gui, ICScriptHub:Add, Text, vTotalFailRunTimeID x+2 w50,
; Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stack Conversion:
; Gui, ICScriptHub:Add, Text, vFailedStackConvID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stacking Tally by Type:
Gui, ICScriptHub:Add, Text, vFailedStackingID x+2 w120,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Silvers Gained:
Gui, ICScriptHub:Add, Text, vSilversPurchasedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Silvers Opened:
Gui, ICScriptHub:Add, Text, vSilversOpenedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Gained:
Gui, ICScriptHub:Add, Text, vGoldsPurchasedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Opened:
Gui, ICScriptHub:Add, Text, vGoldsOpenedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Shinies Found:
Gui, ICScriptHub:Add, Text, vShiniesID x+2 w200, 0

Gui, ICScriptHub:Font, cBlue w700
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Bosses per hour:
Gui, ICScriptHub:Add, Text, vbossesPhrID x+2 w50, % bossesPhr

Gui, ICScriptHub:Font, cGreen
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Gems:
Gui, ICScriptHub:Add, Text, vGemsTotalID x+2 w50, % GemsTotal
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Gems per hour:
Gui, ICScriptHub:Add, Text, vGemsPhrID x+2 w200, % GemsPhr
if(g_isDarkMode)
    Gui, ICScriptHub:Font, cSilver w400
else
    Gui, ICScriptHub:Font, cDefault w400
; Gui, ICScriptHub:Font, w700
; Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+7 vButtonResetStats, Reset
; buttonFunc := ObjBindMethod(IC_BrivGemFarm_Stats_Component, "ResetStats")
; GuiControl,ICScriptHub: +g, ButtonResetStats, % buttonFunc
; Gui, ICScriptHub:Font, w400
GuiControlGet, pos, ICScriptHub:Pos, OnceRunGroupID
g_DownAlign := g_DownAlign + posH -5
IC_BrivGemFarm_Stats_Component.isLoaded := true
class IC_BrivGemFarm_Stats_Component
{
    doesExist := true
    StatsTabFunctions := {}
    isLoaded := false

    BuildToolTips()
    {
        StackFailToolTip := "
        (
            StackFail Types:
            1.  Ran out of stacks when ( > min stack zone AND < target stack zone). only reported when fail recovery is on
                Will stack farm - only a warning. Configuration likely incorrect
            2.  Failed stack conversion (Haste <= 50, SB > target stacks). Forced Reset
            3.  Game was stuck (checkifstuck), forced reset
            4.  Ran out of haste and steelbones > target, forced reset
            5.  Failed stack conversion, all stacks lost.
            6.  Modron not resetting, forced reset
        )"
        GUIFunctions.AddToolTip("FailedStackingID", StackFailToolTip)
    }

    AddStatsTabMod(FunctionName, Object := "")
    {
        if(Object != "")
        {
            functionToPush := ObjBindMethod(%Object%, FunctionName)
        }
        else
        {
            functionToPush := Func(FunctionName)
        }
        this.StatsTabFunctions.Push(functionToPush)
    }

    UpdateStatsTabWithMods()
    {
        for k,v in this.StatsTabFunctions
        {
            v.Call()
        }
        this.StatsTabFunctions := {}
    }
}
IC_BrivGemFarm_Stats_Component.UpdateStatsTabWithMods()
IC_BrivGemFarm_Stats_Component.BuildToolTips()


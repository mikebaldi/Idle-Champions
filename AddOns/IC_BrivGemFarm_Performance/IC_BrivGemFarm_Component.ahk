;Load user settings
global g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
global g_BrivFarm := new IC_BrivGemFarm_Class
g_BrivFarm.GemFarmGUID := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
global g_BrivFarmModLoc := A_LineFile . "\..\IC_BrivGemFarm_Mods.ahk"
global g_BrivFarmAddonStartFunctions := {}
global g_BrivFarmAddonStopFunctions := {}
global g_BrivFarmLastRunMiniscripts := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_Miniscripts.json")

GUIFunctions.AddTab("Briv Gem Farm")
Gui, ICScriptHub:Tab, Briv Gem Farm
Gui, ICScriptHub:Add, Text, x15 y68 w120, User Settings:

#include %A_LineFile%\..\IC_BrivGemFarm_Settings.ahk
ReloadBrivGemFarmSettings()
Gui, ICScriptHub:Add, Checkbox, vFkeysCheck Checked%Fkeys% x15 y+5, Level Champions with Fkeys?
Gui, ICScriptHub:Add, Checkbox, vStackFailRecoveryCheck Checked%StackFailRecovery% x15 y+5, Enable manual resets to recover from failed Briv stacking?
Gui, ICScriptHub:Add, Checkbox, vDisableDashWaitCheck Checked%DisableDashWait% x15 y+5, Disable Dash Wait?
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewStackZone x15 y+5 w50, % g_BrivUserSettings[ "StackZone" ]
Gui, ICScriptHub:Add, Edit, vNewMinStackZone x15 y+10 w50, % g_BrivUserSettings[ "MinStackZone" ]
Gui, ICScriptHub:Add, Edit, vNewTargetStacks x15 y+10 w50, % g_BrivUserSettings[ "TargetStacks" ]
Gui, ICScriptHub:Add, Edit, vNewRestartStackTime x15 y+10 w50, % g_BrivUserSettings[ "RestartStackTime" ]
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Checkbox, vDoChestsCheck Checked%DoChests% x15 y+20, Enable server calls to buy and open chests during stack restart?
Gui, ICScriptHub:Add, Checkbox, vBuySilversCheck Checked%BuySilvers% x15 y+5, Buy silver chests?
Gui, ICScriptHub:Add, Checkbox, vBuyGoldsCheck Checked%BuyGolds% x15 y+5, Buy gold chests? Will not work if 'Buy Silver Chests?' is checked.
Gui, ICScriptHub:Add, Checkbox, vOpenSilversCheck Checked%OpenSilvers% x15 y+5, Open silver chests?
Gui, ICScriptHub:Add, Checkbox, vOpenGoldsCheck Checked%OpenGolds% x15 y+5, Open gold chests?
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewMinGemCount x15 y+15 w100, % g_BrivUserSettings[ "MinGemCount" ]
GUIFunctions.UseThemeTextColor("DefaultTextColor")

Gui, ICScriptHub:Add, Picture, x15 y+15 h50 w50 gBriv_Run_Clicked vBrivGemFarmPlayButton, %g_PlayButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Run_Stop_Clicked vBrivGemFarmStopButton, %g_StopButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Connect_Clicked vBrivGemFarmConnectButton, %g_ConnectButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Save_Clicked vBrivGemFarmSaveButton, %g_SaveButton%
Gui, ICScriptHub:Add, Text, x+15 y+-30 w240 vgBriv_Button_Status,

; Gui, ICScriptHub:Add, Button, x15 y+15 gBriv_Save_Clicked, Save Settings
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Run_Clicked, `Run
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Connect_Clicked, Connect
; Gui, ICScriptHub:Add, Button, x+25 w50 gBriv_Run_Stop_Clicked, Stop

GuiControlGet, xyVal, ICScriptHub:Pos, NewStackZone
xyValX += 55
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%+10, Farm SB stacks AFTER this zone
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Minimum zone Briv can farm SB stacks on
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Target Haste stacks for next run
Gui, ICScriptHub:Add, Checkbox, vBrivAutoCalcStatsCheck Checked%BrivAutoCalcStats% x+10 gBrivAutoDetectStacks_Click, Auto Detect
Gui, ICScriptHub:Add, Checkbox, vBrivAutoCalcStatsWorstCaseCheck Hidden Checked%BrivAutoCalcStats% x+10, Worst Case
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, `Time (ms) client remains closed to trigger Restart Stacking (0 disables)
GuiControlGet, xyVal, ICScriptHub:Pos, NewMinGemCount
xyValX += 105
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%, Maintain this many gems when buying chests.

IC_BrivGemFarm_Component.UpdateGUICheckBoxes()
IC_BrivGemFarm_Component.BuildToolTips()
IC_BrivGemFarm_Component.ResetModFile()
Briv_Run_Clicked() {
    IC_BrivGemFarm_Component.Briv_Run_Clicked()
}
Briv_Run_Stop_Clicked() {
    IC_BrivGemFarm_Component.Briv_Run_Stop_Clicked()
}
Briv_Connect_Clicked() {
    IC_BrivGemFarm_Component.Briv_Connect_Clicked()
}
Briv_Save_Clicked() {
    IC_BrivGemFarm_Component.Briv_Save_Clicked()
}
DisableBrivTargetStacksBox(g_BrivUserSettings[ "AutoCalculateBrivStacks" ])

BrivAutoDetectStacks_Click()
{
    Gui, ICScriptHub:Submit, NoHide
    isChecked := %A_GuiControl%
    DisableBrivTargetStacksBox(isChecked)
}

DisableBrivTargetStacksBox(doDisable)
{
    if(doDisable)
        GuiControl,ICScriptHub:Disable, NewTargetStacks
    else
        GuiControl,ICScriptHub:Enable, NewTargetStacks
}

GuiControl, Choose, ICScriptHub:ModronTabControl, BrivGemFarm

ClearBrivGemFarmStatusMessage()
{
    IC_BrivGemFarm_Component.UpdateStatus("")
}

class IC_BrivGemFarm_Component
{
    BuildTooltips()
    {
        GUIFunctions.AddToolTip("BrivGemFarmPlayButton", "Start Gem Farm")
        GUIFunctions.AddToolTip("BrivGemFarmStopButton", "Stop Gem Farm")
        GUIFunctions.AddToolTip("BrivGemFarmConnectButton", "Reconnect to Gem Farm Script. [If the stats have stopped updating, click this to start updating them again]")
        GUIFunctions.AddToolTip("BrivGemFarmSaveButton", "Save Gem Farm Settings")
    }

    UpdateGUICheckBoxes()
    {
        GuiControl,ICScriptHub:, FkeysCheck, % g_BrivUserSettings[ "Fkeys" ]
        GuiControl,ICScriptHub:, StackFailRecoveryCheck, % g_BrivUserSettings[ "StackFailRecovery" ]
        GuiControl,ICScriptHub:, DoChestsCheck, % g_BrivUserSettings[ "DoChests" ]
        GuiControl,ICScriptHub:, BuySilversCheck, % g_BrivUserSettings[ "BuySilvers" ]
        GuiControl,ICScriptHub:, BuyGoldsCheck, % g_BrivUserSettings[ "BuyGolds" ] 
        GuiControl,ICScriptHub:, OpenSilversCheck, % g_BrivUserSettings[ "OpenSilvers" ] 
        GuiControl,ICScriptHub:, OpenGoldsCheck, % g_BrivUserSettings[ "OpenGolds" ] 
        GuiControl,ICScriptHub:, DisableDashWaitCheck, % g_BrivUserSettings[ "DisableDashWait" ]
        GuiControl,ICScriptHub:, BrivAutoCalcStatsCheck, % g_BrivUserSettings[ "AutoCalculateBrivStacks" ]
        GuiControl,ICScriptHub:, BrivAutoCalcStatsWorstCaseCheck, % g_BrivUserSettings[ "AutoCalculateWorstCase" ]
    }
    
    Briv_Run_Clicked()
    {
        g_SF.WriteObjectToJSON(A_LineFile . "\..\LastGUID_Miniscripts.json", g_Miniscripts)
        for k,v in g_Miniscripts
        {
            try
            {
                this.UpdateStatus("Starting Miniscript: " . v)
                Run, %A_AhkPath% "%v%" "%k%"
            }
        }
        try
        {
            Briv_Connect_Clicked()
            SharedData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedData.ShowGui()
        }
        catch
        {
            ;g_BrivGemFarm.GemFarm()
            g_SF.Hwnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
            g_SF.Memory.OpenProcessReader()
            scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_Run.ahk"
            GuiControl, ICScriptHub:Choose, ModronTabControl, Stats
            for k,v in g_BrivFarmAddonStartFunctions
            {
                v.Call()
            }
            GuidCreate := ComObjCreate("Scriptlet.TypeLib")
            g_BrivFarm.GemFarmGUID := guid := GuidCreate.Guid
            Run, %A_AhkPath% "%scriptLocation%" "%guid%"
        }
        this.TestGameVersion()
    }

    UpdateGUIDFromLast()
    {
        g_BrivFarm.GemFarmGUID := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
    }

    TestGameVersion()
    {
        gameVersion := g_SF.Memory.ReadGameVersion()
        importsVersion := _MemoryManager.is64bit ? g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64 : g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32
        GuiControl, ICScriptHub: +cF18500, Warning_Imports_Bad, 
        if (gameVersion == "")
            GuiControl, ICScriptHub:, Warning_Imports_Bad, % "⚠ Warning: Memory Read Failure. Check for updated Imports."
        else if( gameVersion > 100 AND gameVersion <= 999 AND gameVersion != importsVersion )
            GuiControl, ICScriptHub:, Warning_Imports_Bad, % "⚠ Warning: Game version (" . gameVersion . ") does not match Imports version (" . importsVersion . ")."
        else
            GuiControl, ICScriptHub:, Warning_Imports_Bad, % ""
    }

    Briv_Run_Stop_Clicked()
    {
        for k,v in g_BrivFarmAddonStopFunctions
        {
            this.UpdateStatus("Stopping Addon Function: " . v)
            v.Call()
        }
        for k,v in g_Miniscripts
        {
            this.UpdateStatus("Stopping Miniscript: " . v)
            try
            {
                SharedRunData := ComObjActive(k)
                SharedRunData.Close()
            }
        }
        for k,v in g_BrivFarmLastRunMiniscripts
        {
            try
            {
                SharedRunData := ComObjActive(k)
                SharedRunData.Close()
            }
        }
        this.UpdateStatus("Closing Gem Farm")
        try
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.Close()
        }
        catch, err
        {
            ; When the Close() function is called "0x800706BE - The remote procedure call failed." is thrown even though the function successfully executes.
            if(err.Message != "0x800706BE - The remote procedure call failed.")
                this.UpdateStatus("Gem Farm not running")
            else
                this.UpdateStatus("Gem Farm Stopped")
        }
    }

    Briv_Connect_Clicked()
    {   
        this.UpdateStatus("Connecting to Gem Farm...") 
        this.UpdateGUIDFromLast()
        Try 
        {
            ComObjActive(g_BrivFarm.GemFarmGUID)
        }
        Catch
        {
            this.UpdateStatus("Gem Farm not running.") 
            return
        }
        g_SF.Hwnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
        g_SF.Memory.OpenProcessReader()
        for k,v in g_BrivFarmAddonStartFunctions
        {
            v.Call()
        }
        GuiControl, ICScriptHub:Choose, ModronTabControl, Stats
    }

    ;Saves Settings associated with BrivGemFarm
    Briv_Save_Clicked()
    {
        global
        this.UpdateStatus("Saving Settings...")
        Gui, ICScriptHub:Submit, NoHide
        g_BrivUserSettings[ "Fkeys" ] := FkeysCheck
        g_BrivUserSettings[ "StackFailRecovery" ] := StackFailRecoveryCheck
        g_BrivUserSettings[ "StackZone" ] := StrReplace(NewStackZone, ",")
        g_BrivUserSettings[ "MinStackZone" ] := StrReplace(NewMinStackZone, ",")
        g_BrivUserSettings[ "TargetStacks" ] := StrReplace(NewTargetStacks, ",")
        g_BrivUserSettings[ "RestartStackTime" ] := StrReplace(NewRestartStackTime, ",")
        g_BrivUserSettings[ "DisableDashWait" ] := DisableDashWaitCheck
        g_BrivUserSettings[ "DoChests" ] := DoChestsCheck
        g_BrivUserSettings[ "BuySilvers" ] := BuySilversCheck
        g_BrivUserSettings[ "BuyGolds" ] := BuyGoldsCheck
        g_BrivUserSettings[ "OpenSilvers" ] := OpenSilversCheck
        g_BrivUserSettings[ "OpenGolds" ] := OpenGoldsCheck
        g_BrivUserSettings[ "MinGemCount" ] := StrReplace(NewMinGemCount, ",")
        g_BrivUserSettings[ "AutoCalculateBrivStacks" ] := BrivAutoCalcStatsCheck
        g_BrivUserSettings[ "AutoCalculateWorstCase" ] := BrivAutoCalcStatsWorstCaseCheck
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        this.UpdateStatus("Save complete.")
        return
    }

    ResetModFile()
    {
        IfExist, %g_BrivFarmModLoc%
            FileDelete, %g_BrivFarmModLoc%
        FileAppend, `;THIS FILE IS AUTOMATICALLY GENERATED BY BRIV GEM FARM PERFORMANCE ADDON`n, %g_BrivFarmModLoc%
    }

    UpdateStatus(msg)
    {
        GuiControl, ICScriptHub:, gBriv_Button_Status, % msg
        SetTimer, ClearBrivGemFarmStatusMessage,-3000
    }
}

#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
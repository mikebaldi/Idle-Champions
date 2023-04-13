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

Gui, ICScriptHub:Add, Text, x15 y+15, Profile: 
Gui, ICScriptHub:Add, DDL, gBriv_Load_Profile_Clicked x+6 hwndBrivDropDownSettingsHWND vBrivDropDownSettings,
Gui, ICScriptHub:Add, Button, x+10 gBriv_Save_Profile_Clicked, Save Profile
Gui, ICScriptHub:Add, Button, x+10 gBriv_Delete_Profile_Clicked, Delete Profile

Gui, ICScriptHub:Add, Text, x15 y+10 w120, User Settings:
#include %A_LineFile%\..\IC_BrivGemFarm_Settings.ahk
FileCreateDir, % A_LineFile . "\..\Profiles"
ReloadBrivGemFarmSettings(True)
Gui, ICScriptHub:Add, Checkbox, vFkeysCheck x15 y+5, Level Champions with Fkeys?
Gui, ICScriptHub:Add, Checkbox, vStackFailRecoveryCheck x15 y+5, Enable manual resets to recover from failed Briv stacking?
Gui, ICScriptHub:Add, Checkbox, vDisableDashWaitCheck x15 y+5, Disable Dash Wait?
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewStackZone x15 y+5 w50, % g_BrivUserSettings[ "StackZone" ]
Gui, ICScriptHub:Add, Edit, vNewMinStackZone x15 y+10 w50, % g_BrivUserSettings[ "MinStackZone" ]
Gui, ICScriptHub:Add, Edit, vNewTargetStacks x15 y+10 w50, % g_BrivUserSettings[ "TargetStacks" ]
Gui, ICScriptHub:Add, Edit, vNewRestartStackTime x15 y+10 w50, % g_BrivUserSettings[ "RestartStackTime" ]
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Text, x15 y+20, Chest options during a game restart for stacking.
Gui, ICScriptHub:Add, Text, x15 y+5, NOTE: Buy Silver enabled may leave too few gems or too little time to also Buy Gold.
Gui, ICScriptHub:Add, Checkbox, vBuySilversCheck x15 y+5, Buy silver chests?
Gui, ICScriptHub:Add, Checkbox, vBuyGoldsCheck x15 y+5, Buy gold chests? 
Gui, ICScriptHub:Add, Checkbox, vOpenSilversCheck x15 y+5, Open silver chests?
Gui, ICScriptHub:Add, Checkbox, vOpenGoldsCheck x15 y+5, Open gold chests?
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewMinGemCount x15 y+15 w100, % g_BrivUserSettings[ "MinGemCount" ]
GUIFunctions.UseThemeTextColor("DefaultTextColor")

Gui, ICScriptHub:Add, Picture, x15 y+15 h50 w50 gBriv_Run_Clicked vBrivGemFarmPlayButton, %g_PlayButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Run_Stop_Clicked vBrivGemFarmStopButton, %g_StopButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Connect_Clicked vBrivGemFarmConnectButton, %g_ConnectButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Save_Clicked vBrivGemFarmSaveButton, %g_SaveButton%
Gui, ICScriptHub:Add, Text, x+15 y+-30 w240 h30 vgBriv_Button_Status,

GuiControlGet, xyVal, ICScriptHub:Pos, NewStackZone
xyValX += 55
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%+10, Farm SB stacks AFTER this zone
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Minimum zone Briv can farm SB stacks on
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Target Haste stacks for next run
Gui, ICScriptHub:Add, Checkbox, vBrivAutoCalcStatsCheck x+10 gBrivAutoDetectStacks_Click, Auto Detect
Gui, ICScriptHub:Add, Checkbox, vBrivAutoCalcStatsWorstCaseCheck Hidden x+10, Worst Case
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, `Time (ms) client remains closed to trigger Restart Stacking (0 disables)
GuiControlGet, xyVal, ICScriptHub:Pos, NewMinGemCount
xyValX += 105
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%, Maintain this many gems when buying chests.

IC_BrivGemFarm_Component.ProfilesList := {}
IC_BrivGemFarm_Component.ProfileLastSelected := "Default"
IC_BrivGemFarm_Component.Briv_Load_Profiles_List()
IC_BrivGemFarm_Component.Briv_Load_Profile_Clicked(g_BrivUserSettings["LastSettingsUsed"], fullLoad := false)
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

Briv_Load_Profile_Clicked(controlID)
{
    Gui, Submit, NoHide
    global BrivDropDownSettings
    IC_BrivGemFarm_Component.Briv_Load_Profile_Clicked(BrivDropDownSettings)
}

Briv_Save_Profile_Clicked()
{
    Gui, Submit, NoHide
    global BrivDropDownSettings
    InputBox, profileName, Choose a profile name, Profile Name:,, Width := 375, Height := 129, X := 0, Y := 0,,, %BrivDropDownSettings%
    isCanceled := ErrorLevel
    while ((!GUIFunctions.TestInputForAlphaNumericDash(profileName) AND !isCanceled) OR profileName == "Default")
    {
        if(profileName == "Default")
            errMsg := "Can not use ""Default"" as a profile name."
        else
            errMsg := "Can only contain letters, numbers, and -."
        InputBox, profileName, Choose a profile name, %errMsg%`nProfile Name:,, Width := 375, Height := 144, X := 0, Y := 0,
        isCanceled := ErrorLevel
    }
    if(!isCanceled)
    {
        IC_BrivGemFarm_Component.Briv_Save_Clicked(profileName)
        IC_BrivGemFarm_Component.BrivUserSettingsProfile := g_BrivUserSettings.Clone()
        IC_BrivGemFarm_Component.Briv_Load_Profiles_List()
    }
}

Briv_Delete_Profile_Clicked()
{
    Gui, Submit, NoHide
    global BrivDropDownSettings
    if(BrivDropDownSettings == "Default")
    {
        MsgBox,, Error, Cannot delete Default settings
        return
    }
    FileName := A_LineFile . "..\..\Profiles\" . BrivDropDownSettings . "_Settings.json"
    MsgBox 4,, Are you sure you want to delete the profile '%BrivDropDownSettings%'
    IfMsgBox Yes
    {
        FileDelete, %FileName%
        IC_BrivGemFarm_Component.Briv_Load_Profiles_List()
        IC_BrivGemFarm_Component.Briv_Load_Profile_Clicked("Default")
    }
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
    ProfilesList := {}
    ProfileLastSelected := "Default"

    BuildTooltips()
    {
        GUIFunctions.AddToolTip("BrivGemFarmPlayButton", "Start Gem Farm")
        GUIFunctions.AddToolTip("BrivGemFarmStopButton", "Stop Gem Farm")
        GUIFunctions.AddToolTip("BrivGemFarmConnectButton", "Reconnect to Gem Farm Script. [If the stats have stopped updating, click this to start updating them again]")
        GUIFunctions.AddToolTip("BrivGemFarmSaveButton", "Save settings for this session.")
    }

    UpdateGUICheckBoxes()
    {
        GuiControl,ICScriptHub:, FkeysCheck, % g_BrivUserSettings[ "Fkeys" ]
        GuiControl,ICScriptHub:, StackFailRecoveryCheck, % g_BrivUserSettings[ "StackFailRecovery" ]
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
    Briv_Save_Clicked(profile := "")
    {
        global
        local k
        local v
        local k1
        local v1
        this.UpdateStatus("Saving Settings...")
        Gui, ICScriptHub:Submit, NoHide
        if(OptionSettingCheck_DoChestsContinuous != "")
            IC_BrivGemFarm_AdvancedSettings_Component.SaveAdvancedSettings()
        g_BrivUserSettings[ "Fkeys" ] := FkeysCheck
        g_BrivUserSettings[ "StackFailRecovery" ] := StackFailRecoveryCheck
        g_BrivUserSettings[ "StackZone" ] := StrReplace(NewStackZone, ",")
        g_BrivUserSettings[ "MinStackZone" ] := StrReplace(NewMinStackZone, ",")
        g_BrivUserSettings[ "TargetStacks" ] := StrReplace(NewTargetStacks, ",")
        g_BrivUserSettings[ "RestartStackTime" ] := StrReplace(NewRestartStackTime, ",")
        g_BrivUserSettings[ "DisableDashWait" ] := DisableDashWaitCheck
        g_BrivUserSettings[ "BuySilvers" ] := BuySilversCheck
        g_BrivUserSettings[ "BuyGolds" ] := BuyGoldsCheck
        g_BrivUserSettings[ "OpenSilvers" ] := OpenSilversCheck
        g_BrivUserSettings[ "OpenGolds" ] := OpenGoldsCheck
        g_BrivUserSettings[ "MinGemCount" ] := StrReplace(NewMinGemCount, ",")
        g_BrivUserSettings[ "AutoCalculateBrivStacks" ] := BrivAutoCalcStatsCheck
        g_BrivUserSettings[ "AutoCalculateWorstCase" ] := BrivAutoCalcStatsWorstCaseCheck
        g_BrivUserSettings[ "LastSettingsUsed" ] := profile? profile : BrivDropDownSettings
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
        shouldIgnoreTimer := False
        updateStatusMsg := "Save Complete."
        if(profile != "" AND profile != "Default")
        {
            this.ProfileLastSelected := profile
            updateStatusMsg := "Profile Save Complete."
            g_SF.WriteObjectToJSON( A_LineFile . "\..\Profiles\" . profile . "_Settings.json" , g_BrivUserSettings )
        }
        else if (profile == "")
        {
            for k,v in this.BrivUserSettingsProfile
            {
                if(!IsObject(v) AND this.BrivUserSettingsProfile[k] != g_BrivUserSettings[k])
                {
                    updateStatusMsg := "Session contains changes not yet saved to profile."
                    break
                }
                else if (IsObject(v))
                {
                    for k1, v1 in v
                    {
                        local v2 := g_BrivUserSettings[k][k1]
                        if(v[k1] != g_BrivUserSettings[k][k1])
                        {
                            updateStatusMsg := "Session contains changes not yet saved to profile."
                            break
                        }
                    }
                }
            }
        }
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        this.UpdateStatus(updateStatusMsg)
        return
    }

    ;Saves Settings associated with BrivGemFarm
    Briv_Load_Profile_Clicked(settings := "Default", fullLoad := True)
    {
        global
        ; GuiControl, ICScriptHub:ChooseString, BrivDropDownSettings, %settings%
        Controlget, Row, FindString, %settings%, , ahk_id %BrivDropDownSettingsHWND% ; Docs: Sets OutputVar to the entry number of a ListBox or ComboBox that is an exact match for String.
        GuiControl, ICScriptHub:Choose, BrivDropDownSettings, %Row%
        if (!fullLoad)
            return
        this.UpdateStatus("Loading Settings...")
        g_BrivUserSettings = {}
        if(settings == "")
            return
        if(settings == "Default")
            ReloadBrivGemFarmSettings(False)
        else
            g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Profiles\" . settings . "_Settings.json" )
        this.LastSelected := settings
        GuiControl, ICScriptHub:, FkeysCheck, % g_BrivUserSettings[ "Fkeys" ]
        GuiControl, ICScriptHub:, StackFailRecoveryCheck, % g_BrivUserSettings[ "StackFailRecovery" ]
        GuiControl, ICScriptHub:, NewStackZone, % g_BrivUserSettings[ "StackZone" ]
        GuiControl, ICScriptHub:, NewMinStackZone, % g_BrivUserSettings[ "MinStackZone" ]
        GuiControl, ICScriptHub:, NewTargetStacks, % g_BrivUserSettings[ "TargetStacks" ]
        GuiControl, ICScriptHub:, NewRestartStackTime, % g_BrivUserSettings[ "RestartStackTime" ]
        GuiControl, ICScriptHub:, DisableDashWaitCheck, % g_BrivUserSettings[ "DisableDashWait" ]
        GuiControl, ICScriptHub:, BuySilversCheck, % g_BrivUserSettings[ "BuySilvers" ]
        GuiControl, ICScriptHub:, BuyGoldsCheck, % g_BrivUserSettings[ "BuyGolds" ]
        GuiControl, ICScriptHub:, OpenSilversCheck, % g_BrivUserSettings[ "OpenSilvers" ]
        GuiControl, ICScriptHub:, OpenGoldsCheck, % g_BrivUserSettings[ "OpenGolds" ]
        GuiControl, ICScriptHub:, NewMinGemCount, % g_BrivUserSettings[ "MinGemCount" ]
        GuiControl, ICScriptHub:, BrivAutoCalcStatsCheck, % g_BrivUserSettings[ "AutoCalculateBrivStacks" ]
        GuiControl, ICScriptHub:, BrivAutoCalcStatsWorstCaseCheck, % g_BrivUserSettings[ "AutoCalculateWorstCase" ]  
        DisableBrivTargetStacksBox(g_BrivUserSettings[ "AutoCalculateBrivStacks" ])
        ; Load advanced settings.
        if(OptionSettingCheck_DoChestsContinuous != "")
            IC_BrivGemFarm_AdvancedSettings_Component.LoadAdvancedSettings()
        g_BrivUserSettings[ "LastSettingsUsed" ] := settings
        this.BrivUserSettingsProfile := g_BrivUserSettings.Clone()
        this.Briv_Save_Clicked(settings)
        this.UpdateStatus("Load complete.")
        return
    }

    Briv_Load_Profiles_List()
    {
        this.ProfilesList := {}
        profileDDLString := "|Default|"
        this.ProfilesList["Default"] := A_LineFile . "..\BrivGemFarmSettings.json"
        Loop, Files, % A_LineFile . "\..\Profiles\*_Settings.json"
        {
            profileName := StrSplit(A_LoopFileName, "_")[1]
            this.ProfilesList[profileName]:= A_LoopFileName
            if(profileName != "")
                profileDDLString .= profileName . "|"
                
        }
        GuiControl, ICScriptHub:, BrivDropDownSettings, %profileDDLString%
        lastSelected := this.ProfileLastSelected
        GuiControl, ICScriptHub:ChooseString, BrivDropDownSettings, %lastSelected%
        Gui, Submit, NoHide
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
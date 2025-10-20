﻿#include %A_LineFile%\..\IC_BrivGemFarm_Addon.ahk
;Load user settings
global g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
global g_BrivFarm := new IC_BrivGemFarm_Class
g_BrivFarm.GemFarmGUID := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
global g_BrivFarmModLoc := A_LineFile . "\..\IC_BrivGemFarm_Mods.ahk"
global g_BrivFarmServerCallModLoc := A_LineFile . "\..\IC_BrivGemFarm_Extra_ServerCall_Mods.ahk"
global g_BrivFarmAddonStartFunctions := {}
global g_BrivFarmAddonStopFunctions := {}
global g_BrivFarmComsObj := new IC_BrivGemFarm_Coms
g_BrivFarmComsObj.Init()
g_globalTempSettingsFiles.Push(A_LineFile . "\..\LastGUID_BrivGemFarmComponent.json")
g_globalTempSettingsFiles.Push(A_LineFile . "\..\ServerCallLocationOverride_Settings.json") ; may break a server call on exit before normal function
g_globalTempSettingsFiles.Push(A_LineFile . "\..\ServerCall_Settings.json")


global g_BrivFarmLastRunMiniscripts := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_Miniscripts.json")
GUIFunctions.AddTab("Briv Gem Farm")
Gui, ICScriptHub:Tab, Briv Gem Farm

Gui, ICScriptHub:Add, Text, x15 y+15, Profile: 
Gui, ICScriptHub:Add, DDL, gBriv_Load_Profile_Clicked x+6 hwndBrivDropDownSettingsHWND vBrivDropDownSettings, ||
Gui, ICScriptHub:Add, Button, x+10 gBriv_Save_Profile_Clicked, Save Profile
Gui, ICScriptHub:Add, Button, x+10 gBriv_Delete_Profile_Clicked, Delete Profile

Gui, ICScriptHub:Add, Text, x15 y+10 w120, User Settings:
FileCreateDir, % A_LineFile . "\..\Profiles"
ReloadBrivGemFarmSettings(True)
Gui, ICScriptHub:Add, Checkbox, vFkeysCheck x15 y+5, Level Champions with Fkeys?
Gui, ICScriptHub:Add, Checkbox, vStackFailRecoveryCheck x15 y+5, Enable manual resets to recover from failed Briv stacking?
Gui, ICScriptHub:Add, Checkbox, vDisableDashWaitCheck x15 y+5, Disable Dash Wait?
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewMinStackZone x15 y+5 w50, % g_BrivUserSettings[ "MinStackZone" ]
Gui, ICScriptHub:Add, Edit, vNewStackZone x15 y+10 w50, % g_BrivUserSettings[ "StackZone" ]
Gui, ICScriptHub:Add, Edit, vNewRestartStackTime x15 y+10 w50, % g_BrivUserSettings[ "RestartStackTime" ]
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, GroupBox, Section w400 h50 vBrivGemFarmTargetHasteGroupBox, Target haste stacks for next run

; ------- Haste Stacks Group --------------
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewTargetStacks xs+10 ys+20 w50, % g_BrivUserSettings[ "TargetStacks" ]
;GUIFunctions.UseThemeTextColor("DefaultTextColor")
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Button, x+5 gBriv_Visit_Byteglow_Speed_Avg_Stacks, % "Detect Average"
Gui, ICScriptHub:Add, Button, x+3 gBriv_Visit_Byteglow_Speed_Max_Stacks, % "Detect Max"
Gui, ICScriptHub:Add, Text, x+5 yp+2, % "(Provided by "
GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
Gui, ICScriptHub:Font, underline 
Gui, ICScriptHub:Add, Text, x+2 gBriv_Visit_Byteglow_Speed_Link, % "byteglow"
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Font, norm
Gui, ICScriptHub:Add, Text, x+1 gBriv_Visit_Byteglow_Speed_Link, % ")"
; ------- ------------------- --------------
GuiControlGet, xyVal, ICScriptHub:Pos, BrivGemFarmTargetHasteGroupBox
xyValX += 0
xyValY += 55

GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, GroupBox, Section w400 h205 x%xyValX% y%xyValY% vBrivGemFarmChestBuyGroupBox, Options for buying and opening chests during offline stacking.

; ------- Bottom Button Bar  -----------------
Gui, ICScriptHub:Add, Picture, x15 y+15 h50 w50 gBriv_Run_Clicked vBrivGemFarmPlayButton, %g_PlayButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Run_Stop_Clicked vBrivGemFarmStopButton, %g_StopButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Connect_Clicked vBrivGemFarmConnectButton, %g_ConnectButton%
Gui, ICScriptHub:Add, Picture, x+15 h50 w50 gBriv_Save_Clicked vBrivGemFarmSaveButton, %g_SaveButton%
Gui, ICScriptHub:Add, Text, x+15 y+-30 w240 h30 vgBriv_Button_Status,
xyValX := 26

; ------- Buy/Open Chests Group --------------
Gui, ICScriptHub:Add, Checkbox, vBrivGemFarmBuyChestsCheck x26 ys+22, Buy chests?
Gui, ICScriptHub:Add, Slider, vBuyGoldChestRatioSlider Range0-100 h20 x20 y+8 gBriv_Update_Chest_Ratio_Slider AltSubmit, 100
GuiControlGet, xyVal, ICScriptHub:Pos, BuyGoldChestRatioSlider
xyValY += 4
Gui, ICScriptHub:Add, Text, x+5 y%xyValY% w150 vBuyGoldChestRatioSliderText, % "Gold Chest Ratio: " Round(g_BrivUserSettings[ "BuyGoldChestRatio" ], 2)
Gui, ICScriptHub:Add, Slider, vBuySilverChestRatioSlider Range0-100 h20 x20 y+1 gBriv_Update_Chest_Ratio_Slider AltSubmit, 0
GuiControlGet, xyVal, ICScriptHub:Pos, BuySilverChestRatioSlider
xyValY += 4
Gui, ICScriptHub:Add, Text, x+5 y%xyValY% w150 vBuySilverChestRatioSliderText, % "Silver Chest Ratio: " Round(g_BrivUserSettings[ "BuySilverChestRatio" ], 2)

Gui,  ICScriptHub:Add, Text, x26 y+10 w370 h1 0x10 
; ------- Open Chests Group --------------
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Checkbox, vBrivGemFarmOpenChestsCheck x26 y+10, Open chests?
Gui, ICScriptHub:Add, Text, x26 yp+18, % "Reserve Chests --   Gold:"
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x+5 yp-5 w50 vMinimumGoldChestCount, % g_BrivUserSettings[ "MinGoldChestCount" ]

GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Text, x+10 yp+5, % "Silver:"
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x+5 yp-5 w50 vMinimumSilverChestCount, % g_BrivUserSettings[ "MinSilverChestCount" ]

Gui,  ICScriptHub:Add, Text, x26 y+5 w370 h1 0x10 
GUIFunctions.UseThemeTextColor("DefaultTextColor")
Gui, ICScriptHub:Add, Checkbox, vBuyAllChestsCheck gBriv_MaxChests_Check_Clicked x26 y+10, Only buy/open max chests (250 buy/1000 open)
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNewMinGemCount x25 y+10 w100, % g_BrivUserSettings[ "MinGemCount" ]
; ------- ------------------- --------------


GUIFunctions.UseThemeTextColor("DefaultTextColor")
GuiControlGet, xyVal, ICScriptHub:Pos, NewMinStackZone
xyValX += 55
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%+10, Minimum stack zone (the first area Briv (W) cannot kill.)
Gui, ICScriptHub:Add, Text, x%xyValX% y+18, Farm Steelbones stacks AFTER this zone (typically 2 jumps before modron reset)
GuiControlGet, xyVal, ICScriptHub:Pos, NewRestartStackTime
xyValX += 55
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%, `Time (ms) client remains closed to trigger Restart Stacking (0 disables)

GuiControlGet, xyVal, ICScriptHub:Pos, NewMinGemCount
xyValX += 105
xyValY += 5
Gui, ICScriptHub:Add, Text, x%xyValX% y%xyValY%, Reserve this many gems when buying chests.

IC_BrivGemFarm_Component.ProfilesList := {}
IC_BrivGemFarm_Component.ProfileLastSelected := "Default"
IC_BrivGemFarm_Component.Briv_Load_Profiles_List()
IC_BrivGemFarm_Component.Briv_Load_Profile_Clicked(g_BrivUserSettings["LastSettingsUsed"], fullLoad := false)
IC_BrivGemFarm_Component.UpdateGUICheckBoxes()
IC_BrivGemFarm_Component.BuildToolTips()
IC_BrivGemFarm_Component.ResetModFile()
IC_BrivGemFarm_Component.StartComs()

Briv_MaxChests_Check_Clicked()
{
    global BuyAllChestsCheck
    Gui, ICScriptHub:Submit, NoHide
    if(BuyAllChestsCheck)
    {
        GuiControl, ICScriptHub:Enable, BuySilverChestRatioSlider
        GuiControl, ICScriptHub:Enable, BuyGoldChestRatioSlider
    }
    else
    {
        GuiControl, ICScriptHub:Disable, BuySilverChestRatioSlider
        GuiControl, ICScriptHub:Disable, BuyGoldChestRatioSlider
    }
    Gui, ICScriptHub:Submit, NoHide
}

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

Briv_Visit_Byteglow_Speed_Avg_Stacks()
{
    IC_BrivGemFarm_Component.Briv_Visit_Byteglow_Speed("avg")
}

Briv_Visit_Byteglow_Speed_Max_Stacks()
{
    IC_BrivGemFarm_Component.Briv_Visit_Byteglow_Speed("max")
}

Briv_Visit_Byteglow_Speed_Link()
{
    byteglowURL := "http://ic.byteglow.com/speed"
    Run % byteglowURL 
}

Briv_Update_Chest_Ratio_Slider()
{
    ; Get the value of the slider that was just moved
    If (A_GuiControl = "BuyGoldChestRatioSlider") {
        GuiControlGet, BuyGoldChestRatioSliderValue,, BuyGoldChestRatioSlider
        BuySilverChestRatioSliderValue := 100 - BuyGoldChestRatioSliderValue
        GuiControl,, BuySilverChestRatioSlider, %BuySilverChestRatioSliderValue%
    } Else { ; A_GuiControl must be Slider2
        GuiControlGet, BuySilverChestRatioSliderValue,, BuySilverChestRatioSlider
        BuyGoldChestRatioSliderValue := 100 - BuySilverChestRatioSliderValue
        GuiControl,, BuyGoldChestRatioSlider, %BuyGoldChestRatioSliderValue%
    }

    Gui, ICScriptHub:Submit, NoHide
    g_BrivUserSettings[ "BuyGoldChestRatio" ]  := Round(BuyGoldChestRatioSliderValue / 100, 2)
    g_BrivUserSettings[ "BuySilverChestRatio" ] := Round(BuySilverChestRatioSliderValue / 100, 2)
    GuiControl,,BuyGoldChestRatioSliderText, % "Gold Chest Ratio: " . Round(BuyGoldChestRatioSliderValue / 100, 2)
    GuiControl,,BuySilverChestRatioSliderText, % "Silver Chest Ratio: " . Round(BuySilverChestRatioSliderValue / 100, 2)
    Gui, ICScriptHub:Submit, NoHide
}

Briv_Save_Profile_Clicked()
{
    Gui, Submit, NoHide
    global BrivDropDownSettings
    WinGetPos, xPos, yPos,,, 
    InputBox, profileName, Choose a profile name, Profile Name:,, Width := 375, Height := 129, X := xPos, Y := yPos,,, %BrivDropDownSettings%
    isCanceled := ErrorLevel
    while ((!GUIFunctions.TestInputForAlphaNumericDash(profileName) AND !isCanceled) OR profileName == "Default")
    {
        if(profileName == "Default")
            errMsg := "Can not use ""Default"" as a profile name."
        else
            errMsg := "Can only contain letters, numbers, and -."
        InputBox, profileName, Choose a profile name, %errMsg%`nProfile Name:,, Width := 375, Height := 144, X := xPos, Y := yPos,
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
        GuiControl,ICScriptHub:, BrivGemFarmBuyChestsCheck, % g_BrivUserSettings[ "BuyChests" ]
        GuiControl,ICScriptHub:, BrivGemFarmOpenChestsCheck, % g_BrivUserSettings[ "OpenChests" ] 
        GuiControl,ICScriptHub:, BuyAllChestsCheck, % g_BrivUserSettings[ "WaitToBuyChests" ] 
        GuiControl,ICScriptHub:, DisableDashWaitCheck, % g_BrivUserSettings[ "DisableDashWait" ]
        ; Sliders
        GuiControl, ICScriptHub:, BuyGoldChestRatioSlider , % Round(g_BrivUserSettings[ "BuyGoldChestRatio" ] * 100, 2)
        GuiControl, ICScriptHub:, BuySilverChestRatioSlider, % Round(g_BrivUserSettings[ "BuySilverChestRatio" ] * 100, 2)
        ; Force recolor of sliders so they don't have a white background with dark theme
        GuiControlGet, sliderID, ICScriptHub:Hwnd, BuyGoldChestRatioSlider
        WinActivate, ahk_id %sliderID% 
        GuiControlGet, sliderID, ICScriptHub:Hwnd, BuySilverChestRatioSlider
        WinActivate, ahk_id %sliderID% 
        ; Select an Edit box so left/right arrow keys do not change profiles in dropdown list
        WinGet wID, ID, A 
        ControlFocus, NewStackZone, ahk_id %wID%
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
        try ; Connect to current running if it exists
        {
            Briv_Connect_Clicked()
            SharedData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedData.ShowGui()
        }
        catch ; otherwise start farm
        {
            ;g_BrivGemFarm.GemFarm()
            g_SF.Hwnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
            g_SF.Memory.OpenProcessReader()
            scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_Run.ahk"
            GuiControl, ICScriptHub:Choose, ModronTabControl, Stats
            g_SF.ResetServerCall()
            for k,v in g_BrivFarmAddonStartFunctions
            {
                v.Call()
            }
            GuidCreate := ComObjCreate("Scriptlet.TypeLib")
            g_BrivFarm.GemFarmGUID := guid := GuidCreate.Guid
            Run, %A_AhkPath% "%scriptLocation%" "%guid%"
            IC_BrivGemFarm_Component.StartComs()
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
        g_BrivFarmComsObj.StopAll()
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
        g_SF.ResetServerCall()
        Try 
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
        }
        Catch
        {
            this.UpdateStatus("Gem Farm not running.") 
            return
        }
        try
        {
            IC_BrivGemFarm_Component.StartComs()
        }
        g_SF.Hwnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
        g_SF.Memory.OpenProcessReader()
        for k,v in g_BrivFarmAddonStartFunctions
            v.Call()
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
        if(OptionSettingCheck_HiddenFarmWindow != "")
            IC_BrivGemFarm_AdvancedSettings_Component.SaveAdvancedSettings()
        g_BrivUserSettings[ "Fkeys" ] := FkeysCheck
        g_BrivUserSettings[ "StackFailRecovery" ] := StackFailRecoveryCheck
        g_BrivUserSettings[ "StackZone" ] := StrReplace(NewStackZone, ",")
        g_BrivUserSettings[ "MinStackZone" ] := StrReplace(NewMinStackZone, ",")
        g_BrivUserSettings[ "TargetStacks" ] := StrReplace(NewTargetStacks, ",")
        g_BrivUserSettings[ "RestartStackTime" ] := StrReplace(NewRestartStackTime, ",")
        g_BrivUserSettings[ "DisableDashWait" ] := DisableDashWaitCheck
        g_BrivUserSettings[ "BuyChests" ] := BrivGemFarmBuyChestsCheck
        g_BrivUserSettings[ "OpenChests" ] := BrivGemFarmOpenChestsCheck
        g_BrivUserSettings[ "WaitToBuyChests" ] := BuyAllChestsCheck
        g_BrivUserSettings[ "MinGoldChestCount" ] := MinimumGoldChestCount
        g_BrivUserSettings[ "MinSilverChestCount" ] := MinimumSilverChestCount
        g_BrivUserSettings[ "MinGemCount" ] := StrReplace(NewMinGemCount, ",")
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
            updateStatusMsg := this.TestSettingsMatchProfile(updateStatusMsg)
        }
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        this.UpdateStatus(updateStatusMsg)
        return
    }

    ; Checks that current user settings match the currently selected profile's settings.
    TestSettingsMatchProfile(updateStatusMsg)
    {
        global g_BrivUserSettings
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
                    v2 := g_BrivUserSettings[k][k1]
                    if(v[k1] != g_BrivUserSettings[k][k1])
                    {
                        updateStatusMsg := "Session contains changes not yet saved to profile."
                        break
                    }
                }
            }
        }
        return updateStatusMsg
    }

    ;Saves Settings associated with BrivGemFarm
    Briv_Load_Profile_Clicked(settings := "Default", fullLoad := True)
    {
        global
        if(settings == "")
            return
        ; GuiControl, ICScriptHub:ChooseString, BrivDropDownSettings, %settings%
        Controlget, Row, FindString, %settings%, , ahk_id %BrivDropDownSettingsHWND% ; Docs: Sets OutputVar to the entry number of a ListBox or ComboBox that is an exact match for String.
        GuiControl, ICScriptHub:Choose, BrivDropDownSettings, %Row%
        if (!fullLoad)
        {
            this.BrivUserSettingsProfile := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Profiles\" . settings . "_Settings.json" )
            return
        }
        if(this.TestSettingsMatchProfile("") != "")
        {
            MsgBox 4,, There are unsaved changes to this profile. Are you sure you wish to load a new profile?
            IfMsgBox No
            {
                lastSelected := g_BrivUserSettings[ "LastSettingsUsed" ] 
                Controlget, Row, FindString, %lastSelected%, , ahk_id %BrivDropDownSettingsHWND% ; Docs: Sets OutputVar to the entry number of a ListBox or ComboBox that is an exact match for String.
                GuiControl, ICScriptHub:Choose, BrivDropDownSettings, %Row%
                return
            }
        }
        this.UpdateStatus("Loading Settings...")
        g_BrivUserSettings = {}
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
        GuiControl, ICScriptHub:, BrivGemFarmBuyChestsCheck, % g_BrivUserSettings[ "BuyChests" ]
        GuiControl, ICScriptHub:, BrivGemFarmOpenChestsCheck, % g_BrivUserSettings[ "OpenChests" ]
        GuiControl, ICScriptHub:, BuyAllChestsCheck, % g_BrivUserSettings[ "WaitToBuyChests" ]
        GuiControl, ICScriptHub:, NewMinGemCount, % g_BrivUserSettings[ "MinGemCount" ]
        GuiControl, ICScriptHub:, BuyGoldChestRatioSlider , % Round(g_BrivUserSettings[ "BuyGoldChestRatio" ] * 100, 2)
        GuiControl, ICScriptHub:, BuySilverChestRatioSlider, % Round(g_BrivUserSettings[ "BuySilverChestRatio" ] * 100, 2)
        GuiControl, ICScriptHub:, MinimumGoldChestCount , % g_BrivUserSettings[ "MinGoldChestCount" ]
        GuiControl, ICScriptHub:, MinimumSilverChestCount, % g_BrivUserSettings[ "MinSilverChestCount" ]
        if(OptionSettingCheck_HiddenFarmWindow != "")
            IC_BrivGemFarm_AdvancedSettings_Component.LoadAdvancedSettings()
        g_BrivUserSettings[ "LastSettingsUsed" ] := settings
        this.BrivUserSettingsProfile := g_BrivUserSettings.Clone()
        this.Briv_Save_Clicked(settings)
        this.UpdateStatus("Load complete.")
        return
    }

    Briv_Load_Profiles_List()
    {
        global BrivDropDownSettingsHWND
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
        Controlget, Row, FindString, %lastSelected%, , ahk_id %BrivDropDownSettingsHWND% ; Docs: Sets OutputVar to the entry number of a ListBox or ComboBox that is an exact match for String.
        GuiControl, ICScriptHub:Choose, BrivDropDownSettings, %Row%
        Gui, Submit, NoHide
    }

    ResetModFile()
    {
        IfExist, %g_BrivFarmModLoc%
            FileDelete, %g_BrivFarmModLoc%
        FileAppend, `;THIS FILE IS AUTOMATICALLY GENERATED BY BRIV GEM FARM PERFORMANCE ADDON`n, %g_BrivFarmModLoc%
        IfExist, %g_BrivFarmServerCallModLoc%
            FileDelete, %g_BrivFarmServerCallModLoc%
        FileAppend, `;THIS FILE IS AUTOMATICALLY GENERATED BY BRIV GEM FARM PERFORMANCE ADDON`n, %g_BrivFarmServerCallModLoc%
    }

    UpdateStatus(msg)
    {
        global gBriv_Button_Status
        GUIFunctions.UpdateStatusTextWithClear(gBriv_Button_Status, msg, 3000)
    }

    StartComs()
    {
        GuidCreate := ComObjCreate("Scriptlet.TypeLib")
        guid := GuidCreate.Guid
        ObjRegisterActive(g_BrivFarmComsObj, "")
        ObjRegisterActive(g_BrivFarmComsObj, guid)
        g_SF.WriteObjectToJSON(A_LineFile . "\..\LastGUID_BrivGemFarmComponent.json", guid)
        Try
        {
            SharedData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedData.ResetComs()
        }
    }
    
    Briv_Visit_Byteglow_Speed(speedType := "avg")
    {
        if (!WinExist("ahk_exe " . g_UserSettings[ "ExeName" ]))
        {
            IC_BrivGemFarm_Component.UpdateStatus("Game not running.")
            return
        }
        BrivID := 58
        BrivJumpSlot := 4
        byteglow := new Byteglow_ServerCalls_Class 

        g_SF.Memory.OpenProcessReader()
        gild := g_SF.Memory.ReadHeroLootGild(BrivID, BrivJumpSlot)
        ilvls := Floor(g_SF.Memory.ReadHeroLootEnchant(BrivID, BrivJumpSlot))
        rarity := g_SF.Memory.ReadHeroLootRarityValue(BrivID, BrivJumpSlot)
        if (ilvls == "" OR rarity == "" OR gild == "")
        {
            if(ilvls != "")
            {
                rarity := 1
                gild := 0
            }
            else
            {
                IC_BrivGemFarm_Component.UpdateStatus("Error reading Briv item data from game memory.")
                return
            }
        }
        isMetalBorn := g_SF.IsBrivMetalborn()
        modronReset := g_SF.Memory.GetModronResetArea()
        if (modronReset == "")
        {
            IC_BrivGemFarm_Component.UpdateStatus("Error reading reset area from Modron.")
            return
        }
        else if (modronReset == -1)
        {
            IC_BrivGemFarm_Component.UpdateStatus("Error reading reset area from Modron. (-1)")
            return
        }
        isMetalBorn := isMetalBorn == "" ? 0 : isMetalBorn
        response := byteGlow.CallBrivStacks(gild, ilvls, rarity, isMetalborn, modronReset)
        if(response != "" AND response.Message != "")
        {
            MsgBox, % "Error - " . response.Message
            IC_BrivGemFarm_Component.UpdateStatus("Error retrieving stacks from byteglow.")
        }
        else if(response != "" AND response.error == "")
        {
            if(speedType == "avg")
            {
                GuiControl, ICScriptHub:, NewTargetStacks, % response.stats.stacks.avg
            }
            else if (speedType == "max")
            {
                GuiControl, ICScriptHub:, NewTargetStacks, % response.stats.stacks.max
            }
            IC_BrivGemFarm_Component.UpdateStatus("Target haste stacks updated.")
        }
        else
        {
            IC_BrivGemFarm_Component.UpdateStatus("Error retrieving stacks from byteglow.")
        }
    }
}

; Revoke coms on exit.
OnExit("Briv_Com_Object_Revoke")
; OnExit(Briv_Com_Object_Revoke())
Briv_Com_Object_Revoke()
{
    ObjRegisterActive(g_BrivFarmComsObj, "")
}

Gui, ICScriptHub:Submit, NoHide
Briv_MaxChests_Check_Clicked()
#include %A_LineFile%\..\IC_BrivGemFarm_ClassUpdates.ahk
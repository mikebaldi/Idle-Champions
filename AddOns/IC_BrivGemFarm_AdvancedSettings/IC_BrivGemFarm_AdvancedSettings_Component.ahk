class IC_BrivGemFarm_AdvancedSettings_Component
{
    ;Saves Advanced Settings associated with BrivGemFarm
    SaveAdvancedSettings(number := "") {
        global
        Gui, ICScriptHub:Submit, NoHide
        if (number != "") {
            InputBox, descriptionTemp, Enter a Profile Description
            g_BrivUserSettings[ "ProfileInformation" ] := descriptionTemp  
        }
        else {
            g_BrivUserSettings[ "ProfileInformation" ] := "Default"
        }

        ;Save settings for Briv Gem Farm Main
        #include %A_ScriptDir%\Addons\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Component.ahk
        g_BrivUserSettings[ "StackZone" ] := NewStackZone
        g_BrivUserSettings[ "MinStackZone" ] := NewMinStackZone
        g_BrivUserSettings[ "TargetStacks" ] := NewTargetStacks
        g_BrivUserSettings[ "RestartStackTime" ] := NewRestartStackTime
        g_BrivUserSettings[ "MinGemCount" ] := NewMinGemCount

        ;Save advanced settings
        g_BrivUserSettings[ "DoChestsContinuous" ] := OptionSettingCheck_DoChestsContinuous
        g_BrivUserSettings[ "HiddenFarmWindow" ] := OptionSettingCheck_HiddenFarmWindow
        g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ] := OptionSettingCheck_RestoreLastWindowOnGameOpen
        g_BrivUserSettings[ "BrivJumpBuffer" ] := OptionSettingEdit_BrivJumpBuffer
        g_BrivUserSettings[ "DashWaitBuffer" ] := OptionSettingEdit_DashWaitBuffer
        g_BrivUserSettings[ "ResetZoneBuffer" ] := OptionSettingEdit_ResetZoneBuffer
        g_BrivUserSettings[ "WindowXPositon" ] := OptionSettingEdit_WindowXPositon
        g_BrivUserSettings[ "WindowYPositon" ] := OptionSettingEdit_WindowYPositon
        IC_BrivGemFarm_AdvancedSettings_Functions.UpdateSettings()
        g_SF.WriteObjectToJSON( A_LineFile . "\..\..\IC_BrivGemFarm_Performance\BrivGemFarmSettings" . number . ".json" , g_BrivUserSettings )
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive("{416ABC15-9EFC-400C-8123-D7D8778A2103}")
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        return
    }

    ;Loads Advanced Settings associated with BrivGemFarm
    LoadAdvancedSettings(number := "") {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\IC_BrivGemFarm_Performance\BrivGemFarmSettings" . number . ".json" )
    }
    
    AddToolTips() {
            GUIFunctions.AddToolTip( "OptionSettingCheck_DoChestsContinuous", "Whether The script will buy and open as many as it can within the stack sleep time set or just 99 max.")
            GUIFunctions.AddToolTip( "OptionSettingCheck_HiddenFarmWindow", "Disable the visibility of the second script window")
            GUIFunctions.AddToolTip( "OptionSettingCheck_RestoreLastWindowOnGameOpen", "Whether the script will try to switch focus back to the last active window immediately when the game opens")
            GUIFunctions.AddToolTip( "OptionSettingText_BrivJumpBuffer", "How many areas before a modron reset zone that switching to e formation over q formation is desired.")
            GUIFunctions.AddToolTip( "OptionSettingText_DashWaitBuffer", "The distance from your modron's reset zone where dashwait will stop being activated.")
            GUIFunctions.AddToolTip( "OptionSettingText_ResetZoneBuffer", "Change this value to increase the number of zones the script will go waiting for modron reset after stacking before manually resetting")
            GUIFunctions.AddToolTip( "OptionSettingText_WindowXPositon", "Where the gem farm script will appear horizontally across your screen")
            GUIFunctions.AddToolTip( "OptionSettingText_WindowYPositon", "Where the gem farm script will appear vertically on your screen")            
    }

    Refresh() {
        ;Refresh CheckBoxes
        GuiControl,ICScriptHub:, OptionSettingCheck_DoChestsContinuous, % g_BrivUserSettings[ "DoChestsContinuous" ]
        GuiControl,ICScriptHub:, OptionSettingCheck_HiddenFarmWindow, % g_BrivUserSettings[ "HiddenFarmWindow" ]
        GuiControl,ICScriptHub:, OptionSettingCheck_RestoreLastWindowOnGameOpen, % g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ]

        ;Refresh Editable fields
        GuiControl,ICScriptHub:, OptionSettingEdit_BrivJumpBuffer, % g_BrivUserSettings[ "BrivJumpBuffer" ]
        GuiControl,ICScriptHub:, OptionSettingEdit_DashWaitBuffer, % g_BrivUserSettings[ "DashWaitBuffer" ]
        GuiControl,ICScriptHub:, OptionSettingEdit_ResetZoneBuffer, % g_BrivUserSettings[ "ResetZoneBuffer" ]
        GuiControl,ICScriptHub:, OptionSettingEdit_WindowXPositon, % g_BrivUserSettings[ "WindowXPositon" ]
        GuiControl,ICScriptHub:, OptionSettingEdit_WindowYPositon, % g_BrivUserSettings[ "WindowYPositon" ]

        ;Rebuild Preferred Briv Jump Zones
        IC_BrivGemFarm_AdvancedSettings_Functions.LoadPreferredBrivJumpSettings()

        ;Update Main Briv Gem Farm window checkboxes.
        #include %A_ScriptDir%\Addons\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Component.ahk
        IC_BrivGemFarm_Component.UpdateGUICheckBoxes()

        ;Update Main Briv Gem Farm window editable fields
        GuiControl,ICScriptHub:, NewStackZone, % g_BrivUserSettings[ "StackZone" ]
        GuiControl,ICScriptHub:, NewMinStackZone, % g_BrivUserSettings[ "MinStackZone" ]
        GuiControl,ICScriptHub:, NewTargetStacks, % g_BrivUserSettings[ "TargetStacks" ]
        GuiControl,ICScriptHub:, NewRestartStackTime, % g_BrivUserSettings[ "RestartStackTime" ]
        GuiControl,ICScriptHub:, NewMinGemCount, % g_BrivUserSettings[ "MinGemCount" ]
    }
}
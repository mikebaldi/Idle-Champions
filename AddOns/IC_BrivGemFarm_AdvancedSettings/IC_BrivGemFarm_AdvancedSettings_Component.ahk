class IC_BrivGemFarm_AdvancedSettings_Component
{
    ;Saves Advanced Settings associated with BrivGemFarm
    SaveAdvancedSettings() {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivUserSettings[ "DoChestsContinuous" ] := OptionSettingCheck_DoChestsContinuous
        g_BrivUserSettings[ "HiddenFarmWindow" ] := OptionSettingCheck_HiddenFarmWindow
        g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ] := OptionSettingCheck_RestoreLastWindowOnGameOpen
        g_BrivUserSettings[ "ForceOfflineGemThreshold" ] := OptionSettingEdit_ForceOfflineGemThreshold
        g_BrivUserSettings[ "ForceOfflineRunThreshold" ] := OptionSettingEdit_ForceOfflineRunThreshold
        g_BrivUserSettings[ "BrivJumpBuffer" ] := OptionSettingEdit_BrivJumpBuffer
        g_BrivUserSettings[ "DashWaitBuffer" ] := OptionSettingEdit_DashWaitBuffer
        g_BrivUserSettings[ "ResetZoneBuffer" ] := OptionSettingEdit_ResetZoneBuffer
        g_BrivUserSettings[ "WindowXPosition" ] := OptionSettingEdit_WindowXPosition
        g_BrivUserSettings[ "WindowYPosition" ] := OptionSettingEdit_WindowYPosition
        g_BrivUserSettings[ "ManualBrivJumpValue" ] := OptionSettingEdit_ManualBrivJumpValue
        g_BrivUserSettings[ "IgnoreBrivHaste" ] := OptionSettingEdit_IgnoreBrivHaste
        IC_BrivGemFarm_AdvancedSettings_Functions.UpdateJumpSettings()
        g_SF.WriteObjectToJSON( A_LineFile . "\..\..\IC_BrivGemFarm_Performance\BrivGemFarmSettings.json" , g_BrivUserSettings )
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        return
    }

    LoadAdvancedSettings() {
        global
        if(g_BrivUserSettings)
        {
            GuiControl, ICScriptHub:, OptionSettingCheck_DoChestsContinuous, % g_BrivUserSettings[ "DoChestsContinuous" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_HiddenFarmWindow, % g_BrivUserSettings[ "HiddenFarmWindow" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_RestoreLastWindowOnGameOpen, % g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_ForceOfflineGemThreshold, % g_BrivUserSettings[ "ForceOfflineGemThreshold" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_ForceOfflineRunThreshold, % g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_BrivJumpBuffer, % g_BrivUserSettings[ "BrivJumpBuffer" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_DashWaitBuffer, % g_BrivUserSettings[ "DashWaitBuffer" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_ResetZoneBuffer, % g_BrivUserSettings[ "ResetZoneBuffer" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_WindowXPosition, % g_BrivUserSettings[ "WindowXPosition" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_WindowYPosition, % g_BrivUserSettings[ "WindowYPosition" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_ManualBrivJumpValue, % g_BrivUserSettings[ "ManualBrivJumpValue" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_IgnoreBrivHaste, % g_BrivUserSettings[ "IgnoreBrivHaste" ]
            IC_BrivGemFarm_AdvancedSettings_Functions.LoadPreferredBrivJumpSettings()
        }
        Gui, ICScriptHub:Submit, NoHide
        return
    }

    AddToolTips() {
            GUIFunctions.AddToolTip( "OptionSettingCheck_DoChestsContinuous", "Whether The script will buy and open as many as it can within the stack sleep time set or just 99 max.")
            GUIFunctions.AddToolTip( "OptionSettingCheck_HiddenFarmWindow", "Disable the visibility of the second script window")
            GUIFunctions.AddToolTip( "OptionSettingCheck_RestoreLastWindowOnGameOpen", "Whether the script will try to switch focus back to the last active window immediately when the game opens")
            GUIFunctions.AddToolTip( "OptionSettingText_ForceOfflineGemThreshold", "Stack offline only when this many gems are available for chest purchase (0 = disable)")
            GUIFunctions.AddToolTip( "OptionSettingText_ForceOfflineRunThreshold", "Stack offline once in every N runs as reported by Resets done of current core (0 or 1 = disable)")
            GUIFunctions.AddToolTip( "OptionSettingText_BrivJumpBuffer", "How many areas before a modron reset zone that switching to e formation over q formation is desired.")
            GUIFunctions.AddToolTip( "OptionSettingText_DashWaitBuffer", "The distance from your modron's reset zone where dashwait will stop being activated.")
            GUIFunctions.AddToolTip( "OptionSettingText_ResetZoneBuffer", "Change this value to increase the number of zones the script will go waiting for modron reset after stacking before manually resetting")
            GUIFunctions.AddToolTip( "OptionSettingText_WindowXPosition", "Where the gem farm script will appear horizontally across your screen")
            GUIFunctions.AddToolTip( "OptionSettingText_WindowYPosition", "Where the gem farm script will appear vertically on your screen")            
            GUIFunctions.AddToolTip( "OptionSettingText_ManualBrivJumpValue", "Set Briv's jump level for stack calculations. Useful for feat swapping setups. 0 is the default value which will ignore this setting.")
            GUIFunctions.AddToolTip( "OptionSettingEdit_IgnoreBrivHaste", "Ignore haste stacks when deciding to stack. Will force stacking one time each run.")
    }
}
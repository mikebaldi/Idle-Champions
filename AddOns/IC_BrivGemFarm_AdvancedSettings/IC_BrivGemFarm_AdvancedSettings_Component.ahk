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
        g_BrivUserSettings[ "WindowXPositon" ] := OptionSettingEdit_WindowXPositon
        g_BrivUserSettings[ "WindowYPositon" ] := OptionSettingEdit_WindowYPositon
        IC_BrivGemFarm_AdvancedSettings_Functions.UpdateSettings()
        g_SF.WriteObjectToJSON( A_LineFile . "\..\..\IC_BrivGemFarm_Performance\BrivGemFarmSettings.json" , g_BrivUserSettings )
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
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
            GUIFunctions.AddToolTip( "OptionSettingText_WindowXPositon", "Where the gem farm script will appear horizontally across your screen")
            GUIFunctions.AddToolTip( "OptionSettingText_WindowYPositon", "Where the gem farm script will appear vertically on your screen")            
    }

    Refresh() {
        GuiControl,ICScriptHub:, OptionSettingCheck_DoChestsContinuous, % g_BrivUserSettings[ "DoChestsContinuous" ]
        GuiControl,ICScriptHub:, OptionSettingCheck_HiddenFarmWindow, % g_BrivUserSettings[ "HiddenFarmWindow" ]
        GuiControl,ICScriptHub:, OptionSettingCheck_RestoreLastWindowOnGameOpen, % g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ]
    }
}
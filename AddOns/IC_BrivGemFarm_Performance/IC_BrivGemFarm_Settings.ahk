ReloadBrivGemFarmSettings(loadFromFile := True)
{
    global g_BrivUserSettings
    writeSettings := False
    if(loadFromFile)
        userSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    If !IsObject( userSettings )
    {
        userSettings := {}
        writeSettings := True
    }
    g_BrivUserSettings := {}
    if ( g_BrivUserSettings[ "LastSettingsUsed" ] == "" )
        g_BrivUserSettings[ "LastSettingsUsed" ] := "Default"
    if ( g_BrivUserSettings[ "Fkeys" ] == "" )
        g_BrivUserSettings[ "Fkeys" ] := 1
    if ( g_BrivUserSettings[ "StackFailRecovery" ] == "" )
        g_BrivUserSettings[ "StackFailRecovery" ] := 1
    if ( g_BrivUserSettings[ "DisableDashWait" ] == "" )
        g_BrivUserSettings[ "DisableDashWait" ] := False
    if ( g_BrivUserSettings[ "StackZone" ] == "" )
        g_BrivUserSettings[ "StackZone" ] := 700
    if ( g_BrivUserSettings[ "MinStackZone" ] == "" )
        g_BrivUserSettings[ "MinStackZone" ] := 200
    if (g_BrivUserSettings[ "TargetStacks" ] == "")
        g_BrivUserSettings[ "TargetStacks" ] := 0
    if ( g_BrivUserSettings[ "RestartStackTime" ] == "" )
        g_BrivUserSettings[ "RestartStackTime" ] := 12000
    if ( g_BrivUserSettings[ "BuySilvers" ] == "" )
        g_BrivUserSettings[ "BuySilvers" ] := 1
    if ( g_BrivUserSettings[ "BuyGolds" ] == "" )
        g_BrivUserSettings[ "BuyGolds" ] := 0
    if ( g_BrivUserSettings[ "OpenSilvers" ] == "" )
        g_BrivUserSettings[ "OpenSilvers" ] := 1
    if ( g_BrivUserSettings[ "OpenGolds" ] == "" )
        g_BrivUserSettings[ "OpenGolds" ] := 1
    if ( g_BrivUserSettings[ "MinGemCount" ] == "" )
        g_BrivUserSettings[ "MinGemCount" ] := 0
    
    ; New
    if ( g_BrivUserSettings[ "BuyGoldChestRatio" ] == "" )
        g_BrivUserSettings[ "BuyGoldChestRatio" ] := 1
    if ( g_BrivUserSettings[ "BuySilverChestRatio" ] == "" )
        g_BrivUserSettings[ "BuySilverChestRatio" ] := 0
    if ( g_BrivUserSettings[ "MinGoldChestCount" ] == "" )
        g_BrivUserSettings[ "MinGoldChestCount" ] := 0
    if ( g_BrivUserSettings[ "MinSilverChestCount" ] == "" )
        g_BrivUserSettings[ "MinSilverChestCount" ] := 0
    if ( g_BrivUserSettings[ "WaitToBuyChests" ] == "" )
        g_BrivUserSettings[ "WaitToBuyChests" ] := True

    ; Advanced BrivGemFarm Settings
    if ( g_BrivUserSettings[ "HiddenFarmWindow" ] == "" )
        g_BrivUserSettings[ "HiddenFarmWindow" ] := 0
    if ( g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ] == "" )
        g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ] := True
    if ( g_BrivUserSettings[ "ForceOfflineGemThreshold" ] == "" )
        g_BrivUserSettings[ "ForceOfflineGemThreshold" ] := 0
    if ( g_BrivUserSettings[ "ForceOfflineRunThreshold" ] == "" )
        g_BrivUserSettings[ "ForceOfflineRunThreshold" ] := 0
    if ( g_BrivUserSettings[ "BrivJumpBuffer" ] == "" )
        g_BrivUserSettings[ "BrivJumpBuffer" ] := 0
    if (g_BrivUserSettings[ "DashWaitBuffer" ] == "")    
        g_BrivUserSettings[ "DashWaitBuffer" ] := 30
    if ( g_BrivUserSettings[ "WindowXPosition" ] == "" )
        g_BrivUserSettings[ "WindowXPosition" ] := 0
    if ( g_BrivUserSettings[ "WindowYPosition" ] == "" )
        g_BrivUserSettings[ "WindowYPosition" ] := 0
    if ( g_BrivUserSettings[ "ManualBrivJumpValue" ] == "" )
        g_BrivUserSettings[ "ManualBrivJumpValue" ] := 0
    if (g_BrivUserSettings[ "IgnoreBrivHaste" ] == "" )
        g_BrivUserSettings[ "IgnoreBrivHaste" ] := 0   
    if ( g_BrivUserSettings[ "PreferredBrivJumpZones" ] == "")
	    g_BrivUserSettings[ "PreferredBrivJumpZones" ] := [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1] 

    ; =========================================
    ; LEGACY handling
    if ( g_BrivUserSettings[ "WindowXPositon" ] != "" ) ; Legacy settings name handling.
    {
        g_BrivUserSettings[ "WindowXPosition" ] := g_BrivUserSettings[ "WindowXPositon" ]
        g_BrivUserSettings.Delete("WindowXPositon")
        writeSettings := True
    }
    if ( g_BrivUserSettings[ "WindowYPositon" ] != "" )
    {
        g_BrivUserSettings[ "WindowYPosition" ] := g_BrivUserSettings[ "WindowYPositon" ]
        g_BrivUserSettings.Delete("WindowYPositon")
        writeSettings := True
    }
    ; Found legacy settings file.
    if ( !writeSettings AND loadFromFile AND userSettings[ "LastSettingsUsed" ] == "" )
    {
        userSettings[ "LastSettingsUsed" ] := "LegacySettings"
        g_SF.WriteObjectToJSON( A_LineFile . "\..\Profiles\LegacySettings_Settings.json" , userSettings )
    }
    ; =========================================

    ; strip unused settings from the settings file.
    for k,v in g_BrivUserSettings
        g_BrivUserSettings[k] := userSettings[k] != "" ? userSettings[k] : g_BrivUserSettings[k] ; keep new setting if old is not found


    if (writeSettings == True)
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
}

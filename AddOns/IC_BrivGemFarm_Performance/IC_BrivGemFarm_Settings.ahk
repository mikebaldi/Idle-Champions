ReloadBrivGemFarmSettings()
{
    g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    If !IsObject( g_BrivUserSettings )
    {
        g_BrivUserSettings := {}
        g_BrivUserSettings["WriteSettings"] := true
    }
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
    if (g_BrivUserSettings[ "TargetStacks" ] == "")
        g_BrivUserSettings[ "TargetStacks" ] := 4000
    if ( g_BrivUserSettings[ "RestartStackTime" ] == "" )
        g_BrivUserSettings[ "RestartStackTime" ] := 12000
    if ( g_BrivUserSettings[ "DashSleepTime" ] == "" )
        g_BrivUserSettings[ "DashSleepTime" ] := 60000
    if ( g_BrivUserSettings[ "SwapSleep" ] == "" )
        g_BrivUserSettings[ "SwapSleep" ] := 2500
    if ( g_BrivUserSettings[ "DoChests" ] == "" )
        g_BrivUserSettings[ "DoChests" ] := 1
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
    if (g_BrivUserSettings[ "DashWaitBuffer" ] == "")    
        g_BrivUserSettings[ "DashWaitBuffer" ] := 0
    if ( g_BrivUserSettings[ "WindowXPositon" ] == "" )
        g_BrivUserSettings[ "WindowXPositon" ] := 0
    if ( g_BrivUserSettings[ "WindowYPositon" ] == "" )
        g_BrivUserSettings[ "WindowYPositon" ] := 0
    if ( g_BrivUserSettings[ "HiddenFarmWindow" ] == "" )
        g_BrivUserSettings[ "HiddenFarmWindow" ] := 0
    if ( g_BrivUserSettings[ "DoChestsContinuous" ] == "" )
        g_BrivUserSettings[ "DoChestsContinuous" ] := 0
    if(g_BrivUserSettings["WriteSettings"] := true)
    {
        g_BrivUserSettings.Delete("WriteSettings")
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )   
    }     
}

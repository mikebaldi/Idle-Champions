; Add tab to the GUI
GUIFunctions.AddTab("About")

Gui, ICScriptHub:Tab, About
aboutRows := 17
aboutGroupBoxHeight := aboutRows * 15
Gui, ICScriptHub:Add, GroupBox, x+15 y+15 w425 h%aboutGroupBoxHeight%, Version Info: 
Gui, ICScriptHub:Add, Text, vVersionStringID xp+20 yp+25 w400 r%aboutRows%, % IC_About_Component.GetVersionString()

class IC_About_Component
{
    GetVersionString()
    {
        g_SF.Memory.OpenProcessReader()
        string := ""
        string .= "Script Version: " . GetScriptHubVersion() . "`n`n"
        gameVersionaArch := _MemoryManager.is64bit ? " (64 bit)" : " (32 bit)"
        gameVersion := g_SF.Memory.ReadGameVersion() == "" ? " -- Game not found on Script Hub load. --" : g_SF.Memory.ReadGameVersion() . gameVersionaArch 
        if(isFunc(g_SF.Memory.ReadGameVersion))
            string .= "Idle Champions Game Version: " . gameVersion . "`n"
        if(isFunc(g_SF.Memory.GetPointersVersion))
            string .= "Current Pointers: " . (g_SF.Memory.GetPointersVersion() ? g_SF.Memory.GetPointersVersion() : " ---- ") . "`n"
        string .= "Imports Versions: " . (g_ImportsGameVersion32 == "" ? " ---- " : (g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32 )) . " (32 bit), " . (g_ImportsGameVersion64 == "" ? " ---- " : (g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)) . " (64 bit)`n`n"
        if(isFunc(g_SF.Memory.GetVersion))
            string .= "MemoryFunctions Version: " . g_SF.Memory.GetVersion() . "`n"
        if(isFunc(IC_IdleGameManager_Class.GetVersion))
            string .= "IdleGameManager Memory: " . IC_IdleGameManager_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings_Class.GetVersion))
            string .= "GameSettings Memory: " . IC_GameSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings_Class.GetVersion))
            string .= "EngineSettings Memory: " . IC_EngineSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet_Class.GetVersion))
            string .= "CrusadersGameDataSet Memory: " . IC_CrusadersGameDataSet_Class.GetVersion() . "`n"
        if(isFunc(IC_DialogManager_Class.GetVersion))
            string .= "DialogManager Memory: " . IC_DialogManager_Class.GetVersion() . "`n`n"
        if(isFunc(IC_ActiveEffectKeyHandler_Class.GetVersion))
            string .= "EffectKeyHandler Memory: " . IC_ActiveEffectKeyHandler_Class.GetVersion() . "`n`n"
        if(isFunc(IC_SharedFunctions_Class.GetVersion))
            string .= "SharedFunctions Version: " . IC_SharedFunctions_Class.GetVersion() . "`n"
        if(isFunc(IC_ServerCalls_Class.GetVersion))
            string .= "ServerCalls Version: " . IC_ServerCalls_Class.GetVersion() . "`n"
        if(isFunc(_classLog.GetVersion))
            string .= "Log Class Version: " . _classLog.GetVersion() . "`n"
        return string
    }
}
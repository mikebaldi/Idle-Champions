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
        gameVersion := g_SF.Memory.ReadGameVersion()
        if(gameVersion == "")
            gameVersion := " -- Game not found on Script Hub load. --"
        if(isFunc(g_SF.Memory.ReadGameVersion))
            string .= "Idle Champions Game Version: " . gameVersion . "`n`n"
        if(isFunc(IC_IdleGameManager32_Class.GetVersion))
            string .= "GameManager Memory Functions (32-bit) : " . IC_IdleGameManager32_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings32_Class.GetVersion))
            string .= "GameSettings Memory Functions (32-bit) : " . IC_GameSettings32_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings32_Class.GetVersion))
            string .= "EngineSettings Memory Functions (32-bit): " . IC_EngineSettings32_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet32_Class.GetVersion))
            string .= "CGDataSet Memory Functions (32-bit): " . IC_CrusadersGameDataSet32_Class.GetVersion() . "`n"
        if(isFunc(IC_DialogManager32_Class.GetVersion))
            string .= "DialogManager Memory Functions (32-bit): " . IC_DialogManager32_Class.GetVersion() . "`n`n"
        if(isFunc(IC_IdleGameManager64_Class.GetVersion))
            string .= "GameManager Memory Functions (64-bit): " . IC_IdleGameManager64_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings64_Class.GetVersion))
            string .= "GameSettings Memory Functions (64-bit): " . IC_GameSettings64_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings64_Class.GetVersion))
            string .= "EngineSettings Memory Functions (64-bit): " . IC_EngineSettings64_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet64_Class.GetVersion))
            string .= "CGDataSet Memory Functions (64-bit): " . IC_CrusadersGameDataSet64_Class.GetVersion() . "`n"
        if(isFunc(IC_DialogManager64_Class.GetVersion))
            string .= "DialogManager Memory Functions (64-bit): " . IC_DialogManager64_Class.GetVersion() . "`n`n"
        if(isFunc(IC_ActiveEffectKeyHandler_Class.GetVersion))
            string .= "EffectKeyHandler Memory Functions (64-bit): " . IC_DialogManager64_Class.GetVersion() . "`n`n"
        if(isFunc(IC_SharedFunctions_Class.GetVersion))
            string .= "Shared Functions Version: " . IC_SharedFunctions_Class.GetVersion() . "`n"
        if(isFunc(IC_ServerCalls_Class.GetVersion))
            string .= "Server Call Class Version: " . IC_ServerCalls_Class.GetVersion() . "`n"
        if(isFunc(_classLog.GetVersion))
            string .= "Log Class Version: " . _classLog.GetVersion() . "`n"
        return string
    }
}
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
        string := ""
        string .= "Script Version: " . GetModronGUIVersion() . "`n`n"
        if(isFunc(g_SF.Memory.ReadGameVersion))
            string .= "Idle Champions Game Version: " . g_SF.Memory.ReadGameVersion() . "`n`n"
        if(isFunc(IC_GameManager_Class.GetVersion))
            string .= "GameManager Memory Functions (Steam) : " . IC_GameManager_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings_Class.GetVersion))
            string .= "GameSettings Memory Functions (Steam) : " . IC_GameSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings_Class.GetVersion))
            string .= "EngineSettings Memory Functions (Steam): " . IC_EngineSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet_Class.GetVersion))
            string .= "CGDataSet Memory Functions (Steam): " . IC_CrusadersGameDataSet_Class.GetVersion() . "`n`n"
        if(isFunc(IC_GameManagerEGS_Class.GetVersion))
            string .= "GameManager Memory Functions (EGS): " . IC_GameManagerEGS_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettingsEGS_Class.GetVersion))
            string .= "GameSettings Memory Functions (EGS): " . IC_GameSettingsEGS_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettingsEGS_Class.GetVersion))
            string .= "EngineSettings Memory Functions (EGS): " . IC_EngineSettingsEGS_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSetEGS_Class.GetVersion))
            string .= "CGDataSet Memory Functions (EGS): " . IC_CrusadersGameDataSetEGS_Class.GetVersion() . "`n`n"
        if(isFunc(IC_GameManager_Class32.GetVersion))
            string .= "GameManager Memory Functions (32-bit) : " . IC_GameManager_Class32.GetVersion() . "`n"
        if(isFunc(IC_GameSettings_Class32.GetVersion))
            string .= "GameSettings Memory Functions (32-bit) : " . IC_GameSettings_Class32.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings_Class32.GetVersion))
            string .= "EngineSettings Memory Functions (32-bit): " . IC_EngineSettings_Class32.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet_Class32.GetVersion))
            string .= "CGDataSet Memory Functions (32-bit): " . IC_CrusadersGameDataSet_Class32.GetVersion() . "`n`n"
        if(isFunc(IC_DialogManager_Class.GetVersion))
            string .= "CGDataSet Memory Functions (32-bit): " . IC_DialogManager_Class.GetVersion() . "`n`n"
        if(isFunc(IC_GameManager64_Class.GetVersion))
            string .= "GameManager Memory Functions (64-bit): " . IC_GameManager64_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings64_Class.GetVersion))
            string .= "GameSettings Memory Functions (64-bit): " . IC_GameSettings64_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings64_Class.GetVersion))
            string .= "EngineSettings Memory Functions (64-bit): " . IC_EngineSettings64_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet64_Class.GetVersion))
            string .= "CGDataSet Memory Functions (64-bit): " . IC_CrusadersGameDataSet64_Class.GetVersion() . "`n`n"
        if(isFunc(IC_DialogManager64_Class.GetVersion))
            string .= "CGDataSet Memory Functions (64-bit): " . IC_DialogManager64_Class.GetVersion() . "`n`n"
        if(isFunc(IC_SharedFunctions_Class.GetVersion))
            string .= "Shared Functions Version: " . IC_SharedFunctions_Class.GetVersion() . "`n"
        if(isFunc(IC_ServerCalls_Class.GetVersion))
            string .= "Server Call Class Version: " . IC_ServerCalls_Class.GetVersion() . "`n"
        if(isFunc(_classLog.GetVersion))
            string .= "Log Class Version: " . _classLog.GetVersion() . "`n"
        return string
    }
}
; Add tab to the GUI
GUIFunctions.AddTab("About")

Gui, ICScriptHub:Tab, About
IC_About_Component.Refresh()

class IC_About_Component
{
    EnabledAddonsValues := Array()
    EnabledAddonsRows := 0
    VersionStringValues := Array()
    VersionStringRows := 0

    Refresh()
    {
        global
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vAboutLineHeightTest w2,     
        GuiControlGet, xyVal, ICScriptHub:Pos, AboutLineHeightTest
        IC_About_Component.GetScriptVersions()
        aboutGroupBoxHeight := (IC_About_Component.VersionStringValues.Count() + 2) * (xyValH+1) + 15
        Gui, ICScriptHub:Add, GroupBox, xp+15 yp+15 w425 h%aboutGroupBoxHeight% vAboutVersionGroupBox, Version Info: 
        xyValX += 0
        xyValY += (aboutGroupBoxHeight + 15)
        IC_About_Component.ShowScriptVersions()

        IC_About_Component.GetEnabledAddons()
        AboutAddonGroupBoxHeight := (IC_About_Component.EnabledAddonsValues.Count() + 2) * (xyValH+1) + 15
        GuiControlGet, xyVal, ICScriptHub:Pos, AboutVersionGroupBox
        xyValX += 0
        xyValY += (aboutGroupBoxHeight + 15)
        Gui, ICScriptHub:Add, GroupBox, x%xyValX% y%xyValY% w425 h%AboutAddonGroupBoxHeight% vAboutAddonGroupBox, % "Enabled Addons [" . (g_UserSettings["CheckForUpdates"] ? "ON" : "OFF") . "]: "
        IC_About_Component.ShowEnabledAddons()
    }

    GetScriptVersions()
    {
        global
        this.VersionStringValues := Array() 
        g_SF.Memory.OpenProcessReader()
        this.VersionStringValues.Push("Script Version: " . GetScriptHubVersion())
        this.VersionStringValues.Push(" ")
        local gameVersionaArch := _MemoryManager.is64bit ? " (64 bit)" : " (32 bit)"
        local gameVersion := g_SF.Memory.ReadGameVersion() == "" ? " -- Game not found on Script Hub load. --" : g_SF.Memory.ReadGameVersion() . gameVersionaArch 
        if(isFunc(g_SF.Memory.ReadGameVersion))
            this.VersionStringValues.Push("Idle Champions Game Version: " . gameVersion)
        if(isFunc(g_SF.Memory.GetPointersVersion))
            this.VersionStringValues.Push("Current Pointers: " . (g_SF.Memory.GetPointersVersion() ? g_SF.Memory.GetPointersVersion() : " ---- "))
        this.VersionStringValues.Push("Imports: "  . (g_ImportsGameVersion64 == "" ? " ---- " : (g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)) . (g_ImportsGameVersionPlatform64 != "" ? " (" . g_ImportsGameVersionPlatform64 . ")" : ""))
        this.VersionStringValues.Push("Game Location: " . (g_UserSettings[ "InstallPath" ] == "explorer.exe ""com.epicgames.launcher://apps/7e508f543b05465abe3a935960eb70ac%3A48353a502e72433298f25827e03dbff0%3A40cb42e38c0b4a14a1bb133eb3291572?action=launch&silent=true""" ? "EGS" : "Steam/Other"))
        this.VersionStringValues.Push(" ")
        if(isFunc(g_SF.Memory.GetVersion))
            this.VersionStringValues.Push("MemoryFunctions Version: " . g_SF.Memory.GetVersion())
        if(isFunc(GameObjectStructure.GetVersion))
            this.VersionStringValues.Push("GameObjectStructure Version: " . GameObjectStructure.GetVersion())
        if(isFunc(IC_IdleGameManager_Class.GetVersion))
            this.VersionStringValues.Push("IdleGameManager Memory: " . IC_IdleGameManager_Class.GetVersion())
        if(isFunc(IC_GameSettings_Class.GetVersion))
            this.VersionStringValues.Push("GameSettings Memory: " . IC_GameSettings_Class.GetVersion())
        if(isFunc(IC_EngineSettings_Class.GetVersion))
            this.VersionStringValues.Push("EngineSettings Memory: " . IC_EngineSettings_Class.GetVersion())
        if(isFunc(IC_CrusadersGameDataSet_Class.GetVersion))
            this.VersionStringValues.Push("CrusadersGameDataSet Memory: " . IC_CrusadersGameDataSet_Class.GetVersion())
        if(isFunc(IC_DialogManager_Class.GetVersion))
            this.VersionStringValues.Push("DialogManager Memory: " . IC_DialogManager_Class.GetVersion())
        ; if(isFunc(IC_UserStatHandler_Class.GetVersion))
        ;     this.VersionStringValues.Push("UserStatHandler Memory: " . IC_UserStatHandler_Class.GetVersion())
        ; if(isFunc(IC_UserData_Class.GetVersion))
        ;     this.VersionStringValues.Push("UserData Memory: " . IC_UserData_Class.GetVersion())
        if(isFunc(IC_ActiveEffectKeyHandler_Class.GetVersion))
            this.VersionStringValues.Push("EffectKeyHandler Memory: " . IC_ActiveEffectKeyHandler_Class.GetVersion())
        this.VersionStringValues.Push(" ")
        if(isFunc(IC_SharedFunctions_Class.GetVersion))
            this.VersionStringValues.Push("SharedFunctions Version: " . IC_SharedFunctions_Class.GetVersion())
        if(isFunc(IC_ServerCalls_Class.GetVersion))
            this.VersionStringValues.Push("ServerCalls Version: " . IC_ServerCalls_Class.GetVersion())
        if(isFunc(_classLog.GetVersion))
            this.VersionStringValues.Push("Log Class Version: " . _classLog.GetVersion())
        this.VersionStringValues.Push("`nAHK Version: " . A_AhkVersion)
    }

    ShowScriptVersions()
    {
        global xyValX, AboutPointerChangeLink
        GuiControlGet, posVal, ICScriptHub:Pos, AboutLineHeightTest
        height := posValH + 1
        xyValX := xyValX + 36
        Gui, ICScriptHub:Add, Text, x%xyValX% yp+10 w0
        GUIFunctions.UseThemeTextColor()
        for k,v in this.VersionStringValues
        {
            if(InStr(v, "Imports:") AND g_SF.Memory.ReadGameVersion() != g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)
            {   
                Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% r1, % v
                GUIFunctions.UseThemeTextColor("WarningTextColor", 600) 
                Gui, ICScriptHub:Add, Text, x+6 r1, % "Warning: Does not match game version!"
                GUIFunctions.UseThemeTextColor()
                Continue
            }    
            else if(Instr(v,"Current Pointers:"))
            {
                Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% r1, % v
                Gui, ICScriptHub:Font, underline 
                GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
                Gui, ICScriptHub:Add, Text, vAboutPointerChangeLink x+6, Change
                GUIFunctions.UseThemeTextColor()
                Gui, ICScriptHub:Font, norm
                runVersionPicker := ObjBindMethod(IC_About_Component, "AboutRunPointerVersionPicker")
                GuiControl,ICScriptHub: +g, AboutPointerChangeLink, % runVersionPicker
                Continue
            }
            Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% w380 r1, % v
        }
    }

    GetEnabledAddons()
    {
        string := ""
        enabledAddons := Array()
        for k,v in AddonManagement.EnabledAddons
        {
            if(v.MostRecentVer != "" AND SH_VersionHelper.IsVersionNewer(v.MostRecentVer, v.Version))
                string := v.Name . " Version: " . v.Version . "`t -- Out of Date (" . v.MostRecentVer . ") -- `n" 
            else
                string := v.Name . " Version: " . v.Version . "`n"
            
            enabledAddons.Push(string)
        }
        this.EnabledAddonsValues := enabledAddons
        return enabledAddons
    }

    ShowEnabledAddons()
    {
        global xyValX
        GuiControlGet, posVal, ICScriptHub:Pos, AboutLineHeightTest
        height := posValH + 1
        xyValX := xyValX + 20
        Gui, ICScriptHub:Add, Text, x%xyValX% yp+10 w0
        GUIFunctions.UseThemeTextColor()
        for k,v in this.EnabledAddonsValues
        {
            if(InStr(v, "Out of Date"))
            {   
                GUIFunctions.UseThemeTextColor("WarningTextColor", 600) 
                Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% w400 r1, % v
                GUIFunctions.UseThemeTextColor()
                Continue
            }    
            Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% w400 r1, % v
        }
    }

    AboutRunPointerVersionPicker()
    {
        MsgBox, Closing Script Hub and running the pointer version picker.
        versionPickerLoc := A_LineFile . "\..\..\IC_Core\IC_VersionPicker.ahk"
        Run, %versionPickerLoc%
        ExitApp
    }
}
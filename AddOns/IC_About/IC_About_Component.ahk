; Add tab to the GUI
GUIFunctions.AddTab("About")

Gui, ICScriptHub:Tab, About
IC_About_Component.Build()

class IC_About_Component
{
    EnabledAddonsValues := Array()
    VersionStringValues := Array()
    ServerCaller := ""

    Build()
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
        IC_About_Component.BuildScriptVersions()

        IC_About_Component.GetEnabledAddons()
        AboutAddonGroupBoxHeight := (IC_About_Component.EnabledAddonsValues.Count() + 2) * (xyValH+1) + 15
        GuiControlGet, xyVal, ICScriptHub:Pos, AboutVersionGroupBox
        xyValX += 0
        xyValY += (aboutGroupBoxHeight + 15)
        Gui, ICScriptHub:Add, GroupBox, x%xyValX% y%xyValY% w425 h%AboutAddonGroupBoxHeight% vAboutAddonGroupBox, % "Enabled Addons [" . (g_UserSettings["CheckForUpdates"] ? "ON" : "OFF") . "]: "
        IC_About_Component.AddAddonToggle()
        IC_About_Component.BuildEnabledAddons()
    }

    AddAddonToggle()
    {
        global
        local xLoc := xyValX + GUIFunctions.GetControlSizeFromBasicText("Enabled Addons [OFF]") + 10
        Gui, ICScriptHub:Font, underline 
        GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
        Gui, ICScriptHub:Add, Text, vAboutToggleAddonCheck x%xLoc% y%xyValY%, % "Toggle "
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Font, norm
        toggleAddonCheckFnc := ObjBindMethod(IC_About_Component, "ToggleAddonCheck")
        GuiControl,ICScriptHub: +g, AboutToggleAddonCheck, % toggleAddonCheckFnc
    }

    ; Refreshes game version and compares to imports. Updates UI Accordingly.
    Refresh()
    {
        global AboutComponentImportsWarning, AboutComponentGameVersion, g_SF, _MemoryManager, g_ImportsGameVersion64, g_ImportsGameVersionPostFix64
        ; local gameVersionaArch, gameVersion, xyVal, xLoc, xyValX, xyValY, xyValH, xyValW
        g_SF.Memory.OpenProcessReader()
        gameVersionaArch := _MemoryManager.is64bit ? " (64 bit)" : " (32 bit)"
        gameVersion := "Idle Champions Game Version: " . (g_SF.Memory.ReadGameVersion() == "" ? " -- Game not found on Script Hub load. --" : g_SF.Memory.ReadGameVersion() . gameVersionaArch)
        GuiControl,ICScriptHub:, AboutComponentGameVersion, % gameVersion
        GuiControl,ICScriptHub:, AboutComponentImportsWarning, % " "
        if(g_SF.Memory.ReadGameVersion() != g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)
            GuiControl,ICScriptHub:, AboutComponentImportsWarning, % "Warning: Does not match game version!"
        width := GUIFunctions.GetControlSizeFromBasicText(gameVersion)
        GuiControlGet, xyVal, ICScriptHub:Pos, AboutComponentGameVersion
        xLoc := xyValX + width
        GuiControl,ICScriptHub:Move, AboutComponentRefreshLink, % "x"xLoc
        ; Controls like to disappear sometimes when moved, so hide/show to refresh their view.
        GuiControl,ICScriptHub:Hide, AboutComponentGameVersion
        GuiControl,ICScriptHub:Show, AboutComponentGameVersion
        GuiControl,ICScriptHub:Hide, AboutComponentRefreshLink
        GuiControl,ICScriptHub:Show, AboutComponentRefreshLink
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
        local gameLocationString := "Game Location Setting: "
        if(InStr(g_UserSettings[ "InstallPath" ], "com.epicgames.launcher:"))
            gameLocationString .= """epicgames.launcher"" (EGS)"
        else if(InStr(g_UserSettings[ "InstallPath" ], "legendary.exe"))
            gameLocationString .= """legendary.exe"" (Legendary)"
        else if(InStr(g_UserSettings[ "InstallPath" ], "heroic://"))
            gameLocationString .= """heroic://"" (Heroic)"
        else if(InStr(g_UserSettings[ "InstallPath" ], "IdleDragons.exe"))
            gameLocationString .= "IdleDragons.exe (Steam/Other)"
        else
            gameLocationString .= "(Unknown)"
        this.VersionStringValues.Push(gameLocationString)
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

    BuildScriptVersions()
    {
        global ;xyValX, AboutPointerChangeLink
        local k, v, height
        GuiControlGet, posVal, ICScriptHub:Pos, AboutLineHeightTest
        height := posValH + 1
        xyValX := xyValX + 36
        Gui, ICScriptHub:Add, Text, x%xyValX% yp+10 w0
        GUIFunctions.UseThemeTextColor()
        for k,v in this.VersionStringValues
        {
            if(InStr(v, "Game Version:"))
            {
                Gui, ICScriptHub:Add, Text, vAboutComponentGameVersion x%xyValX% yp+%height% r1, % v
                Gui, ICScriptHub:Font, underline 
                GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
                Gui, ICScriptHub:Add, Text, x+6 vAboutComponentRefreshLink, Refresh
                GUIFunctions.UseThemeTextColor()
                Gui, ICScriptHub:Font, norm
                AboutComponentRefresh := ObjBindMethod(IC_About_Component, "Refresh")
                GuiControl,ICScriptHub: +g, AboutComponentRefreshLink, % AboutComponentRefresh
                Continue
            }
            else if(InStr(v, "Imports:") AND g_SF.Memory.ReadGameVersion() != g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)
            {   
                Gui, ICScriptHub:Add, Text, x%xyValX% yp+%height% r1, % v
                GUIFunctions.UseThemeTextColor("WarningTextColor", 600) 
                Gui, ICScriptHub:Add, Text, vAboutComponentImportsWarning x+6 r1, % "Warning: Does not match game version!"
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
            if(g_UserSettings[ "CheckForUpdates" ] == True)
                mostRecent := this.GetMostRecentVersion(v.Url)
            if(mostRecent != "" AND SH_VersionHelper.IsVersionNewer(mostRecent, v.Version))
                string := v.Name . " Version: " . v.Version . "`t -- Out of Date (" . mostRecent . ") -- `n" 
            else
                string := v.Name . " Version: " . v.Version . "`n"
            
            enabledAddons.Push(string)
        }
        this.EnabledAddonsValues := enabledAddons
        return enabledAddons
    }

    BuildEnabledAddons()
    {
        global
        GuiControlGet, posVal, ICScriptHub:Pos, AboutLineHeightTest
        local height := posValH + 1
        local k,v
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

    ToggleAddonCheck()
    {
        g_UserSettings[ "CheckForUpdates" ] := ! g_UserSettings[ "CheckForUpdates" ] 
        GuiControl,ICScriptHub:, AboutAddonGroupBox, % "Enabled Addons [" . (g_UserSettings["CheckForUpdates"] ? "ON" : "OFF") . "]: "
        GuiControl,ICScriptHub:Hide, AboutToggleAddonCheck
        GuiControl,ICScriptHub:Show, AboutToggleAddonCheck
        SaveUserSettings()
    }

    GetMostRecentVersion(remoteUrl)
    {
        if(this.ServerCaller == "")
            this.ServerCaller := new SH_ServerCalls()
        if(InStr(remoteUrl, "https://github.com"))
        {
            remoteUrl := StrReplace(remoteUrl, "https://github.com", "https://raw.githubusercontent.com")
            remoteUrl := StrReplace(remoteUrl, "/tree/", "/refs/heads/")
            remoteUrl := remoteUrl . "/Addon.json"
            addonInfo := this.ServerCaller.BasicServerCall(remoteURL) 
            return addonInfo["Version"]
        }
        else
            return ""
    }
}
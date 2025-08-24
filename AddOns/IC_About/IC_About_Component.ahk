; Add tab to the GUI
GUIFunctions.AddTab("About")

Gui, ICScriptHub:Tab, About
GUIFunctions.UseThemeTextColor()
aboutRows := 21
aboutGroupBoxHeight := aboutRows * 15
Gui, ICScriptHub:Add, Text, vAboutLineHeightTest w2,     
GuiControlGet, xyVal, ICScriptHub:Pos, AboutLineHeightTest
Gui, ICScriptHub:Add, GroupBox, xp+15 yp+15 w425 h%aboutGroupBoxHeight% vAboutVersionGroupBox, Version Info: 
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, vAboutVersionStringID xp+20 yp+25 w400 r%aboutRows%, % IC_About_Component.GetVersionString()

IC_About_Component.GetEnabledAddons()
AboutAddonGroupBoxHeight := (IC_About_Component.EnabledAddonsValues.Count() + 2) * (xyValH+1) + 15
GuiControlGet, xyVal, ICScriptHub:Pos, AboutVersionGroupBox
xyValX += 0
xyValY += (aboutGroupBoxHeight + 15)
Gui, ICScriptHub:Add, GroupBox, x%xyValX% y%xyValY% w425 h%AboutAddonGroupBoxHeight% vAboutAddonGroupBox, % "Enabled Addons [" . (g_UserSettings["CheckForUpdates"] ? "ON" : "OFF") . "]: "
IC_About_Component.ShowEnabledAddons()
; Gui, ICScriptHub:Add, Text, vAboutAddonStringID xp+20 yp+25 w400 r%AboutEnabledAddonsRows%, % AboutEnabledAddonsString

if(isFunc(g_SF.Memory.GetPointersVersion) AND isFunc(g_SF.Memory.ReadGameVersion))
{
    IC_About_Component.AddPointerLink()
}

class IC_About_Component
{
    EnabledAddonsValues := Array()
    EnabledAddonsRows := 0

    VersionStringValues := Array()
    VersionStringRows := 0

    GetVersionString()
    {
        global
        g_SF.Memory.OpenProcessReader()
        local string := ""
        string .= "Script Version: " . GetScriptHubVersion() . "`n`n"
        local gameVersionaArch := _MemoryManager.is64bit ? " (64 bit)" : " (32 bit)"
        local gameVersion := g_SF.Memory.ReadGameVersion() == "" ? " -- Game not found on Script Hub load. --" : g_SF.Memory.ReadGameVersion() . gameVersionaArch 
        if(isFunc(g_SF.Memory.ReadGameVersion))
            string .= "Idle Champions Game Version: " . gameVersion . "`n"
        if(isFunc(g_SF.Memory.GetPointersVersion))
            string .= "Current Pointers: " . (g_SF.Memory.GetPointersVersion() ? g_SF.Memory.GetPointersVersion() : " ---- ") . "`n"
        string .= "Imports Versions: " . (g_ImportsGameVersion32 == "" ? " ---- " : (g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32 )) . (g_ImportsGameVersionPlatform32 != "" ? " " : "") . g_ImportsGameVersionPlatform32 . " (32 bit), " . (g_ImportsGameVersion64 == "" ? " ---- " : (g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)) . (g_ImportsGameVersionPlatform64 != "" ? " " : "") . g_ImportsGameVersionPlatform64 . " (64 bit)`n"
        string .= "Game Location: " . (g_UserSettings[ "InstallPath" ] == "explorer.exe ""com.epicgames.launcher://apps/7e508f543b05465abe3a935960eb70ac%3A48353a502e72433298f25827e03dbff0%3A40cb42e38c0b4a14a1bb133eb3291572?action=launch&silent=true""" ? "EGS" : "Steam/Other") . "`n`n" 
        if(isFunc(g_SF.Memory.GetVersion))
            string .= "MemoryFunctions Version: " . g_SF.Memory.GetVersion() . "`n"
        if(isFunc(GameObjectStructure.GetVersion))
            string .= "GameObjectStructure Version: " . GameObjectStructure.GetVersion() . "`n"
        if(isFunc(IC_IdleGameManager_Class.GetVersion))
            string .= "IdleGameManager Memory: " . IC_IdleGameManager_Class.GetVersion() . "`n"
        if(isFunc(IC_GameSettings_Class.GetVersion))
            string .= "GameSettings Memory: " . IC_GameSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_EngineSettings_Class.GetVersion))
            string .= "EngineSettings Memory: " . IC_EngineSettings_Class.GetVersion() . "`n"
        if(isFunc(IC_CrusadersGameDataSet_Class.GetVersion))
            string .= "CrusadersGameDataSet Memory: " . IC_CrusadersGameDataSet_Class.GetVersion() . "`n"
        if(isFunc(IC_DialogManager_Class.GetVersion))
            string .= "DialogManager Memory: " . IC_DialogManager_Class.GetVersion() . "`n"
        ; if(isFunc(IC_UserStatHandler_Class.GetVersion))
        ;     string .= "UserStatHandler Memory: " . IC_UserStatHandler_Class.GetVersion() . "`n"    
        ; if(isFunc(IC_UserData_Class.GetVersion))
        ;     string .= "UserData Memory: " . IC_UserData_Class.GetVersion() . "`n"           
        if(isFunc(IC_ActiveEffectKeyHandler_Class.GetVersion))
            string .= "EffectKeyHandler Memory: " . IC_ActiveEffectKeyHandler_Class.GetVersion() . "`n`n"
        if(isFunc(IC_SharedFunctions_Class.GetVersion))
            string .= "SharedFunctions Version: " . IC_SharedFunctions_Class.GetVersion() . "`n"
        if(isFunc(IC_ServerCalls_Class.GetVersion))
            string .= "ServerCalls Version: " . IC_ServerCalls_Class.GetVersion() . "`n"
        if(isFunc(_classLog.GetVersion))
            string .= "Log Class Version: " . _classLog.GetVersion() . "`n"
        string .= "`nAHK Version: " . A_AhkVersion
        return string
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
        xyValX := xyVal - 20
    }

    AddPointerLink()
    {
        global AboutPointerChangeLink
        global AboutPointerChangeLinkText1
        global AboutPointerChangeLinkText2
        string := "Current Pointers: " . (g_SF.Memory.GetPointersVersion() ? g_SF.Memory.GetPointersVersion() : " ---- ") . "`n"
        GuiControlGet, pos, ICScriptHub:Pos, AboutVersionGroupBox
        yLocation := posY + 63
        Gui, ICScriptHub:Add, Text, vAboutPointerChangeLinkText1 Hidden, %string%
        Gui, ICScriptHub:Add, Text, vAboutPointerChangeLinkText2 Hidden x+1, .
        GuiControlGet, pos, ICScriptHub:Pos, AboutPointerChangeLinkText1
        posXStart := posX
        GuiControlGet, pos, ICScriptHub:Pos, AboutPointerChangeLinkText2
        posXEnd := posX
        xWidth := posXEnd - posXstart
        xLocation := posXStart + 5 + xWidth

        Gui, ICScriptHub:Font, underline 
        GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
        Gui, ICScriptHub:Add, Text, vAboutPointerChangeLink x%xLocation% y%yLocation% , Change
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Font, norm
        runVersionPicker := ObjBindMethod(IC_About_Component, "AboutRunPointerVersionPicker")
        GuiControl,ICScriptHub: +g, AboutPointerChangeLink, % runVersionPicker
    }

    AboutRunPointerVersionPicker()
    {
        MsgBox, Closing Script Hub and running the pointer version picker.
        versionPickerLoc := A_LineFile . "\..\..\IC_Core\IC_VersionPicker.ahk"
        Run, %versionPickerLoc%
        ExitApp
    }
}
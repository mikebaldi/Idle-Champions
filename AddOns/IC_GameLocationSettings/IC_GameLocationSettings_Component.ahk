;Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Gem Farm
GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmPlayButton
posY += 65
Gui, ICScriptHub:Add, Button, x15 y%posY% w160 vButtonOpenInstallGui, Change Game Location
OpenGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "ChangeInstallLocation_Clicked")
GuiControl,ICScriptHub: +g, ButtonOpenInstallGui, % OpenGameLocationSettingUpdate

;GUI to input a new install path.
Gui, InstallGUI:New
GUIFunctions.LoadTheme("InstallGUI")
GUIFunctions.UseThemeTextColor()
GUIFunctions.UseThemeBackgroundColor()
Gui, InstallGUI:Add, Text, x15 y+10 w250, Launch Command [Used to start the game]
Gui, InstallGUI:Add, Edit, vNewInstallPath x15 y+5 w300 r3, % g_UserSettings[ "InstallPath" ]
Gui, InstallGUI:Add, Text, x15 y+5 w250, Game Exe [Used to read game memory]
Gui, InstallGUI:Add, Edit, vNewInstallExe x15 y+5 w300 r1, % g_UserSettings[ "ExeName"]
Gui, InstallGUI:Add, Button, x15 y+15 vButtonSaveGameLocationSettings, Save and `Close
Gui, InstallGUI:Add, Button, x+15 w140 vButtonCopyGameLocationFromRunninGame, Copy From Running Game
Gui, InstallGUI:Add, Button, x+15 vButtonCancelGameLocationSettings, `Cancel
SaveGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "InstallOK_Clicked")
CancelGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "InstallCancel_Clicked")
CopyGameLocationFromExeLocation := ObjBindMethod(IC_GameLocationSettings_Component, "CopyExePath_Clicked")
GuiControl,InstallGUI: +g, ButtonSaveGameLocationSettings, % SaveGameLocationSettingUpdate
GuiControl,InstallGUI: +g, ButtonCancelGameLocationSettings, % CancelGameLocationSettingUpdate
GuiControl,InstallGUI: +g, ButtonCopyGameLocationFromRunninGame, % CopyGameLocationFromExeLocation



; Switch back to main GUI
Gui, ICScriptHub:Default

InstallGUIGuiClose()
{
    IC_GameLocationSettings_Component.InstallCancel_Clicked()
}

class IC_GameLocationSettings_Component
{
    InstallCancel_Clicked()
    {
        Gui, InstallGUI:Default
        GuiControl, InstallGUI:, NewInstallPath, % g_UserSettings[ "InstallPath" ]
        GuiControl, InstallGUI:, NewInstallExe, % g_UserSettings[ "ExeName" ]
        Gui, InstallGUI:Hide
        Gui, ICScriptHub:Default
        Gui, InstallGUI:Submit, NoHide
        Return
    }

    InstallOK_Clicked()
    {
        global
        Gui, InstallGUI:Default
        Gui, InstallGUI:Submit, NoHide
        this.HandleEndString("\309647") ; Kartridge Path
        this.HandleEndString("\IdleChampions") ; Steam/EGS Path (if not using EGS launcher)
        g_UserSettings[ "InstallPath" ] := NewInstallPath
        if( NewInstallExe == "")
            NewInstallExe := "IdleDragons.exe"
        g_UserSettings[ "ExeName"] := NewInstallExe
        g_SF.WriteObjectToJSON( A_LineFile . "\..\..\..\Settings.json", g_UserSettings )
        Gui, InstallGUI:Hide
        Gui, ICScriptHub:Default
        Return
    }

    HandleEndString(endString)
    {
        global
        local startPos := StrLen(NewInstallPath) - StrLen(endString)
        if(InStr(NewInstallPath, endString,, startPos) == startPos + 1)
        {
            NewInstallPath := NewInstallPath . "\"
            GuiControl, InstallGUI:, NewInstallPath, % NewInstallPath
        }
        if(InStr(NewInstallPath, endString,, startPos-1))
        {
            NewInstallPath := newInstallPath . (NewInstallExe ? NewInstallExe : "IdleDragons.exe")
            GuiControl, InstallGUI:, NewInstallPath, % NewInstallPath
        }
        Return
    }

    CopyExePath_Clicked()
    {
        hWnd := WinExist("ahk_exe IdleDragons.exe")
        if(!hWnd)
            hWnd := WinExist("ahk_exe " . NewInstallExe )
        WinGet, pPath, ProcessPath, % "ahk_id " hWnd
        GuiControl, InstallGUI:, NewInstallPath, % pPath
        Gui, InstallGUI:Submit, NoHide
        Return
    }

    ChangeInstallLocation_Clicked()
    {
        GuiControl, InstallGUI:, NewInstallPath, % g_UserSettings[ "InstallPath" ]
        GuiControl, InstallGUI:, NewInstallExe, % g_UserSettings[ "ExeName" ]
        Gui, InstallGUI:Submit, NoHide
        Gui, InstallGUI:Show,,Install Location
        GUIFunctions.UseThemeTitleBar("InstallGUI")
        Gui, InstallGUI:Default
        Return
    }
}
;Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Gem Farm
GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmPlayButton
posY += 65
Gui, ICScriptHub:Add, Button, x15 y%posY% w160 vButtonOpenInstallGui, Change Game Location
OpenGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "ChangeInstallLocation_Clicked")
GuiControl,ICScriptHub: +g, ButtonOpenInstallGui, % OpenGameLocationSettingUpdate

;GUI to input a new install path.
Gui, InstallGUI:New
Gui, InstallGUI:Add, Text, x15 y+10 w200, Install Path
Gui, InstallGUI:Add, Edit, vNewInstallPath x15 y+5 w300 r3, % g_UserSettings[ "InstallPath" ]
Gui, InstallGUI:Add, Text, x15 y+5 w200, Install Exe
Gui, InstallGUI:Add, Edit, vNewInstallExe x15 y+5 w300 r1, % g_UserSettings[ "ExeName"]
Gui, InstallGUI:Add, Button, x15 y+15 vButtonSaveGameLocationSettings, Save and `Close
Gui, InstallGUI:Add, Button, x+100 vButtonCancelGameLocationSettings, `Cancel
SaveGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "InstallOK_Clicked")
CancelGameLocationSettingUpdate := ObjBindMethod(IC_GameLocationSettings_Component, "InstallCancel_Clicked")
GuiControl,InstallGUI: +g, ButtonSaveGameLocationSettings, % SaveGameLocationSettingUpdate
GuiControl,InstallGUI: +g, ButtonCancelGameLocationSettings, % CancelGameLocationSettingUpdate

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
            NewInstallPath := newInstallPath . NewInstallExe
            GuiControl, InstallGUI:, NewInstallPath, % NewInstallPath
        }
    }

    ChangeInstallLocation_Clicked()
    {
        Gui, InstallGUI:Show,,Install Location
        Gui, InstallGUI:Default
        Return
    }
}
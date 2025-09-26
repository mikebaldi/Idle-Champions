class IC_BrivGemFarm_Component_StackAndStop_Class
{
    Briv_Run_Clicked()
    {
        try
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            this.UpdateStatus("Gem Farm Already Running.") 
            return
        }
        g_SF.Hwnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
        g_SF.Memory.OpenProcessReader()
        for k,v in g_BrivFarmAddonStartFunctions
            v.Call()
        scriptLocation := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Run.ahk"
        GuidCreate := ComObjCreate("Scriptlet.TypeLib")
        g_BrivFarm.GemFarmGUID := guid := GuidCreate.Guid
        size := 12
        this.SetButtonActivationText("WarningTextColor", size)
        Run, %A_AhkPath% "%scriptLocation%" "%guid%"
        this.UpdateStatus("Proceeding with farm up until stacking.")

        this.TestGameVersion()
        size := 6
        resetTextFnc := ObjBindMethod(this, "SetButtonActivationText", "DefaultTextColor", size)
        SetTimer, %resetTextFnc%, -3000
        this.StartComs()
    }
}

class IC_BrivGemFarm_Component_StackAndStop_Added_Class
{ 
    SetButtonActivationText(textColor, size)
    {
        global gBriv_Button_Status
        newTextColor := GUIFunctions.CurrentTheme[textColor]
        newTextColor := Format("{:#x}", newTextColor)
        GuiControl, ICScriptHub: +c%newTextColor%, gBriv_Button_Status,
    }
}

; Overrides IC_BrivGemFarm_Class.GemFarmPreLoopSetup()
; Overrides IC_BrivGemFarm_Class.TestEFormation()
class IC_BrivGemFarm_StackAndStop_Class extends IC_BrivGemFarm_Class
{
    ; Enables featswap after other setup settings
    StackNormal()
    {
        base.StackNormal()
        g_SF.ToggleAutoProgress( 0, false, true )
        g_SF.FallBackFromZone()
        ExitApp
    }

    ; Tests to make sure Gem Farm is properly set up before attempting to run and Briv is in E formation.
    StackOffline()
    {
        base.StackOffline()
        ExitApp
    }
}

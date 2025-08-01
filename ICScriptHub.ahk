#Requires AutoHotkey 1.1.33+ <1.2
#SingleInstance force
;put together with the help from many different people. thanks for all the help.
#HotkeyInterval 1000  ; The default value is 2000 (milliseconds).
#MaxHotkeysPerInterval 70 ; The default value is 70
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
; #Warn ALL, OutputDebug
;=======================
;Script Optimization
;=======================
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
;SetKeyDelay, 0 ; Sets the delay that will occur after each keystroke sent by Send or ControlSend. [SetKeyDelay , Delay, PressDuration, Play]
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time.
                  ; This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, Normal

CoordMode, Mouse, Client

;Modron Automation Gem Farming Script
GetScriptHubVersion()
{
    return "v4.0.1, 2025-08-01"
}

;class and methods for parsing JSON (User details sent back from a server call)
#include %A_ScriptDir%\SharedFunctions\json.ahk
;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include %A_ScriptDir%\ServerCalls\SH_ServerCalls_Includes.ahk
;logging functions
;#include *i %A_ScriptDir%\Logging\IC_Log_Class.ahk

global g_KeyMap:= {}
global g_SCKeyMap:= {}
KeyHelper.BuildVirtualKeysMap(g_KeyMap, g_SCKeyMap)
global g_ServerCall
global g_UserSettings := {}
global g_TabControlHeight := 630
global g_TabControlWidth := 430
global g_InputsSent := 0
global g_TabList := ""
global g_PlayButton := A_LineFile . "\..\Images\play-100x100.png"
global g_StopButton := A_LineFile . "\..\Images\stop-100x100.png"
global g_ConnectButton := A_LineFile . "\..\Images\connect-100x100.png"
global g_ReloadButton := A_LineFile . "\..\Images\refresh-smooth-25x25.png"
global g_SaveButton := A_LineFile . "\..\Images\save-100x100.png"
global g_GameButton := A_LineFile . "\..\Images\idledragons-25x25.png"
global g_MacroButton := A_LineFile . "\..\Images\macro-100x100.png"
global g_MouseTooltips := {}
global g_Miniscripts := {}

;Load themes
GUIFunctions.LoadTheme()
if (GUIfunctions.isDarkMode)
{
    g_ReloadButton := A_LineFile . "\..\Images\refresh-smooth-white-25x25.png"
    g_MacroButton := A_LineFile . "\..\Images\macro-dark-100x100.png"
}
;Load user settings
g_UserSettings := IC_SharedFunctions_Class.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )
;check if first run
If !IsObject( g_UserSettings )
{
    g_UserSettings := {}
    g_UserSettings[ "WriteSettings" ] := true
}
if ( g_UserSettings[ "InstallPath" ] == "" )
    g_UserSettings[ "InstallPath" ] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
if (g_UserSettings[ "ExeName"] == "")
    g_UserSettings[ "ExeName"] := "IdleDragons.exe"
if ( g_UserSettings[ "WindowXPosition" ] == "" )
    g_UserSettings[ "WindowXPosition" ] := 0
if ( g_UserSettings[ "WindowYPosition" ] == "" )
    g_UserSettings[ "WindowYPosition" ] := 0
if ( g_UserSettings[ "NoCtrlKeypress" ] == "" )
    g_UserSettings[ "NoCtrlKeypress" ] := 0
if ( g_UserSettings[ "WaitForProcessTime" ] == "" )
    g_UserSettings[ "WaitForProcessTime" ] := 0
if(g_UserSettings[ "WriteSettings" ] == true)
{
    g_UserSettings.Delete("WriteSettings")
    IC_SharedFunctions_Class.WriteObjectToJSON( A_LineFile . "\..\Settings.json" , g_UserSettings )
}


global g_SF := new SH_SharedFunctions ; includes MemoryFunctions in g_SF.Memory

;define a new gui with tabs and buttons
Gui, ICScriptHub:New
Gui, ICScriptHub:+Resize -MaximizeBox 
Gui, ICScriptHub: +HwndGUIICScriptHub
;Gui, ICScriptHub:Add, Button, x4 y5 w50 gReload_Clicked, `Reload
;Gui, ICScriptHub:Add, Button, x+20 gLaunch_Clicked, Launch IC
global g_MenuBarXPos:=4
GUIFunctions.AddButton(g_GameButton,"Launch_Clicked","LaunchClickButton")
GUIFunctions.AddButton(g_ReloadButton,"Reload_Clicked","ReloadClickButton")
GUIFunctions.AddButton(g_MacroButton, "Launch_Macro_Clicked", "LaunchMacroClickButton")

GUIFunctions.UseThemeTextColor()
; Needed to add tabs
Gui, ICScriptHub:Add, Tab3, x5 y32 w%g_TabControlWidth%+40 h%g_TabControlHeight%+40 vModronTabControl, %g_TabList%
; Set specific tab ordering for prioritized scripts.

GuiControl, Move, ICScriptHub:ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
GUIFunctions.UseThemeBackgroundColor()
Gui, ICScriptHub:Show, %  "x" . g_UserSettings[ "WindowXPosition" ] " y" . g_UserSettings[ "WindowYPosition" ] . " w" . g_TabControlWidth+5 . " h" . g_TabControlHeight, % "IC Script Hub" . (g_UserSettings[ "WindowTitle" ] ? (" - " .  g_UserSettings[ "WindowTitle" ]) : "") . "  (Loading...)"
GUIFunctions.UseThemeTitleBar("ICScriptHub")
;WinSet, Style, -0xC00000, A  ; Remove the active window's title bar (WS_CAPTION).

Reload_Clicked()
{
    Reload
    return
}

Launch_Clicked()
{
    programLoc := g_UserSettings[ "InstallPath" ]
    try
    {
        Run, %programLoc%
    }
    catch
    {
        MsgBox, 48, Unable to launch game, `nVerify the game location is set properly by enabling the Game Location Settings addon, clicking Change Game Location on the Briv Gem Farm tab, and ensuring the launch command is set properly.
    }
    Process, Exist, % g_UserSettings[ "ExeName"]
    g_SF.PID := ErrorLevel
}

Launch_Macro_Clicked()
{
    macroRecLoc :=  A_LineFile . "\..\SharedFunctions\SH_MacroRecorder.ahk"
    try
    {
        Run, %A_AhkPath% /r "%macroRecLoc%"
    }
    catch
    {
        MsgBox, 48, Unable to launch Macro Recorder, `nThere was a problem launching the Macro Recorder
    }
}

ICScriptHubGuiClose()
{
    MsgBox 4,, Are you sure you want to `exit?
    IfMsgBox Yes
    {
        MiniScriptWarning()
        ExitApp
    }
    IfMsgBox No
        return True
}

ICScriptHubGuiSize(GuiHwnd, EventInfo, Width, Height)
{
    GuiControl, Move, ModronTabControl, % "w" Width - 20 "h" Height - 40
    GuiControl, Move, MemoryFunctionsViewID, % "w" Width - 40 "h" Height - 120
    GuiControl, Move, InventoryViewID, % "w" Width - 40 "h" Height - 170
}
; ToolTip Test
OnMessage(0x200, "CheckControlForTooltip")
; Creates tooltips for various controls in Script Hub.
BuildToolTips()
{
    GUIFunctions.AddToolTip("LaunchClickButton", "Launch Idle Champions")
    GUIFunctions.AddToolTip("ReloadClickButton", "Reload Script Hub")
    GUIFunctions.AddToolTip("LaunchMacroClickButton", "Launch Macro Recorder")
}

; Shows a tooltip if the control with mouseover has a tooltip associated with it.
CheckControlForTooltip()
{
        MouseGetPos,,,VarWin, VarControl
        varTTLoc := VarWin . VarControl
        if(varTTLoc)
            ToolTip % g_MouseToolTips[varTTLoc]
        else
            ToolTip
        SetTimer, HideToolTip, -3000
}

HideToolTip()
{
    ToolTip
}

;#include %A_ScriptDir%\SharedFunctions\Windrag.ahk
; Shared Functions
#include %A_ScriptDir%\SharedFunctions\SH_SharedFunctions.ahk
#include %A_ScriptDir%\SharedFunctions\SH_ArrFnc.ahk
#include %A_ScriptDir%\SharedFunctions\SH_KeyHelper.ahk
#include %A_ScriptDir%\SharedFunctions\SH_GUIFunctions.ahk
#include %A_ScriptDir%\SharedFunctions\SH_UpdateClass.ahk
#include *i %A_ScriptDir%\AddOns\AddOnsIncluded.ahk

;#IfWinActive ahk_exe AutoHotkeyU64.exe
;!LButton::WindowMouseDragMove()
;^LButton::WindowMouseDragMove()

BuildToolTips()
if(IsObject(AddonManagement))
    AddonManagement.BuildToolTips()

Gui, ICScriptHub:Show,, % "IC Script Hub" . (g_UserSettings[ "WindowTitle" ] ? (" - " .  g_UserSettings[ "WindowTitle" ]) : "")

StopMiniscripts()
{
    for k,v in g_Miniscripts
    {
        try
        {
            SharedRunData := ComObjActive(k)
            SharedRunData.Close()
        }
    }
}

CountRunningMiniscripts()
{
    objectCount := 0
    for k,v in g_Miniscripts
    {
        try
        {
            SharedRunData := ComObjActive(k)
            objectCount += 1
        }
    }
    return objectCount
}

MiniScriptWarning()
{
    if(CountRunningMiniscripts())
    {
        MsgBox 4,, There are still Miniscripts running in the baackground. Do you wish to close them?
        IfMsgBox Yes
        {
            StopMiniscripts()
            ExitApp
        }
        IfMsgBox No
            return True
    }
}
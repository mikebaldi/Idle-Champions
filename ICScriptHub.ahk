#SingleInstance force
;put together with the help from many different people. thanks for all the help.
#HotkeyInterval 1000  ; The default value is 2000 (milliseconds).
#MaxHotkeysPerInterval 70 ; The default value is 70
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
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
Process, Priority,, High

CoordMode, Mouse, Client


;Modron Automation Gem Farming Script
GetModronGUIVersion()
{
    return "v3.3, 01/20/2022"
}

;class and methods for parsing JSON (User details sent back from a server call)
#include %A_ScriptDir%\SharedFunctions\json.ahk
;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include %A_ScriptDir%\ServerCalls\IC_ServerCalls_Class.ahk
;logging functions
#include %A_ScriptDir%\Logging\IC_Log_Class.ahk

global g_KeyMap := KeyHelper.BuildVirtualKeysMap()
global g_ServerCall
global g_UserSettings := {}
global g_TabControlHeight := 630
global g_TabControlWidth := 430
global g_SF := new IC_SharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
global g_InputsSent := 0
global g_TabList := ""
global g_CustomColor := 0x333333
global g_isDarkMode := false
global g_PlayButton := A_LineFile . "\..\Images\play-100x100.png"
global g_StopButton := A_LineFile . "\..\Images\stop-100x100.png"
global g_ConnectButton := A_LineFile . "\..\Images\connect-100x100.png"
global g_ReloadButton := A_LineFile . "\..\Images\refresh-smooth-25x25.png"
global g_SaveButton := A_LineFile . "\..\Images\save-100x100.png"
global g_GameButton := A_LineFile . "\..\Images\idledragons-25x25.png"
global g_MouseTooltips := {}
if (g_isDarkMode)
    g_ReloadButton := A_LineFile . "\..\Images\refresh-smooth-white-25x25.png"

;Load user settings
g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )

;check if first run
If !IsObject( g_UserSettings )
{
    g_UserSettings := {}
    g_UserSettings[ "ExeName"] := "IdleDragons.exe"
    g_UserSettings[ "WriteSettings" ] := true
}
if ( g_UserSettings[ "InstallPath" ] == "" )
    g_UserSettings[ "InstallPath" ] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
if ( g_UserSettings[ "WindowXPositon" ] == "" )
    g_UserSettings[ "WindowXPositon" ] := 0
if ( g_UserSettings[ "WindowYPositon" ] == "" )
    g_UserSettings[ "WindowYPositon" ] := 0
if ( g_UserSettings[ "NoCtrlKeypress" ] == "" )
    g_UserSettings[ "NoCtrlKeypress" ] := 0
if(g_UserSettings[ "WriteSettings" ] := true)
{
    g_UserSettings.Delete("WriteSettings")
    g_SF.WriteObjectToJSON( A_LineFile . "\..\Settings.json" , g_UserSettings )
}

;define a new gui with tabs and buttons
Gui, ICScriptHub:New
Gui, ICScriptHub:+Resize -MaximizeBox

global g_MenuBarXPos:=4
GUIFunctions.AddButton(g_GameButton,"Launch_Clicked","LaunchClickButton","Launch Idle Champions")
GUIFunctions.AddButton(g_ReloadButton,"Reload_Clicked","ReloadClickButton","Reload Script Hub")

if(g_isDarkMode)
    Gui, ICScriptHub:Font, cSilver ;
; Needed to add tabs
Gui, ICScriptHub:Add, Tab3, x5 y32 w%TabControlWidth%+40 h%TabControlHeight%+40 vModronTabControl, %g_TabList%
; Set specific tab ordering for prioritized scripts.

GuiControl, Move, ICScriptHub:ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
if(g_isDarkMode)
    Gui, ICScriptHub:Color, % g_CustomColor
Gui, ICScriptHub:Show, %  "x" . g_UserSettings[ "WindowXPositon" ] " y" . g_UserSettings[ "WindowYPositon" ] . " w" . g_TabControlWidth+5 . " h" . g_TabControlHeight, IC Script Hub
;WinSet, Style, -0xC00000, A  ; Remove the active window's title bar (WS_CAPTION).

Reload_Clicked()
{
    Reload
    return
}

Launch_Clicked()
{
    programLoc := g_UserSettings[ "InstallPath" ] . g_UserSettings ["ExeName" ]
    Run, %programLoc%
    Process, Exist, IdleDragons.exe
    g_SF.PID := ErrorLevel
}

ICScriptHubGuiClose()
{
    MsgBox 4,, Are you sure you want to `exit?
    IfMsgBox Yes
    {
        ExitApp
    }
    IfMsgBox No
    return True
}

; ToolTip Test
OnMessage(0x200, "CheckControlForTooltip")

; Shows a tooltip if the control with mouseover has a tooltip associated with it.
CheckControlForTooltip()
{
    MouseGetPos,,,, VarControl
    Message := g_MouseToolTips[VarControl]
    ToolTip % Message
}

#include *i %A_ScriptDir%\AddOns\AddOnsIncluded.ahk
;#include %A_ScriptDir%\SharedFunctions\Windrag.ahk
; Shared Functions
#include %A_ScriptDir%\SharedFunctions\IC_SharedFunctions_Class.ahk
#include %A_ScriptDir%\SharedFunctions\IC_ArrayFunctions_Class.ahk
#include %A_ScriptDir%\SharedFunctions\IC_KeyHelper_Class.ahk
#include %A_ScriptDir%\SharedFunctions\IC_GUIFunctions_Class.ahk

;#IfWinActive ahk_exe AutoHotkeyU64.exe
;!LButton::WindowMouseDragMove()
;^LButton::WindowMouseDragMove()

;BuildToolTips
GUIFunctions.GenerateToolTips()


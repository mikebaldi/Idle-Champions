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
    return "v3.1, 01/02/2022"
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
global g_TabList := "|"
global g_CustomColor := 0x333333
global g_isDarkMode := false
global g_PlayButton := A_LineFile . "\..\Images\play-100x100.png"
global g_StopButton := A_LineFile . "\..\Images\stop-100x100.png"
global g_ConnectButton := A_LineFile . "\..\Images\connect-100x100.png"
global g_ReloadButton := A_LineFile . "\..\Images\refresh-smooth-25x25.png"
global g_SaveButton := A_LineFile . "\..\Images\save-100x100.png"
global g_GameButton := A_LineFile . "\..\Images\idledragons-25x25.png"
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
;Gui, ICScriptHub:Add, Button, x4 y5 w50 gReload_Clicked, `Reload
;Gui, ICScriptHub:Add, Button, x+20 gLaunch_Clicked, Launch IC
Gui, ICScriptHub:Add, Picture, x4 y5 h25 w25 gLaunch_Clicked, %g_GameButton%
Gui, ICScriptHub:Add, Picture, x+5 h25 w25 gReload_Clicked, %g_ReloadButton%
; TODO: Fix this hack so addons do it themselves (if possible)
if(g_isDarkMode)
    Gui, ICScriptHub:Font, cSilver ;
if(IsObject(IC_BrivGemFarm_Class))
    Gui, ICScriptHub:Add, Tab3, x5 y32 w%TabControlWidth%+40 h%TabControlHeight%+40 vModronTabControl, Briv Gem Farm|Stats|
else
    Gui, ICScriptHub:Add, Tab3, x5 y32 w%TabControlWidth%+40 h%TabControlHeight%+40 vModronTabControl, Stats|

Gui, ICScriptHub:Tab, Stats
g_TabList .= "Stats|"
global g_LeftAlign
global g_DownAlign
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, x+0 y+15 w450 h130 vCurrentRunGroupID, Current `Run:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vLoopAlignID xp+15 yp+25 , `Loop:
GuiControlGet, pos, ICScriptHub:Pos, LoopAlignID
g_LeftAlign := posX
Gui, ICScriptHub:Add, Text, vLoopID x+2 w400, Not Started
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current Area Time (s):
Gui, ICScriptHub:Add, Text, vdtCurrentLevelTimeID x+2 w200, % dtCurrentLevelTime
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current `Run Time (min):
Gui, ICScriptHub:Add, Text, vdtCurrentRunTimeID x+2 w50, % dtCurrentRunTime

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, SB Stack `Count:
Gui, ICScriptHub:Add, Text, vg_StackCountSBID x+2 w100, % g_StackCountSB
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Haste Stack `Count:
Gui, ICScriptHub:Add, Text, vg_StackCountHID x+2 w100, % g_StackCountH

; Gui, ICScriptHub:Add, Text, x15 y+10, Inputs Sent:
; Gui, ICScriptHub:Add, Text, vg_InputsSentID x+2 w50, % g_InputsSent
GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
g_DownAlign := posY + posH -5
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, x6 y%g_DownAlign% w450 h350 vOnceRunGroupID, Updated Once Per Full Run:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, Previous Run Time (min):
Gui, ICScriptHub:Add, Text, vPrevRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Fastest Run Time (min):
Gui, ICScriptHub:Add, Text, vFastRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Slowest Run Time (min):
Gui, ICScriptHub:Add, Text, vSlowRunTimeID x+2 w50,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Run `Count:
Gui, ICScriptHub:Add, Text, vTotalRunCountID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Total Run Time (hr):
Gui, ICScriptHub:Add, Text, vdtTotalTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Avg. Run Time (min):
Gui, ICScriptHub:Add, Text, vAvgRunTimeID x+2 w50,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Fail Run Time (min):
Gui, ICScriptHub:Add, Text, vFailRunTimeID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stack Conversion:
Gui, ICScriptHub:Add, Text, vFailedStackConvID x+2 w50,
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stacking:
Gui, ICScriptHub:Add, Text, vFailedStackingID x+2 w50,

Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Silvers Gained:
Gui, ICScriptHub:Add, Text, vSilversPurchasedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Silvers Opened:
Gui, ICScriptHub:Add, Text, vSilversOpenedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Gained:
Gui, ICScriptHub:Add, Text, vGoldsPurchasedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Opened:
Gui, ICScriptHub:Add, Text, vGoldsOpenedID x+2 w200, 0
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Shinies Found:
Gui, ICScriptHub:Add, Text, vShiniesID x+2 w200, 0

Gui, ICScriptHub:Font, cBlue w700
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Bosses per hour:
Gui, ICScriptHub:Add, Text, vbossesPhrID x+2 w50, % bossesPhr

Gui, ICScriptHub:Font, cGreen
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Gems:
Gui, ICScriptHub:Add, Text, vGemsTotalID x+2 w50, % GemsTotal
Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Gems per hour:
Gui, ICScriptHub:Add, Text, vGemsPhrID x+2 w200, % GemsPhr
if(g_isDarkMode)
    Gui, ICScriptHub:Font, cSilver w400
else
    Gui, ICScriptHub:Font, cDefault w400
GuiControlGet, pos, ICScriptHub:Pos, OnceRunGroupID
g_DownAlign := g_DownAlign + posH -5

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
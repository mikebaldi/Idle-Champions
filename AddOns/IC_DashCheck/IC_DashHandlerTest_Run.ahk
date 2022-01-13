#SingleInstance force
;put together with the help from many different people. thanks for all the help.

;=======================
;Script Optimization
;=======================
#HotkeyInterval 1000  ; The default value is 2000 (milliseconds).
#MaxHotkeysPerInterval 70 ; The default value is 70
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
;SetKeyDelay, 0 ; Sets the delay that will occur after each keystroke sent by Send or ControlSend. [SetKeyDelay , Delay, PressDuration, Play]
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time.
                  ; This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, High
CoordMode, Mouse, Client

;Load user settings
global g_SF := new IC_SharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
global g_DashHandler := new TimeScaleWhenNotAttackedHandler
global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_KeyMap := KeyHelper.BuildVirtualKeysMap()
global g_ServerCall
global g_InputsSent := 0
global g_SaveHelper := new IC_SaveHelper_Class

#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_SharedFunctions_Class.ahk

;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_SaveHelper_Class.ahk
#include *i %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

;Gui, DashHandler:New, -LabelMain +hWndhMainWnd -Resize
Gui, DashHandler:New, -Resize
Gui, DashHandler:+Resize -MaximizeBox
Gui, DashHandler:Font, w700
Gui, DashHandler:Add, Text, x15 y15 w400, This script only works on Steam.
Gui, DashHandler:Font, w400
Gui, DashHandler:Add, Text, vBaseAddress x15 y+15 w400,
Gui, DashHandler:Add, Text, vDictIndex x15 y+5 w400,
Gui, DashHandler:Add, Text, vInitialized x15 y+5 w400,
Gui, DashHandler:Add, Text, vActive x15 y+5 w400,
Gui, DashHandler:Add, Text, vScaleActive x15 y+5 w400,
Gui, DashHandler:Add, Text, vEffectTime x15 y+5 w400,
Gui, DashHandler:Add, Text, vInfo x15 y+15 w400, Press F10 to end this script.

 Gui, DashHandler:Show

g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
g_SF.Memory.OpenProcessReader()
init := g_DashHandler.Initialize()

loop
{
    if (!g_SF.SafetyCheck())
        init := g_DashHandler.Initialize()
    
    if (init == -1)
    {
        g_SF.LevelChampByID(47, 120,, "")
        init := g_DashHandler.Initialize()
    }

    if (!g_DashHandler.IsBaseAddressCorrect())
        init := g_DashHandler.Initialize()

    GuiControl, DashHandler:, BaseAddress, % "Handler Address: " . g_DashHandler.BaseAddress
    GuiControl, DashHandler:, DictIndex, % "Dictionary Index: " . g_DashHandler.DictIndex
    GuiControl, DashHandler:, Initialized, % "Initialized: " . g_DashHandler.Initialized
    GuiControl, DashHandler:, Active, % "Active Property: " . g_DashHandler.GetActiveValue()
    GuiControl, DashHandler:, ScaleActive, % "ScaleActive Property: " . g_DashHandler.GetScaleActiveValue()
    GuiControl, DashHandler:, EffectTime, % "EffectTime Property: " . g_DashHandler.GetEffectTimeValue()
    sleep, 250
}

F10::
ExitApp
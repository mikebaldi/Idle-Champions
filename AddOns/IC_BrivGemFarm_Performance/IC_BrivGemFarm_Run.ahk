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
global g_SF := new IC_BrivSharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
global g_BrivUserSettings 
global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_BrivGemFarm := new IC_BrivGemFarm_Class
global g_KeyMap := KeyHelper.BuildVirtualKeysMap()
global g_ServerCall
global g_InputsSent := 0
global g_SaveHelper := new IC_SaveHelper_Class

#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_SharedFunctions_Class.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_SaveHelper_Class.ahk


;check if first run
If !IsObject( g_UserSettings )
{
    g_UserSettings := {}
    if ( g_UserSettings[ "InstallPath" ] == "" )
        g_UserSettings[ "InstallPath" ] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
    g_UserSettings[ "ExeName"] := "IdleDragons.exe"
    g_SF.WriteObjectToJSON( A_LineFile . "\..\..\..\Settings.json", g_UserSettings )
}

Menu Tray, Icon, shell32.dll, -51380
;Gui, BrivPerformanceGemFarm:New, -LabelMain +hWndhMainWnd -Resize
Gui, BrivPerformanceGemFarm:New, -Resize
Gui, BrivPerformanceGemFarm:+Resize -MaximizeBox
Gui BrivPerformanceGemFarm:Add, GroupBox, w400 h315, BrivFarm Settings: 
Gui BrivPerformanceGemFarm:Add, ListView, xp+15 yp+25 w375 h270 vBrivFarmSettingsID -HDR, Setting|Value
LoadBrivGemFarmSettings() ; load settings file.
Gui, BrivPerformanceGemFarm:Show,% "x" . g_BrivUserSettings[ "WindowXPositon" ] " y" . g_BrivUserSettings[ "WindowYPositon" ], Running Gem Farm...

ReloadBrivGemFarmSettingsDisplay()
{
    ReloadBrivGemFarmSettings()
    Gui, ListView, BrivFarmSettingsID
    LV_Delete()
    LV_Add(, "Using Fkeys? ", g_BrivUserSettings[ "Fkeys" ] ? "Yes" : "No")
    LV_Add(, "Avoid Bosses? ", g_BrivUserSettings[ "AvoidBosses" ] ? "Yes" : "No")
    LV_Add(, "Stack Fail Recovery? ", g_BrivUserSettings[ "StackFailRecovery" ] ? "Yes" : "No")
    LV_Add(, "Stack Zone: ", g_BrivUserSettings[ "StackZone" ])
    LV_Add(, "Min Stack Zone w/ can't reach Stack Zone: ", g_BrivUserSettings[ "MinStackZone" ])
    LV_Add(, "Target Haste stacks: ", g_BrivUserSettings[ "TargetStacks" ])
    LV_Add(, "Stacking Restart wait time: ", g_BrivUserSettings[ "RestartStackTime" ])
    LV_Add(, "Dash Wait Time: ", g_BrivUserSettings[ "DashSleepTime" ])
    LV_Add(, "Briv Swap Sleep time: ", g_BrivUserSettings[ "SwapSleep" ])
    LV_Add(, "Buy and open Chests? ", g_BrivUserSettings[ "DoChests" ] ? "Yes" : "No")
    if(g_BrivUserSettings[ "DoChests" ])
    {
        LV_Add(, "Buy Silver? ", g_BrivUserSettings[ "BuySilvers" ] ? "Yes" : "No")
        LV_Add(, "Buy Gold? ", g_BrivUserSettings[ "BuyGolds" ] ? "Yes" : "No")
        LV_Add(, "Open Silver? ", g_BrivUserSettings[ "OpenSilvers" ] ? "Yes" : "No")
        LV_Add(, "Open Gold? ", g_BrivUserSettings[ "OpenGolds" ] ? "Yes" : "No")
        LV_Add(, "Required Gems to Buy: " g_BrivUserSettings[ "MinGemCount" ])
    }
    LV_ModifyCol()
}

ReloadBrivGemFarmSettings()
{
    g_BrivUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    If !IsObject( g_BrivUserSettings )
    {
        g_BrivUserSettings := {}
        g_BrivUserSettings["WriteSettings"] := true
    }
    if ( g_BrivUserSettings[ "Fkeys" ] == "" )
        g_BrivUserSettings[ "Fkeys" ] := 1
    Fkeys := g_BrivUserSettings[ "Fkeys" ]
    if ( g_BrivUserSettings[ "AvoidBosses" ] == "" )
        g_BrivUserSettings[ "AvoidBosses" ] := 0
    AvoidBosses := g_BrivUserSettings[ "AvoidBosses" ]
    if ( g_BrivUserSettings[ "StackFailRecovery" ] == "" )
        g_BrivUserSettings[ "StackFailRecovery" ] := 1
    StackFailRecovery := g_BrivUserSettings[ "StackFailRecovery" ]
    if ( g_BrivUserSettings[ "StackZone" ] == "" )
        g_BrivUserSettings[ "StackZone" ] := 2000
    if (g_BrivUserSettings[ "TargetStacks" ] == "")
        g_BrivUserSettings[ "TargetStacks" ] := 4000
    if ( g_BrivUserSettings[ "RestartStackTime" ] == "" )
        g_BrivUserSettings[ "RestartStackTime" ] := 12000
    if ( g_BrivUserSettings[ "DashSleepTime" ] == "" )
        g_BrivUserSettings[ "DashSleepTime" ] := 60000
    if ( g_BrivUserSettings[ "SwapSleep" ] == "" )
        g_BrivUserSettings[ "SwapSleep" ] := 2500
    if ( g_BrivUserSettings[ "DoChests" ] == "" )
        g_BrivUserSettings[ "DoChests" ] := 1
    if ( g_BrivUserSettings[ "BuySilvers" ] == "" )
        g_BrivUserSettings[ "BuySilvers" ] := 1
    if ( g_BrivUserSettings[ "BuyGolds" ] == "" )
        g_BrivUserSettings[ "BuyGolds" ] := 0
    if ( g_BrivUserSettings[ "OpenSilvers" ] == "" )
        g_BrivUserSettings[ "OpenSilvers" ] := 1
    if ( g_BrivUserSettings[ "OpenGolds" ] == "" )
        g_BrivUserSettings[ "OpenGolds" ] := 1
    if ( g_BrivUserSettings[ "MinGemCount" ] == "" )
        g_BrivUserSettings[ "MinGemCount" ] := 0
    if (g_BrivUserSettings[ "DashWaitBuffer" ] == "")    
        g_BrivUserSettings[ "DashWaitBuffer" ] := 0
    if ( g_BrivUserSettings[ "WindowXPositon" ] == "" )
        g_BrivUserSettings[ "WindowXPositon" ] := 0
    if ( g_BrivUserSettings[ "WindowYPositon" ] == "" )
        g_BrivUserSettings[ "WindowYPositon" ] := 0
    if(g_BrivUserSettings["WriteSettings"] := true)
    {
        g_BrivUserSettings.Delete("WriteSettings")
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )   
    }     
}


LoadBrivGemFarmSettings()
{
    ReloadBrivGemFarmSettingsDisplay()
    If !IsObject( g_BrivUserSettings )
    {
        g_BrivUserSettings := {}
        g_SF.WriteObjectToJSON( A_LineFile . "\..\BrivGemFarmSettings.json" , g_BrivUserSettings )
    }
}
ObjRegisterActive(g_SharedData, "{416ABC15-9EFC-400C-8123-D7D8778A2103}")
; g_SharedData.ReloadSettingsFunc := Func("LoadBrivGemFarmSettings")

g_BrivGemFarm.GemFarm()

OnExit(ComObjectRevoke())

ComObjectRevoke()
{
    ObjRegisterActive(g_SharedData, "")
    ExitApp
}

$SC045::
Pause
return 

BrivPerformanceGemFarmGuiClose()
{
    ComObjectRevoke()
    ExitApp
}

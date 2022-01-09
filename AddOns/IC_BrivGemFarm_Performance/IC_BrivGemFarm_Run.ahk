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
#include *i %A_LineFile%\..\IC_BrivGemFarm_Mods.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_Settings.ahk

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
Gui BrivPerformanceGemFarm:Add, GroupBox, w300 h315, BrivFarm Settings: 
Gui BrivPerformanceGemFarm:Add, ListView, xp+15 yp+25 w270 h270 vBrivFarmSettingsID -HDR, Setting|Value

ReloadBrivGemFarmSettingsDisplay() ; load settings file.

if ( !g_BrivUserSettings[ "HiddenFarmWindow" ]){
    if (g_BrivUserSettings["Autoposition"]="Right"){
        if(WinExist("ahk_exe IdleDragons.exe")){
            WinGetPos, xpos, ypos, width,, ahk_exe IdleDragons.exe
        }
        else{
            WinGetPos, xpos, ypos, width, height, IC Script Hub
        }
        xpos := xpos + width - 10
        Gui, BrivPerformanceGemFarm:Show, X%xpos% Y%ypos% , Running Gem Farm...
    }
    else if (g_BrivUserSettings["Autoposition"]="Left"){
        if(WinExist("ahk_exe IdleDragons.exe")){
            WinGetPos, xpos, ypos, width,, ahk_exe IdleDragons.exe
        }
        else{
            WinGetPos, xpos, ypos, width, height, IC Script Hub
        }
        xpos := xpos - 310 ; width of 300 with extra 10 px
        Gui, BrivPerformanceGemFarm:Show, X%xpos% Y%ypos% , Running Gem Farm...
    }
    else {
        Gui, BrivPerformanceGemFarm:Show,% "x" . g_BrivUserSettings[ "WindowXPositon" ] " y" . g_BrivUserSettings[ "WindowYPositon" ], Running Gem Farm...
    }
}
    
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

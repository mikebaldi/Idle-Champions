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

#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SharedFunctions_Class.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SaveHelper_Class.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_Settings.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_GUIFunctions.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk

;Load user settings
global g_SF := new IC_BrivSharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
global g_BrivUserSettings 
global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_BrivGemFarm := new IC_BrivGemFarm_Class
global g_KeyMap:= {}
global g_SCKeyMap:= {}
KeyHelper.BuildVirtualKeysMap(g_KeyMap, g_SCKeyMap)
global g_ServerCall
global g_InputsSent := 0
global g_SaveHelper := new IC_SaveHelper_Class
global g_BrivUserSettingsFromAddons := {}

#include *i %A_LineFile%\..\IC_BrivGemFarm_Mods.ahk

;check if first run
If !IsObject( g_UserSettings )
{
    g_UserSettings := {}
    if ( g_UserSettings[ "InstallPath" ] == "" )
        g_UserSettings[ "InstallPath" ] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
    g_UserSettings[ "ExeName"] := "IdleDragons.exe"
    g_SF.WriteObjectToJSON( A_LineFile . "\..\..\..\Settings.json", g_UserSettings )
}

global isAdvancedBrivSettings := false
try
{
    if(A_OSVersion >= "10." && A_OSVersion < "W")
        Menu Tray, Icon, shell32.dll, -51380
    else
        Menu, Tray, Icon, shell32.dll, 138
}

; Update SharedData class from SharedFunctions to have extra steps when closing the script.
class IC_BrivGemFarmRun_SharedData_Class
{
    Close()
    {
        if (g_SF.Memory.ReadCurrentZone() == "") ; Invalid game state
            ExitApp
        g_SF.WaitForTransition()
        g_SF.FallBackFromZone()
        g_SF.ToggleAutoProgress(false, false, true)
        ExitApp
    }
}
SH_UpdateClass.UpdateClassFunctions(g_SharedData, IC_BrivGemFarmRun_SharedData_Class)

;Gui, BrivPerformanceGemFarm:New, -LabelMain +hWndhMainWnd -Resize
Gui, BrivPerformanceGemFarm:New, -Resize
GUIFunctions.LoadTheme("BrivPerformanceGemFarm")
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()
Gui, BrivPerformanceGemFarm:+Resize -MaximizeBox
Gui BrivPerformanceGemFarm:Add, GroupBox, w400 h315, BrivFarm Settings: 
Gui BrivPerformanceGemFarm:Add, ListView, xp+15 yp+25 w375 h270 vBrivFarmSettingsID -HDR, Setting|Value
GUIFunctions.UseThemeListViewBackgroundColor("BrivFarmSettingsID")
Gui, BrivPerformanceGemFarm:Add, Checkbox, vAdvancedBrivSettingsCheck Checked%isAdvancedBrivSettings% gReloadSettingsView_Click x55 y+5, See Advanced (All) Settings.
ReloadBrivGemFarmSettingsDisplay() ; load settings file.
if ( !g_BrivUserSettings[ "HiddenFarmWindow" ])
{
    Gui, BrivPerformanceGemFarm:Show,% "x" . g_BrivUserSettings[ "WindowXPosition" ] " y" . g_BrivUserSettings[ "WindowYPosition" ], Running Gem Farm...
    GUIFunctions.UseThemeTitleBar("BrivPerformanceGemFarm")
}

ReloadBrivGemFarmSettingsDisplay()
{
    ReloadBrivGemFarmSettings()
    Gui, BrivPerformanceGemFarm:ListView, BrivFarmSettingsID
    LV_Delete()
    LV_Add(, "Using Fkeys? ", g_BrivUserSettings[ "Fkeys" ] ? "Yes" : "No")
    LV_Add(, "Stack Fail Recovery? ", g_BrivUserSettings[ "StackFailRecovery" ] ? "Yes" : "No")
    LV_Add(, "Disable Dash Wait ", g_BrivUserSettings[ "DisableDashWait" ] ? "Yes" : "No")
    LV_Add(, "Stack Zone: ", g_BrivUserSettings[ "StackZone" ])
    LV_Add(, "Min Stack Zone w/ can't reach Stack Zone: ", g_BrivUserSettings[ "MinStackZone" ])
    if(!g_BrivUserSettings[ "AutoCalculateBrivStacks" ])
        LV_Add(, "Target Haste stacks: ", g_BrivUserSettings[ "TargetStacks" ])
    LV_Add(, "Stacking Restart wait time: ", g_BrivUserSettings[ "RestartStackTime" ])
    LV_Add(, "Auto Calculate Briv Stacks? ", g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? "Yes" : "No")
    LV_Add(, "Buy Silver? ", g_BrivUserSettings[ "BuySilvers" ] ? "Yes" : "No")
    LV_Add(, "Buy Gold? ", g_BrivUserSettings[ "BuyGolds" ] ? "Yes" : "No")
    LV_Add(, "Open Silver? ", g_BrivUserSettings[ "OpenSilvers" ] ? "Yes" : "No")
    LV_Add(, "Open Gold? ", g_BrivUserSettings[ "OpenGolds" ] ? "Yes" : "No")
    LV_Add(, "Required Gems to Buy: ", g_BrivUserSettings[ "MinGemCount" ])
    LV_ModifyCol()
}

ReloadAdvancedBrivGemFarmSettingsDisplay()
{
    ReloadBrivGemFarmSettings()
    columns := 0
    Gui, BrivPerformanceGemFarm:ListView, BrivFarmSettingsID
    LV_Delete()
    for k,v in g_BrivUserSettings
    {
        if IsObject(v)
            v := ArrFnc.GetDecFormattedArrayString(v)
        LV_Add(, k, v)
        columns += 1
    }
    for k,v in g_BrivUserSettingsFromAddons
    {
        LV_Add(, k, v)
        columns += 1
    }
    LV_ModifyCol()
}

ReloadSettingsView_Click()
{
    if(isAdvancedBrivSettings)
        ReloadBrivGemFarmSettingsDisplay()
    else
        ReloadAdvancedBrivGemFarmSettingsDisplay()
    isAdvancedBrivSettings := !isAdvancedBrivSettings
}

RefreshSettingsView()
{
    if(!isAdvancedBrivSettings)
        ReloadBrivGemFarmSettingsDisplay()
    else
        ReloadAdvancedBrivGemFarmSettingsDisplay()
}

if(A_Args[1])
{
    ObjRegisterActive(g_SharedData, A_Args[1])
    g_SF.WriteObjectToJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json", A_Args[1])
}
else
{
    GuidCreate := ComObjCreate("Scriptlet.TypeLib")
    guid := GuidCreate.Guid
    ObjRegisterActive(g_SharedData, guid)
    g_SF.WriteObjectToJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json", guid)
}
; g_SharedData.ReloadSettingsFunc := Func("LoadBrivGemFarmSettings")

g_BrivGemFarm.GemFarm()

OnExit(ComObjectRevoke())

ComObjectRevoke()
{
    ObjRegisterActive(g_SharedData, "")
    ExitApp
}

BrivPerformanceGemFarmGuiClose()
{
    MsgBox, 35, Close, Really close the gem farm script? `n`nWarning: This script is required for gem farming. `n"Yes" will close the gem farm script. `n"No" will miniize the script to the tray.`n     You can open it again by pressing the play button in Script Hub.
    IfMsgBox, Yes
        ExitApp
    IfMsgBox, No
        Gui, BrivPerformanceGemFarm:hide
    IfMsgBox, Cancel
        return true
}
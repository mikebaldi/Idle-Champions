; ############################################################
;  Script that runs when Play button pressed in BrivGemFarm
; ############################################################
; This file is used in Script Hub to know where the script it needs to run is located.
; The meat of the functionality of the script is in the Example_BrivGemFarm_TimerScript_Run.ahk file.

; This example uses timers to call a function at a fixed interval
; This example explains how Antilectual's MoveGameWindow miniscript functions

; Create unique identifier (GUID) for the addon to be used by Script Hub.
g_guid := ComObjCreate("Scriptlet.TypeLib").Guid
; Added the script to be run when play is pressed to the list of scripts to be run.
g_Miniscripts[g_guid] := A_LineFile . "\..\Example_BrivGemFarm_TimerScript_Run.ahk"

; See Example_BrivGemFarm_TimerScript_Run.ahk for the code that is being run.
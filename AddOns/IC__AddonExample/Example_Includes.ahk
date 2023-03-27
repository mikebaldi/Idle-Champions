; ############################################################
;                        Includes
; ############################################################
#include *i %A_LineFile%\..\Example_Gui.ahk
#include *i %A_LineFile%\..\Example_Component.ahk
; -- Timer Example 1 - Indepenent Script -- 
; Uncomment the following line to enable the sample timer script which will move the game window when BrivGemFarm starts.
;#include *i %A_LineFile%\..\Example_Timer\Example_BrivGemFarm_TimerScript.ahk

; -- Timer Example 2 - Runs through Script Hub's main window -- 
; The second method of timer script must be loaded after BrivGemFarm in order to function. 
; To enable it with this addon the ExampleAddon must come after BrivGemFarm in the addon list.
; Uncomment the following line to enable the second style of sample timer script which will move the game window when BrivGemFarm starts.
;#include *i %A_LineFile%\..\Example_Timer2\Example_BrivGemFarm_TimerScript2.ahk

; -- Extends Example --
; Adds/Overwrites functions in a class. Gives flexibility to the script.
; Uncomment the following lines to enable the an Extends sample that adds or overwrites some functions.
; #include *i %A_LineFile%\..\Example_Extends\Example_BrivGemFarm_Extends_Component.ahk

; -- Server Calls Example --
; Allows direct interaction with the back end API for the game.
; Uncomment the following lines to enable the a sample that contacts the server API to do a task.
#include *i %A_LineFile%\..\Example_ServerCall\Example_ServerCall_Includes.ahk
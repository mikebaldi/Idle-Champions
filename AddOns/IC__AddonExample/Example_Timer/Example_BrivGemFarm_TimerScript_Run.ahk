; Sample timer script with a breakdown of how the MoveGameWindow_Mini addon is constructed.

#SingleInstance force ; Only allow one copy of the script to run at once.
#NoTrayIcon ; Hides AHK icon from the tray
#Persistent ; Keeps the script running even if there is no GUI or hotkeys

; Include code required for script to script communication
#include %A_LineFile%\..\..\..\..\SharedFunctions\ObjRegisterActive.ahk
; Include common script functions. 
#include %A_LineFile%\..\..\..\..\SharedFunctions\IC_SharedFunctions_Class.ahk

; Create instance of the class with functions needed for addon
global g_TimerExample_Mini := new IC_TimerExample_Mini
; Read main script's settings. Used in script to get exe name. "\..\..\..\..\" backtracks "Addons\IC__AddonExample\Example_Timer\Example_BrivGemFarm_TimerScript_Run.ahk"
global g_UserSettings := g_TimerExample_Mini.SF.LoadObjectFromJSON(A_LineFile . "\..\..\..\..\settings.json")
; Bind class functions into functions that can be called from a timer.
g_TimerExample_Mini.CreateTimedFunctions()
; Start functions to be called on timer.
g_TimerExample_Mini.StartTimedFunctions()
; Enable script-script communication. When Script Hub starts the script, it passes the GUID as a parameter so Script Hub has this script's GUID.
ObjRegisterActive(g_TimerExample_Mini, A_Args[1])
; Function that removes script communication link and closes the script.
ComObjectRevoke()
{
    ObjRegisterActive(g_TimerExample_Mini, "")
    ExitApp
}
return
; Automatically calls the above function when the script attempts to close.
; This makes sure windows recognizes that the comm link has been removed if the script is closed.
OnExit(ComObjectRevoke())

; This class contains code to be run 
class IC_TimerExample_Mini
{
    ; Shared functions is used for loading the settings file above.
    SF := new IC_SharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory

    ; When "var := new IC_TimerExample_Mini" is used, the __new function is called.
    __new() 
    {
        ; Assign an instance of Shared Functions to this class.
        this.SF := new IC_SharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
    }

    ; Creates a function binding that can be used by AHKs timer to call the function.
    CreateTimedFunctions() 
    {
        ;Binds the class's function to a variable
        this.fncToCallOnTimer :=  ObjBindMethod(this, "DoTimedExample")
    }

    ; Starts functions that need to be run in a separate thread such as GUI Updates.
    StartTimedFunctions() 
    {
        ; The '.' cannot be used in some AHK instructions. This assigns the bound function to a local variable.
        fncCall := this.fncToCallOnTimer
        ; Starts a repeating timer of 2 seconds that will call the function in fncCall on each cycle of the timer.
        SetTimer, %fncCall%, 2000, 0
    }

    ; Function that simply closes the script.
    Close() 
    {
        ExitApp
    }

    DoTimedExample() 
    {
        ; Gets the window ID and checks if it is the same as what the script is using
        if((Hwnd := WinExist( "ahk_exe " . g_UserSettings["ExeName"] )) AND Hwnd != this.SF.Hwnd )
        {
                ; Saves the XY coordinates and Width/Height values into the the matching variables.
                WinGetPos, X, Y, Width, Height, ahk_id %Hwnd%
                ; Place the top left corner of the window the screen width's distance from the right and at the top of the screen.
                WinMove, A_ScreenWidth - Width, 0 ;A_ScreenHeight = 0 and top of the screen. Some border pixels may be missed in width size.
        }
    }
}


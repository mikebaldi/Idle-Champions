; ##################################################################
;  Timed function that runs when Play button pressed in BrivGemFarm
; ##################################################################

; This example uses timers to call a function at a fixed interval
; This example uses techniques as seen in the BrivGemFarmStat_Stats addon and the MemoryFunctions addon.

; This class contains code to be run 
class IC_TimerExample2_Class
{
    TimerFunctions := ""
    ; Adds timed functions (typically to be started when briv gem farm is started)
    CreateTimedFunctions()
    {
        ; Clear the timer functions in this class.
        this.TimerFunctions := {}
        ; Bind DoTimedExample function to a variable.
        fncToCallOnTimer :=  ObjBindMethod(this, "DoTimedExample")
        ; Set the timer for the function to be called.
        this.TimerFunctions[fncToCallOnTimer] := 1500
    }

    ; Starts the saved timed functions (typically to be started when briv gem farm is started)
    StartTimedFunctions()
    {
        ; Iterates the timemd functions stored in this class and starts them using their corresponding timer.
        for func,timer in this.TimerFunctions
        {
            ; Start the timed function.
            SetTimer, %func%, %timer%, 0
        }
    }

    ; Stops the saved timed functions (typically to be stopped when briv gem farm is stopped)
    StopTimedFunctions()
    {
        ; Iterates the timemd functions stored in this class and stops them.
        for func,timer in this.TimerFunctions
        {
            ; Off tells the function to stop repeating.
            SetTimer, %func%, Off
            ; Delete removes the timer from the functions AHK is calling on timers.
            SetTimer, %func%, Delete
        }
    }

    ; Sample timer function.
    DoTimedExample() 
    {
        ; Gets the window ID and checks if it is the same as what the script is using
        if((Hwnd := WinExist( "ahk_exe " . g_UserSettings["ExeName"] )) AND Hwnd != this.SF.Hwnd )
        {
                ; Saves the XY coordinates and Width/Height values into the the matching variables.
                WinGetPos, X, Y, Width, Height, ahk_id %Hwnd%
                ; Place the top left corner of the window the screen width's distance from the right and at the top of the screen.
                WinMove, A_ScreenWidth - Width, 200 ;A_ScreenHeight = 0 and top of the screen. Some border pixels may be missed in width size.
        }
    }
}

; Test to see if BrivGemFarm addon is avaialbe.
if(IsObject(IC_BrivGemFarm_Component))
{
    ; g_BrivFarmAddonStartFunctions is a global variable that contains all functions that will be called when play or connect is pressed in BrivGemFarm.
    ; Add CreateTimedFunctions and StartTimedfunctions to the list of functions to be started.
    g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_TimerExample2_Class, "CreateTimedFunctions"))
    g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_TimerExample2_Class, "StartTimedFunctions"))
    ; g_BrivFarmAddonStopFunctions is a global variable that contains all functions that will be called when stop is pressed in BrivGemFarm.
    ; Add CreateTimedFunctions and StartTimedfunctions to the list of functions to be stopped.
    g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(IC_TimerExample2_Class, "StopTimedFunctions"))
}
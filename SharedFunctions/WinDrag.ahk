; +---------------------+
; |   Set/Reset cursor  |
; +---------------------+
; from: https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
SetSystemCursor()
{
	IDC_SIZEALL := 32646
	CursorHandle := DllCall( "LoadCursor", Uint,0, Int, IDC_SIZEALL )
	Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
	Loop, Parse, Cursors, `,
	{
		DllCall( "SetSystemCursor", Uint, CursorHandle, Int, A_Loopfield )
	}
}

RestoreCursors()
{
	SPI_SETCURSORS := 0x57
	DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

; +--------------------------------------------+
; |             WindowMouseDragMove            |
; +--------------------------------------------+
/*
@brief Drag windows around following mouse while pressing left click

For example, assign to ctrl+alt while mouse drag

@code
^!LButton::WindowMouseDragMove()
@endcode

@todo `WindowMouseDragMove` Left click is hardcoded. Customize to any given key.

@remark based on: https://autohotkey.com/board/topic/25106-altlbutton-window-dragging/ 
Fixed a few things here and there
*/
WindowMouseDragMove()
{
    CoordMode, Mouse, Screen
    MouseGetPos, x0, y0, window_id
    ahkPID := DllCall("GetCurrentProcessId")
    WinGet, ahkWinID, PID, ahk_id %window_id%
    if (ahkWinID != ahkPID)
    {
        MouseClick, left
        return
    }
    else
    {
        MouseClick, left
    }

    WinGet, window_minmax, MinMax, ahk_id %window_id%
    WinGetPos, wx, wy, ww, wh, ahk_id %window_id%

    ; Return if the window is maximized or minimized
    if window_minmax <> 0 
        return
    init := 1
    SetWinDelay, 0
    while(GetKeyState("LButton", "P"))
    {
        MouseGetPos, x, y
        if( x == x0 && y == y0 ) {
            continue
        }
        
        if( init == 1 )  {
            SetSystemCursor()
            init := 0
        }

        wx += x - x0
        wy += y - y0
        x0 := x
        y0 := y

        WinMove ahk_id %window_id%,, wx, wy
    }
    SetWinDelay, -1
    RestoreCursors()
    return
}
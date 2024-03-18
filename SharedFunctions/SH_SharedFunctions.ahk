#include %A_LineFile%\..\SH_KeyHelper.ahk
#include %A_LineFile%\..\SH_ArrFnc.ahk

class SH_SharedFunctions
{
    Hwnd := 0
    PID := 0
    ErrorKeyDown := 0
    ErrorKeyUp := 0

    ;Gets data from JSON file
    LoadObjectFromJSON( FileName )
    {
        FileRead, oData, %FileName%
        data := "" 
        try
        {
            data := JSON.parse( oData )
        }
        catch err
        {
            err.Message := err.Message . "`nFile:`t" . FileName
            throw err
        }
        return data
    }

    ;Writes beautified json (object) to a file (FileName)
    WriteObjectToJSON( FileName, ByRef object )
    {
        objectJSON := JSON.stringify( object )
        objectJSON := JSON.Beautify( objectJSON )
        FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }

    ;====================================================
    ;Keyboard/Mouse input (and helper) functions
    ;====================================================

    /*  DirectedInput - A function to send keyboard inputs to Idle Champions while in background.

        Parameters:
        s - The keyboard inputs to be sent to Idle Champions. Single Character string, or array of characters.
        Returns: Nothing
    */
    /*
    Resources:
    https://www.autohotkey.com/docs/v1/lib/PostMessage.htm
    https://www.autohotkey.com/docs/v1/misc/SendMessageList.htm
    https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage
    https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setfocus (ControlFocus == SetFocus)
    https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
    https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keyup
    
    Expected:
        SendMessage, MsgNumber , wParam, lParam, Control, WinTitle, WinText, ExcludeTitle, ExcludeText, Timeout
    Example:
        SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,,,%timeout%
    Breakdown:
        SendMessage,
                MsgNumber - (WM_KEYDOWN := 0x0100, WM_KEYUP := 0x0101),
                wParam - ("`" = "0xC0", "a" = Format("0x{:X}", GetKeyVK("a")),
                lParam - (0x0 for keydown, 0xC0000001 for keyup. Also can include scancode See WM-keydown/keyup documentation.)
                Control - ("") No specific control specified
                WinTitle - (ahk_id 0x1234) where 0x1234 is the window handle of the window being sent keypress
                WinText - ("") No Specific window text specified
                ExcludeTitle - ("") No Exclusion title specified 
                ExcludeText - ("") No Exclusion text specified
                Timeout - (5000) Value in ms to wait before "FAIL" thrown to ErrorLevel. Otherwise ErrorLevel 0 on success, 1 on failure from SendMessage.

    Expected Input for Win32 API:                
        LRESULT SendMessage(in] HWND   hWnd, [in] UINT   Msg, [in] WPARAM wParam, [in] LPARAM lParam);
        HWND SetFocus([in, optional] HWND hWnd);
    */
    DirectedInput(hold := 1, release := 1, s* )
    {
        Critical, On
        ; TestVar := {}
        ; for k,v in g_KeyPresses
        ; {
        ;     TestVar[k] := v
        ; }
        timeout := 5000
        directedInputStart := A_TickCount
        hwnd := this.Hwnd
        ControlFocus,, ahk_id %hwnd%
        ;while (ErrorLevel AND A_TickCount - directedInputStart < timeout * 10)  ; testing reliability
        ; if ErrorLevel
        ;     ControlFocus,, ahk_id %hwnd%
        values := s
        if(IsObject(values))
        {
            if(hold)
            {
                for k, v in values
                {
                    g_InputsSent++
                    ; if TestVar[v] == ""
                    ;     TestVar[v] := 0
                    ; TestVar[v] += 1
                    key := g_KeyMap[v]
                    sc := g_SCKeyMap[v] << 16
                    lparam := 0x0 & sc
                    SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,,,%timeout%
                    if ErrorLevel
                        this.ErrorKeyDown++
                    ;     PostMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,
                }
            }
            if(release)
            {
                for k, v in values
                {
                    key := g_KeyMap[v]
                    sc := g_SCKeyMap[v] << 16
                    lparam := 0xC0000001 & sc
                    SendMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,,,,%timeout%
                    if ErrorLevel
                        this.ErrorKeyUp++
                    ;     PostMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,
                }
            }
        }
        else
        {
            key := g_KeyMap[values]
            sc := g_SCKeyMap[v] << 16
            if(hold)
            {
                g_InputsSent++
                ; if TestVar[v] == ""
                ;     TestVar[v] := 0
                ; TestVar[v] += 1
                
                lparam := sc
                SendMessage, 0x0100, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                if ErrorLevel
                    this.ErrorKeyDown++
            }
            if(release)
            {
                lparam := 0xC0000001 & sc
                SendMessage, 0x0101, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
            }
            if ErrorLevel
                this.ErrorKeyUp++
            ;     PostMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,
        }
        Critical, Off
        ; g_KeyPresses := TestVar
    }
}
#include %A_LineFile%\..\SH_KeyHelper.ahk
#include %A_LineFile%\..\SH_ArrFnc.ahk

class SH_SharedFunctions
{
    Hwnd := 0
    PID := 0
    Logger := {}

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
        if (!objectJSON)
            return
        objectJSON := JSON.Beautify( objectJSON )
        if(FileExist(FileName))
            FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }

    ; Copies top level items in com object to new AHK object.
    ComObjectCopy(comObj)
    {
        convertedObj := {}
        for k,v in comObj
            convertedObj[k] := comObj[k]
        return convertedObj
    }

    ; Copies AHK object into COM object.
    CopyToComObject(byref comObj, AHKObject)
    {
        size := AHKObject.Length()
        loop %size%
            comObj[A_Index] := AHKObject[A_Index]
        return comObj
    }

    ; Removes any settings that are in loadedSettings that are not in expectedSettings.
    DeleteExtraSettings(loadedSettings, expectedSettings)
    {
        needSave := false
        for k, v in loadedSettings
            if (!expectedSettings.HasKey(k))
                needSave := True, loadedSettings.Delete(k)
        ; Add missing settings
        for k, v in expectedSettings
            if (!loadedSettings.HasKey(k) || loadedSettings[k] == "")
                needSave := true, loadedSettings[k] := expectedSettings[k]
        if(needSave)
            return loadedSettings
        else
            return ""
    }
    
    ; Helper function to add commas every 3 digits for display purposes.
    AddThousandsSeperator(val)
    {
        if (!(val is number) || Abs(val) < 1000)
            return val
        return RegExReplace(val, "(\G|[^\d,.])\d{1,3}(?=(\d{3})+(\D|$))", "$0,")
    }
    
    ; Convert val to scientific notation
    GetScientificNotation(val, minExponents := 7, thousandsSeparate := true)
    {
        if !(val is number)
            return val
        sciNote := Format("{:2.2e}", val)
        ePos := InStr(sciNote, "e")
        postExp := Format("{:02d}", SubStr(sciNote, ePos+2))
        if (postExp < minExponents)
            return thousandsSeparate ? this.AddThousandsSeperator(val) : val
        signExp := SubStr(sciNote, ePos+1, 1)
        return SubStr(sciNote, 1, ePos) . (signExp=="+" ? "" : signExp) . postExp
    }

    ArrSize(arr)
    {
        if (IsObject(arr))
        {
            currArrSize := arr.MaxIndex()
            if (currArrSize == "")
                return 0
            return currArrSize
        }
        return 0
    }
    ;====================================================
    ;Keyboard/Mouse input (and helper) functions
    ;====================================================

    /*  DirectedInput - A function to send keyboard inputs to a game that is in the background (if it supports it).

        Parameters:
        hold - true for a key down, false to skip key down
        release - true for a key up, false to skip key up
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
    DirectedInput(hold := 1, release := 1, values* )
    {
        if (values == "") ; no input
            return
        else if (IsObject(values) AND (values.Count() == 0 OR (values[1] == "" AND values.Count() == 1))) ; no input
            return
        Critical, On
        timeout := 5000
        hwnd := this.Hwnd
        ControlFocus,, ahk_id %hwnd%
        if(IsObject(values))
        {
            for k, v in values
            {
                if (v == "")
                    continue
                key := g_KeyMap[v]
                sc := g_SCKeyMap[v]
                sc := sc << 16
                lparam := Format("0x{:X}", 0x0 | sc)
                if(hold)
                    SendMessage, 0x0100, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                if(release)
                {
                    if(hold)
                        Sleep, 16
                    lparam := Format("0x{:X}", 0xC0000001 | sc)
                    SendMessage, 0x0101, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                }
                Sleep, 16
            }
        }
        else
        {
            key := g_KeyMap[values]
            sc := g_SCKeyMap[values]
            sc := sc << 16
            if(hold)
            {
                lparam := Format("0x{:X}", 0x0 | sc)
                SendMessage, 0x0100, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
            }
            if(release)
            {
                if(hold)
                    Sleep, 16
                lparam := Format("0x{:X}", 0xC0000001 | sc)
                SendMessage, 0x0101, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
            }
        }
        Critical, Off
    }

    ; ======================================================================================================================
    ; GetCallStack([Report := 0]) - retrieves the current callstack.
    ;
    ; Returns an array of objects with the following keys:
    ;     Called   -  the name of the called function/label
    ;     Caller   -  the name of the function/label which called the function/label
    ;     Line     -  the number of the line Called was called from
    ;     File     -  the name of the file containing the line
    ; The properties of the first object contain the currently executed line and file.
    ;
    ; The parameter Report may be set to one of the following values:
    ;     0  -  return the stack array silently
    ;     1  -  additionally show the values by MsgBox
    ;     2  -  additionally send the values to the debugger by OutputDebug
    ;     3  -  use both of the report options
    ; ======================================================================================================================
    GetCallStack(Report := 0) {
    Local Stack := [], StackIndex := 0, E, M
    While (E := Exception("", --StackIndex)).What <> StackIndex {
        Stack[A_Index] := {Called: E.What, Caller: "Auto-Exec/Event", Line: E.Line, File: E.File}
        If (A_Index > 1)
            Stack[A_Index - 1].Caller := E.What
    }
    If (Report & 1) { ; MsgBox
        M := ""
        For Each, E In Stack
            M .= E.Called . "  <<  called by " . E.Caller . " at line " . E.Line . " of " . E.File . "`r`n"
        MsgBox, 0, Callstack, % M
    }
    If (Report & 2) ; OutputDebug
        For Each, E In Stack
            OutputDebug, %  "`r`n" . E.Called . " called by " . E.Caller . " at line " . E.Line . " of " . E.File
    Return Stack
    }

    ; https://www.autohotkey.com/board/topic/30042-run-ahk-scripts-with-less-half-or-even-less-memory-usage/
    EmptyMem(pid:="")
    {
        pid := pid == "" ? DllCall("GetCurrentProcessId") : pid
        h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
        DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
        DllCall("CloseHandle", "Int", h)
    }

    ; typedef struct _PROCESS_MEMORY_COUNTERS_EX {
    ;   DWORD  cb;                          // offset 0
    ;   DWORD  PageFaultCount;              // offset 4
    ;   SIZE_T PeakWorkingSetSize;          // offset 8
    ;   SIZE_T WorkingSetSize;              // offset 8 + A_PtrSize
    ;   SIZE_T QuotaPeakPagedPoolUsage;     // offset 8 + A_PtrSize*2
    ;   SIZE_T QuotaPagedPoolUsage;         // offset 8 + A_PtrSize*3
    ;   SIZE_T QuotaPeakNonPagedPoolUsage;  // offset 8 + A_PtrSize*4
    ;   SIZE_T QuotaNonPagedPoolUsage;      // offset 8 + A_PtrSize*5
    ;   SIZE_T PagefileUsage;               // offset 8 + A_PtrSize*6
    ;   SIZE_T PeakPagefileUsage;           // offset 8 + A_PtrSize*7
    ;   SIZE_T PrivateUsage;                // offset 8 + A_PtrSize*8
    ; } PROCESS_MEMORY_COUNTERS_EX;
    ; Sizes to use for the return value next to PMC_EX to get different memory reads.
    GetProcessMemoryUsage(ProcessID := "")
    {
        if(ProcessID == "")
            ProcessID := DllCall("GetCurrentProcessId")
        static PMC_EX, size := NumPut(VarSetCapacity(PMC_EX, 8 + A_PtrSize * 9, 0), PMC_EX, "uint")

        if (hProcess := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "uint", ProcessID)) {
            if !(DllCall("GetProcessMemoryInfo", "ptr", hProcess, "ptr", &PMC_EX, "uint", size))
                if !(DllCall("psapi\GetProcessMemoryInfo", "ptr", hProcess, "ptr", &PMC_EX, "uint", size))
                    return (ErrorLevel := 2) & 0, DllCall("CloseHandle", "ptr", hProcess)
            DllCall("CloseHandle", "ptr", hProcess)
            return Round(NumGet(PMC_EX, 8 + A_PtrSize, "uptr") / 1024**2, 2)
        }
        return (ErrorLevel := 1) & 0
    }

    UpdateLog(var, msg, logAsObject := False)
    {
        static lastCallTime := 0
        static delayTime := 10000
        FormatTime, ts,, yyyy-MM-dd HH:mm:ss
        FormatTime, ts2,, yyyy-MM-dd HH.mm.ss
        header := ts . " [info] [" . var . "] "
        logFile := A_LineFile . "\..\..\Logging\" . ts2 . " debug_log.json"
        if (this.logger[var] == "")
            this.logger[var] := {}
        ; logger[var].push(header . msg)
        if(logAsObject)
            this.logger[var].push(header, msg)
        else
            this.logger.push(header . msg)
        if(A_TickCount - lastCallTime > delayTime)
            this.WriteObjectToJSON(logFile, this.logger)
            , lastCallTime := A_TickCount, this.logger := {}
    }
    
    Log1(level, msg) 
    {
        FormatTime, ts,, yyyy-MM-dd HH:mm:ss
        logFile := A_ScriptDir "\debug_log.txt"
        FileAppend, [%ts%] [%level%] %msg%`n, %logFile%
    }

    Log2(level, msg, outputNow) 
    {
        static log2log := ""
        FormatTime, ts,, yyyy-MM-dd HH:mm:ss
        string = [%ts%] [%level%] %msg%`n
        log2log .= string

        if(!outputNow)
            return
        logFileLoc := A_ScriptDir "\debug_log.txt"
        FileAppend, %log2log%, %logFileLoc%
        log2log := ""
    }
}

global g_UTimer := new SH_SharedTimers ;universal timer
; Class used to test if time taken has been completed. Not recommended for use with functions called from SetTimer.
class SH_SharedTimers
{
    StartTime := 0

    __New()
    {
        this.StartTime := 0
    }
    
    ; Starts timer on first call. WIll return True on timed out and false when time is left. timeout of 0 resets timer.
    IsTimeUp(timeout)
    {
        if(this.StartTime == 0)
            this.StartTime := A_TickCount
        this.ElapsedTime := A_TickCount - this.StartTime
        if this.ElapsedTime < timeout
            return False
        return True
    }
}
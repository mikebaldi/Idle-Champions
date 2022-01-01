/*  A class to send key inputs to a specified window, similar to ControlSend.

    Usage:
    ;initialize class
    VirtualKeyInputs.Init( window )
    window == A window title or other criteria identifying the target window. See https://www.autohotkey.com/docs/misc/WinTitle.htm

    VirtualKeyInputs.Generic( inputs * ) ;Generic method provides no confirmation if message was accepted by application.
    inputs* == Variadic parameter of inputs

    VirtualKeyInputs.Priority( inputs* ) ;Priority method will attempt to resend inputs if the application does not respond with success.
    inputs* == Variadic parameter of inputs

    Note: Each input should be its own parameter, for example VirtualKeyInputs.Priority( "a", "b" ) and not VirtualKeyInputs.Priority( "ab" )
    Also accepts arrays of strings, use * when passing an array, for example VirtualKeyInputs.Priority( AnArray* ) or VirtualKeyInputs.Priority( ["a", "b"]* )
*/

class VirtualKeyInputs
{
    GetVersion()
    {
        return "v1.1, 11/18/21"
    }

    Generic( inputs* )
    {
        ControlFocus,, % this.Window
        for k, v in inputs
        {
            PostMessage, 0x0100, % this.KeyMap[ v ], 0,, % this.Window
            PostMessage, 0x101, % this.KeyMap[ v ], 0xC0000001,, % this.Window
        }
        Sleep, 10
    }

    Priority( inputs* )
    {
        keyState := [ "Down", "Up" ]
        ControlFocus,, % this.Window
        for k, v in inputs
        {
            for l, b in keyState
            {
                SendMessage, % b == "Down" ? 0x100 : 0x101, % this.KeyMap[ v ], % b == "Down" ? 0 : 0xC0000001,, % this.Window,,,, % this[ b ].Wait
                this[ b ].SetLastRun( i := 0 )
                while ( ErrorLevel AND this[ b ].GetLastRun() < this[ b ].MaxAttempts )
                {
                    SendMessage, % b == "Down" ? 0x100 : 0x101, % this.KeyMap[ v ], % b == "Down" ? 0 : 0xC0000001,, % this.Window,,,, % this[ b ].Wait

                    this[ b ].SetLastRun( ++i )
                }
                if this[ b ].GetLastRun()
                    this[ b ].IncrementTotal()
            }
        }
    }

    Init( window )
    {
        this.Window := window

        this.KeyMap := {}
        alphabet := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
        extraKeys := ["Left","Right","Esc","Shift","Alt","Ctrl","``","RCtrl","LCtrl"]
        fKeys := ["F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"]
        numKeys := ["0","1","2","3","4","5","6","7","8","9"]
        
        allKeys := {}
        allKeys.Push(alphabet*)
        allKeys.Push(extraKeys*)
        allKeys.Push(fKeys*)
        allKeys.Push(numKeys*)

        for k,v in allKeys
        {
            index := "{" . v . "}"
            vk := GetKeyVK(v)
            formattedHexCode := Format("0x{:X}", vk)
            this.KeyMap[index] := formattedHexCode
            this.KeyMap[v] := formattedHexCode
        }

        this.Down := new _FAILhandler( 10, 5 )
        this.Up := new _FAILhandler( 10, 5 )
    }
}

class _FAILhandler
{
    __new( wait, maxAttempts )
    {
        this.Wait := wait ;How long the script will wait for a response from SendMessage command. Will increment up 10ms when failure rate exceeds 5%
        this.MaxAttempts := maxAttempts ;Number of times script will attempt to resend input on ErrorLevel == FAIL.
        this.lastRun := 0 ;Tracks number of attempts per input.
        this.countFAIL := 0 ;Failure count. Increments when number of actual attempts exceeds MaxAttempts.
        this.countTotal := 0 ;Increments every input.
        Return this
    }

    SetLastRun( value )
    {
        Return this.lastRun := value
    }

    GetLastRun()
    {
        Return this.lastRun
    }

    IncrementTotal()
    {
        this.countTotal += 1
        if ( this.GetLastRun() >= this.MaxAttempts )
            this.countFAIL += 1
        if ( this.GetLastRun() >= this.MaxAttempts AND this.Wait < 100 AND ( this.countFAIL / this.countTotal ) >= 0.05 )
        {
            this.Wait += 10
            this.countFAIL := 0
            this.countTotal := 0
        }
        Return
    }
}
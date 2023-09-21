/*  Various functions for use with scripts for Idle Champions.
    change log
    v 0.2 11/11/21
    1. refactoring of logging
    2. toggle auto progress function
    3. add some failsafes for when key inputs aren't registering
*/

global g_PreviousZoneStartTime
global g_KeyPresses := {}
global g_SharedData := new IC_SharedData_Class

#include %A_LineFile%\..\IC_KeyHelper_Class.ahk
#include %A_LineFile%\..\IC_ArrayFunctions_Class.ahk
#include %A_LineFile%\..\MemoryRead\IC_MemoryFunctions_Class.ahk

class IC_SharedData_Class
{
    ; Note stats vs States. Confusing, but intended.
    StackFailStats := new StackFailStates
    LoopString := ""
    TotalBossesHit := 0
    BossesHitThisRun := 0
    SwapsMadeThisRun := 0
    StackFail := 0
    OpenedSilverChests := 0
    OpenedGoldChests := 0
    PurchasedGoldChests := 0
    PurchasedSilverChests := 0
    ShinyCount := 0
    TriggerStart := false
    TotalRollBacks := 0
    BadAutoProgress := 0
    PreviousStacksFromOffline := 0
    TargetStacks := 0
    ShiniesByChamp := {}
    ShiniesByChampJson := ""

    Close()
    {
        ExitApp
    }

    ReloadSettings(ReloadSettingsFunc)
    {
        reloadFunc := Func(ReloadSettingsFunc)
        reloadFunc.Call()
    }

    ShowGUI()
    {
        Gui, show
    }
}

class StackFailStates
{
    ; StackFail Types:
    ; 1.  Ran out of stacks when ( > min stack zone AND < target stack zone). only reported when fail recovery is on
    ;       Will stack farm - only a warning. Configuration likely incorrect
    ; 2.  Failed stack conversion (Haste <= 50, SB > target stacks). Forced Reset
    ; 3.  Game was stuck (checkifstuck), forced reset
    ; 4.  Ran out of haste and steelbones > target, forced reset
    ; 5.  Failed stack conversion, all stacks lost.
    ; 6.  Modron not resetting, forced reset
    static FAILED_TO_REACH_STACK_ZONE := 1
    static FAILED_TO_CONVERT_STACKS := 2
    static FAILED_TO_PROGRESS := 3
    static FAILED_TO_REACH_STACK_ZONE_HARD:= 4
    static FAILED_TO_KEEP_STACKS := 5
    static FAILED_TO_RESET_MODRON := 6
    TALLY := [0,0,0,0,0,0]
}

class IC_SharedFunctions_Class
{
    Memory := ""
    Hwnd := 0
    PID := 0
    UserID := ""
    UserHash := ""
    InstanceID := 0
    CurrentAdventure := 30 ; default cursed farmer
    ErrorKeyDown := 0
    ErrorKeyUp := 0
    GameStartFormation := 1
    ModronResetZone := 0
    CurrentZone := ""
    Settings := ""
    TotalGems := 0
    TotalSilverChests := 0
    TotalGoldChests := 0

    __new()
    {
        this.Memory := New IC_MemoryFunctions_Class(A_LineFile . "\..\MemoryRead\CurrentPointers.json")
    }

    ;=======================
    ;Script Helper Functions
    ;=======================

    ; returns this class's version information (string)
    GetVersion()
    {
        return "v2.7.1, 2023-09-21"
    }

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

    ;Takes input of first and second sets of eight byte int64s that make up a quad in memory. Obviously will not work if quad value exceeds double max.
    ConvQuadToDouble(FirstEight, SecondEight)
    {
        return (FirstEight + (2.0**63)) * (2.0**SecondEight)
    }

    ;Returns true if champion is in formation
    IsChampInFormation(champID, formation)
    {
        for k, v in formation
        {
            if ( v == champID )
            {
                return true
            }
        }
        return false
    }

    ; Parses a response from an open chests call to tally shiny counts by champ and slot. Returns count of shinies
    ParseChestResults( chestResults )
    {
        shinies := 0
        for k, v in chestResults.loot_details
        {
            if v.gilded
            {
                shinies += 1
                g_SharedData.ShiniesByChamp[v.hero_id] := (g_SharedData.ShiniesByChamp[v.hero_id] != "" ? g_SharedData.ShiniesByChamp[v.hero_id] : {})
                g_SharedData.ShiniesByChamp[v.hero_id][v.slot_id] := ((g_SharedData.ShiniesByChamp[v.hero_id][v.slot_id] != "") ? (g_SharedData.ShiniesByChamp[v.hero_id][v.slot_id] + 1) : 1)
                ;string := "New shiny! Champ ID: " . v.hero_id . " (Slot " . v.slot_id . ")`n"
            }
        }
        g_SharedData.ShiniesByChampJson := JSON.Stringify(g_SharedData.ShiniesByChamp)
        return shinies
    }

    ;====================================================
    ;General use functions, useful for a variety of tasks
    ;====================================================

    /*  KillCurrentBoss - Switches to e formation and kills the boss

        Parameters:
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns: 1 on current boss zone cleared, 0 otherwise

    */
    KillCurrentBoss( maxLoopTime := 25000 )
    {
        CurrentZone := this.Memory.ReadCurrentZone()
        if mod( CurrentZone, 5 )
            return 1
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 67
        g_SharedData.LoopString := "Killing boss before stacking."
        while ( !mod( this.Memory.ReadCurrentZone(), 5 ) AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            this.DirectedInput(,,"{e}")
            if(!this.Memory.ReadQuestRemaining()) ; Quest complete, still on boss zone. Skip boss bag.
                this.ToggleAutoProgress(1,0,false)
            Sleep, %sleepTime%
        }
        if(ElapsedTime >= maxLoopTime)
            return 0
        this.WaitForTransition()
        return 1
    }

    /*  FallBackFromBossZone - A function that does what it says.

        Parameters:
        spam ;passed to WaitForTranstion()
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns: 0 if didn't fall back, 1 if did.

    */
    FallBackFromBossZone( spam := "", maxLoopTime := 5000 )
    {
        fellBack := 0
        CurrentZone := this.Memory.ReadCurrentZone()
        if mod( CurrentZone, 5 )
        {
            return fellBack
        }
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 67
        g_SharedData.LoopString := "Falling back from boss zone."
        while ( !mod( this.Memory.ReadCurrentZone(), 5 ) AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                this.DirectedInput(,, "{Left}" )
                counter++
            }
            fellBack := 1
        }
        this.WaitForTransition( spam )
        return fellBack
    }

    /*  FallBackFromZone - Drops back one zone

        Parameters:
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns: 0 if didn't fall back, 1 if did.

    */
    FallBackFromZone( maxLoopTime := 5000 )
    {
        fellBack := 0
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 100
        while(this.Memory.ReadCurrentZone() == -1 AND ElapsedTime < maxLoopTime)
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime))
            {
                CurrentZone := this.Memory.ReadCurrentZone()
                counter++
            }
        }
        CurrentZone := this.Memory.ReadCurrentZone()
        StartTime := A_TickCount
        ElapsedTime := counter := 0
        g_SharedData.LoopString := "Falling back from zone.."
        while(!this.Memory.ReadTransitioning() AND ElapsedTime < maxLoopTime)
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                this.DirectedInput(,, "{Left}" )
                counter++
            }
        }
        this.WaitForTransition()
        ElapsedTime := A_TickCount - StartTime
        fellBack := 1
        return fellBack
    }

    ; IsToggled be 0 for off or 1 for on. ForceToggle always hits G. ForceState will press G until AutoProgress is read as on (<5s).
    ToggleAutoProgress( isToggled := 1, forceToggle := false, forceState := false )
    {
        Critical, On
        StartTime := A_TickCount
        ElapsedTime := keyCount:= 0
        sleepTime := 125

        if ( forceToggle )
            this.DirectedInput(,, "{g}" )
        if ( this.Memory.ReadAutoProgressToggled() != isToggled )
            this.DirectedInput(,, "{g}" )
        while ( this.Memory.ReadAutoProgressToggled() != isToggled AND forceState AND ElapsedTime < 5001 )
        {
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime > sleepTime * keyCount)
            {
                this.DirectedInput(,, "{g}" )
                keyCount++
            }
        }
        Critical, Off
    }

    /*  WaitForFirstGold - A function that will wait for the first gold drop then return the amount dropped.

        Parameters:
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns:
        gold value
    */
    WaitForFirstGold( maxLoopTime := 30000 )
    {
        g_SharedData.LoopString := "Waiting for first gold"
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 250
        this.DirectedInput(,, "{q}")
        gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
        while ( gold == 0 AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                this.DirectedInput(,, "{q}" )
                counter++
            }
            gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
        }
        return gold
    }

    /*  WaitForTransition - A function that will spam inputs, update a GUI timer, and wait for a transition to complete.
        Useful for falling back from a zone.

        Parameters:
        spam ;The string of keyboard inputs to be sent to Idle Champions.
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns: nothing
    */
    WaitForTransition( spam := "", maxLoopTime := 5000 )
    {
        if !this.Memory.ReadTransitioning()
            return
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 20
        g_SharedData.LoopString := "Waiting for Transition..."
        while ( this.Memory.ReadTransitioning() == 1 and ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                if(IsObject(spam))
                    this.DirectedInput(,, spam* )
                else
                    this.DirectedInput(,, spam )
                counter++
            }
        }
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
    
    Expected:
        SendMessage, MsgNumber , wParam, lParam, Control, WinTitle, WinText, ExcludeTitle, ExcludeText, Timeout
    Example:
        SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,,,%timeout%
    Breakdown:
        SendMessage,
                MsgNumber - (WM_KEYDOWN := 0x0100, WM_KEYUP := 0x0101),
                wParam - ("`" = "0xC0", "a" = Format("0x{:X}", GetKeyVK("a")),
                lParam - (0)
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
            if(hold)
            {
                g_InputsSent++
                ; if TestVar[v] == ""
                ;     TestVar[v] := 0
                ; TestVar[v] += 1
                SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,,,%timeout%
                if ErrorLevel
                    this.ErrorKeyDown++
            }
            if(release)
                SendMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,,,,%timeout%
            if ErrorLevel
                this.ErrorKeyUp++
            ;     PostMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,
        }
        Critical, Off
        ; g_KeyPresses := TestVar
    }

    ;================================
    ;Functions mostly for gem farming
    ;================================
    /*  DoDashWait - A function that will wait for Dash ability to activate by reading the current time scale multiplier.

        Parameters:
        DashWaitMaxZone ;Maximum zone to attempt to Dash wait.

        Returns: nothing
    */
    DoDashWait( DashWaitMaxZone := 2000 )
    {
        this.ToggleAutoProgress( 0, false, true )
        this.LevelChampByID( 47, 230, 7000, "{q}") ; level shandie
        ; Make sure the ability handler has the correct base address.
        ; It can change on game restarts or modron resets.
        this.Memory.ActiveEffectKeyHandler.Refresh()
        StartTime := A_TickCount
        ElapsedTime := 0
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := timeScale < 1 ? 1 : timeScale ; time scale should never be less than 1
        timeout := 30000 ; 60s seconds ( previously / timescale (6s at 10x) )
        estimate := (timeout / timeScale) ; no buffer: 60s / timescale to show in LoopString
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted dashwait triggering area
        ;   dash is active, dash.GetScaleActive() toggles to true when dash is active and returns "" if fails to read.
        while ( ElapsedTime < timeout AND this.Memory.ReadCurrentZone() < DashWaitMaxZone AND !this.IsDashActive() )
        {
            this.ToggleAutoProgress(0)
            this.SetFormation()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
            percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10), 15)
            Sleep, %percentageReducedSleep%
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }

    ; Template function for whether determining if to Dash Wait. Default is Yes if shandie is in the formation.
    ShouldDashWait()
    {
        return this.IsChampInFormation( 47, this.Memory.GetCurrentFormation() )
    }

    ; Returns count for how many TimeScale values equal the value passed to the function
    CountTimeScaleMultipliersOfValue(value := 1.5)
    {
        total := 0
        multipliersCount := this.Memory.ReadTimeScaleMultipliersCount()
        loop, % multipliersCount
        {
            if(this.Memory.ReadTimeScaleMultiplierByIndex(A_Index - 1) == value)
                total++
        }
        return total
    }

    ; Searches TimeScale dictionary objects for TimeScaleWhenNotAttackedHandler (Shandie's Dash)
    IsDashActive()
    {
        if(ActiveEffectKeySharedFunctions.Shandie.TimeScaleWhenNotAttackedHandler.ReadDashActive())
            return true
        else if (!this.Memory.ActiveEffectKeyHandler.TimeScaleWhenNotAttackedHandler.BaseAddress)
            this.Memory.ActiveEffectKeyHandler.Refresh()
        return false
    }

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        ;this.DirectedInput(hold := 0,, "{RCtrl}") ;extra release for safety
        if(g_UserSettings[ "NoCtrlKeypress" ])
        {
            this.DirectedInput(,release := 0, "{ClickDmg}") ;keysdown
            this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
        }
        else
        {
            ; ctrl level clickers
            this.DirectedInput(,release := 0, ["{RCtrl}","{ClickDmg}"]*) ;keysdown
            this.DirectedInput(hold := 0,, ["{ClickDmg}","{RCtrl}"]*) ;keysup
        }
        ; turn Fkeys off/on again
        this.DirectedInput(hold := 0,, spam*) ;keysup
        this.DirectedInput(,release := 0, spam*) ;keysdown
        ; try to progress
        this.DirectedInput(,,"{Right}")
        this.ToggleAutoProgress(1)
        this.ModronResetZone := this.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }

    ;A test if stuck on current area. After 35s, toggles autoprogress every 5s. After 45s, attempts falling back up to 2 times. After 65s, restarts level.
    CheckifStuck(isStuck := false)
    {
        static lastCheck := 0
        static fallBackTries := 0
        ;TODO: add better code in case a modron reset happens without being detected. might mean updating other functions.
        dtCurrentZoneTime := Round((A_TickCount - g_PreviousZoneStartTime) / 1000, 2)
        if (isStuck)
        {
            this.RestartAdventure( "Game is stuck z[" . this.Memory.ReadCurrentZone() . "]")
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            lastCheck := 0
            fallBackTries := 0
            return true
        }
        if (dtCurrentZoneTime > 35 AND dtCurrentZoneTime <= 45 AND dtCurrentZoneTime - lastCheck > 5) ; first check - ensuring autoprogress enabled
        {
            this.ToggleAutoProgress(1, true)
            if(dtCurrentZoneTime < 40)
                lastCheck := dtCurrentZoneTime
        }
        if (dtCurrentZoneTime > 45 AND fallBackTries < 3 AND dtCurrentZoneTime - lastCheck > 15) ; second check - Fall back to previous zone and try to continue
        {
            ; reset memory values in case they missed an update.
            this.Hwnd := WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )
            this.Memory.OpenProcessReader()
            this.ResetServerCall()
            ; try a fall back
            this.FallBackFromZone()
            this.DirectedInput(,, "{q}" ) ; safety for correct party
            this.ToggleAutoProgress(1, true)
            lastCheck := dtCurrentZoneTime
            fallBackTries++
        }
        if (dtCurrentZoneTime > 65)
        {
            this.RestartAdventure( "Game is stuck z[" . this.Memory.ReadCurrentZone() . "]" )
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            lastCheck := 0
            fallBackTries := 0
            return true
        }
        return false
    }

    ;Uses server calls to test for being on world map, and if so, start an adventure (CurrentObjID). If force is declared, will use server calls to stop/start adventure.
    RestartAdventure( reason := "" )
    {
            g_SharedData.LoopString := "ServerCall: Restarting adventure"
            this.CloseIC( reason )
            g_ServerCall.CallEndAdventure()
            g_ServerCall.CallLoadAdventure( this.CurrentAdventure )
    }

    /*  WaitForModronReset - A function that monitors a modron resetting process.

        Returns:
        bool - true if completed successfully; returns false if reset does not occur within 75s
    */
    WaitForModronReset( timeout := 75000)
    {
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.LoopString := "Modron Resetting..."
        while (this.Memory.ReadResetting() AND ElapsedTime < timeout)
        {
            ElapsedTime := A_TickCount - StartTime
        }
        g_SharedData.LoopString := "Loading z1..."
        Sleep, 50
        while(!this.Memory.ReadUserIsInited() AND ElapsedTime < timeout)
        {
            ElapsedTime := A_TickCount - StartTime
        }
        if (ElapsedTime >= timeout)
        {
            return false
        }
        return true
    }

    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "")
    {
        if(settings != "")
        {
            this.Settings := settings
        }
        ;only send input messages if necessary
        brivBenched := this.Memory.ReadChampBenchedByID(58)
        ;check to bench briv
        if (!brivBenched AND this.BenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        ;check to unbench briv
        if (brivBenched AND this.UnBenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        isFormation2 := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2))
        isWalkZone := this.Settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50)] == 0
        ; check to swap briv from favorite 2 to favorite 3 (W to E)
        if (!brivBenched AND isFormation2 AND isWalkZone)
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        if (!brivBenched AND isFormation2 AND !isWalkZone)
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
            return
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchBrivConditions(settings)
    {
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() == 3 )
            return true
        ;bench briv not in a preferred briv jump zone
        if (settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50) ] == 0)
            return true
        ;perform no other checks if 'Briv Jump Buffer' setting is disabled
        if !(settings[ "BrivJumpBuffer" ])
            return false
        ;bench briv if within the 'Briv Jump Buffer'-supposedly this reduces chances of failed conversions by having briv on bench during modron reset.
        maxSwapArea := this.ModronResetZone - settings[ "BrivJumpBuffer" ]
        if (this.Memory.ReadCurrentZone() >= maxSwapArea)
            return true

        return false
    }

    ; True/False on whether Briv should be unbenched based on game conditions.
    UnBenchBrivConditions(settings)
    {
        ; do not unbench briv if party is not on a perferred briv jump zone.
        if (settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 :  Mod(this.Memory.ReadCurrentZone(), 50)] == 0)
            return false
        ;unbench briv if 'Briv Jump Buffer' setting is disabled and transition direction is "OnFromLeft"
        if (!(settings[ "BrivJumpBuffer" ]) AND this.Memory.ReadFormationTransitionDir() == 0)
            return true
        ;perform no other checks if 'Briv Jump Buffer' setting is disabled
        else if !(settings[ "BrivJumpBuffer" ])
            return false
        ;keep briv benched if within the 'Briv Jump Buffer'-supposedly this reduces chances of failed conversions by having briv on bench during modron reset.
        maxSwapArea := this.ModronResetZone - settings[ "BrivJumpBuffer" ]
        if (this.Memory.ReadCurrentZone() >= maxSwapArea)
            return false
        ;unbench briv if outside the 'Briv Jump Buffer' and a jump animation override isn't added to the list
        else if (this.Memory.ReadTransitionOverrideSize() != 1)
            return true

        return false
    }

    ;===================================
    ;Functions for closing or opening IC
    ;===================================
    ;A function that closes IC. If IC takes longer than 60 seconds to save and close then the script will force it closed.
    CloseIC( string := "" )
    {
        g_SharedData.LastCloseReason := string
        ; check that server call object is updated before closing IC in case any server calls need to be made
        ; by the script before the game restarts
        this.ResetServerCall()
        if ( string != "" )
            string := ": " . string
        g_SharedData.LoopString := "Closing IC" . string
        sendMessageString := "ahk_exe " . g_userSettings[ "ExeName"]
        if WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )
            SendMessage, 0x112, 0xF060,,, %sendMessageString%,,,, 10000 ; WinClose
        StartTime := A_TickCount
        ElapsedTime := 0
        while ( WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ) AND ElapsedTime < 10000 )
        {
            Sleep, 200
            ElapsedTime := A_TickCount - StartTime
        }
        while ( WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ) ) ; Kill after 10 seconds.
            WinKill
        return
    }

    ; Attemps to open IC. Game should be closed before running this function or multiple copies could open.
    OpenIC()
    {
        timeoutVal := 32000 + 90000 ; 32s + waitforgameready timeout
        loadingDone := false
        g_SharedData.LoopString := "Starting Game"
        WinGetActiveTitle, savedActive
        this.SavedActiveWindow := savedActive
        StartTime := A_TickCount
        while ( !loadingZone AND ElapsedTime < timeoutVal )
        {
            this.Hwnd := 0
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime < timeoutVal)
                this.OpenProcessAndSetPID(timeoutVal - ElapsedTime)
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime < timeoutVal)
                this.SetLastActiveWindowWhileWaingForGameExe(timeoutVal - ElapsedTime)
            Process, Priority, % this.PID, High
            this.ActivateLastWindow()
            this.Memory.OpenProcessReader()
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime < timeoutVal)
                loadingZone := this.WaitForGameReady()
            if(loadingZone)
                this.ResetServerCall()
            Sleep, 62
            ElapsedTime := A_TickCount - StartTime
        }
        if(ElapsedTime >= timeoutVal)
            return -1 ; took too long to open
        else
            return 0
    }

    ; Runs the process and set this.PID once it is found running. 
    OpenProcessAndSetPID(timeoutLeft := 32000)
    {
        this.PID := 0
        processWaitingTimeout := 10000 ;10s
        waitForProcessTime := g_UserSettings[ "WaitForProcessTime" ]
        ElapsedTime := 0
        StartTime := A_TickCount
        while (!this.PID AND ElapsedTime < timeoutLeft )
        {
            g_SharedData.LoopString := "Opening IC.."
            programLoc := g_UserSettings[ "InstallPath" ]
            Run, %programLoc%
            Sleep, %waitForProcessTime%
            ; Add 10s (default) to ElapsedTime so each exe waiting loop will take at least 10s before trying to run a new instance of hte game
            timeoutForPID := ElapsedTime + processWaitingTimeout 
            while(!this.PID AND ElapsedTime < timeoutForPID AND ElapsedTime < timeoutLeft)
            {
                existingProcessID := g_userSettings[ "ExeName"]
                Process, Exist, %existingProcessID%
                this.PID := ErrorLevel
                Sleep, 62
                ElapsedTime := A_TickCount - StartTime
            }
            ElapsedTime := A_TickCount - StartTime
            Sleep, 62
        }
    }

    ; Saves this.SavedActiveWindow as the last window and waits for the game exe to load its window.
    SetLastActiveWindowWhileWaingForGameExe(timeoutLeft := 32000)
    {
        StartTime := A_TickCount
        ; Process exists, wait for the window:
        while(!(this.Hwnd := WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )) AND ElapsedTime < timeoutLeft)
        {
            WinGetActiveTitle, savedActive
            this.SavedActiveWindow := savedActive
            ElapsedTime := A_TickCount - StartTime
            Sleep, 62
        }
    }

    ; Template function for swapping windows after another has loaded.
    ActivateLastWindow() 
    { 
        ; Just for prototyping purposes
        Sleep, 100 ; extra wait for window to load
        hwnd := this.Hwnd
        WinActivate, ahk_id %hwnd% ; Idle Champions likes to be activated before it can be deactivated            
        savedActive := this.SavedActiveWindow
        WinActivate, %savedActive%
    }

    ; Waits for the game to be in a ready state
    WaitForGameReady( timeout := 90000)
    {
        timeoutTimerStart := A_TickCount
        ElapsedTime := 0
        ; wait for game to start
        g_SharedData.LoopString := "Waiting for game started.."
        gameStarted := 0
        while( ElapsedTime < timeout AND !gameStarted)
        {
            gameStarted := this.Memory.ReadGameStarted()
            ; If the popup warning message about failed offline progress, restart the game.
            ; if(this.Memory.ReadDialogActiveBySlot(this.Memory.GetDialogSlotByName("DontShowAgainDialog")) == 1)
            ; {
            ;     g_SharedData.LoopString := "Failed offline progress message. Restarting to clear popup."
            ;     this.CloseIC( "Failed offline progress warning." ) 
            ;     return false
            ; }
            Sleep, 100
            ElapsedTime := A_TickCount - timeoutTimerStart
        }
        ; check if game has offline progress to calculate
        offlineTime := this.Memory.ReadOfflineTime()
        if(gameStarted AND offlineTime <= 0 AND offlineTime != "")
            return true ; No offline progress to caclculate, game started
        ; wait for offline progress to finish
        g_SharedData.LoopString := "Waiting for offline progress.."
        offlineDone := 0
        while( ElapsedTime < timeout AND !offlineDone)
        {
            offlineDone := this.Memory.ReadOfflineDone()
            Sleep, 250
            ElapsedTime := A_TickCount - timeoutTimerStart
        }
        ; finished before timeout
        if(offlineDone)
        {
            this.WaitForFinalStatUpdates()
            g_PreviousZoneStartTime := A_TickCount
            return true
        }
        this.CloseIC( "WaitForGameReady-Failed to finish in " . Floor(timeout/ 1000) . "s." )
        return false
    }

    ; Waits until stats are finished updating from offline progress calculations.
    WaitForFinalStatUpdates()
    {
        g_SharedData.LoopString := "Waiting for offline progress (Area Active)..."
        ElapsedTime := 0
        ; Starts as 1, turns to 0, back to 1 when active again.
        StartTime := A_TickCount
        while(this.Memory.ReadAreaActive() AND ElapsedTime < 1736)
        {
            ElapsedTime := A_TickCount - StartTime
            Sleep, 15
        }
        while(!this.Memory.ReadAreaActive() AND ElapsedTime < 3038)
        {
            ElapsedTime := A_TickCount - StartTime
            Sleep, 15
        }
    }

    ;Reopens Idle Champions if it is closed. Calls RecoverFromGameClose after opening IC. Returns true if window still exists.
    SafetyCheck()
    {
        ; TODO: Base case check in case safety check never succeeds in opening the game.
        if (Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
        {
            if(this.OpenIC() == -1)
            {
                this.CloseIC("Failed to start Idle Champions")
                this.SafetyCheck()
            }
            if(this.Memory.ReadResetting() AND this.Memory.ReadCurrentZone() <= 1 AND this.Memory.ReadCurrentObjID() == "")
                this.WorldMapRestart()
            this.RecoverFromGameClose(this.GameStartFormation)
            this.BadSaveTest()
            return false
        }
         ; game loaded but can't read zone? failed to load proper on last load? (Tests if game started without script starting it)
        else if ( this.Memory.ReadCurrentZone() == "" )
        {
            this.Hwnd := WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )
            existingProcessID := g_userSettings[ "ExeName"]
            Process, Exist, %existingProcessID%
            this.PID := ErrorLevel
            this.Memory.OpenProcessReader()
            this.ResetServerCall()
        }
        return true
    }

    ; Checks for rollbacks after a stack restart.
    BadSaveTest()
    {
        if(this.CurrentZone != "" and this.CurrentZone - 1 > g_SF.Memory.ReadCurrentZone())
            g_SharedData.TotalRollBacks++
        else if (this.CurrentZone != "" and this.CurrentZone < g_SF.Memory.ReadCurrentZone())
            g_SharedData.BadAutoProgress++
    }

    ; Reloads memory reads after game has closed. For updating GUI.
    MonitorIsGameClosed()
    {
        static gameLoaded := false
        if(this.Memory.ReadCurrentZone() == "")
        {
            if (Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
            {
                gameLoaded := false
            }
            else if (!gameLoaded)
            {
                this.Memory.OpenProcessReader()
                gameLoaded := true
            }
        }
        return gameLoaded
    }

    /* Function that does follow-up tasks when IC is opened.
    This function should be overridden by AddOns using it to match their objective

    The default functionality is to switch to Q formation (briv progression), or
    fall back and switch to Q if being attacked
    */
    ; falls back zone until switching to Q formation can be done.
    RecoverFromGameClose(formationFavoriteNum := 1)
    {
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 67
        timeout := 10000
        isCurrentFormation := false
        if(this.Memory.ReadCurrentZone() == 1)
            return
        if(formationFavoriteNum == 1)
            spam := ["{q}"]
        else if(formationFavoriteNum == 2)
            spam := ["{w}"]
        else if(formationFavoriteNum == 3)
            spam := ["{e}"]
        else
            spam := ""
        g_SharedData.LoopString := "Waiting for offline settings wipe..."
        while(this.Memory.ReadNumAttackingMonstersReached() >= 95 AND ElapsedTime < timeout )
        {
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime > sleepTime * counter AND IsObject(spam))
            {
                this.DirectedInput(,, spam* )
                counter++
            }
            else
                Sleep, 20
        }
        g_SharedData.LoopString := "Waiting for formation swap..."
        formationFavorite := this.Memory.GetFormationByFavorite( formationFavoriteNum )
        ElapsedTime := counter := 0
        while(!isCurrentFormation AND ElapsedTime < timeout AND !this.Memory.ReadNumAttackingMonstersReached())
        {
            isCurrentFormation := this.IsCurrentFormation( formationFavorite )
            ElapsedTime := A_TickCount - StartTime
            if(ElapsedTime > sleepTime * counter AND IsObject(spam))
            {
                this.DirectedInput(,, spam* )
                counter++
            }
            else
                Sleep, 20
        }
        isCurrentFormation := this.IsCurrentFormation( formationFavorite )
        ;spam.Push(this.GetFormationFKeys(formationFavorite1)*) ; make sure champions are leveled
        ;;;if ( this.Memory.ReadNumAttackingMonstersReached() OR this.Memory.ReadNumRangedAttackingMonsters() )
        g_SharedData.LoopString := "Under attack. Retreating to change formations..."
        while(!IsCurrentFormation AND (this.Memory.ReadNumAttackingMonstersReached() OR this.Memory.ReadNumRangedAttackingMonsters()) AND (ElapsedTime < (2 * timeout)))
        {
            ElapsedTime := A_TickCount - StartTime
            this.FallBackFromZone()
            this.DirectedInput(,, spam* ) ;not spammed, delayed by fallback call
            this.ToggleAutoProgress(1, true)
            isCurrentFormation := this.IsCurrentFormation( formationFavorite )
        }
        g_SharedData.LoopString := "Loading game finished."
    }

    ;Returns true if the formation array passed is the same as the formation currently on the game field. Always false on empty formation reads. Requires full formation.
    IsCurrentFormation(testformation := "")
    {
        if(!IsObject(testFormation))
            return false
        currentFormation := this.Memory.GetCurrentFormation()
        if(!IsObject(currentFormation))
            return false
        if(currentFormation.Count() != testformation.Count())
            return false
        loop, % currentFormation.Count()
        {
            if(testformation[A_Index] != currentFormation[A_Index])
                return false
        }
        return true
    }

    ;Reads game for UserID, UserHash, InstanceID and stores it to script memory.
    SetUserCredentials()
    {
        this.UserID := this.Memory.ReadUserID()
        this.UserHash := this.Memory.ReadUserHash()
        this.InstanceID := this.Memory.ReadInstanceID()
        ; needed to know if there are enough chests to open using server calls
        this.TotalGems := this.Memory.ReadGems()
        silverChests := this.Memory.ReadChestCountByID(1)
        goldChests := this.Memory.ReadChestCountByID(2)
        this.TotalSilverChests := (silverChests != "") ? silverChests : 0
        this.TotalGoldChests := (goldChests != "") ? goldChests : 0
    }

    ; Forces an adventure restart through closing IC and using server calls
    WorldMapRestart()
    {
        g_SharedData.LoopString := "Zone is -1. At world map?"
        this.RestartAdventure( "Zone is -1. At world map? Forcing Restart." )
    }

    ;=================================
    ;Functions for leveling a champion
    ;=================================
    ;similar to LevelToTargetByID, but doesn't require HeroDefines and thus relies on specializing via modron, also accepts a parameter for additional key inputs.
    LevelChampByID(ChampID := 1, Lvl := 0, timeout := 5000, keys := "{q}")
    {
        Critical, On
        g_SharedData.LoopString := "Leveling Champ " . ChampID . " to " . Lvl
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 34
        seat := this.Memory.ReadChampSeatByID(ChampID)
        if ( seat < 0 )
        {
            Critical, Off
            return
        }
        var := ["{F" . seat . "}"]
        keys := !IsObject(keys) ? [keys] : keys
        this.DirectedInput(,, keys* )
        this.DirectedInput(,release := 0, var* ) ; keysdown
        champLevel := this.Memory.ReadChampLvlByID( ChampID )
        while ( champLevel < Lvl AND ElapsedTime < timeout )
        {
            ElapsedTime := A_TickCount - StartTime
            champLevel := this.Memory.ReadChampLvlByID( ChampID )
            if( ElapsedTime > (counter * sleepTime) ) ; input limiter..
            {
                this.DirectedInput(hold:=0,, var* ) ;keysup
                this.DirectedInput(,release := 0, var* ) ; keysdown
                if(!Mod(counter, 10))
                    this.DirectedInput(,, keys* )
                counter ++
            }
        }
        Critical, Off
        return
    }

    ;=========================================================
    ;Functions for testing if Automated script is ready to run
    ;=========================================================

    /* A function to search a saved formation for a particular champ.

        Parameters:
            FavoriteSlot - 1 == Q, 2 == W, 3 == E
            includeChampion - 1 == success when champion is found, 0 == success when champion not found
            champID - champion ID to be searched for

        Return:
            Array of champion IDs from the saved formation. -1 represents an empty slot.
            A value of "" means run needs to be canceled.
    */
    ; Finds a specific champ in a favorite formation. Returns -1 on failure and the formation object otherwise.
    FindChampIDinSavedFavorite( champID := 58, favorite := 1, includeChampion := True )
    {
        formationSaveSlot := this.Memory.GetSavedFormationSlotByFavorite( favorite )
        if (formationSaveSlot < 0)
            return -1
        formation := this.Memory.GetFormationSaveBySlot( formationSaveSlot, 0 )
        formationSize := formation.Count()
        if (!formationSize OR formationSize > 50 OR formationSize < 0 )
            return -1
        foundChamp := this.IsChampInFormation(champID, formation)
        if (!foundChamp AND includeChampion)
            return -1
        else if (foundChamp AND !includeChampion)
            return -1
        return formation
        ; foundChampName := this.Memory.ReadChampNameByID(champID)
    }

    ; Displays a MsgBox with a prompt until the test function succeeds or prompt is canceled. Returns -1 on cancel.
    RetryTestOnError( errMsg := "Error", testFunction := "", expectedValue := "", shouldBeEqual := True, testSize := False)
    {
        if(testFunction == "" OR testFunction.Base.Call != "")
        {
            MsgBox,, RetryTstOnError, No function to retry!
            return -1
        }
        foundValue := testFunction.Call() ; Some value that should never be read from game's memory. Do while loop at least once.
        
        ; Test if expected value matches OR test if should NOT find expected value
        while ( (foundValue == expectedValue AND !shouldBeEqual) OR (foundValue != expectedValue AND shouldBeEqual) )
        {
            MsgBox, 5,, %errMsg%
            IfMsgBox, Retry
            {
                this.Memory.OpenProcessReader()
                foundValue := testFunction.Call()
                if (testSize)
                    foundValue := foundValue.Count()
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return -1
            }
        }
        return foundValue
    }

    ; -----------------------------------------------------------------
    /* A function to search a saved favorite for familiars on click damage.

        Parameters:
            favorite - 1 == Q, 2 == W, 3 == E
            shouldInclude - Whether the formation should include familiars

        Return:
            -1 if invalid favorite.
            ErrorMsg - a string containing an error message if needed.
            "" if all checks passed okay.
    */
    ; -----------------------------------------------------------------

    ;Searches a saved favorite for familiars on click damage.
    FormationFamiliarCheckByFavorite(favorite := 1, shouldInclude := True)
    {
        ErrorMsg := ""
        if(favorite < 1 OR favorite > 3)
            return -1 ; failed call. -1 is used because "" IS a valid read from this function.
        FormationFavoriteHotkey := {1:"Q", 2:"W", 3:"E"}
        ; Favorites 1 and 3 SHOULD have familirs.
        ; Formation 2 should NOT have familiars.
        if (shouldInclude AND this.Memory.GetFormationFamiliarsByFavorite(favorite) == "")
        {
            ErrorMsg := "Warning: No famliars found in Favorite Formation " . favorite . " (" . FormationFavoriteHotkey[favorite] . "). It is highly recommended to use familiars for click damage."
            return ErrorMsg
        }
        if (!shouldInclude AND this.Memory.GetFormationFamiliarsByFavorite(favorite) != "")
        {
            ErrorMsg := "Familiars found in Favorite Formation " . favorite . " (" . FormationFavoriteHotkey[favorite] . "). Remove familiars before continuing."
            return ErrorMsg
        }
        return ErrorMsg
    }

    ; Tests if there is an adventure (objective) loaded. If not, asks the user to verify they are using the correct memory files and have an adventure loaded
    ; Returns -1 if failed to load adventure id. Returns current adventure's ID if successful in finding adventure.
    VerifyAdventureLoaded()
    {
        CurrentObjID := this.Memory.ReadCurrentObjID()
        while ( CurrentObjID == "" OR CurrentObjID <= 0 )
        {
            txtCheck := "Unable to read adventure data."
            txtCheck .= "`n1. Please load into a valid adventure. Current adventure shows as: " . (CurrentObjID ? CurrentObjID : "-- Error --")
            txtcheck .= "`n2. Make sure the game exe in Game Location settings is set to ""IdleDragons.exe"""
            txtCheck .= "`n3. Check the correct memory file is being used. `n    Current version: " . this.Memory.GameManager.GetVersion()
            txtcheck .= "`n4. If IC is running with admin privileges, then the script will also require admin privileges."
            if (_MemoryManager.is64bit)
                txtcheck .= "`n5. Check AHK is 64-bit. (Currently " . (A_PtrSize = 4 ? 32 : 64) . "-bit)"
            MsgBox, 5,, % txtCheck

            IfMsgBox, Retry
            {
                this.Memory.OpenProcessReader()
                CurrentObjID := this.Memory.ReadCurrentObjID()
            }
            IfMsgBox, Cancel
            {
                MsgBox, Stopping run.
                return -1
            }
        }
        return CurrentObjID
    }

    ;======================
    ; Server Calls
    ;======================

    ; sets the user information used in server calls such as user_id, hash, active modron, etc.
    ResetServerCall()
    {
        this.SetUserCredentials()
        previousPatron := g_ServerCall.activePatronID ? g_ServerCall.activePatronID : 0 
        g_ServerCall := new IC_ServerCalls_Class( this.UserID, this.UserHash, this.InstanceID ) ; Note: resets patronID to 0
        version := this.Memory.ReadBaseGameVersion()
        if(version != "")
            g_ServerCall.clientVersion := version
        tempWebRoot := this.Memory.ReadWebRoot()
        httpString := StrSplit(tempWebRoot,":")[1]
        isWebRootValid := httpString == "http" or httpString == "https"
        g_ServerCall.webroot := isWebRootValid ? tempWebRoot : g_ServerCall.webroot
        g_ServerCall.networkID := this.Memory.ReadPlatform() ? this.Memory.ReadPlatform() : g_ServerCall.networkID
        g_ServerCall.activeModronID := this.Memory.ReadActiveGameInstance() ? this.Memory.ReadActiveGameInstance() : 1 ; 1, 2, 3 for modron cores 1, 2, 3
        g_ServerCall.activePatronID := this.Memory.ReadPatronID() == "" ? previousPatron : this.Memory.ReadPatronID() ; 0 = no patron
        g_ServerCall.UpdateDummyData()
    }

    ;======================
    ; New Helper Functions
    ;======================

    ; Calculates the number of Haste stacks are required to jump from area 1 to the modron's reset area. worstCase default is true.
    CalculateBrivStacksToReachNextModronResetZone(worstCase := true)
    {
        jumps := 0
        consume := this.IsBrivMetalborn() ? -.032 : -.04  ;Default := 4%, SteelBorn := 3.2%
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        distance := this.Memory.GetModronResetArea()
        ; skipAmount == 1 is a special case where Briv won't use stacks when he skips 0 areas.
        ; average
        if(skipAmount == 1) ; true worst case =  worstCase ? Ceil(distance / 2) : normalcalc
            jumps := worstCase ? Ceil(((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1)) * 1.15) : Ceil((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1))
        else
            jumps := Ceil(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance)))
        isEffectively100 := 1 - skipChance < .004
        stacks := Ceil(49 / (1+consume)**jumps)
        if (worstCase AND skipChance < 1 AND !isEffectively100 AND skipAmount != 1) 
            stacks := Floor(stacks * 1.15) ; 15% more - guesstimate
        return stacks
    }

    ; Calculates the number of Haste stacks that will be left over once when the target zone has been reached. Defaults: startZone=1, targetZone=1, worstCase=true.
    CalculateBrivStacksLeftAtTargetZone(startZone := 1, targetZone := 1, worstCase := true)
    {
        jumps := 0
        consume := this.IsBrivMetalborn() ? -.032 : -.04 ;Default := 4%, MetalBorn := 3.2%
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        distance := targetZone - startZone
        ; skipAmount == 1 is a special case where Briv won't use stacks when he skips 0 areas.
        if(skipAmount == 1)
            jumps := worstCase ? Max(Ceil(distance / 2),0) : Max(Ceil((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1)),0)
        else
            jumps :=  Max(Floor(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance))), 0)
        isEffectively100 := 1 - skipChance < .004
        if (worstCase AND skipChance < 1 AND !isEffectively100 AND skipAmount != 1)
            jumps := Floor(jumps * 1.05)
        return Floor(stacks*(1+consume)**jumps)
    }

    ; Calculates the number of Haste stacks will be used to progress from the current zone to the modron reset area.
    CalculateBrivStacksConsumedToReachModronResetZone(worstCase := true)
    {
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        return stacks - this.CalculateBrivStacksLeftAtTargetZone(this.Memory.ReadCurrentZone(), this.Memory.GetModronResetArea() + 1, worstCase)
    }

    ; Calculates the farthest zone Briv expects to jump to with his current stacks on his current zone.  avgMinOrMax: avg = 0, min = 1, max = 2.
    CalculateMaxZone(avgMinOrMax := 0)
    {
        ; 1 jump results will change based on the current zone depending on whether the previous zones had jumps and used stacks or not.
        consume := this.IsBrivMetalborn() ? -.032 : -.04 ;Default := 4%, MetalBorn := 3.2%
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        currentZone := this.Memory.ReadCurrentZone()
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        jumps := Floor(Log(49 / Max(stacks,49)) / Log(1+consume))
        avgJumpDistance := skipAmount * (1-skipChance) + (skipAmount+1) * skipChance
        maxJumpDistance := skipAmount+1
        minJumpDistance := skipAmount
        ;zones := jumps * avgJumpDistance
        zones := avgMinOrMax == 0 ? jumps * avgJumpDistance : (avgMinOrMax == 1 ? jumps * minJumpDistance : jumps * maxJumpDistance)
        return currentZone + zones
    }

    ; Returns whether Briv's spec in the modron core is set to Metalborn.
    IsBrivMetalborn()
    {
        brivID := 58
        specID := this.Memory.GetCoreSpecializationForHero(brivID)
        if (specID == 3455)
            return true
        return false
    }

    IsChampInFavoriteFormation(champID := 1, favorite := 1)
    {
        formation := this.Memory.GetFormationByFavorite(favorite)
        return this.IsChampInFormation(champID, formation)
    }

    /*  GetFormationFKeys - Gets a list of FKeys required to level all champions in the formation passed to it.

    Parameters:
    formation - A list of champion ID values.

    Returns:
    FKey - A list of keys, for use in keyspamming. (e.g. ["{F1}", "{F2}", "{F5}", "{F6}"]))
    */
    ; Takes an array of champion IDs and creates a list of FKeys for their appropriate seat slots.
    GetFormationFKeys(formation)
    {
        Fkeys := {}
        for k, v in formation
        {
            ;added a check that v is not 0 or "" for bad reads or NPC in saved formation some how, they show up as 0 supposedly.
            if ( v != -1 AND v )
            {
                Fkeys.Push("{F" . this.Memory.ReadChampSeatByID(v) . "}")
            }
        }
        return Fkeys
    }

    /*  AreChampionsUpgraded - Tests to see if all seats in formation are upgraded to max.

    Parameters:
    formation - A list of champion ID values from the formation currently on the field.

    Returns:
    True if all seats are fully upgraded. False otherwise.
    */
    ; Takes an array of champion IDs and determines if the slots they are in (NOT the champions themselves) are fully upgraded.
    AreChampionsUpgraded(formation)
    {
        for k, v in formation
        {
            if ( v != -1 )
            {
                hasSeatUpgrade := this.Memory.ReadBoughtLastUpgrade(this.Memory.ReadChampSeatByID(v))
                if (!hasSeatUpgrade)
                    return false
            }
        }
        return true
    }

    ;a method to get the ultimate button number corresponding to a given champ
    ;parameter: champID - the champion ID you want to match
    ;returns button number on success, -1 on failure.
    GetUltimateButtonByChampID(champID)
    {
        i := 0
        loop, % this.Memory.ReadUltimateButtonListSize()
        {
            if (champID == this.Memory.ReadUltimateButtonChampIDByItem(i))
            {
                if (i < 9)
                    return ++i
                Else
                    return 0
            }
            i++
        }
        return -1
    }

    #include *i %A_LineFile%\..\IC_SharedFunctions_Extra.ahk
}
#include *i %A_LineFile%\..\IC_SharedFunctions_Extended.ahk

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
;Shandie's Dash handler
#include %A_LineFile%\..\MemoryRead\EffectKeyHandlers\TimeScaleWhenNotAttackedHandler.ahk

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

    __new()
    {
        this.Memory := New IC_MemoryFunctions_Class
    }

    ;=======================
    ;Script Helper Functions
    ;=======================

    ; returns this class's version information (string)
    GetVersion()
    {
        return "v2.5.4, 2022-02-15"
    }

    ;Gets data from JSON file
    LoadObjectFromJSON( FileName )
    {
        FileRead, oData, %FileName%
        return JSON.parse( oData )
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

    ;====================================================
    ;General use functions, useful for a variety of tasks
    ;====================================================
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
    DirectedInput(hold := 1, release := 1, s* )
    {
        Critical, On
        ; TestVar := {}
        ; for k,v in g_KeyPresses
        ; {
        ;     TestVar[k] := v
        ; }
        timeout := 33
        directedInputStart := A_TickCount
        ;hwnd := "ahk_exe IdleDragons.exe"
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
                    SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,%timeout%
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
                    SendMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,,%timeout%
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
                SendMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,,%timeout%
                if ErrorLevel
                    this.ErrorKeyDown++
            }
            if(release)
                SendMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,,%timeout%
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
        StartTime := A_TickCount
        ElapsedTime := 0
        dash := new TimeScaleWhenNotAttackedHandler ; create a new Dash Handler object.
        dash.Initialize()
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := timeScale < 1 ? 1 : timeScale ; time scale should never be less than 1
        timeout := 60000 ; 60s seconds ( previously / timescale (6s at 10x) )
        estimate := (60000 / timeScale) ; no buffer: 60s / timescale to show in LoopString
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted dashwait triggering area
        ;   dash is active, dash.GetScaleActive() toggles to true when dash is active and returns "" if fails to read.
        while ( ElapsedTime < timeout AND this.Memory.ReadCurrentZone() < DashWaitMaxZone AND !(dash.GetScaleActive()) )
        {
            this.ToggleAutoProgress(0)
            if !(this.SafetyCheck()) OR !(dash.IsBaseAddressCorrect())
                dash.Initialize()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }

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
        multipliersCount := this.Memory.ReadTimeScaleMultipliersCount()
        loop, % multipliersCount
        {
            ;should this if be an OR? Will the floating point number always be exactly 1.5?
            if(this.Memory.ReadTimeScaleMultiplierByIndex(A_Index - 1) == 1.5 AND this.Memory.ReadTimeScaleMultipliersKeyByIndex(A_Index - 1) == 2774)
                return true
        }
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
        this.ModronResetZone := this.Memory.GetCoreTargetAreaByInstance(this.Memory.ReadActiveGameInstance()) ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }

    ;A test if stuck on current area. After 35s, toggles autoprogress every 5s. After 45s, attempts falling back up to 2 times. After 65s, restarts level.
    CheckifStuck()
    {
        static lastCheck := 0
        static fallBackTries := 0
        ;TODO: add better code in case a modron reset happens without being detected. might mean updating other functions.
        dtCurrentZoneTime := Round((A_TickCount - g_PreviousZoneStartTime) / 1000, 2)
        if (dtCurrentZoneTime > 35 AND dtCurrentZoneTime <= 45 AND dtCurrentZoneTime - lastCheck > 5) ; first check - ensuring autoprogress enabled
        {
            this.ToggleAutoProgress(1, true)
            if(dtCurrentZoneTime < 40)
                lastCheck := dtCurrentZoneTime
        }
        if (dtCurrentZoneTime > 45 AND fallBackTries < 3 AND dtCurrentZoneTime - lastCheck > 15) ; second check - Fall back to previous zone and try to continue
        {
            ; reset memory values in case they missed an update.
            this.Hwnd := WinExist( "ahk_exe IdleDragons.exe" )
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
            this.RestartAdventure( "Game is stuck" )
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
        ;only send input messages if necessary
        brivBenched := this.Memory.ReadChampBenchedByID(58)
        ;check to bench briv
        if (!brivBenched AND this.BenchBrivConditions(settings))
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.SwapsMadeThisRun++
        }
        ;check to unbench briv
        else if (brivBenched AND this.UnBenchBrivConditions(settings))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        else if (!brivBenched AND this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2)))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchBrivConditions(settings)
    {
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() == 3 )
            return true
        ;bench briv if avoid bosses setting is on and on a boss zone
        if (settings[ "AvoidBosses" ] AND !Mod( this.Memory.ReadCurrentZone(), 5 ))
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
        ;keep Briv benched if 'Avoid Bosses' setting is enabled and on a boss zone
        if (settings[ "AvoidBosses" ] AND !Mod( this.Memory.ReadCurrentZone(), 5 ))
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
        ; check that server call object is updated before closing IC in case any server calls need to be made
        ; by the script before the game restarts
        this.ResetServerCall()
        if ( string != "" )
            string := ": " . string
        g_SharedData.LoopString := "Closing IC" . string
        if WinExist( "ahk_exe IdleDragons.exe" )
            SendMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe,,,, 10000 ; WinClose
        StartTime := A_TickCount
        ElapsedTime := 0
        while ( WinExist( "ahk_exe IdleDragons.exe" ) AND ElapsedTime < 10000 )
            ElapsedTime := A_TickCount - StartTime
        while ( WinExist( "ahk_exe IdleDragons.exe" ) ) ; Kill after 10 seconds.
            WinKill
        return
    }

    ; Attemps to open IC. Game should be closed before running this function or multiple copies could open.
    OpenIC()
    {
        loadingDone := false
        g_SharedData.LoopString := "Starting Game"
        waitForProcessTime := g_UserSettings[ "WaitForProcessTime" ]
        WinGetActiveTitle, savedActive
        this.SavedActiveWindow := savedActive
        while ( !loadingZone AND ElapsedTime < 32000 )
        {
            this.Hwnd := 0
            this.PID := 0
            while (!this.PID)
            {
                StartTime := A_TickCount
                ElapsedTime := 0
                g_SharedData.LoopString := "Opening IC.."
                programLoc := g_UserSettings[ "InstallPath" ] . g_UserSettings ["ExeName" ]
                Run, %programLoc%
                Sleep, %waitForProcessTime%
                while(ElapsedTime < 10000 AND !this.PID )
                {
                    ElapsedTime := A_TickCount - StartTime
                    Process, Exist, IdleDragons.exe
                    this.PID := ErrorLevel
                }
            }
            ; Process exists, wait for the window:
            while(!(this.Hwnd := WinExist( "ahk_exe IdleDragons.exe" )) AND ElapsedTime < 32000)
                ElapsedTime := A_TickCount - StartTime
            this.ActivateLastWindow()
            Process, Priority, % this.PID, High
            this.Memory.OpenProcessReader()
            loadingZone := this.WaitForGameReady()
            this.ResetServerCall()
        }
        if(ElapsedTime >= 30000)
            return -1 ; took too long to open
        else
            return 0
    }

    ActivateLastWindow() { ; Just for prototyping purposes
    }

    ; Waits for the game to be in a ready state
    WaitForGameReady( timeout := 90000)
    {
        timeoutTimerStart := A_TickCount
        ElapsedTime := 0
        ; wait for game to start
        g_SharedData.LoopString := "Waiting for game started.."
        while( ElapsedTime < timeout AND !this.Memory.ReadGameStarted())
        {
            ElapsedTime := A_TickCount - timeoutTimerStart
        }
        ; check if game has offline progress to calculate
        offlineTime := this.Memory.ReadOfflineTime()
        if(this.Memory.ReadGameStarted())
        {
            if(offlineTime <= 0 AND offlineTime != "")
                return true ; No offline progress to caclculate, game started
            else
            {
                ; wait for offline progress to finish
                g_SharedData.LoopString := "Waiting for offline progress.."
                while( ElapsedTime < timeout AND !this.Memory.ReadOfflineDone())
                {
                    ElapsedTime := A_TickCount - timeoutTimerStart
                }
                ; finished before timeout
                if(this.Memory.ReadOfflineDone())
                {
                    this.WaitForFinalStatUpdates()
                    g_PreviousZoneStartTime := A_TickCount
                    return true
                }
            }
        }
        ; timed out
        secondsToTimeout := Floor(timeout/ 1000)
        this.CloseIC( "WaitForGameReady-Failed to finish in " . secondsToTimeout . "s." )
        return false
    }

    ; Waits until stats are finished updating from offline progress calculations. (Currently just Sleep, 1200)
    WaitForFinalStatUpdates()
    {
        g_SharedData.LoopString := "Waiting for offline progress (Area Active)..."
        ; Starts as 1, turns to 0, back to 1 when active again.
        StartTime := ElapsedTime := A_TickCount
        while(this.Memory.ReadAreaActive() AND ElapsedTime < 1700)
            ElapsedTime := A_TickCount - StartTime
        while(!this.Memory.ReadAreaActive() AND ElapsedTime < 3000)
            ElapsedTime := A_TickCount - StartTime
        ; Briv stacks are finished updating shortly after ReadOfflineDone() completes. Give it a second.
        ; Sleep, 1200
    }

    ;Reopens Idle Champions if it is closed. Calls RecoverFromGameClose after opening IC. Returns true if window still exists.
    SafetyCheck()
    {
        if (Not WinExist( "ahk_exe IdleDragons.exe" ))
        {
            if(this.OpenIC() == -1)
            {
                this.CloseIC("Failed to start Idle Champions")
                this.SafetyCheck()
            }
            if(this.Memory.ReadResetting() AND this.Memory.ReadCurrentZone() <= 1 AND this.Memory.ReadCurrentObjID() == "")
                this.WorldMapRestart()
            this.RecoverFromGameClose(this.GameStartFormation)
            return false
        }
         ; game loaded but can't read zone? failed to load proper on last load? (Tests if game started without script starting it)
        else if ( this.Memory.ReadCurrentZone() == "" )
        {
            this.Hwnd := WinExist( "ahk_exe IdleDragons.exe" )
            Process, Exist, IdleDragons.exe
            this.PID := ErrorLevel
            this.Memory.OpenProcessReader()
            this.ResetServerCall()
        }
        return true
    }

    ; Reloads memory reads after game has closed. For updating GUI.
    MonitorIsGameClosed()
    {
        static gameLoaded := false
        if(this.Memory.ReadCurrentZone() == "")
        {
            if (Not WinExist( "ahk_exe IdleDragons.exe" ))
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
        }
        g_SharedData.LoopString := "Waiting for formation swap..."
        formationFavorite := this.Memory.GetFormationByFavorite( formationFavoriteNum )
        ElapsedTime := counter := 0
        while(!isCurrentFormation AND ElapsedTime < timeout AND !this.Memory.ReadNumAttackingMonstersReached())
        {
            ElapsedTime := A_TickCount - StartTime
            isCurrentFormation := this.IsCurrentFormation( formationFavorite )
            if(ElapsedTime > sleepTime * counter AND IsObject(spam))
            {
                this.DirectedInput(,, spam* )
                counter++
            }
        }
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
        this.ToggleAutoProgress(1)
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
        this.TotalSilverChests := this.Memory.GetChestCountByID(1)
        this.TotalGoldChests := this.Memory.GetChestCountByID(2)
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
            team - String, used for debugging to identify the formation you are searching though
            findChamp - 1 == success when champion is found, 0 == success when champion not found
            champID - champion ID to be searched for

        Return:
            Array of champion IDs from the saved formation. -1 represents an empty slot.
            A value of "" means run needs to be canceled.
    */
    FindChampIDinSavedFormation( FavoriteSlot := 1, team := "Speed", findChamp := 1, champID := 58 )
    {
        memoryVersion := this.Memory.GameManager.GetVersion()
        formationSaveSlot := this.Memory.GetSavedFormationSlotByFavorite( FavoriteSlot )
        ; Test Favorite Exists
        txtCheck := "1. Check the correct memory file is being used. Current version: " . memoryVersion
        txtcheck .= "`n`n2. If IC is running with admin privileges, then the script will also require admin privileges."
        if (this.Memory.GameManager.is64bit())
            txtcheck .= "`n`n3. Check AHK is 64bit."
        while ( formationSaveSlot == -1 )
        {
            MsgBox, 5,, Please confirm a formation is saved in formation favorite slot %FavoriteSlot%.`n`nOther potential solutions:`n`n%txtCheck%
            IfMsgBox, Retry
            {
                this.Memory.OpenProcessReader()
                formationSaveSlot := this.Memory.GetSavedFormationSlotByFavorite( FavoriteSlot )
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return ""
            }
        }
        formation := this.Memory.GetFormationSaveBySlot( formationSaveSlot, 0 )
        var := formation.Count()
        ; Test that the formation has champions
        while !var
        {
            MsgBox, 5,, Please confirm your %team% team is saved in formation favorite slot %FavoriteSlot%.`n`nOther potential solutions:`n`n%txtCheck%
            IfMsgBox, Retry
            {
                this.Memory.OpenProcessReader()
                formation := this.Memory.GetFormationSaveBySlot( formationSaveSlot, 1 )
                var := formation.Count()
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return ""
            }
        }
        foundChamp := this.IsChampInFormation(champID, formation)
        foundChampName := this.Memory.ReadChampNameByID(champID)
        stateText := findChamp ? "is" : "isn't"
        ; Test that the specific champions is in the formation
        while ( foundChamp != findChamp )
        {
            MsgBox, 5,, Please confirm %foundChampName% %stateText% saved in formation favorite slot %FavoriteSlot%.`n`nOther potential solutions:`n`n%txtCheck%
            IfMsgBox, Retry
            {
                this.Memory.OpenProcessReader()
                formation := this.Memory.GetFormationByFavorite( FavoriteSlot )
                foundChamp := this.IsChampInFormation(champID, formation)
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return ""
            }
        }
        return formation
    }

    ; Tests if there is an adventure (objective) loaded. If not, asks the user to verify they are using the correct memory files and have an adventure loaded
    ; Returns -1 if failed to load adventure id. Returns current adventure's ID if successful in finding adventure.
    VerifyAdventureLoaded()
    {
        CurrentObjID := this.Memory.ReadCurrentObjID()
        while ( CurrentObjID == "" OR CurrentObjID <= 0 )
        {
            MsgBox, 5,, % "Please load into a valid adventure or confirm the correct memory file is being used. `nCurrent version: " . this.Memory.GameManager.GetVersion() . "`nDebug Value: " CurrentObjID
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
        g_ServerCall := new IC_ServerCalls_Class( this.UserID, this.UserHash, this.InstanceID )
        version := this.Memory.ReadGameVersion()
        if(version != "")
            g_ServerCall.clientVersion := version
        tempWebRoot := this.Memory.ReadWebRoot()
        httpString := StrSplit(tempWebRoot,":")
        isWebRootValid := httpString == "http" or httpString == "https"
        g_ServerCall.webroot := isWebRootValid ? this.Memory.ReadWebRoot() : g_ServerCall.webroot
        g_ServerCall.networkID := this.Memory.ReadPlatform() ? this.Memory.ReadPlatform() : g_ServerCall.networkID
        g_ServerCall.activeModronID := this.Memory.ReadActiveGameInstance() ? this.Memory.ReadActiveGameInstance() : 1 ; 1, 2, 3 for modron cores 1, 2, 3
        g_ServerCall.activePatronID := this.Memory.ReadPatronID() ; 0 = no patron
        g_ServerCall.UpdateDummyData()
    }

    ;======================
    ; New Helper Functions
    ;======================

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

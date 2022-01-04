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
#include %A_LineFile%\..\IC_UserDetails_Class.ahk
#include %A_LineFile%\..\MemoryRead\IC_MemoryFunctions_Class.ahk

class IC_SharedData_Class
{
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
        return "v2.3, 01/01/2022"
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
        sleepTime := 20
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
        while(this.Memory.ReadCurrentZone() == -1)
            CurrentZone := this.Memory.ReadCurrentZone()
        CurrentZone := this.Memory.ReadCurrentZone()
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 100
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

    /*  FinishZone - Completes the quests in the current zone

        Parameters:
        maxLoopTime ;Maximum time, in milliseconds, the loop will continue.

        Returns: nothing

        Does not include WaitForTransition for situations when autoprogress is off and you may want to spam ults or something before triggering a transition.
        ; TODO: test if champ leveling / ult spamming is needed
    */
    FinishZone(maxLoopTime := 60000 )
    {
        StartTime := A_TickCount
        ElapsedTime := 0
        QuestRemaining := this.Memory.ReadQuestRemaining()
        g_SharedData.LoopString := "Finishing Zone: " . QuestRemaining . " / 25"
        while ( QuestRemaining AND ElapsedTime < maxLoopTime )
        {
            QuestRemaining := this.Memory.ReadQuestRemaining()
            g_SharedData.LoopString := "Finishing Zone: " . QuestRemaining . " / 25"
            ElapsedTime := A_TickCount - StartTime
        }
        return
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
        g_SF.DirectedInput(,, "{q}")
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
        TestVar := {}
        for k,v in g_KeyPresses
        {
            TestVar[k] := v
        }
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
                    if TestVar[v] == ""
                        TestVar[v] := 0
                    TestVar[v] += 1
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
                if TestVar[v] == ""
                    TestVar[v] := 0
                TestVar[v] += 1
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
        g_KeyPresses := TestVar
    }
 
    ;Test to see if swapping is unneccessary. (Useful for skipping swaps on Tall Tales adventure)
    ShouldSkipSwap()
    {
        ; 0 = right, 1 = left, 2 = static (instant)
        if(this.Memory.ReadTransitionDirection() == 2)
            return true
        return false
    }

    ;================================
    ;Functions mostly for gem farming
    ;================================
    /*  DoDashWait - A function that will wait for Dash ability to activate by reading the current time scale multiplier.

        Parameters:
        DashSleepTime ;Maximum time, in milliseconds, the loop will continue. This value is modified by the time scale multiplier at the start of the loop.

        Returns: nothing
    */
    DoDashWait( DashSleepTime )
    {
        this.ToggleAutoProgress( 0, false, true )
        specializedCount := g_SF.CountTimeScaleMultipliersOfValue(1.5)
        unSpecializedCount := g_SF.CountTimeScaleMultipliersOfValue(1.25)
        this.LevelChampByID( 47, 230, 7000, "{q}") ; level shandie
        StartTime := A_TickCount
        ElapsedTime := 0
        g_BrivUserSettings["DashWaitBuffer"] := 2500
        ;timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        if (timeScale < 1)
            timeScale := 1
        DashSpeed := Min(timeScale * 1.24, 10.0) ;time scale multiplier caps at 10
        modDashSleep := ( DashSleepTime + g_BrivUserSettings["DashWaitBuffer"] ) / timeScale
        if (modDashSleep < 1)
            modDashSleep := DashSleepTime          
        while ( this.Memory.ReadTimeScaleMultiplier() < DashSpeed AND ElapsedTime < modDashSleep AND this.Memory.ReadCurrentZone() < Floor(g_BrivUserSettings[ "StackZone" ] / 2))
        {
            this.ToggleAutoProgress(0)
            ; Temporary Shandie test. 1.5 can be from: Modron, Shandie.  1.25 can be from Small Speed Potion, Shandie (No specialization)
            isValueIncreased := g_SF.CountTimeScaleMultipliersOfValue(1.5) > specializedCount OR g_SF.CountTimeScaleMultipliersOfValue(1.25) > unSpecializedCount 
            ; TODO: Update Shandie Tests to be future compatible in case more speed is added.
            isValueOverExpected := g_SF.CountTimeScaleMultipliersOfValue(1.5) > 1 OR g_SF.CountTimeScaleMultipliersOfValue(1.25) > 1
            if(isValueIncreased OR isValueOverExpected)
                break
            this.SafetyCheck()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . modDashSleep
        }
        g_PreviousZoneStartTime := A_TickCount
        return
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

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        ;this.DirectedInput(hold := 0,, "{RCtrl}") ;extra release for safety
        ; ctrl level clickers
        this.DirectedInput(,release := 0, ["{RCtrl}","{ClickDmg}"]*) ;keysdown
        this.DirectedInput(hold := 0,, ["{ClickDmg}","{RCtrl}"]*) ;keysup
        ; turn Fkeys off/on again
        this.DirectedInput(hold := 0,, spam*) ;keysup
        this.DirectedInput(,release := 0, spam*) ;keysdown
        ; try to progress
        this.DirectedInput("{Right}")
        this.ToggleAutoProgress(1)
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
            this.FallBackFromZone()
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

    ; Forces an adventure restart through closing IC and using server calls
    WorldMapRestart()
    {
        g_SharedData.LoopString := "Zone is -1. At world map?"
        this.RestartAdventure( "Zone is -1. At world map? Forcing Restart." )
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

    OpenIC()
    {
        loadingDone := false
        g_SharedData.LoopString := "Starting Game"
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
        If(offlineTime <= 0 AND offlineTime != "")
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
            this.RecoverFromGameClose()
            return false
        }
        return true
    }

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
    This function should be overridden by AddOns using ot to match their objective

    The default functionality is to switch to Q formation (briv progression), or 
    fall back and switch to Q if being attacked
    */
    ; falls back zone until switching to Q formation can be done.
    RecoverFromGameClose()
    {
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 67
        timeout := 10000
        formationFavorite1 := this.Memory.GetFormationByFavorite( 1 )
        isCurrentFormation := false
        spam := ["{q}"]
        spam.Push(this.GetFormationFKeys(formationFavorite1)*)
        g_SharedData.LoopString := "Waiting for offline settings wipe..."
        while(this.Memory.ReadNumAttackingMonstersReached() >= 95 AND ElapsedTime < timeout ) 
        {
            ElapsedTime := A_TickCount - StartTime
            this.DirectedInput(,, "{q}" )
        }
        g_SharedData.LoopString := "Waiting for formation swap..."
        ElapsedTime := counter := 0
        while(!isCurrentFormation AND ElapsedTime < timeout AND !this.Memory.ReadNumAttackingMonstersReached())
        {
            ElapsedTime := A_TickCount - StartTime
            isCurrentFormation := this.IsCurrentFormation( formationFavorite1 )
            this.DirectedInput(,, spam* )
        }
        ;;;if ( this.Memory.ReadNumAttackingMonstersReached() OR this.Memory.ReadNumRangedAttackingMonsters() )
            g_SharedData.LoopString := "Under attack. Retreating to change formations..."
        ElapsedTime := counter := 0
        while(this.Memory.ReadNumAttackingMonstersReached() OR this.Memory.ReadNumRangedAttackingMonsters() AND ElapsedTime < 2 * timeout)
        {
            ElapsedTime := A_TickCount - StartTime
            this.FallBackFromZone()
            this.DirectedInput(,, spam* ) ;not spammed, delayed by fallback call
            this.ToggleAutoProgress(1, true)
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
        if(seat < 0)  
            return
        var := ["{F" . seat . "}"]
        if( IsObject(keys) )
            var.Push(keys*)
        else 
            var.Push(keys)
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
                counter ++
            }
        }
        this.DirectedInput(hold:=0,, var* ) ;keysup
        Critical, Off
        return
    }

    ;=====================================================
    ;Functions for finding and loading formation save data
    ;=====================================================
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
        while ( formationSaveSlot == -1 )
        {
            MsgBox, 5,, Please confirm a formation is saved in favorite slot %FavoriteSlot% or the correct memory file is being used. `nCurrent version: %memoryVersion%
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
            MsgBox, 5,, Please confirm your %team% team is saved in favorite slot %FavoriteSlot% or the correct memory file is being used. `nCurrent version: %memoryVersion%
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
        stateText := findChamp ? "is" : "isn't"
        ; Test that the specific champions is in the formation
        while ( foundChamp != findChamp )
        {
            MsgBox, 5,, Please confirm ChampID: %champID% %stateText% saved in favorite slot %FavoriteSlot% or the correct memory file is being used. `nCurrent version: %memoryVersion%
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
        ; TODO: Update these values based on memory reads
        g_ServerCall.networkID := 11 ;11 = steam
        g_ServerCall.activeModronID := this.Memory.ReadActiveGameInstance() ? this.Memory.ReadActiveGameInstance() : 1 ; 1, 2, 3 for modron cores 1, 2, 3
        g_ServerCall.activePatronID := 0 ; 0 = no patron
        g_ServerCall.UpdateDummyData()
    }

    ;======================
    ; New Helper Functions
    ;======================

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
            if ( v != -1 )
            {
                Fkeys.Push("{F" . this.Memory.ReadChampSeatByID(v) . "}")
            }
        }
        return Fkeys
    }

    /*  areChampionsUpgraded - Tests to see if all seats in formation are upgraded to max.

    Parameters:
    formation - A list of champion ID values from the formation currently on the field.

    Returns:
    True if all seats are fully upgraded. False otherwise.
    */
    ; Takes an array of champion IDs and determines if the slots they are in (NOT the champions themselves) are fully upgraded.
    areChampionsUpgraded(formation)
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
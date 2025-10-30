/*  Various functions for use with scripts for Idle Champions.
    change log
    v 0.3 2025/07/02
    1. CNE changed `ReadFormationTransitionDir` to 4 during non-QTs. Broke animation skipping.
*/

global g_PreviousZoneStartTime
global g_KeyPresses := {}
global g_SharedData := new IC_SharedData_Class
g_SF := new IC_SharedFunctions_Class

#include %A_LineFile%\..\IC_SharedData_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_SharedFunctions.ahk
#include %A_LineFile%\..\MemoryRead\IC_MemoryFunctions_Class.ahk


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

class IC_SharedFunctions_Class extends SH_SharedFunctions
{
    Memory := ""
    UserID := ""
    UserHash := ""
    InstanceID := 0
    CurrentAdventure := 30 ; default cursed farmer
    GameStartFormation := 1
    ModronResetZone := 0
    CurrentZone := ""
    Settings := ""
    TotalGems := 0
    TotalSilverChests := 0
    TotalGoldChests := 0
    StackedBeforeRestart := False

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
        return "v3.0.7, 2025-10-26"
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
            if ( v == champID )
                return true
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
    KillCurrentBoss( maxLoopTime := 25000 , loopString := "Killing boss before stacking.")
    {
        CurrentZone := this.Memory.ReadCurrentZone()
        if ( mod( CurrentZone, 5 ) )
            return 1
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 60
        g_SharedData.LoopString := loopString
        while ( !mod( this.Memory.ReadCurrentZone(), 5 ) AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                this.DirectedInput(,,"{e}")
                if(!this.Memory.ReadQuestRemaining()) ; Quest complete, still on boss zone. Skip boss bag.
                    this.ToggleAutoProgress(1,0,false)
            }
            Sleep, 20
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
            return fellBack
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 32
        g_SharedData.LoopString := "Falling back from boss zone."
        while ( !mod( this.Memory.ReadCurrentZone(), 5 ) AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                this.DirectedInput(,, "{Left}" )
                fellBack := 1
                counter++
            }
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
            Sleep, 20
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
            Sleep, 20
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
            Sleep, 20
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
        gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
        while ( gold == 0 AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
            Sleep, 16
        }
        return gold
    }

    WaitForFirstGoldSetup( maxLoopTime := 30000 )
    {
        this.SetFormationForStart()
        return this.WaitForFirstGold(maxLoopTime)
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
        sleepTime := 32
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
            Sleep, 16
        }
        return
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
        static minDashLevel := 120
        if (this.IsDashActive())
            return
        this.ToggleAutoProgress( 0, false, true )
        this.SetFormationForStart()
        this.LevelChampByID(ActiveEffectKeySharedFunctions.Shandie.HeroID, minDashLevel, 7000, "")
        ; Make sure the ability handler has the correct base address.
        ; It can change on game restarts or modron resets.
        this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Shandie.TimeScaleWhenNotAttackedHandler.EffectKeyString)
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := timeScale < 1 ? 1 : timeScale ; time scale should never be less than 1
        timeout := this.IsSecondWindActive() ? 10000 : 30000
        estimate := (timeout / timeScale)
        startTime := A_TickCount
        ElapsedTime := 0
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted dashwait triggering area
        ;   dash is active, dash.GetScaleActive() toggles to true when dash is active and returns "" if fails to read.
        while ( ElapsedTime < timeout AND this.Memory.ReadCurrentZone() < DashWaitMaxZone AND !this.IsDashActive() )
            ElapsedTime := this.DoDashWaitingIdling(StartTime, estimate)
        g_PreviousZoneStartTime := A_TickCount
    }

    ; Template function for whether determining if to Dash Wait. Default is Yes if shandie is in the formation.
    ShouldDashWait()
    {
        return this.IsChampInFormation( ActiveEffectKeySharedFunctions.Shandie.HeroID, this.Memory.GetCurrentFormation() )
    }

    ; Things to do while waiting for dash to be ready.
    DoDashWaitingIdling(startTime := 1, estimate := 1)
    {
        this.ToggleAutoProgress(0)
        ElapsedTime := A_TickCount - startTime
        g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
        percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10 + 15), 15)
        Sleep, %percentageReducedSleep%
        ElapsedTime := A_TickCount - StartTime
        return ElapsedTime
    }

    ; Loads formation to use in zone 1
    SetFormationForStart()
    {
        this.DirectedInput(,, "{q}")
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
            this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Shandie.TimeScaleWhenNotAttackedHandler.EffectKeyString)
        return false
    }

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        this.ToggleAutoProgress(1)
        this.ModronResetZone := this.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }

    DoLevelingUntilNotEnoughGold(formationValue := "M")
    {
        sleepTime := 80 ; default 80
        keyspamLength := 2 ; default keys not including clickdmg
        
        currKeySpam := []
        if(formationvalue != "M")
            keyspam := g_SF.GetFormationFKeys(this.Memory.GetFormationByFavorite(formationValue))
        else
            keyspam := this.keyspam
        currKeySpam.Push(this.keyspam[this.keyspam.Length()]) ; add last key to currKeySpam to start while loop
        while (currKeyspam.Length() > 0 AND currKeyspam.Length() <= 3)
        {
            currKeySpam := []
            keyspamLength := Min(keyspam.Length(), 3)
            index := 1
            while(currKeyspam.Length() < keySpamLength)
            {
                ; extract fkey number, check champ in seat of number, check if it can afford to upgrade - if yes add to spam
                if(this.CanAffordUpgrade(g_SF.Memory.ReadSelectedChampIDBySeat(SubStr(keyspam[index], 3, -1))))
                    index := index + 1, currKeySpam.Push(keyspam[index - 1]) ; increment index but add index from before increment
                else
                    keyspam.RemoveAt(index)
            }
            if(currKeyspam.Length() > 0)
            {
                currKeySpam.Push("{ClickDmg}")
                g_SF.DirectedInput(,,currKeySpam*)
                Sleep, %sleepTime%
            }
            else
                break
        }
    }

    ;A test if stuck on current area. After 35s, toggles autoprogress every 5s. After 45s, attempts falling back up to 2 times. After 65s, restarts level.
    CheckifStuck(isStuck := false)
    {
        static lastCheck := 0
        static fallBackTries := 0
        global g_PreviousZoneStartTime
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
            targetStackModifier := g_SF.CalculateBrivStacksToReachNextModronResetZone()
            this.StackNormal(30000, targetStackModifier, forceStack := True) ; Give 30s max to try to gain some stacks before a forced reset.
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
            Sleep, 20
        }
        g_SharedData.LoopString := "Loading z1..."
        Sleep, 50
        while(!this.Memory.ReadUserIsInited() AND ElapsedTime < timeout)
        {
            ElapsedTime := A_TickCount - StartTime
            Sleep, 20
        }
        if (ElapsedTime >= timeout)
            return false
        this.AlreadyOfflineStackedThisRun := False
        return true
    }

    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "", forceCheck := False)
    {
        if(settings != "")
            this.Settings := settings
        ;only send input messages if necessary
        brivBenched := this.Memory.ReadChampBenchedByID(ActiveEffectKeySharedFunctions.Briv.HeroID)
        ;check to bench briv
        if (!brivBenched AND this.BenchBrivConditions(this.Settings))
        {
            this.DoSwitchFormation(3)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        ;check to unbench briv
        if (brivBenched AND this.UnBenchBrivConditions(this.Settings))
        {
            this.DoSwitchFormation(1)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        if(!IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun OR forceCheck)
            isFormation2 := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2))
        else
            isFormation2 := g_SF.Memory.ReadMostRecentFormationFavorite() == 2
        isWalkZone := this.Settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50)] == 0
        ; check to swap briv from favorite 2 to favorite 3 (W to E)
        if (!brivBenched AND isFormation2 AND isWalkZone)
        {
            this.DoSwitchFormation(3)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        else if (!brivBenched AND isFormation2 AND !isWalkZone)
        {
            this.DoSwitchFormation(1)
            g_SharedData.SwapsMadeThisRun++
            return
        }
        ; Switch if still in modron formation.
        else if (!g_SF.FormationLock AND g_BrivGemFarm.IsInModronFormation){
        
              ; Q OR E depending on route.
            if (this.UnBenchBrivConditions(this.Settings))
                this.DoSwitchFormation(1)
            else if (this.BenchBrivConditions(this.Settings))
                this.DoSwitchFormation(3)
        }
        if(g_BrivGemFarm.IsInModronFormation AND !this.IsCurrentFormation(g_SF.Memory.GetActiveModronFormation()))
            g_BrivGemFarm.IsInModronFormation := False
    }

    DoSwitchFormation(favoriteNum)
    {
        if(favoriteNum == 1)
            this.DirectedInput(,,["{q}"]*) 
        else if(favoriteNum == 2)
            this.DirectedInput(,,["{w}"]*) 
        else if(favoriteNum == 3)
            this.DirectedInput(,,["{e}"]*) 
        IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun := True            
    }

    ; True/False on whether Briv should be benched based on game conditions. (typically swap to E formation)
    BenchBrivConditions(settings)
    {
        if(!settings[ "FeatSwapEnabled" ])
            ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
            if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() >= 3 )
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

    ; True/False on whether Briv should be unbenched based on game conditions. (typically swap to Q formation)
    UnBenchBrivConditions(settings)
    {
        ;do not unbench briv if party is not on a perferred briv jump zone.
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

    ; Attempts to open IC. Game should be closed before running this function or multiple copies could open.
    OpenIC()
    {
        timeoutVal := 32000 + 90000 ; 32s + waitforgameready timeout
        loadingDone := false
        g_SharedData.LoopString := "Starting Game"
        ; WinGetActiveTitle, savedActive
        WinGet, savedActive, ID, A
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
                this.SetLastActiveWindowWhileWaitingForGameExe(timeoutVal - ElapsedTime)
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
    OpenProcessAndSetPID(timeoutLeft := 35000, retried := 0)
    {
        this.PID := 0
        processWaitingTimeout := 10000 ;10s
        waitForProcessTime := g_UserSettings[ "WaitForProcessTime" ]
        existingProcessID := g_userSettings[ "ExeName"]
        ElapsedTime := 0
        StartTime := A_TickCount
        while (!this.PID AND ElapsedTime < timeoutLeft )
        {
            g_SharedData.LoopString := "Opening IC.."
            programLoc := g_UserSettings[ "InstallPath" ]
            runHidden := g_UserSettings[ "RunHidden" ]
            try
            {
                if (runHidden)
                    Run, %programLoc%,, Hide
                else
                    Run, %programLoc%
            }
            catch
            {
                if(!retried)
                {
                    retried += 1
                    sleep, 60000
                    ElapsedTime := 0
                    StartTime := A_TickCount
                    Process, Exist, %existingProcessID% ; Give another minute and retest. If failed, retry one time.
                    this.PID := ErrorLevel
                    if (!this.PID)
                        continue
                }
                if(!this.PID) ; Do not keep attempting to launch IC if a retry has also failed.
                { 
                    MsgBox, 48, ICScriptHub was unable to re-launch the game. `nVerify the game location is set properly by enabling the Game Location Settings addon, clicking Change Game Location on the Briv Gem Farm tab, and ensuring the launch command is set properly.
                    ExitApp
                }
            }
            Sleep, %waitForProcessTime%
            ; Add 10s (default) to ElapsedTime so each exe waiting loop will take at least 10s before trying to run a new instance of hte game
            timeoutForPID := ElapsedTime + processWaitingTimeout 
            while(!this.PID AND ElapsedTime < timeoutForPID AND ElapsedTime < timeoutLeft)
            {
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
    SetLastActiveWindowWhileWaitingForGameExe(timeoutLeft := 32000)
    {
        StartTime := A_TickCount
        ; Process exists, wait for the window:
        while(!(this.Hwnd := WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )) AND ElapsedTime < timeoutLeft)
        {
            
            WinGet, savedActive, ID, A
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
            if (this.Memory.ReadIsSplashVideoActive() == 1)
                this.DirectedInput(,,"{Esc}")
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
    SafetyCheck(stackRestart := False)
    {
        static hasStartedSafetyCheck := False
        static safetyCheckStartTime := 0
        static safetyCheckTimeout := 900000 ; 15 minutes
        static hasCorrectPatron := True
        
        ; Base case check in case safety check never succeeds in opening the game.
        if(!hasStartedSafetyCheck)
        {
            hasStartedSafetyCheck := True
            safetyCheckStartTime := A_TickCount
        }
        else if (A_TickCount - safetyCheckStartTime > safetyCheckTimeout)
        {
            MsgBox, % "Still could not start game after " . safetyCheckTimeout / 1000 / 60 . "minutes. `nCheck game location settings. `nEnding run."
            ExitApp
        }

        if (Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
        {
            if(this.OpenIC() == -1)
            {
                this.CloseIC("Failed to start Idle Champions")
                this.SafetyCheck(stackRestart)
            }
            if(this.Memory.ReadResetting() AND this.Memory.ReadCurrentZone() <= 1 AND this.Memory.ReadCurrentObjID() == "")
                this.WorldMapRestart()
            this.RecoverFromGameClose(stackRestart ? 2 : this.GetRecoveryFormation()) ; ~2516 ms
            this.BadSaveTest() 
            if (hasCorrectPatron)
                hasCorrectPatron := this.PatronTest() ; if needs restart, only do one time.
            else
                hasCorrectPatron := True
            hasStartedSafetyCheck := False
            IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun := False
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
        hasStartedSafetyCheck := False
        return true
    }

    PatronTest()
    {
        readPatron := this.Memory.ReadPatronID()
        ElapsedTime := 0
        StartTime := A_TickCount
        timeout := 5000
        while (readPatron == "" AND ElapsedTime < timeout) ;wait for good patron read.
        {
            readPatron := this.Memory.ReadPatronID()
            sleep, 96
            ElapsedTime := A_TickCount - StartTime
        }

        If (readPatron AND this.PatronID AND this.PatronID != readPatron AND ElapsedTime <= timeout)
        {
            this.CloseIC("Patron does not match expected patron upon restart.")
            this.SafetyCheck()
            return false
        }
        return True
    }
    
    ; Returns formation favorite number based on preferred jump zones.
    GetRecoveryFormation()
    {
        if (g_BrivUserSettings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 :  Mod(this.Memory.ReadCurrentZone(), 50)] == 0)
            return 3
        return 1   
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
    RecoverFromGameClose(formationFavoriteNum := 2)
    {
        StartTime := A_TickCount
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
        this.WaitForOfflineSettingsWipe(timeout, sleepTime, StartTime, spam) ; 0 ms
        isCurrentFormation := this.WaitForRecoveryFormationSwap(timeout, sleepTime, StartTime, spam, formationFavoriteNum) ; 1578 ms
        this.HandleRecoveryUnderAttack(timeout, sleepTime, spam, StartTime, ElapsedTime, formationFavoriteNum, isCurrentFormation) ; 938 ms
        g_SharedData.LoopString := "Loading game finished."
    }

    WaitForOfflineSettingsWipe(timeout, sleepTime, startTime, spam)
    {
        counter := ElapsedTime := 0
        g_SharedData.LoopString := "Waiting for offline settings wipe..."
        while(this.Memory.ReadNumAttackingMonstersReached() >= 95 AND ElapsedTime < timeout )
        {
            ElapsedTime := A_TickCount - startTime
            if(ElapsedTime > sleepTime * counter AND IsObject(spam))
            {
                this.DirectedInput(,, spam* )
                counter++
            }
            else
                Sleep, 20
        }
    }

    WaitForRecoveryFormationSwap(timeout, sleepTime, startTime, spam, formationFavoriteNum)
    {
        ElapsedTime := counter := 0
        this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(formationFavoriteNum), formationFavoriteNum )
        g_SharedData.LoopString := "Waiting for formation swap..."
        while(!isCurrentFormation AND ElapsedTime < timeout AND (!this.Memory.ReadNumAttackingMonstersReached() AND formationFavoriteNum == 2))
        {
            ElapsedTime := A_TickCount - startTime
            if(ElapsedTime > sleepTime * counter AND IsObject(spam))
            {
                this.DirectedInput(,, spam* )
                if(formationFavoriteNum != 2)
                    this.ToggleAutoProgress( 1, false, true )
                counter++
            }
            else
                Sleep, 20
            ; reverted for now. swaps fail more at game restart and restarts don't happen often so stick with old method until (if) CNE fixes their bug.
            ; isCurrentFormation := g_SF.Memory.ReadMostRecentFormationFavorite() == formationFavoriteNum AND IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun
            ; if (!isCurrentFormation)
            ;     isCurrentFormation := this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(formationFavoriteNum), formationFavoriteNum)
            isCurrentFormation := this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(formationFavoriteNum), formationFavoriteNum) ; just being safe for now.
        }
        return isCurrentFormation
    }

    HandleRecoveryUnderAttack(timeout, sleepTime, spam, startTime, ElapsedTime, formationFavoriteNum, isCurrentFormation) ;, lastLoopTimedOut
    {
        if (formationFavoriteNum == 2 AND this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(formationFavoriteNum), formationFavoriteNum))
            return
        g_SharedData.LoopString := "Under attack. Retreating to change formations..."
        while(!IsCurrentFormation AND (this.Memory.ReadNumAttackingMonstersReached() OR this.Memory.ReadNumRangedAttackingMonsters()) AND (ElapsedTime < (2 * timeout)))
        {
            ElapsedTime := A_TickCount - startTime
            this.FallBackFromZone()
            this.DirectedInput(,, spam* ) ;not spammed, delayed by fallback call
            if(formationFavoriteNum != 2)
                this.ToggleAutoProgress(1, true)
            ; if (lastLoopTimedOut) ; use old way, else use new formation check method
            isCurrentFormation := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(formationFavoriteNum)) ; this.Memory.ReadMostRecentFormationFavorite() == formationFavoriteNum
            Sleep, sleepTime
        }
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
            if(testformation[A_Index] != currentFormation[A_Index])
                return false
        return true
    }

    ; Returns true if all champs in the formation are in the favorite formation. Does not need exact match.
    IsCurrentFormationLazy(testformation := "", favorite := "")
    {
        if(!IsObject(testFormation))
            return false
        currentFormation := this.Memory.GetCurrentFormation()
        if(!IsObject(currentFormation))
            return false
        currCount := currentFormation.Count()
        if(currCount != testformation.Count())
            return false
        loop, %currCount%
            if(currentFormation[A_Index] != -1 AND testformation[A_Index] != currentFormation[A_Index] AND (favorite == 2 AND testformation[A_Index] != (Tatyana := 97))) ; favorite 2 + tatyana = skip
                return false
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
        if ((champLevel := this.Memory.ReadChampLvlByID(ChampID)) >= Lvl)
            return
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
        previousPatron := g_ServerCall.activePatronID != "" ? g_ServerCall.activePatronID : 0 
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

    #include %A_LineFile%\..\IC_SharedFunctions_StackCalcs.ahk

    ; Returns how many Rush stacks are available if Thellora is in the party. 
    ThelloraRushTest()
    {
        isInParty := this.IsChampInFormation( ActiveEffectKeySharedFunctions.Thellora.HeroID, this.Memory.GetCurrentFormation() )
        if (isInParty)
            return ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadRushStacks()
        return 0
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

    BrivHasThunderStep() ;Thunder step 'Gain 20% More Sprint Stacks When Converted from Steelbones', feat 2131.
    {
        static thunderStepID := 2131
        If (g_SF.Memory.HeroHasAnyFeatsSavedInFormation(ActiveEffectKeySharedFunctions.Briv.HeroID, g_SF.Memory.GetSavedFormationSlotByFavorite(1)) OR g_SF.Memory.HeroHasAnyFeatsSavedInFormation(ActiveEffectKeySharedFunctions.Briv.HeroID, g_SF.Memory.GetSavedFormationSlotByFavorite(3))) ;If there are feats saved in Q or E (which would overwrite any others in M)
        {
            thunderInQ := g_SF.Memory.HeroHasFeatSavedInFormation(ActiveEffectKeySharedFunctions.Briv.HeroID, thunderStepID, g_SF.Memory.GetSavedFormationSlotByFavorite(1))
            thunderInE := g_SF.Memory.HeroHasFeatSavedInFormation(ActiveEffectKeySharedFunctions.Briv.HeroID, thunderStepID, g_SF.Memory.GetSavedFormationSlotByFavorite(3))
            return (thunderInQ OR thunderInE)
        }
        else if (g_SF.Memory.HeroHasFeatSavedInModronFormation(ActiveEffectKeySharedFunctions.Briv.HeroID, thunderStepID))
            return true
        else
        {
            feats := g_SF.Memory.GetHeroFeats(ActiveEffectKeySharedFunctions.Briv.HeroID)
            for k, v in feats
                if (v == thunderStepID)
                    return true
        }
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
                hasSeatUpgrade := this.Memory.ReadBoughtLastUpgradeBySeat(this.Memory.ReadChampSeatByID(v))
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

    ; Converts a symbol to the corresponding integer exponent.
    ConvertNumberSymbolToInt(name)
    {
        static symbols := {"K":3, "M":6, "B":9, "t":12, "q":15, "Q":18, "s":21, "S":24
                           , "o":27, "n":30, "d":33, "U":36, "D":39, "T":42, "Qt":45
                           , "Qd":48, "Sd":51, "St":54, "O":57, "N":60, "v":63, "c":66}

        return symbols[name]
    }

    ; Converts a number string in scientific notation or symbol notation
    ; to an integer for comparison.
    ; Returns an integer equal to 1000 * exponent plus 100 * significand.
    ; This works only when the number format has less than 3 significant digits.
    ConvertNumberStringToInt(numStr)
    {
        split := StrSplit(numStr, "e")
        if split[2] is integer
        {
            significand := split[1]
            exponent := split[2]
        }
        else
        {
            regex := "(.*\d)([a-zA-Z]+)"
            RegExMatch(numStr, regex, out)
            significand := out1
            exponent := this.ConvertNumberSymbolToInt(out2)
        }
        return Round(exponent * 1000 + significand * 100)
    }

    #include *i %A_LineFile%\..\IC_SharedFunctions_Extra.ahk
}
#include *i %A_LineFile%\..\IC_SharedFunctions_Extended.ahk

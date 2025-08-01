class IC_BrivSharedFunctions_Class extends IC_SharedFunctions_Class
{
    steelbones := ""
    sprint := ""
    PatronID := 0
    ; Force adventure reset rather than relying on modron to reset.
    RestartAdventure( reason := "" )
    {
            g_SharedData.LoopString := "ServerCall: Restarting adventure"
            this.CloseIC( reason )
            if (this.sprint != "" AND this.steelbones != "" AND (this.sprint + this.steelbones) < 190000)
            {
                response := g_serverCall.CallPreventStackFail(this.sprint + this.steelbones)
            }
            else if (this.sprint != "" AND this.steelbones != "")
            {
                response := g_serverCall.CallPreventStackFail(this.sprint + this.steelbones)
                g_SharedData.LoopString := "ServerCall: Restarting with >190k stacks, some stacks lost."
            }
            else
            {
                g_SharedData.LoopString := "ServerCall: Restarting adventure (no manual stack conv.)"
            }
            response := g_ServerCall.CallEndAdventure()
            response := g_ServerCall.CallLoadAdventure( this.CurrentAdventure )
            g_SharedData.TriggerStart := true
    }

    ; Store important user data [UserID, Hash, InstanceID, Briv Stacks, Gems, Chests]
    SetUserCredentials()
    {
        this.UserID := this.Memory.ReadUserID()
        this.UserHash := this.Memory.ReadUserHash()
        this.InstanceID := this.Memory.ReadInstanceID()
        ; needed to know if there are enough chests to open using server calls
        this.TotalGems := this.Memory.ReadGems()
        silverChests := this.Memory.ReadChestCountByID(1)
        goldChests := this.Memory.ReadChestCountByID(2)
        this.TotalSilverChests := (silverChests != "") ? silverChests : this.TotalSilverChests
        this.TotalGoldChests := (goldChests != "") ? goldChests : this.TotalGoldChests
        this.sprint := this.Memory.ReadHasteStacks()
        this.steelbones := this.Memory.ReadSBStacks()
        if (this.BrivHasThunderStep())
            this.steelbones := Floor(this.steelbones * 1.2)
    }

    ; sets the user information used in server calls such as user_id, hash, active modron, etc.
    ResetServerCall()
    {
        this.SetUserCredentials()
        g_ServerCall := new IC_BrivServerCall_Class( this.UserID, this.UserHash, this.InstanceID )
        version := this.Memory.ReadBaseGameVersion()
        if (version != "")
            g_ServerCall.clientVersion := version
        tempWebRoot := this.Memory.ReadWebRoot()
        httpString := StrSplit(tempWebRoot,":")[1]
        isWebRootValid := httpString == "http" or httpString == "https"
        g_ServerCall.webroot := isWebRootValid ? tempWebRoot : g_ServerCall.webroot
        g_ServerCall.networkID := this.Memory.ReadPlatform() ? this.Memory.ReadPlatform() : g_ServerCall.networkID
        g_ServerCall.activeModronID := this.Memory.ReadActiveGameInstance() ? this.Memory.ReadActiveGameInstance() : 1 ; 1, 2, 3 for modron cores 1, 2, 3
        g_ServerCall.activePatronID := this.PatronID ;this.Memory.ReadPatronID() == "" ? g_ServerCall.activePatronID : this.Memory.ReadPatronID() ; 0 = no patron
        g_ServerCall.UpdateDummyData()
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
        this.SetUserCredentials()
        if (this.sprint != "" AND this.steelbones != "" AND (this.sprint + this.steelbones) < 190000)
            response := g_serverCall.CallPreventStackFail( this.sprint + this.steelbones, true)
        while (this.Memory.ReadResetting() AND ElapsedTime < timeout)
        {
            ElapsedTime := A_TickCount - StartTime
            Sleep, 20
        }
        g_SharedData.LoopString := "Loading z1..."
        Sleep, 50
        while ( !this.Memory.ReadUserIsInited() AND g_SF.Memory.ReadCurrentZone() < 1 AND ElapsedTime < timeout )
        {
            ElapsedTime := A_TickCount - StartTime
            Sleep, 20
        }
        if (ElapsedTime >= timeout)
        {
            return false
        }
        return true
    }

    ; Refocuses the window that was recorded as being active before the game window opened.
    ActivateLastWindow()
    {
        if (!g_BrivUserSettings["RestoreLastWindowOnGameOpen"])
            return
        Sleep, 100 ; extra wait for window to load
        hwnd := this.Hwnd
        WinActivate, ahk_id %hwnd% ; Idle Champions likes to be activated before it can be deactivated            
        savedActive := this.SavedActiveWindow
        WinActivate, %savedActive%
    }

    ; Returns true when conditions have been met for starting a wait for dash.
    ShouldDashWait()
    {
        if (g_BrivUserSettings[ "DisableDashWait" ])
            return False
        isInDashWaitBuffer := this.Memory.ReadCurrentZone() >= ( this.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ] )
        if (isInDashWaitBuffer)
            return False
        hasHasteStacks := this.Memory.ReadHasteStacks() > 50
        if (!hasHasteStacks)
            Return False
        isShandieInFormation := this.IsChampInFormation( 47, this.Memory.GetCurrentFormation() )            
        if (!isShandieInFormation)
            return False

        return True
    }

    ; Wait for Thellora ?
    ShouldRushWait()
    {
        if !(this.Memory.ReadCurrentZone() >= 0 AND this.Memory.ReadCurrentZone() <= 3)
            return False
        rushStacks := ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadRushStacks()
        if !(rushStacks > 0 AND rushStacks < 10000)
            return False
        return True
    }

    DoRushWait()
    {
        this.ToggleAutoProgress( 0, false, true )
        this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.EffectKeyString)
        StartTime := A_TickCount
        ElapsedTime := 0
        timeout := 8000 ; 7s seconds
        estimate := (timeout / timeScale) ; no buffer: 60s / timescale to show in LoopString
        
        ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadRushStacks()
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted dashwait triggering area
        ;   dash is active, dash.GetScaleActive() toggles to true when dash is active and returns "" if fails to read.
        while ( ElapsedTime < timeout AND this.ShouldRushWait() )
        {
            this.ToggleAutoProgress(0)
            this.SetFormation()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
            percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10), 15)
            Sleep, %percentageReducedSleep%
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }
    
    BrivHasThunderStep() ;Thunder step 'Gain 20% More Sprint Stacks When Converted from Steelbones', feat 2131.
    {
        If (g_SF.Memory.HeroHasAnyFeatsSavedInFormation(58, g_SF.Memory.GetSavedFormationSlotByFavorite(1)) OR g_SF.Memory.HeroHasAnyFeatsSavedInFormation(58, g_SF.Memory.GetSavedFormationSlotByFavorite(3))) ;If there are feats saved in Q or E (which would overwrite any others in M)
        {
            thunderInQ := g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131, g_SF.Memory.GetSavedFormationSlotByFavorite(1))
            thunderInE := g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131, g_SF.Memory.GetSavedFormationSlotByFavorite(3))
            return (thunderInQ OR thunderInE)
        }
        else if (g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131, g_SF.Memory.GetActiveModronFormationSaveSlot()))
            return true
		else
		{
			feats := g_SF.Memory.GetHeroFeats(58)
			for k, v in feats
				if (v == 2131)
					return true
		}
		return false
    }
}

class IC_BrivServerCall_Class extends IC_ServerCalls_Class
{
    ; forces an attempt for the server to remember stacks
    CallPreventStackFail(stacks, launchScript := False)
    {
        response := ""
        stacks := g_SaveHelper.GetEstimatedStackValue(stacks)
        userData := g_SaveHelper.GetCompressedDataFromBrivStacks(stacks)
        checksum := g_SaveHelper.GetSaveCheckSumFromBrivStacks(stacks)
        save :=  g_SaveHelper.GetSave(userData, checksum, this.userID, this.userHash, this.networkID, this.clientVersion, this.instanceID)
        if (launchScript) ; do server call from new script to prevent hanging script due to network issues.
        {
            webRoot := this.webRoot
            scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_SaveStacks.ahk"
            Run, %A_AhkPath% "%scriptLocation%" "%webRoot%" "%save%"
        }
        else
        {
            try
            {
                response := this.ServerCallSave(save)
            }
            catch, ErrMsg
            {
                g_SharedData.LoopString := "Failed to save Briv stacks"
            }
        }
        return response
    }
}

class IC_BrivGemFarm_Class
{
    TimerFunctions := {}
    TargetStacks := 0
    GemFarmGUID := ""
    StackFailAreasTally := {}
    LastStackSuccessArea := 0
    MaxStackRestartFails := 3
    StackFailAreasThisRunTally := {}
    StackFailRetryAttempt := 0

    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    ;The primary loop for gem farming using Briv and modron.
    GemFarm()
    {
        static lastResetCount := 0
        g_SharedData.TriggerStart := true
        g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName"])
        existingProcessID := g_UserSettings[ "ExeName"]
        Process, Exist, %existingProcessID%
        g_SF.PID := ErrorLevel
        Process, Priority, % g_SF.PID, High
        g_SF.Memory.OpenProcessReader()
        if (g_SF.VerifyAdventureLoaded() < 0)
            return
        g_SF.CurrentAdventure := g_SF.Memory.ReadCurrentObjID()
        g_ServerCall.UpdatePlayServer()
        g_SF.ResetServerCall()
        g_SF.PatronID := g_SF.Memory.ReadPatronID()
        this.LastStackSuccessArea := g_UserSettings [ "StackZone" ]
        this.StackFailAreasThisRunTally := {}
        g_SF.GameStartFormation := g_BrivUserSettings[ "BrivJumpBuffer" ] > 0 ? 3 : 1
        g_SaveHelper.Init() ; slow call, loads briv dictionary (3+s)
        formationModron := g_SF.Memory.GetActiveModronFormation()
        if (this.PreFlightCheck() == -1) ; Did not pass pre flight check.
            return -1
        g_PreviousZoneStartTime := A_TickCount
        g_SharedData.StackFail := 0
        loop
        {
            g_SharedData.LoopString := "Main Loop"
            CurrentZone := g_SF.Memory.ReadCurrentZone()
            if (CurrentZone == "" AND !g_SF.SafetyCheck() ) ; Check for game closed
                g_SF.ToggleAutoProgress( 1, false, true ) ; Turn on autoprogress after a restart
            g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetsCount() > lastResetCount OR g_SharedData.TriggerStart) ; first loop or Modron has reset
            {
                g_SharedData.BossesHitThisRun := 0
                g_SF.ToggleAutoProgress( 0, false, true )
                g_SharedData.StackFail := this.CheckForFailedConv()
                g_SF.WaitForFirstGold()
                keyspam := Array()
                if g_BrivUserSettings[ "Fkeys" ]
                    keyspam := g_SF.GetFormationFKeys(formationModron)
                doKeySpam := true
                keyspam.Push("{ClickDmg}")
                this.DoPartySetup()
                lastResetCount := g_SF.Memory.ReadResetsCount()
                g_SF.Memory.ActiveEffectKeyHandler.Refresh()
                worstCase := g_BrivUserSettings[ "AutoCalculateWorstCase" ]
                g_SharedData.TargetStacks := this.TargetStacks := g_SF.CalculateBrivStacksToReachNextModronResetZone(worstCase) + 50 ; 50 stack safety net
                this.LeftoverStacks := g_SF.CalculateBrivStacksLeftAtTargetZone(g_SF.Memory.ReadCurrentZone(), g_SF.Memory.GetModronResetArea() + 1  - g_SF.ThelloraRushTest(), worstCase)
                ; Don't reset last stack success area if 3 or more runs have failed to stack.
                this.LastStackSuccessArea := this.StackFailAreasTally[g_UserSettings [ "StackZone" ]] < this.MaxStackRestartFails ? g_UserSettings [ "StackZone" ] : this.LastStackSuccessArea
                this.StackFailAreasThisRunTally := {}
                this.StackFailRetryAttempt := 0
                StartTime := g_PreviousZoneStartTime := A_TickCount
                PreviousZone := 1
                g_SharedData.SwapsMadeThisRun := 0
                g_SharedData.TriggerStart := false
                g_SharedData.LoopString := "Main Loop"
            }
            if (g_SharedData.StackFail != 2)
                g_SharedData.StackFail := Max(this.TestForSteelBonesStackFarming(), g_SharedData.StackFail)
            if (g_SharedData.StackFail == 2 OR g_SharedData.StackFail == 4 OR g_SharedData.StackFail == 6 ) ; OR g_SharedData.StackFail == 3
                g_SharedData.TriggerStart := true
            if (!Mod( g_SF.Memory.ReadCurrentZone(), 5 ) AND Mod( g_SF.Memory.ReadHighestZone(), 5 ) AND !g_SF.Memory.ReadTransitioning())
                g_SF.ToggleAutoProgress( 1, true ) ; Toggle autoprogress to skip boss bag
            if (g_SF.Memory.ReadResetting())
                this.ModronResetCheck()
            if (CurrentZone > PreviousZone ) ; needs to be greater than because offline could stacking getting stuck in descending zones.
            {
                PreviousZone := CurrentZone
                if ((!Mod( g_SF.Memory.ReadCurrentZone(), 5 )) AND (!Mod( g_SF.Memory.ReadHighestZone(), 5)))
                {
                    g_SharedData.TotalBossesHit++
                    g_SharedData.BossesHitThisRun++
                }
                if (doKeySpam AND g_BrivUserSettings[ "Fkeys" ] AND g_SF.AreChampionsUpgraded(formationModron))
                {
                    g_SF.DirectedInput(hold:=0,release:=1, keyspam) ;keysup
                    keyspam := ["{ClickDmg}"]
                    doKeySpam := false
                }
                lastModronResetZone := g_SF.ModronResetZone
                g_SF.InitZone( keyspam )
                if (g_SF.ModronResetZone != lastModronResetZone)
                {
                    worstCase := g_BrivUserSettings[ "AutoCalculateWorstCase" ]
                    g_SharedData.TargetStacks := this.TargetStacks := g_SF.CalculateBrivStacksToReachNextModronResetZone(worstCase) + 50 ; 50 stack safety net
                    this.LeftoverStacks := g_SF.CalculateBrivStacksLeftAtTargetZone(this.Memory.ReadCurrentZone(), this.Memory.GetModronResetArea() + 1, worstCase)
                }
                g_SF.ToggleAutoProgress( 1 )
                continue
            }
            g_SF.ToggleAutoProgress( 1 )
            if (g_SF.CheckifStuck())
            {
                g_SharedData.TriggerStart := true
                g_SharedData.StackFail := StackFailStates.FAILED_TO_PROGRESS ; 3
                g_SharedData.StackFailStats.TALLY[g_SharedData.StackFail] += 1
            }
            Sleep, 20 ; here to keep the script responsive.
        }
    }

    ;=====================================================
    ;Functions for Briv Stack farming, mostly for gem runs
    ;=====================================================
    ;Various checks to determine when to stack SteelBones should be stacked or failed to stack.
    TestForSteelBonesStackFarming()
    {
        CurrentZone := g_SF.Memory.ReadCurrentZone()
        ; Don't test while modron resetting.
        if (CurrentZone < 0 OR CurrentZone >= g_SF.ModronResetZone)
            return
        stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
        targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
        
        stackfail := 0
        forcedResetReason := ""
        ; passed stack zone, start stack farm. Normal operation.
        if (stacks < targetStacks AND CurrentZone > g_BrivUserSettings[ "StackZone" ])
        {
            ; normal-success / adjusted-sucess behavior. Use settings zone or adjusted zone if good zone has been found. (Resets to StackZone for 3 runs before sticking)
            if (this.LastStackSuccessArea == CurrentZone ) 
                this.StackFarm()
            ; abnormal stacking - Normal zone failed, current zone is later and has 0 or "" failures on this zone. Try it.
            else if (!this.StackFailAreasTally[CurrentZone] ) 
                this.StackFarm()
            ; only stack farm if this zone hasn't been tried this run yet and still below max tries. 
            else if (this.LastStackSuccessArea == 0 AND !this.StackFailAreasThisRunTally[CurrentZone] AND this.StackFailAreasTally[CurrentZone] < this.MaxStackRestartFails)
                this.StackFarm()
            ; Safety - One more jump will be over modron reset and stacking has not been done.
            else if (CurrentZone > this.Memory.GetModronResetArea() - (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() + 1))
                this.StackFarm()
            return 0
        }
        ; stack briv between min zone and stack zone if briv is out of jumps (if stack fail recovery is on)
        if (g_SF.Memory.ReadHasteStacks() < 50 AND stacks < targetStacks AND CurrentZone >= g_BrivUserSettings[ "MinStackZone" ] AND g_BrivUserSettings[ "StackFailRecovery" ] AND CurrentZone < g_BrivUserSettings[ "StackZone" ] )
        {
            ; only use current zone if there's been no/non-excess issues with it.
            if (!this.StackFailAreasThisRunTally[CurrentZone] AND (!this.StackFailAreasTally[CurrentZone] OR this.StackFailAreasTally[CurrentZone] < this.MaxStackRestartFails))
            {
                stackFail := StackFailStates.FAILED_TO_REACH_STACK_ZONE ; 1
                g_SharedData.StackFailStats.TALLY[stackfail] += 1
                this.StackFarm()
                return stackfail
            }
            return 0
        }
        ; Briv ran out of jumps but has enough stacks for a new adventure, restart adventure. With protections from repeating too early or resetting within 5 zones of a reset.
        if (g_SF.Memory.ReadHasteStacks() < 50 AND stacks >= targetStacks AND g_SF.Memory.ReadHighestZone() > 10 AND (g_SF.Memory.GetModronResetArea() - g_SF.Memory.ReadHighestZone() > 5 ))
        {
            stackFail := StackFailStates.FAILED_TO_REACH_STACK_ZONE_HARD ; 4
            g_SharedData.StackFailStats.TALLY[stackfail] += 1
            forcedResetReason := "Briv ran out of jumps but has enough stacks for a new adventure"
            g_SF.RestartAdventure(forcedResetReason)
        }
        ; stacks are more than the target stacks and party is more than "ResetZoneBuffer" levels past stack zone, restart adventure
        ; (for restarting after stacking without going to modron reset level)
        if (stacks >= targetStacks AND CurrentZone > g_BrivUserSettings[ "StackZone" ] + g_BrivUserSettings["ResetZoneBuffer"])
        {
            stackFail := StackFailStates.FAILED_TO_RESET_MODRON ; 6
            g_SharedData.StackFailStats.TALLY[stackfail] += 1
            forcedResetReason := " Stacks > target stacks & party > " . g_BrivUserSettings["ResetZoneBuffer"] . " levels past stack zone"
            g_SF.RestartAdventure(forcedResetReason)
        }           
        return stackfail
    }

    ; Determines if offline stacking is expected with current settings and conditions.
    ShouldOfflineStack()
    {
        gemsMax := g_BrivUserSettings[ "ForceOfflineGemThreshold" ]
        runsMax := g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
        ; hybrid stacking not used. Use default test for offline stacking. 
        if !( (gemsMax > 1) OR (runsMax > 0) )
        {
            return ( g_BrivUserSettings [ "RestartStackTime" ] > 0 )
        }
        ; hybrid stacking by number of gems.
        if (gemsMax > 0 AND g_SF.Memory.ReadGems() > (gemsMax + g_BrivUserSettings[ "MinGemCount" ]))
        {
            return 1
        }
        ; hybrid stacking by number of runs.
        if (runsMax > 1)
        {
            memRead := g_SF.Memory.ReadResetsCount()
            if (memRead > 0 AND Mod( memRead, runsMax ) = 0)
            {
                return 1
            }
        }
        ; hybrid stacking enabled but conditions for offline stacking not met
        return 0
    }

    ;thanks meviin for coming up with this solution
    ;Gets total of SteelBonesStacks + Haste Stacks
    GetNumStacksFarmed()
    {
        if (this.ShouldOfflineStack())
        {
            currentStacks := g_BrivUserSettings[ "IgnoreBrivHaste" ] ? g_SF.Memory.ReadSBStacks() : ( g_SF.Memory.ReadHasteStacks() + g_SF.Memory.ReadSBStacks() )
            return currentStacks
        }
        else
        {
            ; If restart stacking is disabled, we'll stack to basically the exact
            ; threshold.  That means that doing a single jump would cause you to
            ; lose stacks to fall below the threshold, which would mean StackNormal
            ; would happen after every jump.
            ; Thus, we use a static 47 instead of using the actual haste stacks
            ; with the assumption that we'll be at minimum stacks after a reset.
            return g_SF.Memory.ReadSBStacks() + 47
        }
    }

    /*  StackRestart - Stops progress and wwitches to appropriate party to prepare for stacking Briv's SteelBones.
                       Falls back from a boss zone if necessary.

    Parameters:

    Returns:
    */
    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup()
    {
        if (!g_SF.KillCurrentBoss() ) ; Previously/Alternatively FallBackFromBossZone()
            g_SF.FallBackFromBossZone()
        inputValues := "{w}" ; Stack farm formation hotkey
        g_SF.DirectedInput(,, inputValues )
        g_SF.WaitForTransition( inputValues )
        g_SF.ToggleAutoProgress( 0 , false, true )
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 50
        g_SharedData.LoopString := "Setting stack farm formation."
        while ( !g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite( 2 )) AND ElapsedTime < 5000 )
        {
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                g_SF.DirectedInput(,,inputValues)
                counter++
            }
        }
        return
    }

    ;Starts stacking SteelBones based on settings (Restart or Normal).
    StackFarm()
    {
        if (this.ShouldOfflineStack())
            this.StackRestart()
        else
            this.StackNormal()
        ; SetFormation needs to occur before dashwait in case game erronously placed party on boss zone after stack restart
        g_SF.SetFormation(g_BrivUserSettings) 
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1 )
    }

    /*  StackRestart - Stack Briv's SteelBones by switching to his formation and restarting the game.
                       Attempts to buy are open chests while game is closed.

    Parameters:

    Returns:
    */
    ; Stack Briv's SteelBones by switching to his formation and restarting the game.
    StackRestart()
    {
        lastStacks := stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
        targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
        if (stacks >= targetStacks)
            return
        numSilverChests := g_SF.Memory.ReadChestCountByID(1)
        numGoldChests := g_SF.Memory.ReadChestCountByID(2)
        retryAttempt := 0
        maxRetries := 2
        if (this.LastStackSuccessArea == 0)
            maxRetries := 1
        while ( stacks < targetStacks AND retryAttempt <= maxRetries )
        {
            this.StackFailRetryAttempt++ ; per run
            retryAttempt++               ; pre stackfarm call
            this.StackFarmSetup()
            g_SF.CurrentZone := g_SF.Memory.ReadCurrentZone() ; record current zone before saving for bad progression checks
            modronResetZone := g_SF.Memory.GetModronResetArea()
            if (modronResetZone != "" AND g_SF.CurrentZone > modronResetZone)
            {
                g_SharedData.LoopString := "Attempted to offline stack after modron reset - verify settings"
                break
            }
            g_SF.CloseIC( "StackRestart" . (this.StackFailRetryAttempt > 1 ? (" - Warning: Retry #" . this.StackFailRetryAttempt - 1 . ". Check Stack Settings."): "") )
            g_SharedData.LoopString := "Stack Sleep: "
            chestsCompletedString := ""
            StartTime := A_TickCount
            ElapsedTime := 0
            chestsCompletedString := " " . this.DoChests(numSilverChests, numGoldChests)
            while ( ElapsedTime < g_BrivUserSettings[ "RestartStackTime" ] )
            {
                g_SharedData.LoopString := "Stack Sleep: " . g_BrivUserSettings[ "RestartStackTime" ] - ElapsedTime . chestsCompletedString
                Sleep, 62
                ElapsedTime := A_TickCount - StartTime
            }
            g_SF.SafetyCheck()
            stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
            ;check if save reverted back to below stacking conditions
            if (g_SF.Memory.ReadCurrentZone() < g_BrivUserSettings[ "MinStackZone" ])
            {
                g_SharedData.LoopString := "Stack Sleep: Failed (zone < min)"
                Break  ; "Bad Save? Loaded below stack zone, see value."
            }
            g_SharedData.PreviousStacksFromOffline := stacks - lastStacks
            lastStacks := stacks
        }
        if (retryAttempt >= maxRetries)
        {
            Loop, 4 ; add next 4 areas to failed stacks so next attempt would be CurrentZone + 4
            {
                this.StackFailAreasTally[g_SF.CurrentZone + A_Index - 1] := (this.StackFailAreasTally[g_SF.CurrentZone + A_Index - 1] == "") ? 1 : (this.StackFailAreasTally[g_SF.CurrentZone + A_Index - 1] + 1)
                ; debugStackFailAreasTallyString := ArrFnc.GetDecFormattedAssocArrayString(this.StackFailAreasTally)
                this.StackFailAreasThisRunTally[g_SF.CurrentZone + A_Index - 1] := 1
                ; debugStackStackFailAreasThisRunTallyString := ArrFnc.GetDecFormattedAssocArrayString(this.StackFailAreasThisRunTally)
                this.LastStackSuccessArea := 0
            }
        }
        else if (retryAttempt == 1)
        {
            this.StackFailAreasTally[g_SF.CurrentZone] := 0
            this.LastStackSuccessArea := g_SF.CurrentZone
        }
        else
        {
            this.LastStackSuccessArea := g_SF.CurrentZone
        }
        g_PreviousZoneStartTime := A_TickCount
        return 
    }

    /*  StackNormal - Stack Briv's SteelBones by switching to his formation and waiting for stacks to build.

    Parameters:
    maxOnlineStackTime -  Maximum time in ms script will spend stacking. Default is 5 minutes.

    Returns:
    */
    ; Stack Briv's SteelBones by switching to his formation.
    StackNormal(maxOnlineStackTime := 300000)
    {
        stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
        targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
        if (this.ShouldAvoidRestack(stacks, targetStacks))
            return
        this.StackFarmSetup()
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.LoopString := "Stack Normal"
        while ( stacks < targetStacks AND ElapsedTime < maxOnlineStackTime )
        {
            g_SF.FallBackFromBossZone()
            stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
            Sleep, 124
            ElapsedTime := A_TickCount - StartTime
        }
        if ( ElapsedTime >= maxOnlineStackTime)
        {
            this.RestartAdventure( "Online stacking took too long (> " . (maxOnlineStackTime / 1000) . "s) - z[" . g_SF.Memory.ReadCurrentZone() . "].")
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            return
        }
        g_PreviousZoneStartTime := A_TickCount
        g_SF.FallBackFromZone()
        return
    }

    ; avoids attempts to stack again after stacking has been completed and level not reset yet.
    ShouldAvoidRestack(stacks, targetStacks)
    {
        if ( stacks >= targetStacks )
            return 1
        if (g_SF.Memory.ReadCurrentZone() == 1) ; likely modron has reset
            return 1
        if (g_SF.Memory.ReadCurrentZone() < g_BrivUserSettings[ "MinStackZone" ]) ; don't stack below min stack zone
            return 1
        return 0
    }

    /* ;A function that checks if farmed SB stacks from previous run failed to convert to haste.
       ;If so, the script will manually end the adventure to attempt to convert the stacks, close IC, use a servercall to restart the adventure, and restart IC.
    */
    CheckForFailedConv()
    {
        CurrentZone := g_SF.Memory.ReadCurrentZone()
        targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? this.TargetStacks : g_BrivUserSettings[ "TargetStacks" ]
        variationLeeway := 10
        ; Zone 10 gives plenty leeway for fast starts that skip level 1 while being low enough to not have received briv stacks
        ; needed to ensure DoPartySetup
        if (!g_BrivUserSettings[ "StackFailRecovery" ] OR CurrentZone > 10)
        {
            return 0
        }
        stacks := g_SF.Memory.ReadHasteStacks() + g_SF.Memory.ReadSBStacks()
        ; stacks not converted to haste properly. Buffer allows for automatic calc variations and possible early jump before calculation done.
        if ((g_SF.Memory.ReadHasteStacks() + variationLeeway) < targetStacks AND stacks >= targetStacks)
        {
            g_SharedData.StackFailStats.TALLY[StackFailStates.FAILED_TO_CONVERT_STACKS] += 1
            g_SF.RestartAdventure( "Failed Conversion" )
            g_SF.SafetyCheck()
            return StackFailStates.FAILED_TO_CONVERT_STACKS ; 2
        }
        ; all stacks were lost on reset. Stack leeway given for automatic calc variations. 
        if ((g_SF.Memory.ReadHasteStacks() + variationLeeway) < targetStacks AND g_SF.Memory.ReadSBStacks() <= variationLeeway)
        {
            g_SharedData.StackFailStats.TALLY[StackFailStates.FAILED_TO_KEEP_STACKS] += 1
            return StackFailStates.FAILED_TO_KEEP_STACKS ; 5
        }
        return 0
    }

    ;===========================================================
    ;Helper functions for Briv Gem Farm
    ;===========================================================
    /*  DoPartySetup - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                       Levels Shandie and Briv, waits for Shandie Dash to start, completes the quests of the zone and then go time.

        Parameters:

        Returns:
    */
    DoPartySetup()
    {
        g_SharedData.LoopString := "Leveling champions"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        isShandieInFormation := g_SF.IsChampInFormation( 47, formationFavorite1 )
        g_SF.LevelChampByID( 58, 170, 7000, "{q}") ; level briv
        if (isShandieInFormation)
            g_SF.LevelChampByID( 47, 230, 7000, "{q}") ; level shandie
        isHavilarInFormation := g_SF.IsChampInFormation( 56, formationFavorite1 )
        if (isHavilarInFormation)
            g_SF.LevelChampByID( 56, 15, 7000, "{q}") ; level havi
        if (g_BrivUserSettings[ "Fkeys" ])
        {
            keyspam := g_SF.GetFormationFKeys(g_SF.Memory.GetActiveModronFormation()) ; level other formation champions
            keyspam.Push("{ClickDmg}")
            g_SF.DirectedInput(,release :=0, keyspam*) ;keysdown
        }
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (g_SF.ShouldRushWait())
            g_SF.DoRushWait()
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1, false, true )
    }

    ;Waits for modron to reset. Closes IC if it fails.
    ModronResetCheck()
    {
        modronResetTimeout := 75000
        if (!g_SF.WaitForModronReset(modronResetTimeout))
            g_SF.CheckifStuck(True)
            ;g_SF.CloseIC( "ModronReset, resetting exceeded " . Floor(modronResetTimeout/1000) . "s" )
        g_PreviousZoneStartTime := A_TickCount
    }

    ; Test that favorite exists
    TestFormationSlotByFavorite(favorite := "", txtCheck := "")
    {
        if (!favorite)
            return ""
        testFunc := ObjBindMethod(g_SF.Memory, "GetSavedFormationSlotByFavorite", favorite)
        errMsg := "Please confirm a formation is saved in formation favorite slot " . favorite . ". " . txtCheck
        formationSlot := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := -1, shouldBeEqual := False)
        if (formationSlot == -1)
            return -1
        return formationSlot
    }

    ; Test that formation has champions
    TestFormationFavorite( formationSlot := "", favorite := "", txtCheck := "")
    {
        if (!formationSlot)
            return ""
        team := {1:"Speed", 2:"Stack Farm", 3:"Speed No Briv"}
        testFunc := ObjBindMethod(g_SF.Memory, "GetFormationSaveBySlot", formationSlot, 0) ; don't ignore empty
        errMsg := "Please confirm your " . team[favorite] . " team is saved in formation favorite slot " . favorite . ". " . txtCheck
        formation := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := 0, shouldBeEqual := False, testSize := True)
        if (formation == -1)
            return -1
        return formation
    }

    ; Test that formation has champions
    TestChampInFormation( champID := "", formation := "", includeChampion := True, favorite := 1, txtCheck := "")
    {
        if (!champID)
            return ""
        team := {1:"Speed", 2:"Stack Farm", 3:"Speed No Briv"}
        testFunc := ObjBindMethod(g_SF, "IsChampInFavoriteFormation", champID, favorite ) ; don't ignore empty
        foundChampName := g_SF.Memory.ReadChampNameByID(champID)
        
        errMsg := "Please confirm " . foundChampName . stateText . (includeChampion ? " is" : " is NOT") .  " saved in formation favorite slot " . favorite . ". " . txtCheck
        formation := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := True, shouldBeEqual := includeChampion)
        if (formation == -1)
            return -1
        return formation
    }

    ; Run tests to check if favorite formations are saved, they have champions, and that the expected champion is/isn't included.
    RunChampionInFormationTests(champion, favorite, includeChampion, txtCheck)
    {
        formationSlot := this.TestFormationSlotByFavorite( favorite , txtcheck)
        if (formationSlot == -1)
            return -1 
        formation := this.TestFormationFavorite(formationSlot, favorite, txtcheck)
        if (formation == -1)
            return -1
        isChampInFormation := this.TestChampInFormation(champion, formation, includeChampion, favorite, txtcheck)
        if (isChampInFormation == -1)
            return -1
    }

    ; Tests to make sure Gem Farm is properly set up before attempting to run.
    PreFlightCheck()
    {
        memoryVersion := g_SF.Memory.GameManager.GetVersion()
        ; Test Favorite Exists
        txtCheck := "`n`nOther potential solutions:"
        txtCheck .= "`n`n1. Be sure Imports are up to date. Current imports are for: v" . g_SF.Memory.GetImportsVersion()
        txtCheck .= "`n`n2. Check the correct memory file is being used. Current version: " . memoryVersion
        txtcheck .= "`n`n3. If IC is running with admin privileges, then the script will also require admin privileges."
        if (_MemoryManager.is64bit)
            txtcheck .= "`n4. Check AHK is 64-bit. (Currently " . (A_PtrSize = 4 ? 32 : 64) . "-bit)"

        champion := 58   ; briv
        formationQ := g_SF.FindChampIDinSavedFavorite( champion, favorite := 1, includeChampion := True )
        if (formationQ == -1 AND this.RunChampionInFormationTests(champion, favorite := 1, includeChampion := True, txtCheck) == -1)
            return -1

        formationW := g_SF.FindChampIDinSavedFavorite( champion, favorite := 2, includeChampion := True  )
        if (formationW == -1 AND this.RunChampionInFormationTests(champion, favorite := 2, includeChampion := True, txtCheck) == -1)
            return -1

        formationE := g_SF.FindChampIDinSavedFavorite( champion, favorite := 3, includeChampion := False  )
        if (formationE == -1 AND this.RunChampionInFormationTests(champion, favorite := 3, includeChampion := False, txtCheck) == -1)
            return -1

        if ((ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 1, True)))
            MsgBox, %ErrorMsg%
        while (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False))
        {
            MsgBox, 5,, %ErrorMsg%
            IfMsgBox, Retry
            {
                g_SF.OpenProcessReader()
                ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False)
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return -1
            }
        }
        if (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 3, True))
            MsgBox, %ErrorMsg%

        return 0
    }

    ;===========================================================
    ;functions for speeding up progression through an adventure.
    ;===========================================================

    ;=====================================================
    ;Functions for direct server calls between runs
    ;=====================================================


    ; Sends calls for buying or opening chests and tracks chest metrics.
    DoChests(numSilverChests, numGoldChests)
    {
        serverRateBuy := 250
        serverRateOpen := 1000
        ; no chests to do - Replaces g_BrivUserSettings[ "DoChests" ] setting.
        if !(g_BrivUserSettings[ "BuySilvers" ] OR g_BrivUserSettings[ "BuyGolds" ] OR g_BrivUserSettings[ "OpenSilvers" ] OR g_BrivUserSettings[ "OpenGolds" ])
            return

        StartTime := A_TickCount
        g_SharedData.LoopString := "Stack Sleep: " . " Buying or Opening Chests"
        loopString := ""
        startingPurchasedSilverChests := g_SharedData.PurchasedSilverChests
        startingPurchasedGoldChests := g_SharedData.PurchasedGoldChests
        startingOpenedGoldChests := g_SharedData.OpenedGoldChests
        startingOpenedSilverChests := g_SharedData.OpenedSilverChests
        currentChestTallies := startingPurchasedSilverChests + startingPurchasedGoldChests + startingOpenedGoldChests + startingOpenedSilverChests
        ElapsedTime := 0

        doHybridStacking := ( g_BrivUserSettings[ "ForceOfflineGemThreshold" ] > 0 ) OR ( g_BrivUserSettings[ "ForceOfflineRunThreshold" ] > 1 )
        while( ( g_BrivUserSettings[ "RestartStackTime" ] > ElapsedTime ) OR doHybridStacking)
        {
            g_SharedData.LoopString := "Stack Sleep: " . g_BrivUserSettings[ "RestartStackTime" ] - ElapsedTime . " " . loopString
            effectiveStartTime := doHybridStacking ? A_TickCount + 30000 : StartTime ; 30000 is an arbitrary time that is long enough to do buy/open (100/99) of both gold and silver chests.

            ;BUYCHESTS
            gems := g_SF.TotalGems - g_BrivUserSettings[ "MinGemCount" ]
            amount := Min(Floor(gems / 50), serverRateBuy )
            if (g_BrivUserSettings[ "BuySilvers" ] AND amount > 0)
                this.BuyChests( chestID := 1, effectiveStartTime, amount )
            gems := g_SF.TotalGems - g_BrivUserSettings[ "MinGemCount" ] ; gems can change from previous buy, reset
            amount := Min(Floor(gems / 500) , serverRateBuy )
            if (g_BrivUserSettings[ "BuyGolds" ] AND amount > 0)
                this.BuyChests( chestID := 2, effectiveStartTime, amount )
            ; OPENCHESTS
            amount := Min(g_SF.TotalSilverChests, serverRateOpen)
            if (g_BrivUserSettings[ "OpenSilvers" ] AND amount > 0)
                this.OpenChests( chestID := 1, effectiveStartTime, amount)
            amount := Min(g_SF.TotalGoldChests, serverRateOpen)
            if (g_BrivUserSettings[ "OpenGolds" ] AND amount > 0)
                this.OpenChests( chestID := 2, effectiveStartTime, amount )

            updatedTallies := g_SharedData.PurchasedSilverChests + g_SharedData.PurchasedGoldChests + g_SharedData.OpenedGoldChests + g_SharedData.OpenedSilverChests
            currentLoopString := this.GetChestDifferenceString(startingPurchasedSilverChests, startingPurchasedGoldChests, startingOpenedGoldChests, startingOpenedSilverChests)
            loopString := currentLoopString == "" ? loopString : currentLoopString

            if (!g_BrivUserSettings[ "DoChestsContinuous" ] ) ; Do one time if not continuous
                return loopString == "" ? "Chests ----" : loopString
            if (updatedTallies == currentChestTallies) ; call failed, likely ran out of time. Don't want to call more if out of time.
                return loopString == "" ? "Chests ----" : loopString
            currentChestTallies := updatedTallies
            ElapsedTime := A_TickCount - StartTime
        }
        return loopString
    }

    ; Builds a string that shows how many chests have been opened/bought above the values passed into this function.
    GetChestDifferenceString(lastPurchasedSilverChests, lastPurchasedGoldChests, lastOpenedGoldChests, lastOpenedSilverChests )
    {
        boughtSilver := g_SharedData.PurchasedSilverChests - lastPurchasedSilverChests 
        boughtGold := g_SharedData.PurchasedGoldChests - lastPurchasedGoldChests
        openedSilver := g_SharedData.OpenedSilverChests - lastOpenedSilverChests
        openedGold := g_SharedData.OpenedGoldChests - lastOpenedGoldChests
        buyString := (boughtSilver > 0 OR boughtGold > 0) ? "Buy: (" . boughtSilver . "s, " . boughtGold . "g)" : ""
        openString := (openedSilver > 0 OR openedGold > 0) ? "Open: (" . openedSilver . "s, " . openedGold . "g)" : ""
        separator := ((boughtSilver > 0 OR boughtGold > 0) AND (openedSilver > 0 OR openedGold > 0)) ? ", " : ""
        returnString := buyString . separator . openString
        return ((returnString != "") ? "Chests - " . returnString : "")
    }

    /*  BuyChests - A method to buy chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. Default is 1 (silver).
        startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
            Used to estimate if there is enough time to perform those actions before attempting to do them.
        numChests - expected number of chests to buy. Default is 100.
            
        Return Values:
        None

        Side Effects:
        On success, will update g_SharedData.PurchasedSilverChests and g_SharedData.PurchasedGoldChests.
        On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    */
    BuyChests( chestID := 1, startTime := 0, numChests := 100)
    {
        startTime := startTime ? startTime : A_TickCount
        purchaseTime := 100 ; .1s
        if (g_BrivUserSettings[ "RestartStackTime" ] > ( A_TickCount - startTime + purchaseTime))
        {
            if (numChests > 0)
            {
                response := g_ServerCall.CallBuyChests( chestID, numChests )
                if (response.okay AND response.success)
                {
                    g_SharedData.PurchasedSilverChests += chestID == 1 ? numChests : 0
                    g_SharedData.PurchasedGoldChests += chestID == 2 ? numChests : 0
                    g_SF.TotalSilverChests := (chestID == 1) ? response.chest_count : g_SF.TotalSilverChests
                    g_SF.TotalGoldChests := (chestID == 2) ? response.chest_count : g_SF.TotalGoldChests
                    g_SF.TotalGems := response.currency_remaining
                }
            }
        }
    }

    /*  OpenChests - A method to open chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. Default is 1 (silver).
        startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
            Used to estimate if there is enough time to perform those actions before attempting to do them.
        numChests - expected number of chests to open. Default is 100.


        Return Values:
        None

        Side Effects:
        On success, will update g_SharedData.OpenedSilverChests and g_SharedData.OpenedGoldChests.
        On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    */
    OpenChests( chestID := 1, startTime := 0, numChests := 99 )
    {
        timePerGold := 4.5
        timePerSilver := .75
        timePerChest := chestID == 1 ? timePerSilver : timePerGold
        startTime := startTime ? startTime : A_TickCount
        ; openChestTimeEst := 1000 ; chestID == 1 ? (numChests * 30.3) : numChests * 60.6 ; ~3s for silver, 6s for anything else
        if (g_BrivUserSettings[ "RestartStackTime" ] - ( A_TickCount - startTime) < numChests * timePerChest)
            numChests := Floor(( A_TickCount - startTime) / timePerChest)
        if (numChests < 1)
            return
        chestResults := g_ServerCall.CallOpenChests( chestID, numChests )
        if (!chestResults.success)
            return
        g_SharedData.OpenedSilverChests += (chestID == 1) ? numChests : 0
        g_SharedData.OpenedGoldChests += (chestID == 2) ? numChests : 0
        g_SF.TotalSilverChests := (chestID == 1) ? chestResults.chests_remaining : g_SF.TotalSilverChests
        g_SF.TotalGoldChests := (chestID == 2) ? chestResults.chests_remaining : g_SF.TotalGoldChests
        g_SharedData.ShinyCount += g_SF.ParseChestResults( chestResults )
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk

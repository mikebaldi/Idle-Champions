#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk


class IC_BrivServerCall_Class extends IC_ServerCalls_Class
{
    ; forces an attempt for the server to remember stacks
    CallPreventStackFail(stacks, launchScript := False)
    {
        call := "CallPreventStackFail"
        scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_ServerCalls.ahk"
        Run, %A_AhkPath% "%scriptLocation%" "%call%" "%stacks%"
    }
}

class IC_BrivSharedFunctions_Class
{
    ; Force adventure reset rather than relying on modron to reset.
    RestartAdventure( reason := "" )
    {
        this.StackNormal(30000) ; Give 30s max to try to gain some stacks before a forced reset.
        g_SharedData.LoopString := "ServerCall: Restarting adventure"
        jsonObj := base.LoadObjectFromJSON(A_LineFile . "\..\ServerCall_Settings.json")
        this.CloseIC( reason )
        stacks := (this.sprint?this.sprint:0) + (this.steelbones?this.steelbones:0)
        if (stacks >= 190000)
            g_SharedData.LoopString := "ServerCall: Restarting with >190k stacks, some stacks lost."
        ; Save stacks
        if (stacks > 49) ; minimum is 49
            g_ServerCall.CallPreventStackFail(stacks)
        else
            g_SharedData.LoopString := "ServerCall: Restarting adventure (no manual stack conv.)"
        ; Restart adventure
        jsonObj["Calls"] := {"CallEndAdventure" : [], "CallLoadAdventure" : [this.CurrentAdventure]}
        jsonObj["ServerCallGUID"] := ComObjCreate("Scriptlet.TypeLib").GUID
        base.WriteObjectToJSON(A_LineFile . "\..\ServerCall_Settings.json" , jsonObj)
        scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_ServerCalls.ahk"
        Run, %A_AhkPath% "%scriptLocation%"
        this.AlreadyOfflineStackedThisRun := False
    }
    ; Store important user data [UserID, Hash, InstanceID, Briv Stacks, Gems, Chests]
    SetUserCredentials()
    {
        jsonObj := {}
        jsonObj.UserID := this.UserID := this.Memory.ReadUserID()
        jsonObj.UserHash := this.UserHash := this.Memory.ReadUserHash()
        jsonObj.InstanceID  := this.InstanceID := this.Memory.ReadInstanceID()
        ; needed to know if there are enough chests to open using server calls
        jsonObj.TotalGems := this.TotalGems := this.Memory.ReadGems()
        silverChests := this.Memory.ReadChestCountByID(1)
        goldChests := this.Memory.ReadChestCountByID(2)
        jsonObj.TotalSilverChests := this.TotalSilverChests := (silverChests != "") ? silverChests : this.TotalSilverChests
        jsonObj.TotalGoldChests := this.TotalGoldChests := (goldChests != "") ? goldChests : this.TotalGoldChests
        jsonObj.sprint := this.sprint := this.Memory.ReadHasteStacks()
        jsonObj.steelbones := this.steelbones := this.Memory.ReadSBStacks()
        if (this.BrivHasThunderStep())
            jsonObj.steelbones := this.steelbones := Floor(this.steelbones * 1.2)
        return jsonObj
    }

    ; sets the user information used in server calls such as user_id, hash, active modron, etc.
    ResetServerCall()
    {
        jsonObj := this.SetUserCredentials()
        g_ServerCall := new IC_BrivServerCall_Class( this.UserID, this.UserHash, this.InstanceID )
        version := this.Memory.ReadBaseGameVersion()
        if (version != "")
            g_ServerCall.clientVersion := version
        this.GetWebRoot()            
        jsonObj.webroot := g_ServerCall.webroot
        jsonObj.networkID := g_ServerCall.networkID := this.Memory.ReadPlatform() ? this.Memory.ReadPlatform() : g_ServerCall.networkID
        jsonObj.activeModronID := g_ServerCall.activeModronID := this.Memory.ReadActiveGameInstance() ? this.Memory.ReadActiveGameInstance() : 1 ; 1, 2, 3 for modron cores 1, 2, 3
        jsonObj.activePatronID := g_ServerCall.activePatronID := this.PatronID ;this.Memory.ReadPatronID() == "" ? g_ServerCall.activePatronID : this.Memory.ReadPatronID() ; 0 = no patron
        g_ServerCall.UpdateDummyData()
        jsonObj.dummyData := g_ServerCall.dummyData
        base.WriteObjectToJSON(A_LineFile . "\..\ServerCall_Settings.json" , jsonObj)
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
            return false
        this.AlreadyOfflineStackedThisRun := False
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
        savedActive := "ahk_id " . this.SavedActiveWindow
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
}

class IC_BrivSharedFunctions_Added_Class extends IC_SharedFunctions_Class
{
    steelbones := ""
    sprint := ""
    PatronID := 0

    WaitForCalls(GUID)
    {
        startTime := A_TickCount
        ElapsedTime := 0
        while (!g_SharedData.CallsAreComplete[GUID] and ElapsedTime < 30000)
        {
            ElapsedTime := A_TickCount - startTime
            Sleep, 1000
        }
    }

    GetWebRoot()
    {
        tempWebRoot := this.Memory.ReadWebRoot()
        httpString := StrSplit(tempWebRoot,":")[1]
        isWebRootValid := httpString == "http" or httpString == "https"
        g_ServerCall.webroot := isWebRootValid ? tempWebRoot : g_ServerCall.webroot
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

    IsSecondWindActive()
    {
        feats := this.Memory.GetHeroFeats(ActiveEffectKeySharedFunctions.Shandie.HeroID)
        for k, v in feats
            if (v == 1035)
                return true
        return false
    }

    DoRushWait()
    {
        this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.EffectKeyString)
        if (!this.ShouldRushWait())
            return
        this.ToggleAutoProgress( 0, false, true )
        StartTime := A_TickCount
        ElapsedTime := 0
        timeout := 8000 ; 8s seconds
        estimate := (timeout / timeScale)
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted rushwait triggering area
        ;   rush is active
        while ( ElapsedTime < timeout AND this.ShouldRushWait() )
        {
            this.ToggleAutoProgress(0)
            this.SetFormation()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
            percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10)+15, 15)
            Sleep, %percentageReducedSleep%
        }
        g_PreviousZoneStartTime := A_TickCount
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

    ; Predicts the number of Briv haste stacks after the next reset.
    ; After resetting, Briv's Steelborne stacks are added to the remaining Haste stacks.
    PredictStacks(addSBStacks := true, refreshCache := false)
    {
        static skipQ
        static skipE

        preferred := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
        if (IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class))
        {
            brivMinlevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ]
            brivMetalbornArea := brivMinlevelArea
        }
        else
        {
            brivMinlevelArea := brivMetalbornArea := 1
        }
        if (refreshCache || skipQ == "" || skipE == "" || skipQ == 0 && skipE == 0)
        {
            skipQ := this.GetBrivSkipValue(1)
            skipE := this.GetBrivSkipValue(3)
        }
        modronReset := g_SF.Memory.GetModronResetArea()
        sbStacks := g_SF.Memory.ReadSBStacks()
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        sprintStacks := g_SF.Memory.ReadHasteStacks()
        ; Party has not progressed to the next zone yet but Briv stacks were consumed.
        if (highestZone - currentZone > 1)
            currentZone := highestZone
        ; This assumes Briv has gained more than 48 stacks ever.
        stacksAtReset := Max(48, this.CalcStacksLeftAtReset(preferred, currentZone, modronReset, sprintStacks, skipQ, skipE, brivMinlevelArea, brivMetalbornArea))
        if (addSBStacks)
            stacksAtReset += sbStacks
        return stacksAtReset
    }
}
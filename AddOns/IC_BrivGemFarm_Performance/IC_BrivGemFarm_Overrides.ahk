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
    CloseIC( string := "")
    {
        base.CloseIC(string)
        try
        {
            g_ScriptHubComs.RunTimersOnModronReset()
        }
    }

    ; Force adventure reset rather than relying on modron to reset.
    RestartAdventure( reason := "" )
    {
        targetStackModifier := g_SF.CalculateBrivStacksToReachNextModronResetZone()
        g_BrivGemFarm.StackNormal(30000, targetStackModifier, forceStack := True) ; Give 30s max to try to gain some stacks before a forced reset.
        g_SharedData.LoopString := "ServerCall: Restarting adventure"
        jsonObj := base.LoadObjectFromJSON(A_LineFile . "\..\ServerCall_Settings.json")
        thunderStepMod := g_SF.BrivHasThunderStep() ? 1.2 : 1
        this.CloseIC( reason )
        stacks := Floor(((this.sprint?this.sprint:0) + (this.steelbones?this.steelbones:0)) * thunderStepMod)
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
        if (g_SF.BrivHasThunderStep())
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
        try ; set off any timers in SH that need to run on a reset.
        {
            ; e.g. buy/open chests
            g_ScriptHubComs.RunTimersOnModronReset()
        }
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
        isShandieInFormation := this.IsChampInFormation( ActiveEffectKeySharedFunctions.Shandie, this.Memory.GetCurrentFormation() )            
        if (!isShandieInFormation)
            return False

        return True
    }

    DoRushWaitIdling(StartTime, estimate)
    {
        this.ToggleAutoProgress(0)
        this.SetFormation()
        ElapsedTime := A_TickCount - StartTime
        g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
        percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10)+15, 15)
        Sleep, %percentageReducedSleep%
        ElapsedTime := A_TickCount - StartTime
        return ElapsedTime
    }

    SetFormationForStart()
    {
        if (g_SF.Memory.ReadCurrentZone() == 1)
        {
            formationKey := g_BrivUserSettings[ "FormationKeyForZ1" ] ? g_BrivUserSettings[ "FormationKeyForZ1" ] : "q"
            g_SF.DirectedInput(,, "{" . formationKey . "}")
        }
        else ; Switch to E formation if necessary
            g_SF.SetFormation(g_BrivUserSettings)
        return formationKey
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

    GetInitialFormation()
    {
        return g_SF.Memory.GetActiveModronFormation()
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
        g_SharedData.LoopString := "Rush Wait: "
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
            ElapsedTime := this.DoRushWaitIdling(StartTime, estimate)
        g_PreviousZoneStartTime := A_TickCount
    }
}
class IC_BrivGemFarm_Stats_Component
{
    doesExist := true
    StatsTabFunctions := {}

    ; Update Tab Stats Variables
    TotalRunCount := 0
    FailedStacking := 0
    FailedStackConv := 0
    SlowRunTime := 0
    FastRunTime := 0
    ScriptStartTime := 0
    CoreXPStart := 0
    NordomXPStart := 0
    GemStart := 0
    GemSpentStart := 0
    BossesPerHour := 0
    LastResetCount := 0
    RunStartTime := A_TickCount
    IsStarted := false ; Skip recording of first run
    StackFail := ""
    SilverChestCountStart := 0
    GoldChestCountStart := 0
    LastTriggerStart := false
    ActiveGameInstance := 1
    FailRunTime := 0
    TotalRunCountRetry := 0
    PreviousRunTime := 0
    GemsTotal := 0
    SbLastStacked := ""
    
    SharedRunData[]
    {
        get 
        {
            try
            {
                return ComObjActive(g_BrivFarm.GemFarmGUID)
            }
            catch, Err
            {
                return ""
            }
        }
    }


    ;======================
    ; GUI Building Functions
    ;======================

    ; Adds tooltip to StackFails
    BuildToolTips()
    {
        StackFailToolTip := "
        (
            StackFail Types:
            1.  Ran out of stacks when ( > min stack zone AND < target stack zone). only reported when fail recovery is on
                Will stack farm - only a warning. Configuration likely incorrect
            2.  Failed stack conversion (Haste <= 50, SB > target stacks). Forced Reset
            3.  Game was stuck (checkifstuck), forced reset
            4.  Ran out of haste and steelbones > target, forced reset
            5.  Failed stack conversion, all stacks lost.
            6.  Modron not resetting, forced reset
        )"
        GUIFunctions.AddToolTip("FailedStackingID", StackFailToolTip)
    }

    ; Used to add a function to be called when generating the stats tab
    AddStatsTabMod(FunctionName, Object := "")
    {
        if(Object != "")
        {
            functionToPush := ObjBindMethod(%Object%, FunctionName)
        }
        else
        {
            functionToPush := Func(FunctionName)
        }
        if(this.StatsTabFunctions == "")
            this.StatsTabFunctions := {}
        this.StatsTabFunctions.Push(functionToPush)
    }

    ; Adds the current run group box to the stats tab under the reset button
    AddCurrentRunGroup()
    {
        global
        GuiControlGet, pos, ICScriptHub:Pos, Reset_Briv_Farm_Stats_Button
        posY := posY + 25
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%posY% w450 h140 vCurrentRunGroupID, Current `Run:
        Gui, ICScriptHub:Font, w400

        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, Text, vLoopAlignID xp+15 yp+25 , `Loop:
        GuiControlGet, pos, ICScriptHub:Pos, LoopAlignID
        g_LeftAlign := posX
        Gui, ICScriptHub:Add, Text, vLoopID x+2 w400, Not Started
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current Area Time (s):
        Gui, ICScriptHub:Add, Text, vdtCurrentLevelTimeID x+2 w200, ; % dtCurrentLevelTime
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current `Run Time (min):
        Gui, ICScriptHub:Add, Text, vdtCurrentRunTimeID x+2 w50, ; % dtCurrentRunTime

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, SB Stack `Count:
        Gui, ICScriptHub:Add, Text, vg_StackCountSBID x+2 w200, ; % g_StackCountSB
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Haste Stack `Count:
        Gui, ICScriptHub:Add, Text, vg_StackCountHID x+2 w200, ; % g_StackCountH
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Last Close Game Reason:
        Gui, ICScriptHub:Add, Text, vLastCloseGameReasonID x+2 w300, 
        GUIFunctions.UseThemeTextColor()
    }

    ; Adds the Once per run group box to the stats tab page under the current run group.
    AddOncePerRunGroup()
    {
        global        
        GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
        g_DownAlign := posY + posH -5
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%g_DownAlign% w450 h350 vOnceRunGroupID, Updated Once Per Full Run:
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, Previous Run Time (min):
        Gui, ICScriptHub:Add, Text, vPrevRunTimeID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Fastest Run Time (min):
        Gui, ICScriptHub:Add, Text, vFastRunTimeID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Slowest Run Time (min):
        Gui, ICScriptHub:Add, Text, vSlowRunTimeID x+2 w50,

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Run `Count:
        Gui, ICScriptHub:Add, Text, vTotalRunCountID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Total Run Time (hr):
        Gui, ICScriptHub:Add, Text, vdtTotalTimeID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Avg. Run Time (min):
        Gui, ICScriptHub:Add, Text, vAvgRunTimeID x+2 w50,

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Fail Run Time (min):
        Gui, ICScriptHub:Add, Text, vFailRunTimeID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Fail Run Time Total (min):
        Gui, ICScriptHub:Add, Text, vTotalFailRunTimeID x+2 w50,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stacking Tally by Type:
        Gui, ICScriptHub:Add, Text, vFailedStackingID x+2 w120,

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Silvers Gained:
        Gui, ICScriptHub:Add, Text, vSilversGainedID x+2 w200, 0
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Silvers Opened:
        Gui, ICScriptHub:Add, Text, vSilversOpenedID x+2 w200, 0
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Gained:
        Gui, ICScriptHub:Add, Text, vGoldsGainedID x+2 w200, 0
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Golds Opened:
        Gui, ICScriptHub:Add, Text, vGoldsOpenedID x+2 w200, 0
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Shinies Found:
        Gui, ICScriptHub:Add, Text, vShiniesID x+2 w200, 0
        ShiniesClassNN := GUIFunctions.GetToolTipTarget("ShiniesID")

        GUIFunctions.UseThemeTextColor("SpecialTextColor1", 700)
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Bosses per hour:
        Gui, ICScriptHub:Add, Text, vbossesPhrID x+2 w60, ; % bossesPhr


        GUIFunctions.UseThemeTextColor("SpecialTextColor2", 700)
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, Total Gems:
        Gui, ICScriptHub:Add, Text, vGemsTotalID x+2 w200, ; % GemsTotal
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Gems per hour:
        Gui, ICScriptHub:Add, Text, vGemsPhrID x+2 w200, ; % GemsPhr
        
        GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
        GuiControlGet, pos, ICScriptHub:Pos, bossesPhrID
        posX += 70
        Gui, ICScriptHub:Add, Text, vNordomWarningID x%posX% y%posY% w265,
        GuiControlGet, pos, ICScriptHub:Pos, OnceRunGroupID
        g_DownAlign := g_DownAlign + posH -5
        GUIFunctions.UseThemeTextColor()
    }

    ; Adds the briv gem farm stats group to the stats page below the current run group 
    AddBrivGemFarmStatsGroup()
    {
        global
        Gui, ICScriptHub:Tab, Stats
        GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%g_DownAlign% w450 h125 vBrivGemFarmStatsID, BrivGemFarm Stats:
        Gui, ICScriptHub:Font, w400 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, Boss Levels Hit `This `Run:
        Gui, ICScriptHub:Add, Text, vBossesHitThisRunID x+2 w200, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Boss Levels Hit Since Start:
        Gui, ICScriptHub:Add, Text, vTotalBossesHitID x+2 w200,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, RollBacks Hit Since Start:
        Gui, ICScriptHub:Add, Text, vTotalRollBacksID x+2 w200,  
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Bad Autoprogression Since Start:
        Gui, ICScriptHub:Add, Text, vBadAutoprogressesID x+2 w200,  
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Calculated Target Stacks:
        Gui, ICScriptHub:Add, Text, vCalculatedTargetStacksID x+2 w200,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 vHybridStatsCountTitle, ForceOfflineRunThreshold Count:
        Gui, ICScriptHub:Add, Text, vHybridStatsCountValue x+2 w200,
        GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmStatsID
        g_DownAlign := g_DownAlign + posH -5
        g_TabControlHeight := Max(g_TabControlHeight, 700)
        GUIFunctions.RefreshTabControlSize()
        GUIFunctions.UseThemeTextColor()
    }

    ; Calls the functions that have been added to the stats tab via the AddStatsTabMod function
    UpdateStatsTabWithMods()
    {
        for k,v in this.StatsTabFunctions
        {
            v.Call()
        }
        this.StatsTabFunctions := {}
    }
    
    ;======================
    ; GUI Update Functions
    ;======================

    ;Updates GUI dtCurrentRunTimeID and dtCurrentLevelTimeID
    UpdateStatTimers()
    {
        static startTime := A_TickCount
        static previousZoneStartTime := A_TickCount
        static previousLoopStartTime := A_TickCount
        static lastZone := -1
        static lastResetCount := 0
        static sbStackMessage := ""
        static hasteStackMessage := ""
        static LastTriggerStart := false

        TriggerStart := IsObject(this.SharedRunData) ? this.SharedRunData.TriggerStart : LastTriggerStart
        Critical, On
        currentZone := g_SF.Memory.ReadCurrentZone()
        if ( g_SF.Memory.ReadResetsCount() > lastResetCount OR (g_SF.Memory.ReadResetsCount() == 0 AND g_SF.Memory.ReadAreaActive() AND lastResetCount != 0 ) OR (TriggerStart AND LastTriggerStart != TriggerStart)) ; Modron or Manual reset happend
        {
            lastResetCount := g_SF.Memory.ReadResetsCount()
            previousLoopStartTime := A_TickCount
            previousZoneStartTime := A_TickCount ; Reset zone timer after modron reset
            lastZone := 0
        }

        if !g_SF.Memory.ReadUserIsInited()
        {
            ; do not update lastZone if game is loading
        }
        else if ( (currentZone > lastZone) AND (currentZone >= 2)) ; zone reset
        {
            lastZone := currentZone
            previousZoneStartTime := A_TickCount
        }
        else if ((g_SF.Memory.ReadHighestZone() < 3) AND (lastZone >= 3) AND (currentZone > 0) ) ; After reset. +1 buffer for time to read value
        {
            lastZone := currentZone
            previousLoopStartTime := A_TickCount
        }

        sbStacks := g_SF.Memory.ReadSBStacks()
        if (sbStacks == "")
        {
            if (SubStr(sbStackMessage, StrLen(sbStackMessage), 1) != "]")
            {
                sbStackMessage := sbStackMessage . " [last]"
            }
        } 
        else 
        {
            lastStackedSB := (this.SbLastStacked > 0) ? (" (Last reset: " . this.SbLastStacked . ")") : ""
            sbStackMessage := sbStacks . lastStackedSB
        }
        hasteStacks := g_SF.Memory.ReadHasteStacks()
        if (hasteStacks == "")
        {
            if (SubStr(hasteStackMessage, StrLen(hasteStackMessage), 1) != "]")
            {
                hasteStackMessage := hasteStackMessage . " [last]"
            }
        } 
        else 
        {
            hasteStackMessage := hasteStacks
        }
        GuiControl, ICScriptHub:, g_StackCountSBID, % sbStackMessage
        GuiControl, ICScriptHub:, g_StackCountHID, % hasteStackMessage

        dtCurrentRunTime := Round( ( A_TickCount - previousLoopStartTime ) / 60000, 2 )
        GuiControl, ICScriptHub:, dtCurrentRunTimeID, % dtCurrentRunTime

        dtCurrentLevelTime := Round( ( A_TickCount - previousZoneStartTime ) / 1000, 2 )
        GuiControl, ICScriptHub:, dtCurrentLevelTimeID, % dtCurrentLevelTime
        if(IsObject(this.SharedRunData))
            GuiControl, ICScriptHub:, LastCloseGameReasonID, % this.SharedRunData.LastCloseReason
        Critical, Off
    }

    ;Updates the stats tab's once per run stats
    UpdateStartLoopStats()
    {
        ; Do not calculate stacks if game/script do not appear to be in a normal state.
        if(!IsObject(this.SharedRunData) OR this.SharedRunData.LoopString != "Main Loop") 
            return
        Critical, On
        if !this.isStarted
        {
            this.LastResetCount := g_SF.Memory.ReadResetsCount()
            this.isStarted := true
        }

        this.StackFail := Max(this.StackFail, IsObject(this.SharedRunData) ? this.SharedRunData.StackFail : 0)
        this.TriggerStart := IsObject(this.SharedRunData) ? this.SharedRunData.TriggerStart : this.LastTriggerStart
        if ( g_SF.Memory.ReadResetsCount() > this.LastResetCount OR (g_SF.Memory.ReadResetsCount() == 0 AND g_SF.Memory.ReadOfflineDone() AND this.LastResetCount != 0 ) OR (this.TriggerStart AND this.LastTriggerStart != this.TriggerStart) )
        {
            while(!g_SF.Memory.ReadOfflineDone() AND IsObject(this.SharedRunData) AND this.SharedRunData.TriggerStart)
            {
                Critical, Off
                Sleep, 50
                Critical, On
            }
            ; CoreXP starting on FRESH run.
            if(!this.TotalRunCount OR (this.TotalRunCount AND this.TotalRunCountRetry < 2 AND (!this.CoreXPStart OR !this.GemStart)))
            {
                if(this.TotalRunCount)
                    this.TotalRunCountRetry++
                this.ActiveGameInstance := g_SF.Memory.ReadActiveGameInstance()
                this.CoreXPStart := g_SF.Memory.GetCoreXPByInstance(this.ActiveGameInstance)
                this.NordomXPStart := ActiveEffectKeySharedFunctions.Nordom.NordomModronCoreToolboxHandler.ReadAwardedXPStat()
                this.GemStart := g_SF.Memory.ReadGems()
                this.GemSpentStart := g_SF.Memory.ReadGemsSpent()
                this.LastResetCount := g_SF.Memory.ReadResetsCount()
                silverChests := g_SF.Memory.ReadChestCountByID(1)
                goldChests := g_SF.Memory.ReadChestCountByID(2)
                this.SilverChestCountStart := (silverChests != "") ? silverChests : 0
                this.GoldChestCountStart := (goldChests != "") ? goldChests : 0
                
                ; start count after first run since total chest count is counted after first run
                if(IsObject(this.SharedRunData)) 
                {
                    this.SharedRunData.PurchasedGoldChests := 0
                    this.SharedRunData.PurchasedSilverChests := 0    
                }
                
                this.FastRunTime := 1000
                this.ScriptStartTime := A_TickCount
            }
            if(IsObject(IC_InventoryView_Component) AND g_InventoryView != "") ; If InventoryView AddOn is available
            {
                InventoryViewRead := ObjBindMethod(g_InventoryView, "ReadCombinedInventory")
                InventoryViewRead.Call(this.TotalRunCount)
            }
            this.LastResetCount := g_SF.Memory.ReadResetsCount()
            this.PreviousRunTime := round( ( A_TickCount - this.RunStartTime ) / 60000, 2 )
            this.SbLastStacked := g_SF.Memory.ReadHasteStacks()
            GuiControl, ICScriptHub:, PrevRunTimeID, % this.PreviousRunTime

            if (this.TotalRunCount AND (!this.StackFail OR this.StackFail == 6))
            {
                if (this.SlowRunTime < this.PreviousRunTime)
                    GuiControl, ICScriptHub:, SlowRunTimeID, % this.SlowRunTime := this.PreviousRunTime
                if (this.FastRunTime > this.PreviousRunTime)
                    GuiControl, ICScriptHub:, FastRunTimeID, % this.FastRunTime := this.PreviousRunTime
            }
            if ( this.StackFail ) ; 1 = Did not make it to Stack Zone. 2 = Stacks did not convert. 3 = Game got stuck in adventure and restarted.
            {
                GuiControl, ICScriptHub:, FailRunTimeID, % this.PreviousRunTime
                this.FailRunTime += this.PreviousRunTime
                GuiControl, ICScriptHub:, TotalFailRunTimeID, % round( this.FailRunTime, 2 )
                if(IsObject(this.SharedRunData))
                    GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString(this.SharedRunData.StackFailStats.TALLY)
            }

            GuiControl, ICScriptHub:, TotalRunCountID, % this.TotalRunCount
            dtTotalTime := (A_TickCount - this.ScriptStartTime) / 3600000
            GuiControl, ICScriptHub:, dtTotalTimeID, % Round( dtTotalTime, 2 )
            GuiControl, ICScriptHub:, AvgRunTimeID, % Round( ( dtTotalTime / this.TotalRunCount ) * 60, 2 )


            ; Check if Nordom is in formation
            formation := g_SF.Memory.GetFormationByFavorite(1)
            foundNordom := g_SF.IsChampInFormation(100, formation)
            formation := g_SF.Memory.GetFormationByFavorite(3)
            foundNordom := foundNordom OR g_SF.IsChampInFormation(100, formation)
            ; Check if Mechanus (+10% core xp) bonus exists
            foundMechanusBlessing := g_SF.Memory.GetXPBlessingSlot()
            foundXPMod := foundMechanusBlessing OR foundNordom
            GuiControl, ICScriptHub:, NordomWarningID, % (foundXPMod ? "Nordom/Mechanus found. Verify BPH." : "")
            currentNordomXP := ActiveEffectKeySharedFunctions.Nordom.NordomModronCoreToolboxHandler.ReadAwardedXPStat()
            currentCoreXP := g_SF.Memory.GetCoreXPByInstance(this.ActiveGameInstance)
            xpGain := currentCoreXP - this.CoreXPStart 
            if(foundXPMod AND foundNordom AND currentCoreXP AND currentCoreXP)
                ; xpGain := ( xpGain / 1.1 ) + ( this.NordomXPStart - currentNordomXP ) ; Other possible calculation
                xpGain := ( xpGain + (this.NordomXPStart - currentNordomXP ) ) / 1.1
            else if(foundNordom AND currentCoreXP AND currentCoreXP)
                xpGain := xpGain + ( this.NordomXPStart - currentNordomXP )
            else if (foundXPMod AND currentCoreXP AND currentCoreXP)
                xpGain := xpGain / 1.1
            else if(currentCoreXP)
                xpGain := currentCoreXP - this.CoreXPStart  
            ; unmodified levels completed / 5 = boss levels completed
            if(currentCoreXP)
                this.bossesPerHour := Round( (xpGain / 5) / dtTotalTime, 2)
            GuiControl, ICScriptHub:, bossesPhrID, % this.BossesPerHour

            this.GemsTotal := ( g_SF.Memory.ReadGems() - this.GemStart ) + ( g_SF.Memory.ReadGemsSpent() - this.GemSpentStart )
            GuiControl, ICScriptHub:, GemsTotalID, % this.GemsTotal
            GuiControl, ICScriptHub:, GemsPhrID, % Round( this.GemsTotal / dtTotalTime, 2 )

            currentSilverChests := g_SF.Memory.ReadChestCountByID(1) ; Start + Purchased + Dropped - Opened
            currentGoldChests := g_SF.Memory.ReadChestCountByID(2)

            if (IsObject(this.SharedRunData))
            {
                GuiControl, ICScriptHub:, SilversGainedID, % currentSilverChests - this.SilverChestCountStart + this.SharedRunData.OpenedSilverChests ; current - Start + Opened = Purchased + Dropped
                GuiControl, ICScriptHub:, GoldsGainedID, % currentGoldChests - this.GoldChestCountStart + this.SharedRunData.OpenedGoldChests
                GuiControl, ICScriptHub:, SilversOpenedID, % this.SharedRunData.OpenedSilverChests
                GuiControl, ICScriptHub:, GoldsOpenedID, % this.SharedRunData.OpenedGoldChests
                global ShiniesClassNN
                g_MouseToolTips[ShiniesClassNN] := this.GetShinyCountTooltip()
                GuiControl, ICScriptHub:, ShiniesID, % this.SharedRunData.ShinyCount
            }
            ++this.TotalRunCount
            this.StackFail := 0
            this.SharedRunData.StackFail := false
            this.SharedRunData.TriggerStart := false
            this.RunStartTime := A_TickCount
        }
        if (IsObject(this.SharedRunData))
            this.LastTriggerStart := this.SharedRunData.TriggerStart
        Critical, Off
    }

    ; Returns a string listing shinies found by champion.
    GetShinyCountTooltip()
    {
        if (IsObject(this.SharedRunData))
        {
            shnieisByChampString := ""
            shiniesJson := this.SharedRunData.ShiniesByChampJson
            shiniesByChamp := JSON.parse(shiniesJson)
            for champID, slots in shiniesByChamp
            {
                champName := g_SF.Memory.ReadChampNameByID(champID)
                shnieisByChampString .= champName . ": Slots ["
                for k,v in slots
                {
                    shnieisByChampString .= k . ","
                }
                if(slots != "")
                {
                    shnieisByChampString := SubStr(shnieisByChampString,1,StrLen(shnieisByChampString)-1)
                }                
                shnieisByChampString .= "]`n"
            }
            shnieisByChampString := SubStr(shnieisByChampString, 1, StrLen(shnieisByChampString)-1)
            return shnieisByChampString
        }
        else
        {
            return "Cannot read data for Shiny counts."
        }
    }

    ; Updates data on the stats tab page that is collected from the Briv Gem Farm script.
    UpdateGUIFromCom()
    {
        static SharedRunData
        ;activeObjects := GetActiveObjects()
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            textColor := Format("{:#x}", GUIFunctions.CurrentTheme["HeaderTextColor"])
            GuiControl, ICScriptHub: +c%textColor%, LoopID, 
            GuiControl, ICScriptHub:, LoopID, % SharedRunData.LoopString
            GuiControl, ICScriptHub:, BossesHitThisRunID, % SharedRunData.BossesHitThisRun
            GuiControl, ICScriptHub:, TotalBossesHitID, % SharedRunData.TotalBossesHit
            GuiControl, ICScriptHub:, TotalRollBacksID, % SharedRunData.TotalRollBacks
            GuiControl, ICScriptHub:, BadAutoprogressesID, % SharedRunData.BadAutoProgress
            GuiControl, ICScriptHub:, CalculatedTargetStacksID, % SharedRunData.TargetStacks
            runsMax := g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
            if (runsMax > 1)
            {
                GuiControl, ICScriptHub:, HybridStatsCountTitle, ForceOfflineRunThreshold Count:
                GuiControl, ICScriptHub:, HybridStatsCountValue, % Mod( g_SF.Memory.ReadResetsCount(), runsMax )
            }
            else
            {
                GuiControl, ICScriptHub:, HybridStatsCountTitle,  
                GuiControl, ICScriptHub:, HybridStatsCountValue,  
            }
        }
        catch
        {
            textColor := Format("{:#x}", GUIFunctions.CurrentTheme["ErrorTextColor"])
            GuiControl, ICScriptHub: +c%textColor%, LoopID, 
            GuiControl, ICScriptHub:, LoopID, % "Error reading from gem farm script [Closed Script?]."
        }
    }

    
    ;==========================
    ; Stats GUI Reset Functions
    ;==========================

    ; Resets stats shown on the stats tab
    ResetBrivFarmStats()
    {
        this.ResetUpdateStats()
        this.ResetComObjectStats()
        this.ResetStatsGUI()
        this.UpdateGUIFromCom()
    }

    ; Connects to Briv Gem Farm script and resets its saved stats variables.
    ResetComObjectStats()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.StackFailStats := new StackFailStates
            SharedRunData.LoopString := ""
            SharedRunData.TotalBossesHit := 0
            SharedRunData.BossesHitThisRun := 0
            SharedRunData.SwapsMadeThisRun := 0
            SharedRunData.StackFail := 0
            SharedRunData.OpenedSilverChests := 0
            SharedRunData.OpenedGoldChests := 0
            SharedRunData.PurchasedGoldChests := 0
            SharedRunData.PurchasedSilverChests := 0
            SharedRunData.ShinyCount := 0
            SharedRunData.TotalRollBacks := 0
            SharedRunData.BadAutoProgress := 0
        }
    }

    ; Resets the values shown on the stats tab immediately without waiting for updates to run.
    ResetStatsGUI()
    {
        GuiControl, ICScriptHub:, PrevRunTimeID, % this.PreviousRunTime
        GuiControl, ICScriptHub:, SlowRunTimeID, % this.SlowRunTime
        GuiControl, ICScriptHub:, FastRunTimeID, % this.FastRunTime
        GuiControl, ICScriptHub:, FailRunTimeID, % this.PreviousRunTime
        GuiControl, ICScriptHub:, TotalFailRunTimeID, % round( this.FailRunTime, 2 )
        GuiControl, ICScriptHub:, TotalRunCountID, % this.TotalRunCount
        GuiControl, ICScriptHub:, dtTotalTimeID, % 0
        GuiControl, ICScriptHub:, AvgRunTimeID, % 0
        GuiControl, ICScriptHub:, bossesPhrID, % this.BossesPerHour
        GuiControl, ICScriptHub:, GemsTotalID, % this.GemsTotal
        GuiControl, ICScriptHub:, GemsPhrID, % Round( this.GemsTotal / dtTotalTime, 2 )
        if(IsObject(this.SharedRunData))
        {
            GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString(this.SharedRunData.StackFailStats.TALLY)
            GuiControl, ICScriptHub:, SilversGainedID, % this.SharedRunData.PurchasedSilverChests
            GuiControl, ICScriptHub:, GoldsGainedID, % this.SharedRunData.PurchasedGoldChests
            GuiControl, ICScriptHub:, SilversOpenedID, % this.SharedRunData.OpenedSilverChests
            GuiControl, ICScriptHub:, GoldsOpenedID, % this.SharedRunData.OpenedGoldChests
            GuiControl, ICScriptHub:, ShiniesID, % this.SharedRunData.ShinyCount
            GuiControl, ICScriptHub:, SwapsMadeThisRunID, % this.SharedRunData.SwapsMadeThisRun
            GuiControl, ICScriptHub:, BossesHitThisRunID, % this.SharedRunData.BossesHitThisRun
            GuiControl, ICScriptHub:, TotalBossesHitID, % this.SharedRunData.TotalBossesHit
            GuiControl, ICScriptHub:, TotalRollBacksID, % this.SharedRunData.TotalRollBacks
            GuiControl, ICScriptHub:, BadAutoProgressID, % this.SharedRunData.BadAutoProgress
        }
        else
        {
            GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString("")
            GuiControl, ICScriptHub:, SilversGainedID, % 0
            GuiControl, ICScriptHub:, GoldsGainedID, % 0
            GuiControl, ICScriptHub:, SilversOpenedID, % 0
            GuiControl, ICScriptHub:, GoldsOpenedID, % 0
            GuiControl, ICScriptHub:, ShiniesID, % 0
            GuiControl, ICScriptHub:, SwapsMadeThisRunID, % 0
            GuiControl, ICScriptHub:, BossesHitThisRunID, % 0
            GuiControl, ICScriptHub:, TotalBossesHitID, % 0
            GuiControl, ICScriptHub:, TotalRollBacksID, % 0
            GuiControl, ICScriptHub:, BadAutoProgressID, % 0
        }
        GuiControl, ICScriptHub:, NordomWarningID, % ""
    }

    ; Resets stats stored on the stats tab.
    ResetUpdateStats()
    {
        this.TotalRunCount := 0
        this.FailedStacking := 0
        this.FailedStackConv := 0
        this.SlowRunTime := 0
        this.FastRunTime := 0
        this.ScriptStartTime := 0
        this.CoreXPStart := 0
        this.NordomXPStart := 0
        this.GemStart := 0
        this.GemSpentStart := 0
        this.BossesPerHour := 0
        this.LastResetCount := 0
        this.RunStartTime := A_TickCount
        this.IsStarted := false ; Skip recording of first run
        this.StackFail := ""
        this.SilverChestCountStart := 0
        this.GoldChestCountStart := 0
        this.LastTriggerStart := false
        this.ActiveGameInstance := 1
        this.FailRunTime := 0
        this.TotalRunCountRetry := 0
        this.PreviousRunTime := 0
        this.GemsTotal := 0
    }

    ;===========================================
    ;Functions for updating GUI stats and timers
    ;===========================================

    ; Adds timed functions (typically to be started when briv gem farm is started)
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer :=  ObjBindMethod(this, "UpdateStatTimers")
        this.TimerFunctions[fncToCallOnTimer] := 200
        fncToCallOnTimer :=  ObjBindMethod(this, "UpdateStartLoopStats")
        this.TimerFunctions[fncToCallOnTimer] := 3000
        fncToCallOnTimer := ObjBindMethod(this, "UpdateGUIFromCom")
        this.TimerFunctions[fncToCallOnTimer] := 100
        fncToCallOnTimer := ObjBindMethod(g_SF, "MonitorIsGameClosed")
        this.TimerFunctions[fncToCallOnTimer] := 200
    }

    ; Starts the saved timed functions (typically to be started when briv gem farm is started)
    StartTimedFunctions()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, %v%, 0
        }
    }

    ; Stops the saved timed functions (typically to be stopped when briv gem farm is stopped)
    StopTimedFunctions()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
    }
}

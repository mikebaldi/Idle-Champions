class IC_BrivGemFarm_Stats_Component
{
    static SettingsPath := A_LineFile . "\..\Stats_Settings.json"
    DefaultSettings := {"CompactTS":false,"Scientific":false}
    Settings := {}

    doesExist := true
    StatsTabFunctions := {}

    ; Update Tab Stats Variables
    TotalRunCount := 0
    FailedStacking := 0
    FailedStackConv := 0
    SlowRunTime := 0
    FastRunTime := 0
    CoreXPStart := 0
    NordomXPStart := 0
    GemStart := 0
    GemSpentStart := 0
    BossesPerHour := 0
    LastResetCount := 0
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
    PreviousLastGameCloseReason := ""
    LastLowestHasteRun := ""
    LastLowestHasteStacks := 9999999
    StatsRunsCount := 0
    DisplayScientific := false
    CompactTimestamps := false
    
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
        if(IsObject(IC_BrivGemFarm_Component))
            GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmStatsPlayButton
        else
            GuiControlGet, pos, ICScriptHub:Pos, Reset_Briv_Farm_Stats_Button
        posY := posY + 30
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%posY% w450 h140 vCurrentRunGroupID, Current `Run:
        Gui, ICScriptHub:Font, w400

        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, Text, vLoopAlignID xp+15 yp+25 , `Loop:
        GuiControlGet, pos, ICScriptHub:Pos, LoopAlignID
        g_LeftAlign := posX
        Gui, ICScriptHub:Add, Text, vLoopID x+2 w395, Not Started
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current Area Time
        Gui, ICScriptHub:Add, Text, vdtCurrentLevelTimeID x+2 w200, ; % dtCurrentLevelTime
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Current `Run Time:
        Gui, ICScriptHub:Add, Text, vdtCurrentRunTimeID x+2 w150, ; % dtCurrentRunTime

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10, SB Stack `Count:
        Gui, ICScriptHub:Add, Text, vg_StackCountSBID x+2 w200, ; % g_StackCountSB
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Haste Stack `Count:
        Gui, ICScriptHub:Add, Text, vg_StackCountHID x+2 w200, ; % g_StackCountH
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Last Close Game Reason:
        Gui, ICScriptHub:Add, Text, vLastCloseGameReasonID x+2 w300,
        GUIFunctions.UseThemeTextColor()
        GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
        posY += 1
        posX += 240
        Gui, ICScriptHub:Add, Text, x%posX% y%posY% w160, 
        posX += 10
        Gui, ICScriptHub:Add, Checkbox, x%posX% y%posY% vStatsCompactTimestamps, Use Compact Timestamps
        buttonFunc := ObjBindMethod(this, "SaveSettings")
        GuiControl,ICScriptHub: +g, StatsCompactTimestamps, % buttonFunc
    }

    ; Adds the Once per run group box to the stats tab page under the current run group.
    AddOncePerRunGroup()
    {
        global
        GuiControlGet, pos, ICScriptHub:Pos, CurrentRunGroupID
        g_DownAlign := posY + posH -5
        local labelWidth := 100
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%g_DownAlign% w450 h330 vOnceRunGroupID, Updated Once Per Full Run:
        Gui, ICScriptHub:Font, w400
        
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25 w%labelWidth% +Right, Total Run `Count:
        Gui, ICScriptHub:Add, Text, vTotalRunCountID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Total Run Time:
        Gui, ICScriptHub:Add, Text, vdtTotalTimeID x+2 w150,

        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10 w%labelWidth% +Right, Previous Run Time:
        Gui, ICScriptHub:Add, Text, vPrevRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Fastest Run Time:
        Gui, ICScriptHub:Add, Text, vFastRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Slowest Run Time:
        Gui, ICScriptHub:Add, Text, vSlowRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Avg. Run Time:
        Gui, ICScriptHub:Add, Text, vAvgRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10 w%labelWidth% +Right, Fail Run Time:
        Gui, ICScriptHub:Add, Text, vFailRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Fail Run Time Total:
        Gui, ICScriptHub:Add, Text, vTotalFailRunTimeID x+2 w150,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Failed Stacking Tally by Type:
        Gui, ICScriptHub:Add, Text, vFailedStackingID x+2 w120,

        labelWidth -= 20
        chestsWidth := 55
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10 w%labelWidth%, Chest Counts:
        Gui, ICScriptHub:Add, Text, x+2 w%chestsWidth% +Right, Opened
        Gui, ICScriptHub:Add, Text, x+2 w%chestsWidth% +Right, Bought
        Gui, ICScriptHub:Add, Text, vGoldsDroppedIDHeader x+2 w%chestsWidth% +Right, Dropped
        Gui, ICScriptHub:Font, w400
		
        GuiControlGet, pos, ICScriptHub:Pos, GoldsDroppedIDHeader
		hLineWidth := ((posX + posW) - g_LeftAlign) + 3
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+4 w%hLineWidth% h1 0x10 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Silver Chests:
        Gui, ICScriptHub:Add, Text, vSilversOpenedID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, vSilversBoughtID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, vSilversDroppedID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Golds Chests:
        Gui, ICScriptHub:Add, Text, vGoldsOpenedID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, vGoldsBoughtID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, vGoldsDroppedID x+2 w%chestsWidth% +Right, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w%labelWidth% +Right, Shinies Found:
        Gui, ICScriptHub:Add, Text, vShiniesID x+2 w200,
        ShiniesClassNN := GUIFunctions.GetToolTipTarget("ShiniesID")

        GUIFunctions.UseThemeTextColor("SpecialTextColor1", 700)
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10 w100 +Right, Bosses per hour:
        Gui, ICScriptHub:Add, Text, vbossesPhrID x+2 w65, ; % bossesPhr


        GUIFunctions.UseThemeTextColor("SpecialTextColor2", 700)
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+10 w100 +Right, Total Gems:
        Gui, ICScriptHub:Add, Text, vGemsTotalID x+2 w300, ; % GemsTotal
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 w100 +Right, Gems per hour:
        Gui, ICScriptHub:Add, Text, vGemsPhrID x+2 w300, ; % GemsPhr
        
        GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
        GuiControlGet, pos, ICScriptHub:Pos, bossesPhrID
        posX += 100
        Gui, ICScriptHub:Add, Text, vNordomWarningID x%posX% y%posY% w220,
               
        GUIFunctions.UseThemeTextColor("DefaultTextColor")
        GuiControlGet, pos, ICScriptHub:Pos, OnceRunGroupID
        posY -= 1
        posX += 240
        Gui, ICScriptHub:Add, Text, x%posX% y%posY% w160, 
        posX += 10
        Gui, ICScriptHub:Add, Checkbox, x%posX% y%posY% vStatsToggleScientific, Toggle Scientific Notation
        buttonFunc := ObjBindMethod(this, "SaveSettings")
        GuiControl,ICScriptHub: +g, StatsToggleScientific, % buttonFunc
        
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
        Gui, ICScriptHub:Add, GroupBox, x%posX% y%g_DownAlign% w450 h140 vBrivGemFarmStatsID, BrivGemFarm Stats:
        Gui, ICScriptHub:Font, w400 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% yp+25, PlayServer:
        Gui, ICScriptHub:Add, Text, vStatsPlayServerID x+2 w200, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Lowest Haste after Reset:
        Gui, ICScriptHub:Add, Text, vStatsLowestHasteID x+2 w200, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Boss Levels Hit `This `Run:
        Gui, ICScriptHub:Add, Text, vBossesHitThisRunID x+2 w200, 
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Boss Levels Hit Since Start:
        Gui, ICScriptHub:Add, Text, vTotalBossesHitID x+2 w200,
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, RollBacks Hit Since Start:
        Gui, ICScriptHub:Add, Text, vTotalRollBacksID x+2 w200,  
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2, Bad Autoprogression Since Start:
        Gui, ICScriptHub:Add, Text, vBadAutoprogressesID x+2 w200,  
        Gui, ICScriptHub:Add, Text, x%g_LeftAlign% y+2 vHybridStatsCountTitle, ForceOfflineRunThreshold Count:
        Gui, ICScriptHub:Add, Text, vHybridStatsCountValue x+2 w200,
        GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmStatsID
        g_DownAlign := g_DownAlign + posH -5
        g_TabControlHeight := Max(g_TabControlHeight, 720)
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
        static foundComs := True
        static lastSBStacks := ""

        Critical, On
        ; ============== Read Coms ===================
        try
            TriggerStart := this.SharedRunData.TriggerStart, foundComs := True
        catch
            TriggerStart := LastTriggerStart, foundComs := False
        if(foundComs)
        {
            sbStacks := g_SF.Memory.ReadSBStacks()
            if (lastSBStacks == "")
                lastSBStacks := sbStacks 
            if (InStr(this.SharedRunData.LastCloseReason, "Check Stack Settings") && this.PreviousLastGameCloseReason != this.SharedRunData.LastCloseReason && lastSBStacks == sbStacks )
            {
                g_BrivUserSettings[ "RestartStackTime" ] += 10
                lastSBStacks := sbStacks
                GuiControl, ICScriptHub:, NewRestartStackTime, % g_BrivUserSettings[ "RestartStackTime" ]
                IC_BrivGemFarm_Component.Briv_Save_Clicked()
            }
            this.PreviousLastGameCloseReason := this.SharedRunData.LastCloseReason
        }
        Critical, Off 

        ; ============== Read Mem ====================
        currentZone := g_SF.Memory.ReadCurrentZone()
        currResetCount := g_SF.Memory.ReadResetsCount()
        if ( currResetCount > lastResetCount OR (g_SF.Memory.ReadResetsCount() == 0 AND g_SF.Memory.ReadAreaActive() AND lastResetCount != 0 ) OR (TriggerStart AND LastTriggerStart != TriggerStart)) ; Modron or Manual reset happened
            lastZone := 0, lastResetCount := currResetCount
            , previousLoopStartTime := previousZoneStartTime := A_TickCount ; Reset zone timer after modron reset
        isInited := g_SF.Memory.ReadUserIsInited()
        if ( isInited AND (currentZone > lastZone) AND (currentZone >= 2)) ; zone reset
            lastZone := currentZone, previousZoneStartTime := A_TickCount
        else if ( isInited AND (g_SF.Memory.ReadHighestZone() < 3) AND (lastZone >= 3) AND (currentZone > 0) ) ; After reset. +1 buffer for time to read value
            lastZone := currentZone, previousLoopStartTime := A_TickCount
        sbStacks := g_SF.Memory.ReadSBStacks()
        if (sbStacks != "")
            lastStackedSB := (this.SbLastStacked > 0) ? (" (Last reset: " . this.SbLastStacked . ")") : ""
            , sbStackMessage := sbStacks . lastStackedSB
        else if (SubStr(sbStackMessage, StrLen(sbStackMessage), 1) != "]")
            sbStackMessage := sbStackMessage . " [last]"
        hasteStacks := g_SF.Memory.ReadHasteStacks()
        if (hasteStacks != "")
            hasteStackMessage := hasteStacks 
        else if (SubStr(hasteStackMessage, StrLen(hasteStackMessage), 1) != "]")
            hasteStackMessage := hasteStackMessage . " [last]"

        ; ============== Update GUI ==================
        GuiControl, ICScriptHub:, LastCloseGameReasonID, % this.PreviousLastGameCloseReason           
        GuiControl, ICScriptHub:, g_StackCountSBID, % sbStackMessage
        GuiControl, ICScriptHub:, g_StackCountHID, % hasteStackMessage
        GuiControl, ICScriptHub:, dtCurrentRunTimeID, % this.FormatMsec( A_TickCount - previousLoopStartTime ) 
        GuiControl, ICScriptHub:, dtCurrentLevelTimeID, % (lastZone == ": " ? "" : "[" . lastZone . "]: ") . this.FormatMsec( A_TickCount - previousZoneStartTime )
        this.UpdateMemoryUsage()
    }

    ;Updates the stats tab's once per run stats
    UpdateStartLoopStats()
    {
        static foundComs := True
        Critical, On
        try ; test, set
            foundComs := this.SharedRunData.StackFail, foundComs := True ; set flag
        catch err
            foundComs := False
        this.StatsRunsCount += 1
        if(this.StatsRunsCount == 2) ; CoreXP / Gems starting on FRESH run.
            this.StoreStartingValues()
        if(this.StatsRunsCount == 1)
            this.ResetBrivFarmStats()
            , this.LastResetCount := g_SF.Memory.ReadResetsCount()
        this.StackFail := Max(this.StackFail, foundComs ? this.SharedRunData.StackFail : 0)
        resetsCount := g_SF.Memory.ReadResetsCount()
        if ( resetsCount > this.LastResetCount )
            this.UpdateStartLoopStatsReset(foundComs, resetsCount)            
        if (foundComs)
            this.LastTriggerStart := this.SharedRunData.TriggerStart
        Critical, Off
    }

    UpdateMemoryUsage()
    {
        GuiControl, ICScriptHub:, SH_Memory_In_Use, % g_SF.GetProcessMemoryUsage() . "MB"
    }

    UpdateStartLoopStatsReset(foundComs, resetsCount)
    {
        if (foundComs)
        {
            if (!this.ScriptStartTime)
                this.ScriptStartTime := this.SharedRunData.ScriptStartTime
            this.PreviousRunTime := this.SharedRunData.LastRunTime
            gemsSpent := this.SharedRunData.GemsSpent
            this.SharedRunData.TriggerStart := false
            this.SharedRunData.StackFail := false
            this.TotalRunCount := this.SharedRunData.TotalRunsCount
        }
        if(IsObject(IC_InventoryView_Component) AND g_InventoryView != "") ; If InventoryView AddOn is available
            g_InventoryView.ReadCombinedInventory(this.TotalRunCount)
        this.LastResetCount := resetsCount
        if (this.SlowRunTime < this.PreviousRunTime AND this.TotalRunCount AND (!this.StackFail OR this.StackFail == 6))
            this.SlowRunTime := this.PreviousRunTime
        if (this.FastRunTime > this.PreviousRunTime AND this.TotalRunCount AND (!this.StackFail OR this.StackFail == 6))
            this.FastRunTime := this.PreviousRunTime
        this.SbLastStacked := g_SF.Memory.ReadHasteStacks()
        if ( this.StackFail ) ; 1 = Did not make it to Stack Zone. 2 = Stacks did not convert. 3 = Game got stuck in adventure and restarted.
            this.FailRunTime += this.PreviousRunTime
        this.TotalFarmTime := (A_TickCount - this.ScriptStartTime)
        this.TotalFarmTimeHrs := this.TotalFarmTime / 3600000
        if(this.TotalRunCount > 0)
            this.BossesPerHour := Round( ((xpGain := this.DoXPChecks()) / 5) / this.TotalFarmTimeHrs, 3) ; unmodified levels completed / 5 = boss levels completed
        { ; (Opened / Bought / Dropped)
            global ShiniesClassNN
            g_MouseToolTips[ShiniesClassNN] := this.GetShinyCountTooltip()
        }
        this.GemsTotal := ( g_SF.Memory.ReadGems() - this.GemStart ) + gemsSpent
        this.UpdateStartLoopStatsGUI(this.TotalFarmTime)
        this.StackFail := 0
    }
    
    UpdateStartLoopStatsGUI()
    {
        if (this.TotalRunCount AND (!this.StackFail OR this.StackFail == 6))
        {
            GuiControl, ICScriptHub:, FastRunTimeID, % this.FormatMsec(this.FastRunTime)
            GuiControl, ICScriptHub:, SlowRunTimeID, % this.FormatMsec(this.SlowRunTime)
        }
        GuiControl, ICScriptHub:, PrevRunTimeID, % this.FormatMsec(this.PreviousRunTime)
        if ( this.StackFail )
        {
            GuiControl, ICScriptHub:, FailRunTimeID, % this.FormatMsec(this.PreviousRunTime)
            GuiControl, ICScriptHub:, TotalFailRunTimeID, % this.FormatMsec(this.FailRunTime)
            if(IsObject(this.SharedRunData))
                GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString(this.SharedRunData.StackFailStats.TALLY)
        }
        GuiControl, ICScriptHub:, TotalRunCountID, % this.DecideScientific(this.TotalRunCount)
        GuiControl, ICScriptHub:, GemsTotalID, % this.DecideScientific(this.GemsTotal)

        if (IsObject(this.SharedRunData))
        {
            currentSilverChests := g_SF.Memory.ReadChestCountByID(1) ; Start + Purchased + Dropped - Opened
            currentGoldChests := g_SF.Memory.ReadChestCountByID(2)
            GuiControl, ICScriptHub:, SilversOpenedID, % this.DecideScientific(this.SharedRunData.OpenedSilverChests)
            GuiControl, ICScriptHub:, SilversBoughtID, % this.DecideScientific(this.SharedRunData.PurchasedSilverChests)
            GuiControl, ICScriptHub:, SilversDroppedID, % this.DecideScientific(this.CalculateDroppedChests(currentSilverChests, 1))
            GuiControl, ICScriptHub:, GoldsOpenedID, % this.DecideScientific(this.SharedRunData.OpenedGoldChests)
            GuiControl, ICScriptHub:, GoldsBoughtID, % this.DecideScientific(this.SharedRunData.PurchasedGoldChests)
            GuiControl, ICScriptHub:, GoldsDroppedID, % this.DecideScientific(this.CalculateDroppedChests(currentGoldChests, 2))
            GuiControl, ICScriptHub:, ShiniesID, % this.SharedRunData.ShinyCount
        }
        if(this.TotalFarmTime == "")
            return
        GuiControl, ICScriptHub:, AvgRunTimeID, % this.FormatMsec(this.TotalFarmTime / this.TotalRunCount)
        GuiControl, ICScriptHub:, dtTotalTimeID, % this.FormatMsec(this.TotalFarmTime)
        GuiControl, ICScriptHub:, bossesPhrID, % this.DecideScientific(this.BossesPerHour)
        GuiControl, ICScriptHub:, GemsPhrID, % this.DecideScientific(Round( this.GemsTotal / this.TotalFarmTimeHrs, 3 ))
    }

    StoreStartingValues()
    {
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
        this.FastRunTime := 999999999
    }

    DoXPChecks()
    {
        ; Check if Nordom is in formations
        foundNordom := g_SF.IsChampInFormation(100, g_SF.Memory.GetFormationByFavorite(1)) OR g_SF.IsChampInFormation(100, g_SF.Memory.GetFormationByFavorite(3)) 
        ; Check if Mechanus (+10% core xp) bonus exists
        foundMechanusBlessing := g_SF.Memory.GetXPBlessingSlot() 
        this.DisplayXPWarning(foundNordom, foundMechanusBlessing)
        currentNordomXP := ActiveEffectKeySharedFunctions.Nordom.NordomModronCoreToolboxHandler.ReadAwardedXPStat()
        currentCoreXP := g_SF.Memory.GetCoreXPByInstance(this.ActiveGameInstance)
        xpGain := currentCoreXP - this.CoreXPStart 
        if(foundMechanusBlessing AND foundNordom AND currentCoreXP)
            ; xpGain := ( xpGain / 1.1 ) + ( this.NordomXPStart - currentNordomXP ) ; Other possible calculation
            xpGain := ( xpGain + (this.NordomXPStart - currentNordomXP ) ) / 1.1
        else if(foundNordom AND currentCoreXP)
            xpGain := xpGain + ( this.NordomXPStart - currentNordomXP )
        else if (foundMechanusBlessing AND currentCoreXP)
            xpGain := xpGain / 1.1
        return xpGain
    }

    DisplayXPWarning(isNordomFound, isMechanusFound)
    {
        preStrValue := ""
        if (isMechanusFound AND isNordomFound)
            preStrValue := "Mechanus/Nordom found."
        else if (isMechanusFound)
            preStrValue := "Mechanus found."
        else if (isNordomFound)
            preStrValue := "Nordom found."
        if (preStrValue)
            GuiControl, ICScriptHub:, NordomWarningID, % preStrValue
    }

    ; Calculate dropped chests according to chest ID (1 or 2) and current number held . dropped := current - starting - purchased + opened
    CalculateDroppedChests(currentNumber, chestID := 1)
    {
        ; id 1 == silver, id 2 == gold. Should not accept any other number
        if (chestID > 2 OR chestID < 1)
            return ""
        if (currentNumber == "")
            return 0
        startingNum := chestID == 1 ? this.SilverChestCountStart : this.GoldChestCountStart
        if (IsObject(this.SharedRunData))
        {
            Try
            {
                purchasedNum := chestID == 1 ? this.SharedRunData.PurchasedSilverChests : this.SharedRunData.PurchasedGoldChests
                openedNum := chestID == 1 ? this.SharedRunData.OpenedSilverChests : this.SharedRunData.OpenedGoldChests
            }
        }
        dropped := currentNumber - startingNum - purchasedNum + openedNum
        return dropped
    }

    ; Returns a string listing shinies found by champion.
    GetShinyCountTooltip()
    {
        if (IsObject(this.SharedRunData))
        {
            shiniesByChampString := ""
            shiniesJson := this.SharedRunData.ShiniesByChampJson
            shiniesByChamp := JSON.parse(shiniesJson)
            for champID, slots in shiniesByChamp
            {
                champName := g_SF.Memory.ReadChampNameByID(champID)
                shiniesByChampString .= champName . ": Slots ["
                for k,v in slots
                {
                    shiniesByChampString .= k . ","
                }
                if(slots != "")
                {
                    shiniesByChampString := SubStr(shiniesByChampString,1,StrLen(shiniesByChampString)-1)
                }
                shiniesByChampString .= "]`n"
            }
            shiniesByChampString := SubStr(shiniesByChampString, 1, StrLen(shiniesByChampString)-1)
            return shiniesByChampString
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
            GuiControl, ICScriptHub:, StatsPlayServerID, % SharedRunData.PlayServer
            if (SharedRunData.LowestHasteStacks  AND SharedRunData.LowestHasteStacks < this.LastLowestHasteStacks)
            {
                this.LastLowestHasteStacks := SharedRunData.LowestHasteStacks
                this.LastLowestHasteRun := this.TotalRunCount
            }
            lowestHasteStr := (this.LastLowestHasteStacks == 9999999 ? "" : this.LastLowestHasteStacks) 
            lowestHasteStr .= this.LastLowestHasteRun != "" ? " [" . this.LastLowestHasteRun . "]" : ""
            GuiControl, ICScriptHub:, StatsLowestHasteID, % lowestHasteStr
            GuiControl, ICScriptHub:, BossesHitThisRunID, % SharedRunData.BossesHitThisRun
            GuiControl, ICScriptHub:, TotalBossesHitID, % SharedRunData.TotalBossesHit
            GuiControl, ICScriptHub:, TotalRollBacksID, % SharedRunData.TotalRollBacks
            GuiControl, ICScriptHub:, BadAutoprogressesID, % SharedRunData.BadAutoProgress
            runsMax := g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
            if (runsMax > 1)
            {
                GuiControl, ICScriptHub:, HybridStatsCountTitle, ForceOfflineRunThreshold Count:
                resetsCount := g_SF.Memory.ReadResetsCount()
                if(resetsCount != "")
                    GuiControl, ICScriptHub:, HybridStatsCountValue, % Mod( resetsCount, runsMax ) . " / " . g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
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
    ResetBrivFarmStats(fullReset := false)
    {
        if(fullReset)
            this.StatsRunsCount := 0
        this.ResetUpdateStats()
        this.ResetComObjectStats()
        this.ResetStatsGUI()
        this.UpdateGUIFromCom()
        ; Show XP warning from start.
        foundNordom := g_SF.IsChampInFormation(100, g_SF.Memory.GetFormationByFavorite(1)) OR g_SF.IsChampInFormation(100, g_SF.Memory.GetFormationByFavorite(3)) 
        foundMechanusBlessing := g_SF.Memory.GetXPBlessingSlot() 
        this.DisplayXPWarning(foundNordom, foundMechanusBlessing)

        if(fullReset)
            this.UpdateStartLoopStats()
    }

    ; Connects to Briv Gem Farm script and resets its saved stats variables.
    ResetComObjectStats()
    {
        if(!IsObject(g_BrivFarmComsObj))
            IC_BrivGemFarm_Component.StartComs()
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
            SharedRunData.TotalRunsCount := 0
            SharedRunData.ThisRunStart := 0
            SharedRunData.LastRunTime := 0
            SharedRunData.ScriptStartTime := 0
            SharedRunData.GemsSpent := 0
        }
    }

    ; Resets the values shown on the stats tab immediately without waiting for updates to run.
    ResetStatsGUI()
    {
        GuiControl, ICScriptHub:, PrevRunTimeID, % this.PreviousRunTime
        GuiControl, ICScriptHub:, FastRunTimeID, % this.FastRunTime
        GuiControl, ICScriptHub:, SlowRunTimeID, % this.SlowRunTime
        GuiControl, ICScriptHub:, FailRunTimeID, % this.PreviousRunTime
        GuiControl, ICScriptHub:, TotalFailRunTimeID, % round( this.FailRunTime, 3 )
        GuiControl, ICScriptHub:, TotalRunCountID, % this.TotalRunCount
        GuiControl, ICScriptHub:, dtTotalTimeID, % 0
        GuiControl, ICScriptHub:, AvgRunTimeID, % 0
        GuiControl, ICScriptHub:, bossesPhrID, % this.BossesPerHour
        GuiControl, ICScriptHub:, GemsTotalID, % this.GemsTotal
        GuiControl, ICScriptHub:, GemsPhrID, % Round( this.GemsTotal / this.TotalFarmTime, 3 )
        if(IsObject(this.SharedRunData))
        {
            GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString(this.SharedRunData.StackFailStats.TALLY)
            GuiControl, ICScriptHub:, SilversOpenedID, % this.DecideScientific(this.SharedRunData.OpenedSilverChests)
            GuiControl, ICScriptHub:, SilversBoughtID, % this.DecideScientific(this.SharedRunData.PurchasedSilverChests)
            GuiControl, ICScriptHub:, SilversDroppedID, % this.DecideScientific(this.CalculateDroppedChests(currentSilverChests, 1))
            GuiControl, ICScriptHub:, GoldsOpenedID, % this.DecideScientific(this.SharedRunData.OpenedGoldChests)
            GuiControl, ICScriptHub:, GoldsBoughtID, % this.DecideScientific(this.SharedRunData.PurchasedGoldChests)
            GuiControl, ICScriptHub:, GoldsDroppedID, % this.DecideScientific(this.CalculateDroppedChests(currentGoldChests, 2))
            GuiControl, ICScriptHub:, ShiniesID, % this.SharedRunData.ShinyCount
            GuiControl, ICScriptHub:, StatsPlayServerID, % this.SharedRunData.PlayServer
            GuiControl, ICScriptHub:, StatsLowestHasteID, % this.SharedRunData.LowestHasteStacks == 9999999 ? "" : this.SharedRunData.LowestHasteStacks
            GuiControl, ICScriptHub:, BossesHitThisRunID, % this.SharedRunData.BossesHitThisRun
            GuiControl, ICScriptHub:, TotalBossesHitID, % this.SharedRunData.TotalBossesHit
            GuiControl, ICScriptHub:, TotalRollBacksID, % this.SharedRunData.TotalRollBacks
            ; GuiControl, ICScriptHub:, BadAutoProgressID, % this.SharedRunData.BadAutoProgress
        }
        else
        {
            GuiControl, ICScriptHub:, FailedStackingID, % ArrFnc.GetDecFormattedArrayString("")
            GuiControl, ICScriptHub:, SilversOpenedID, % "0"
            GuiControl, ICScriptHub:, SilversBoughtID, % "0"
            GuiControl, ICScriptHub:, SilversDroppedID, % "0"
            GuiControl, ICScriptHub:, GoldsOpenedID, % "0"
            GuiControl, ICScriptHub:, GoldsBoughtID, % "0"
            GuiControl, ICScriptHub:, GoldsDroppedID, % "0"
            GuiControl, ICScriptHub:, ShiniesID, % 0
            GuiControl, ICScriptHub:, StatsPlayServerID, % ""
            GuiControl, ICScriptHub:, StatsLowestHasteID, % ""
            GuiControl, ICScriptHub:, SwapsMadeThisRunID, % 0
            GuiControl, ICScriptHub:, BossesHitThisRunID, % 0
            GuiControl, ICScriptHub:, TotalBossesHitID, % 0
            GuiControl, ICScriptHub:, TotalRollBacksID, % 0
            ; GuiControl, ICScriptHub:, BadAutoProgressID, % 0
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
        this.StackFail := ""
        this.SilverChestCountStart := 0
        this.GoldChestCountStart := 0
        this.LastTriggerStart := false
        this.ActiveGameInstance := 1
        this.FailRunTime := 0
        this.TotalRunCountRetry := 0
        this.PreviousRunTime := 0
        this.GemsTotal := 0
        this.LastLowestHasteRun := ""
        this.LastLowestHasteStacks := 9999999
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
        fncToCallOnTimer := ObjBindMethod(this, "UpdateGUIFromCom")
        this.TimerFunctions[fncToCallOnTimer] := 100

        this.UpdateLoopStatsFnc :=  ObjBindMethod(this, "UpdateStartLoopStats", False)
        this.UpdateLoopStatsFncRepeatTime := -300
        fncToCallOnTimer := ObjBindMethod(this, "MonitorIsGameClosed")
        g_BrivFarmComsObj.OneTimeRunAtResetEndFunctions["MonitorIsGameClosed"] := fncToCallOnTimer
        g_BrivFarmComsObj.OneTimeRunAtResetEndFunctionsTimes["MonitorIsGameClosed"] := 200
    }

    ; Reloads memory reads after game has closed. For updating GUI.
    MonitorIsGameClosed()
    {
        static comDisabled := True
        ; Make sure game is running before updating stats
        if (WinExist( "ahk_exe " . g_userSettings[ "ExeName"] )) 
        {
            g_SF.Memory.OpenProcessReader()
            updateGUIFnc := this.UpdateLoopStatsFnc
            repeatTimeMS := this.UpdateLoopStatsFncRepeatTime
            SetTimer, %updateGUIFnc%, %repeatTimeMS%, 5
            gameMonFnc := g_BrivFarmComsObj.OneTimeRunAtResetEndFunctions["MonitorIsGameClosed"]
            SetTimer, %gameMonFnc%, Off
        }
    }

    ; Starts the saved timed functions (typically to be started when briv gem farm is started)
    StartTimedFunctions()
    {
        for k,v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
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

    FormatMsec(ms)
    {
        local form
        if (ms < 60000)
            form := this.CompactTimestamps ? "ss'.'fff" : "s's 'fff'ms"
        else if (ms < 3600000)
            form := this.CompactTimestamps ? "mm':'ss'.'fff" : "m'm 'ss's 'fff'ms"
        else if (ms < 86400000)
            form := this.CompactTimestamps ? "h':'mm':'ss'.'fff" : "h'h 'mm'm 'ss's 'fff'ms"
        else
            form := this.CompactTimestamps ? "d'd 'h':'mm':'ss'.'fff" : "d'd 'h'h 'mm'm 'ss's 'fff'ms"
        VarSetCapacity(t,256),DllCall("GetDurationFormat","uint",2048,"uint",0,"ptr",0,"int64",ms*10000,"wstr",form,"wstr",t,"int",256)
        return t
    }
    
    DecideScientific(val)
    {
        if (this.DisplayScientific)
            return g_SF.GetScientificNotation(val, 3)
        return g_SF.AddThousandsSeperator(val)
    }
    
    LoadSettings()
    {
        Global
        Gui, Submit, NoHide
        writeSettings := false
        this.Settings := g_SF.LoadObjectFromJSON(this.SettingsPath)
        if(!IsObject(this.Settings))
        {
            this.SetDefaultSettings()
            writeSettings := true
        }
        if (this.CheckMissingOrExtraSettings())
            writeSettings := true
        if(writeSettings)
            g_SF.WriteObjectToJSON(this.SettingsPath, this.Settings)
        GuiControl, ICScriptHub:, StatsCompactTimestamps, % this.Settings["CompactTS"]
        GuiControl, ICScriptHub:, StatsToggleScientific, % this.Settings["Scientific"]
        this.CompactTimestamps := this.Settings["CompactTS"]
        this.DisplayScientific := this.Settings["Scientific"]
        Gui, Submit, NoHide
    }
    
    SaveSettings()
    {
        Global
        Gui, Submit, NoHide
        this.CheckMissingOrExtraSettings()
        
        GuiControlGet,StatsCompactTimestamps, ICScriptHub:, StatsCompactTimestamps
        GuiControlGet,StatsToggleScientific, ICScriptHub:, StatsToggleScientific
        this.Settings["CompactTS"] := StatsCompactTimestamps
        this.Settings["Scientific"] := StatsToggleScientific
        this.CompactTimestamps := StatsCompactTimestamps
        this.DisplayScientific := StatsToggleScientific
        
        g_SF.WriteObjectToJSON(this.SettingsPath, this.Settings)
        Gui, Submit, NoHide
        this.UpdateStartLoopStatsGUI()
    }
    
    SetDefaultSettings()
    {
        this.Settings := {}
        for k,v in this.DefaultSettings
            this.Settings[k] := v
    }
    
    CheckMissingOrExtraSettings()
    {
        local madeEdit := false
        for k,v in this.DefaultSettings
        {
            if (this.Settings[k] == "") {
                this.Settings[k] := v
                madeEdit := true
            }
        }
        for k,v in this.Settings
        {
            if (!this.DefaultSettings.HasKey(k)) {
                this.Settings.Delete(k)
                madeEdit := true
            }
        }
        return madeEdit
    }
}

;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include %A_LineFile%\..\classMemory.ahk
#include %A_LineFile%\..\IC_IdleGameManager_Class.ahk
#include %A_LineFile%\..\IC_GameSettings_Class.ahk
#include %A_LineFile%\..\IC_EngineSettings_Class.ahk
#include %A_LineFile%\..\IC_CrusadersGameDataSet_Class.ahk
#include %A_LineFile%\..\IC_DialogManager_Class.ahk
#include %A_LineFile%\..\IC_ActiveEffectKeyHandler_Class.ahk

;Check if you have installed the class correctly.
if (_ClassMemory.__Class != "_ClassMemory")
{
    msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
    ExitApp
}

class IC_MemoryFunctions_Class
{
    
    ;Memory Structures
    GameManager := ""
    GameSettings := ""
    EngineSettings := ""
    CrusadersGameDataSet := ""
    Is64Bit := false

    __new()
    {
        this.GameManager := new IC_GameManager32_Class
        this.GameSettings := new IC_GameSettings32_Class
        this.EngineSettings := new IC_EngineSettings32_Class
        this.CrusadersGameDataSet := new IC_CrusadersGameDataSet32_Class
        this.DialogManager := new IC_DialogManager32_Class
        this.ActiveEffectKeyHandler := new IC_ActiveEffectKeyHandler_Class
    }

    ;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
    GetVersion()
    {
        return "v1.10.2, 2022-04-16, IC v0.415.1-v0.430+"
    }

    ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
    ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
    ;Also, if the target process is running as admin, then the script will also require admin rights!
    ;Automatically selects offsets used depending on if process is 64bit or not (epic or steam)
    OpenProcessReader()
    {
        this.GameManager.Refresh()
        if(!this.Is64Bit and this.GameManager.is64Bit())
        {
            this.GameManager := new IC_GameManager64_Class
            this.GameSettings := new IC_GameSettings64_Class
            this.EngineSettings := new IC_EngineSettings64_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSet64_Class
            this.DialogManager := new IC_DialogManager64_Class
            this.Is64Bit := true
        }
        else if (this.Is64Bit and !this.GameManager.is64Bit())
        {
            this.GameManager := new IC_GameManager32_Class
            this.GameSettings := new IC_GameSettings32_Class
            this.EngineSettings := new IC_EngineSettings32_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSet32_Class
            this.DialogManager := new IC_DialogManager32_Class
            this.Is64Bit := false
        }
        else
        {
            this.GameSettings.Refresh()
            this.EngineSettings.Refresh()
            this.CrusadersGameDataSet.Refresh()
            this.DialogManager.Refresh()
        }
        this.ActiveEffectKeyHandler.Refresh()
    }

    ;=====================
    ;General Purpose Calls
    ;=====================

    ; Not for general use.
    GenericGetValue(GameObject)
    {
        if(GameObject.ValueType == "UTF-16") ; take offsets of string and add offset to "value" of string based on 64/32bit
        {
            offsets := GameObject.FullOffsets.Clone()
            offsets.Push(this.Is64Bit ? 0x14 : 0xC)
            var := this.GameManager.Main.readstring(GameObject.baseAddress, bytes := 0, GameObject.ValueType, offsets*)
        }
        else if (GameObject.ValueType == "List" or GameObject.ValueType == "Dict" or GameObject.ValueType == "HashSet") ; custom ValueTypes not in classMemory.ahk
        {
            var := this.GameManager.Main.read(GameObject.baseAddress, "Int", (GameObject.GetOffsets())*)
        }
        else if (GameObject.ValueType == "Quad") ; custom ValueTypes not in classMemory.ahk
        {
            offsets := GameObject.GetOffsets()
            first8 := this.GameManager.Main.read(GameObject.baseAddress, "Int64", (offsets)*)
            lastIndex := offsets.Count()
            offsets[lastIndex] := offsets[lastIndex] + 0x8
            second8 := this.GameManager.Main.read(GameObject.baseAddress, "Int64", (offsets)*)
            var := this.ConvQuadToString3( first8, second8 )
        }
        else
        {
            var := this.GameManager.Main.read(GameObject.baseAddress, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        ; val := ArrFnc.GetHexFormattedArrayString(GameObject.FullOffsets)
        return var
    }

    ;=========================================
    ;General Game Values
    ;=========================================
    ; The following Read___ functions are shorthand for GenericGetValue(GameObjectStructure). 
    ; They are not necessary but they do increase readability of code and increase ease of use.

    ReadGameVersion()
    {
        if(this.GenericGetValue(this.GameSettings.VersionPostFix)  != "")
            return this.GenericGetValue(this.GameSettings.MobileClientVersion) . this.GenericGetValue(this.GameSettings.VersionPostFix) 
        else
            return this.GenericGetValue(this.GameSettings.MobileClientVersion)  
    }

    ReadBaseGameVersion()
    {
        return this.GenericGetValue(this.GameSettings.MobileClientVersion)  
    }

    ReadGameStarted()
    {
        return this.GenericGetValue(this.GameManager.game.gameStarted)
    }

    ReadMonstersSpawned()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.area.basicMonstersSpawnedThisArea.GetGameObjectFromListValues(0))
    }

    ReadActiveMonstersCount()
    {
         return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.area.activeMonsters.size.GetGameObjectFromListValues(0))
    }

    ReadResetting()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ResetHandler.Resetting.GetGameObjectFromListValues(0))
    }

    ReadTimeScaleMultiplier()
    {
        return this.GenericGetValue(this.GameManager.TimeScale)
    }

    ReadTimeScaleMultiplierByIndex(index := 0)
    {
        offset := Mod(index,2) ? 10
        if (this.Is64Bit)
            timeScaleObject := New GameObjectStructure(this.GameManager.game.gameInstances.timeScales.Multipliers.GetGameObjectFromListValues(0,0), "Float", [0x20 + 0x10 + (index * 0x18)]) ; 20 start, values at 50,68,3C..etc
        else
            timeScaleObject := New GameObjectStructure(this.GameManager.game.gameInstances.TimeScales.Multipliers.GetGameObjectFromListValues(0,0), "Float", [0x10 + 0xC + (index * 0x10)]) ; 10 start, values at 1C,2C,3C..etc
        return Round(this.GenericGetValue(timeScaleObject), 2)
    }

    ;this read will only return a valid key if it is reading from TimeScaleWhenNotAttackedHandler object
    ;TODO: Rewrite for new auto offsets system or this can break.
    ReadTimeScaleMultipliersKeyByIndex(index := 0)
    {
        if (this.Is64Bit)
           key := New GameObjectStructure(this.GameManager.game.gameInstances.timeScales.Multipliers.GetGameObjectFromListValues(0,0),, [0x20 + 0x8 + (index * 0x18), 0x28, 0x10, 0x10, 0x18, 0x10]) ; 20 start -> handler, effectKey, parentEffectKeyHandler, parent, source, ID
        else
            key := New GameObjectStructure(this.GameManager.game.gameInstances.timeScales.Multipliers.GetGameObjectFromListValues(0,0),, [0x10 + 0x8 + (index * 0x10), 0x14, 0x8, 0x8, 0xC, 0x8]) ; 10 start, values at 18,28,38..etc to get to handler, effectKey, parentEffectKeyHandler, parent, source, ID
        return this.GenericGetValue(key)
    }

    ReadTimeScaleMultipliersCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.TimeScales.Multipliers.size.GetGameObjectFromListValues(0,0))
    }

    ReadUncappedTimeScaleMultiplier()
    {
        multiplierTotal := 1
        i := 0
        loop, % this.ReadTimeScaleMultipliersCount()
        {
            value := this.ReadTimeScaleMultiplierByIndex(i)
            multiplierTotal *= Max(1.0, value)
            i++
        }
        return multiplierTotal
    }

    ReadTransitioning()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.areaTransitioner.IsTransitioning_k__BackingField.GetGameObjectFromListValues(0))
    }

    ReadTransitionDelay()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.areaTransitioner.ScreenWipeEffect.DelayTimer.T.GetGameObjectFromListValues(0))
    }

    ; 0 = right, 1 = left, 2 = static (instant)
    ReadTransitionDirection()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.areaTransitioner.transitionDirection.GetGameObjectFromListValues(0))
    }

    ; 0 = OnFromLeft, 1 = OnFromRight, 2 = OffToLeft, 3 = OffToRight
    ReadFormationTransitionDir()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.transitionDir.GetGameObjectFromListValues(0))
    }

    ReadSecondsSinceAreaStart()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.area.SecondsSinceStarted.GetGameObjectFromListValues(0))
    }

    ReadAreaActive()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.area.Active.GetGameObjectFromListValues(0))
    }

    ReadUserIsInited()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.inited.GetGameObjectFromListValues(0))
    }

    ;=================
    ;Screen Resolution
    ;=================

    ReadScreenWidth()
    {
        return this.GenericGetValue(this.GameManager.game.screenController.activeScreen.currentScreenWidth)
    }

    ReadScreenHeight()
    {
        return this.GenericGetValue(this.GameManager.game.screenController.activeScreen.currentScreenHeight)
    }

    ;=========================================================
    ;herohandler - champion related information accessed by ID
    ;=========================================================

    ReadChampHealthByID(ChampID := 0 )
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.health.GetGameObjectFromListValues(0, ChampID - 1))
    }

    ReadChampSlotByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.slotId.GetGameObjectFromListValues(0, ChampID - 1))
    }

    ReadChampBenchedByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.Benched.GetGameObjectFromListValues(0, ChampID - 1))
    }

    ; TODO: Depricate older unused versions
    ReadChampLvlByID(ChampID:= 0)
    {
        val := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.level.GetGameObjectFromListValues(0, ChampID - 1))
        if !val
            val := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.Level_k__BackingField.GetGameObjectFromListValues(0, ChampID - 1))
        if !val
            val := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes._level.GetGameObjectFromListValues(0, ChampID - 1))
        return val
    }

    ReadChampSeatByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.def.SeatID.GetGameObjectFromListValues(0, ChampID - 1))
    }

    ReadChampNameByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.def.name.GetGameObjectFromListValues(0, ChampID - 1))
    }

    ;=============================
    ;ServerCall Related - userid, hash, etc.
    ;=============================

    ReadUserID()
    {
        return this.GenericGetValue(this.GameSettings.UserID)
    }

    ReadUserHash()
    {
        return this.GenericGetValue(this.GameSettings.Hash)
    }

    ReadInstanceID()
    {
        return this.GenericGetValue(this.GameSettings._instance.instanceID)
    }

    ReadWebRoot()
    {
        return this.GenericGetValue(this.Enginesettings.WebRoot) 
    }

    ReadPlatform()
    {
        return this.GenericGetValue(this.GameSettings.Platform) 
    }

    ReadGameLocation()
    {
        return this.GameManager.Main.GetModuleFileNameEx()
    }

    GetWebRequestLogLocation()
    {
        gameLoc := this.ReadGameLocation()
        splitStringArray := StrSplit(gameLoc, "\")
        newString := ""
        i := 1
        size := splitStringArray.Count() - 1
        loop, %size%
        {
            newString := newString . splitStringArray[i] . "\"
            i++
        }
        newString := newString . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
        return newString
    }
    
    
    ;==================================================
    ;userData - gems, red rubies, SB/Haste stacks, etc.
    ;==================================================

    ReadGems()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.redRubies.GetGameObjectFromListValues(0))
    }

    ReadGemsSpent()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.redRubiesSpent.GetGameObjectFromListValues(0))
    }

    ReadRedGems() ; BlackViper Red Gems
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.StatHandler.BlackViperTotalGems.GetGameObjectFromListValues(0)) 
    }

    ReadSBStacks()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.StatHandler.BrivSteelbonesStacks.GetGameObjectFromListValues(0))
    }

    ReadHasteStacks()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.StatHandler.BrivSprintStacks.GetGameObjectFromListValues(0))
    }

    ;======================================================================================
    ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
    ;======================================================================================

    ReadCurrentObjID()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ActiveCampaignData.currentObjective.ID.GetGameObjectFromListValues(0))
    }

    ReadQuestRemaining()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ActiveCampaignData.currentArea.QuestRemaining.GetGameObjectFromListValues(0))
    }

    ReadCurrentZone()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ActiveCampaignData.currentAreaID.GetGameObjectFromListValues(0))
    }

    ReadHighestZone()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ActiveCampaignData.highestAvailableAreaID.GetGameObjectFromListValues(0))
    }

    ;======================================================================================
    ;Gold Related functions.
    ;======================================================================================
    
    ;reads the first 8 bytes of the quad value of gold
    ReadGoldFirst8Bytes()
    {
        newObject := this.GameManager.game.gameInstances.ActiveCampaignData.gold.QuickClone()
        newObject.ValueType := "Int64"
        return this.GenericGetValue(newObject.GetGameObjectFromListValues(0))
    }

    ;reads the last 8 bytes of the quad value of gold
    ReadGoldSecond8Bytes()
    {
        newObject := this.GameManager.game.gameInstances.ActiveCampaignData.gold.QuickClone()
        newObject.ValueType := "Int64"
        goldOffsetIndex := newObject.FullOffsets.Count()
        newObject.FullOffsets[goldOffsetIndex] := newObject.FullOffsets[goldOffsetIndex] + 0x8
        return this.GenericGetValue(newObject.GetGameObjectFromListValues(0))
    }

    ReadGoldString()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ActiveCampaignData.gold.GetGameObjectFromListValues(0))
    }

    ;===================================
    ;Formation save related memory reads
    ;===================================
    ;read the number of saved formations for the active campaign
    ReadFormationSavesSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.size.GetGameObjectFromListValues(0))
    }

    ;reads if a formation save is a favorite
    ;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
    ReadFormationFavoriteIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.Favorite.GetGameObjectFromListValues(0, slot))
    }

    ReadFormationNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.Name.GetGameObjectFromListValues(0, slot)) 
    }

    ; Reads the SaveID for the FormationSaves index passed in.
    ReadFormationSaveIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.SaveID.GetGameObjectFromListValues(0, slot))
    }

    ; Reads the FormationCampaignID for the FormationSaves index passed in.
    ReadFormationCampaignID()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.FormationCampaignID.GetGameObjectFromListValues(0))
    }

    ;=========================================================================
    ;Formation related memory reads (not save, but the in adventure formation)
    ;=========================================================================
    
    ReadNumAttackingMonstersReached()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.numAttackingMonstersReached.GetGameObjectFromListValues(0))
    }

    ReadNumRangedAttackingMonsters()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.numRangedAttackingMonsters.GetGameObjectFromListValues(0))
    }

    ReadChampIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.slots.hero.def.ID.GetGameObjectFromListValues(0, slot))
    }

    ReadHeroAliveBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.slots.heroAlive.GetGameObjectFromListValues(0, slot))
    }

    ; should read 1 if briv jump animation override is loaded to , 0 otherwise
    ReadTransitionOverrideSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.TransitionOverrides.ActionListSize.GetGameObjectFromListValues(0))
    }

    ;==============================
    ;offlineprogress and modronsave
    ;==============================

    ReadActiveGameInstance()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ActiveUserGameInstance.GetGameObjectFromListValues(0))
    }

    GetCoreTargetAreaByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.size.GetGameObjectFromListValues(0))
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        loop, %saveSize%
        {
            if (this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.InstanceID.GetGameObjectFromListValues(0, i)) == InstanceID)
            {
                return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.targetArea.GetGameObjectFromListValues(0, i))
            }
            ++i
        }
        return -1
    }

    GetCoreXPByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.size.GetGameObjectFromListValues(0))
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        loop, %saveSize%
        {
            if (this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.InstanceID.GetGameObjectFromListValues(0, i)) == InstanceID)
            {
                return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.ExpTotal.GetGameObjectFromListValues(0, i))
            }
            ++i
        }
        return -1
    }  

    ;=================
    ; New
    ;=================
    ReadOfflineTime()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.OfflineProgressHandler.inGameNumSecondsToProcess.GetGameObjectFromListValues(0))
    }

    ReadOfflineDone()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.OfflineProgressHandler.finishedOfflineProgressType.GetGameObjectFromListValues(0))
    }

    ReadResetsCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.ResetsSinceLastManual.GetGameObjectFromListValues(0))
    }

    ;=================
    ;UI
    ;=================

    ReadAutoProgressToggled()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButton.toggled.GetGameObjectFromListValues(0))
    }

    ;reads the champ id associated with an ultimate button
    ReadUltimateButtonChampIDByItem(item := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Screen.uiController.ultimatesBar.ultimateItems.hero.def.ID.GetGameObjectFromListValues(0, item))
    }

    ReadUltimateButtonListSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Screen.uiController.ultimatesBar.ultimateItems.size.GetGameObjectFromListValues(0))
    }

    ;======================
    ; Retrieving Formations
    ;======================
    /*
        read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot
        when parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array
    */
    GetFormationSaveBySlot(slot := 0, ignoreEmptySlots := 0 )
    {
        Formation := Array()
        _size := this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.Formation.size.GetGameObjectFromListValues(0, slot))
        loop, %_size%
        {
            heroLoc := this.GameManager.Is64Bit() ? ((A_Index - 1) / 2) : (A_Index - 1) ; -1 for 1->0 indexing conversion
            champID := this.GenericGetValue(this.GameManager.game.gameInstances.FormationSaveHandler.formationSavesV2.Formation.GetGameObjectFromListValues(0, slot, heroLoc))
            if (!ignoreEmptySlots or champID != -1)
            {
                Formation.Push( champID )
            }
        }
        return Formation
    }

    /*
        A function that looks for a saved formation matching a favorite. Returns -1 on failure.
        Optional Paramater Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)

        Requires #include classMemory.ahk and OpenProcessReader() is called each time client is restarted
    */
    GetSavedFormationSlotByFavorite(favorite := 1)
    {
        ;reads memory for the number of saved formations
        formationSavesSize := this.ReadFormationSavesSize() ;+ 1
        ;cycle through saved formations to find save slot of Favorite
        formationSaveSlot := -1
        i := 0
        loop, %formationSavesSize%
        {
            if (this.ReadFormationFavoriteIDBySlot(i) == favorite)
            {
                formationSaveSlot := i
                Break
            }
            ++i
        }
        return formationSaveSlot ; formationSaveSlot is ID which starts at 1,  index starts at 0, so we subtract 1
    }

    ;Returns the formation stored at the favorite value passed in.
    GetFormationByFavorite( favorite := 0 )
    {
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        return Formation
    }

    ; Returns an array containing the current formation. Note: Slots with no hero are converted from 0 to -1 to match other formation saves.
    GetCurrentFormation()
    {
        formation := Array()
        size := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.slots.size.GetGameObjectFromListValues(0))
        if(!size)
            return ""
        loop, %size%
        {
            heroID := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.formation.slots.hero.def.ID.GetGameObjectFromListValues(0, A_index - 1))
            heroID := heroID > 0 ? heroID : -1
            formation.Push(heroID)
        }
        return formation
    }

    ReadBoughtLastUpgrade( seat := 1)
    {
        ; The nextUpgrade pointer could be null if no upgrades are found.
        if(this.GenericGetValue(this.GameManager.game.gameInstances.Screen.uiController.bottomBar.heroPanel.activeBoxes.nextupgrade.GetGameObjectFromListValues(0, seat - 1)))
        {
            val := this.GenericGetValue(this.GameManager.game.gameInstances.Screen.uiController.bottomBar.heroPanel.activeBoxes.nextupgrade.IsPurchased.GetGameObjectFromListValues(0, seat - 1))
            return val
        }
        else
        {
            return True
        }
    }

    GetHeroOrderedUpgrade(champID := 1, upgradeID := 0)
    {
        orderedUpgrade := this.GameManager.Game.gameInstances.Controller.userData.HeroHandler.heroes.allUpgradesOrdered.GetFullGameObjectFromListOrDictValues("List", 0, champID)
        orderedUpgrade := orderedUpgrade.GetFullGameObjectFromListOrDictValues("Dict", 0)
        orderedUpgrade := orderedUpgrade.List.GetFullGameObjectFromListOrDictValues("List", upgradeID)
        return orderedUpgrade
    }

    ; Returns the formation array of the formation used in the currently active modron.
    GetActiveModronFormation()
    {
        formation := ""
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc. )
        formationCampaignID := this.ReadFormationCampaignID()
        ; Find the SaveID associated to the Campaign ID 
        formationSaveID := this.GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
        ; Find the  index (slot) of the formation with the correct SaveID
        ;formationSaveID := 132
        formationSavesSize := this.ReadFormationSavesSize()
        formationSaveSlot := -1
        loop, %formationSavesSize%
        {
            if (this.ReadFormationSaveIDBySlot(A_Index - 1) == formationSaveID)
            {
                formationSaveSlot := A_Index - 1
                Break
            }
        }
        ; Get the formation using the  index (slot)
        if(formationSaveSlot >= 0)
            formation := this.GetFormationSaveBySlot(formationSaveSlot)
        return formation
    }

    ; Uses FormationCampaignID to search the modron for the SaveID of the formation the active modron is using.
    GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
    {
        ; note: current best interpretation of a <int,int> dictionary.
        formationSaveSlot := ""
        ; Find which modron core is being used
        modronSavesSlot := this.GetCurrentModronSaveSlot()
        ; Find SaveID for given formationCampaignID
        modronFormationsSavesSize := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.FormationSaves.size.GetGameObjectFromListValues(0, modronSavesSlot))
        loop, %modronFormationsSavesSize%
        {
            ; 64 bit starts values at offset 0x20, 32 bit at 0x10
            testIndex := this.Is64Bit ? (0x20 + (A_index - 1) * 0x10) : (0x10 + (A_Index - 1) * 0x10)
            testValueObject := new GameObjectStructure(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.FormationSaves.GetGameObjectFromListValues(0, modronSavesSlot),,[testIndex])
            testValue := this.GenericGetValue(testValueObject)
            if (testValue == formationCampaignID)
            {
                testIndex := testIndex + 0xC ; same for 64/32 bit
                testValueObject := new GameObjectStructure(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.FormationSaves.GetGameObjectFromListValues(0, modronSavesSlot),,[testIndex])
                formationSaveSlot := this.GenericGetValue(testValueObject)
                break
            }
        }
        return formationSaveSlot
    }

    ; Finds the index of the current modron in ModronHandlers
    GetCurrentModronSaveSlot()
    {
        modronSavesSlot := ""
        activeGameInstance := this.ReadActiveGameInstance()
        moronSavesSize := this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.size.GetGameObjectFromListValues(0))
        loop, %moronSavesSize%
        {
            if (this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ModronHandler.modronSaves.InstanceID.GetGameObjectFromListValues(0, A_Index - 1)) == activeGameInstance)
            {
                modronSavesSlot := A_Index - 1
                return (A_Index - 1)
            }
        }
    }

    ;======================
    ; Inventory...
    ;======================
    GetInventoryBuffAmountByID(buffID)
    {
        size := this.ReadInventoryItemsCount()
        if(!size)
            return ""
        ; After adding gameInstances list value, remove gameInstances ListIndex and increment ListIndexes values following it
        testObject := this.GameManager.game.gameInstances.Controller.userData.BuffHandler.inventoryBuffs.ID.GetGameObjectFromListValues(0)
        testObject := this.AdjustObjectListIndexes(testObject)
        ; Find the buff
        index := this.BinarySearchList(testObject, 1, size, buffID)
        if (index >= 0)
            return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.inventoryBuffs.InventoryAmount.GetGameObjectFromListValues(0, index - 1))
        else
            return ""
    }

    GetInventoryBuffNameByID(buffID)
    {
        size := this.ReadInventoryItemsCount()
        if(!size)
            return ""
        testObject := this.GameManager.game.gameInstances.Controller.userData.BuffHandler.inventoryBuffs.ID.GetGameObjectFromListValues(0)
        testObject := this.AdjustObjectListIndexes(testObject)
        ; Find the buff
        index := this.BinarySearchList(testObject, 1, size, buffID)
        if (index >= 0)
            return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.inventoryBuffs.Name.GetGameObjectFromListValues(0, index - 1))
        else
            return ""
    }

    ReadInventoryBuffIDBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.InventoryBuffs.ID.GetGameObjectFromListValues(0, index - 1))
    }

    ReadInventoryBuffNameBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.InventoryBuffs.Name.GetGameObjectFromListValues(0, index - 1))
    }

    ReadInventoryBuffCountBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.InventoryBuffs.InventoryAmount.GetGameObjectFromListValues(0, index - 1))
    }

    ReadInventoryItemsCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.BuffHandler.InventoryBuffs.size.GetGameObjectFromListValues(0))
    }

    /* Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer.
    */
    ; TODO: Update GetChestCount with BinarySearch
    GetChestCountByID(chestID)
    {
        size := this.ReadInventoryChestListSize()
        if(!size)
            return "" 
        loop, %size%
        {
            currentChestID := this.GetInventoryChestIDBySlot(A_Index)
            if(currentChestID == chestID)
            {
                return this.GetInventoryChestCountBySlot(A_Index)
            }
        }
        return "" 
    }

    GetInventoryChestIDBySlot(slot)
    {
            ; Not using 64 bit , but need +0x10 offset for where  starts
            testIndex := this.Is64Bit ? 0x20 + ((slot-1) * 0x10) : 0x10 + ((slot-1) * 0x10)
            ; Add gameInstances[0] index to list
            testObject := this.GameManager.game.gameInstances.Controller.userData.ChestHandler.chestCounts.GetGameObjectFromListValues(0)
            this.AdjustObjectListIndexes(testObject)
            ; Calculate chestID index offset and add it to object's offsets
            testObject.FullOffsets.Push(testIndex)
            ; return Chest ID
            return this.GenericGetValue(testObject)
    }

    GetInventoryChestCountBySlot(slot)
    {
            ; Calculate offset 
            ; Addresses are 64 bit but the dictionary entry offsets are 4 bytes instead of 8.
            ; Calculate count index offset and add it
            testIndex := this.Is64Bit ? 0x2C + ((slot-1) * 0x10) : 0x1C + ((slot-1) * 0x10)
            testObject := this.GameManager.game.gameInstances.Controller.userData.ChestHandler.chestCounts.GetGameObjectFromListValues(0)
            this.AdjustObjectListIndexes(testObject) 
            testObject.FullOffsets.Push(testIndex)
            ; return Chest Count
            return this.GenericGetValue(testObject)
    }

    ReadInventoryChestListSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances.Controller.userData.ChestHandler.chestCounts.size.GetGameObjectFromListValues(0))
    }

    GetChestNameByID(chestID)
    {
        size := this.ReadChestDefinesSize()   
        if(!size)
            return "" 
        index := this.BinarySearchList(this.CrusadersGameDataSet.ChestTypeDefines.ID, 1, size, chestID)
        if (index >= 0)
            return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines.NamePlural.GetGameObjectFromListValues(index - 1))
        else
            return ""
    }

    GetChestNameBySlot(index)
    { 
        return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines.Name.GetGameObjectFromListValues(index - 1))
    }

    GetChestIDBySlot(index)
    {
        return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines.ID.GetGameObjectFromListValues(index - 1))
    }

    ReadChestDefinesSize()
    {
        return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines.size) 
    }



    ;===================
    ;Currency Conversion
    ;===================

    ReadDialogsListSize()
    {
        return this.GenericGetValue(this.DialogManager.dialogs.size)
    }

    ReadConversionCurrencyBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.dialogs.currentCurrency.ID.GetGameObjectFromListValues(slot))
    }

    ReadDialogNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.dialogs.sprite.gameObjectName.GetGameObjectFromListValues(slot))
    }

    ReadForceConvertFavorBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.dialogs.forceConvertFavor.GetGameObjectFromListValues(slot))
    }

    GetBlessingsDialogSlot()
    {
        size := this.ReadDialogsListSize()
        loop, %size%
        {
            name := this.GenericGetValue(this.DialogManager.dialogs.sprite.gameObjectName.GetGameObjectFromListValues(A_Index - 1))
            if (name == "BlessingsStoreDialog")
                return (A_Index - 1)
        }
        return ""
    }

    GetBlessingsCurrency()
    {
        return this.ReadConversionCurrencyBySlot(this.GetBlessingsDialogSlot())
    }

    GetForceConvertFavor()
    {
        ; slot := this.GetBlessingsDialogSlot()
        ; value := this.ReadForceConvertFavorBySlot(slot)
        return this.ReadForceConvertFavorBySlot(this.GetBlessingsDialogSlot())
    }

    ReadPatronID()
    {
        if (this.GenericGetValue(this.GameManager.game.gameInstances.PatronHandler.ActivePatron_k__BackingField.GetGameObjectFromListValues(0)))
            return  this.GenericGetValue(this.GameManager.game.gameInstances.PatronHandler.ActivePatron_k__BackingField.ID.GetGameObjectFromListValues(0))
        return 0
    }

    ;==============
    ;Helper Methods
    ;==============

    ; Converts 16 byte Quad value into a string representation.
    ConvQuadToString3( FirstEight, SecondEight )
    {
        f := log( FirstEight + ( 2.0 ** 63 ) )
        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + f

        significand := round( 10 ** ( decimated - floor( decimated ) ), 2 )
        exponent := floor( decimated )
        if(exponent < 4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""
        return significand . "e" . exponent
    }

    BinarySearchList(gameObject, leftIndex, rightIndex, searchValue)
    {
        if(rightIndex < leftIndex)
        {
            return -1
        }
        else
        {
            middle := Ceil(leftIndex + ((rightIndex-leftIndex) / 2))
            IDValue := this.GenericGetValue(gameObject.GetGameObjectFromListValues(middle - 1))
            ; failed memory read
            if(IDValue == "")
                return -1
            ; if value found, return index
            else if (IDValue == searchValue)
                return middle
            ; else if value larger that middle value, check larger half
            else if (IDValue > searchValue)
                return this.BinarySearchList(gameObject, leftIndex, middle-1, searchValue)
            ; else if value smaller than middle value, check smaller half
            else
                return this.BinarySearchList(gameObject, middle+1, rightIndex, searchValue)
        }
    }

    ; Removes the first ListIndex value and increments the rest by adjustmentValue 
    AdjustObjectListIndexes(gameObject, adjustmentValue := 1)
    {
        gameObject.ListIndexes.RemoveAt(1)
        listIndexesSize := gameObject.ListIndexes.Count()
        i := 1
        loop, %listIndexesSize%
        {
            gameObject.ListIndexes[i] += adjustmentValue
            i++
        }
        return gameObject
    }

    #include *i IC_MemoryFunctions_Extended.ahk
}
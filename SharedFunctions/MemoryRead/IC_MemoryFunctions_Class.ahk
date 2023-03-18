;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include %A_LineFile%\..\..\json.ahk
#include %A_LineFile%\..\classMemory.ahk
#include %A_LineFile%\..\IC_IdleGameManager_Class.ahk
#include %A_LineFile%\..\IC_GameSettings_Class.ahk
#include %A_LineFile%\..\IC_EngineSettings_Class.ahk
#include %A_LineFile%\..\IC_CrusadersGameDataSet_Class.ahk
#include %A_LineFile%\..\IC_DialogManager_Class.ahk
#include %A_LineFile%\..\IC_ActiveEffectKeyHandler_Class.ahk
#include *i %A_LineFile%\..\Imports\IC_GameVersion32_Import.ahk
#include *i %A_LineFile%\..\Imports\IC_GameVersion64_Import.ahk

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
    DialogManager := ""
    Is64Bit := false
    ; Active GameInstance is 0 in the DLL so this should not need to change
    ;		public ChampionsGameInstance GetActiveChampionsInstance()
    ;   	{
    ;   		return this.gameInstances[0];
    ;   	}
    GameInstance := 0
    PointerVersionString := ""

    __new(fileLoc := "CurrentPointers.json")
    {
        FileRead, oData, %fileLoc%
        if(oData == "")
        {
            MsgBox, Pointer data not found. Closing IC Script Hub and starting IC_VersionPicker. Please select the version and platform closest to your current version and restart IC Script Hub.
            versionPickerLoc := A_LineFile . "\..\..\IC_VersionPicker.ahk"
            Run, %versionPickerLoc%
            ExitApp
        }
        currentPointers := JSON.parse( oData )
        this.PointerVersionString := currentPointers.Version . (currentPointers.Platform ? (" (" currentPointers.Platform  . ") ") : "")
        this.GameManager := new IC_IdleGameManager_Class(currentPointers.IdleGameManager.moduleAddress, currentPointers.IdleGameManager.moduleOffset)
        this.GameSettings := new IC_GameSettings_Class(currentPointers.GameSettings.moduleAddress, currentPointers.GameSettings.staticOffset, currentPointers.GameSettings.moduleOffset)
        this.EngineSettings := new IC_EngineSettings_Class(currentPointers.EngineSettings.moduleAddress, currentPointers.EngineSettings.staticOffset, currentPointers.EngineSettings.moduleOffset)
        this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class(currentPointers.CrusadersGameDataSet.moduleAddress, currentPointers.CrusadersGameDataSet.moduleOffset)
        this.DialogManager := new IC_DialogManager_Class(currentPointers.DialogManager.moduleAddress, currentPointers.DialogManager.moduleOffset)
        this.ActiveEffectKeyHandler := new IC_ActiveEffectKeyHandler_Class
    }

    ;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
    GetVersion()
    {
        return "v1.10.8, 2023-2-27, IC v0.463+"
    }

    GetPointersVersion()
    {
        return this.PointerVersionString
    }

    ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
    ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
    ;Also, if the target process is running as admin, then the script will also require admin rights!
    ;Automatically selects offsets used depending on if process is 64bit or not (epic or steam)
    OpenProcessReader()
    {
        this.GameManager.Refresh()
        this.GameSettings.Refresh()
        this.EngineSettings.Refresh()
        this.CrusadersGameDataSet.Refresh()
        this.DialogManager.Refresh()
        ;this.ActiveEffectKeyHandler.Refresh()
        this.Is64Bit := this.GameManager.is64Bit()
    }

    ;=====================
    ;General Purpose Calls
    ;=====================

    ; Not for general use.
    GenericGetValue(GameObject)
    {
        val := ArrFnc.GetHexFormattedArrayString(GameObject.FullOffsets)
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
        return var
    }

;     ;=========================================
;     ;General Game Values
;     ;=========================================
;     ; The following Read___ functions are shorthand for GenericGetValue(GameObjectStructure). 
;     ; They are not necessary but they do increase readability of code and increase ease of use.

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
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.area.basicMonstersSpawnedThisArea)
    }

    ReadActiveMonstersCount()
    {
         return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.area.activeMonsters.size)
    }

    ReadResetting()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ResetHandler.Resetting)
    }

    ReadTimeScaleMultiplier()
    {
        return this.GenericGetValue(this.GameManager.TimeScale)
    }

    ; TODO: Find more automated method of dictionary lookups for non-standard dictionary types?
    ReadTimeScaleMultiplierByIndex(index := 0)
    {
        ; Note: collections with different object types can have different entry offsets. (e.g. list of ints would be offset 0x4, not 0x8 like a list of objects)
        ; dictionary <IEffectSource, Int> / <System.Collections.Generic.Dictionary<CrusadersGame.Effects.IEffectSource, System.Single>
        if (this.Is64Bit)
            timeScaleObject := New GameObjectStructure(this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers, "Float", [0x18, 0x20 + 0x10 + (index * 0x18)]) ; 20 start, values at 50,68,3C..etc
        else
            timeScaleObject := New GameObjectStructure(this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers, "Float", [0xC, 0x10 + 0xC + (index * 0x10)]) ; 10 start, values at 1C,2C,3C..etc
        return Round(this.GenericGetValue(timeScaleObject), 2)
    }

    ReadTimeScaleMultipliersCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers.size)
    }

    ReadUncappedTimeScaleMultiplier()
    {
        multiplierTotal := 1
        i := 0
        size := this.ReadTimeScaleMultipliersCount()
        loop, %size%
        {
            value := this.ReadTimeScaleMultiplierByIndex(i)
            multiplierTotal *= Max(1.0, value)
            i++
        }
        return multiplierTotal
    }

    ReadTransitioning()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.IsTransitioning_k__BackingField)
    }

    ReadTransitionDelay()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.ScreenWipeEffect.DelayTimer.T)
    }

    ; 0 = right, 1 = left, 2 = static (instant)
    ReadTransitionDirection()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.transitionDirection)
    }

    ; 0 = OnFromLeft, 1 = OnFromRight, 2 = OffToLeft, 3 = OffToRight
    ReadFormationTransitionDir()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.transitionDir)
    }

    ReadSecondsSinceAreaStart()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.area.SecondsSinceStarted)
    }

    ReadAreaActive()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.area.Active)
    }

    ReadUserIsInited()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.inited)
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
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].health)
    }

    ReadChampSlotByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].slotId)
    }

    ReadChampBenchedByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].Benched)
    }

    ReadChampLvlByID(ChampID:= 0)
    {
        val := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].level)
        if !val
            val := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].Level_k__BackingField)
        if !val
            val := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)]._level)
        return val
    }

    ReadChampSeatByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].def.SeatID)
    }

    ReadChampNameByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].def.name)
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
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.redRubies)
    }

    ReadGemsSpent()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.redRubiesSpent)
    }

    ReadRedGems() ; BlackViper Red Gems
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BlackViperTotalGems) 
    }

    ReadSBStacks()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BrivSteelbonesStacks)
    }

    ReadHasteStacks()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BrivSprintStacks)
    }

    ;======================================================================================
    ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
    ;======================================================================================

    ReadCurrentObjID()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentObjective.ID)
    }

    ReadQuestRemaining()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentArea.QuestRemaining)
    }

    ReadCurrentZone()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentAreaID)
    }

    ReadHighestZone()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.highestAvailableAreaID)
    }

    ;======================================================================================
    ;Gold Related functions.
    ;======================================================================================
    
    ;reads the first 8 bytes of the quad value of gold
    ReadGoldFirst8Bytes()
    {
        newObject := this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold.QuickClone()
        newObject.ValueType := "Int64"
        return this.GenericGetValue(newObject)
    }

    ;reads the last 8 bytes of the quad value of gold
    ReadGoldSecond8Bytes()
    {
        newObject := this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold.QuickClone()
        newObject.ValueType := "Int64"
        goldOffsetIndex := newObject.FullOffsets.Count()
        newObject.FullOffsets[goldOffsetIndex] := newObject.FullOffsets[goldOffsetIndex] + 0x8
        return this.GenericGetValue(newObject)
    }

    ReadGoldString()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold)
    }

    ;===================================
    ;Formation save related memory reads
    ;===================================
    ;read the number of saved formations for the active campaign
    ReadFormationSavesSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2.size)
    }

    ;reads if a formation save is a favorite
    ;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
    ReadFormationFavoriteIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Favorite)
    }

    ReadFormationNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Name) 
    }

    ; Reads the SaveID for the FormationSaves index passed in.
    ReadFormationSaveIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].SaveID)
    }

    ; Reads the FormationCampaignID for the FormationSaves index passed in.
    ReadFormationCampaignID()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.FormationCampaignID)
    }

    ;=========================================================================
    ;Formation related memory reads (not save, but the in adventure formation)
    ;=========================================================================
    
    ReadNumAttackingMonstersReached()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.numAttackingMonstersReached)
    }

    ReadNumRangedAttackingMonsters()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.numRangedAttackingMonsters)
    }

    ReadChampIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots[slot].hero.def.ID)
    }

    ReadHeroAliveBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots[slot].heroAlive)
    }

    ; should read 1 if briv jump animation override is loaded to , 0 otherwise
    ReadTransitionOverrideSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.TransitionOverrides.ActionListSize)
    }

    ; TODO: FIX
    ; Will return the spec ID for the hero if it's in the modron formation and has the spec. Otherwise returns "".
    GetCoreSpecializationForHero(heroID)
    {
        formationSaveSlot := this.GetActiveModronFormationSaveSlot()
        tempSizeObject := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSaveSlot].Specializations.size
        dictCount := g_SF.Memory.GenericGetValue(tempSizeObject)
        i := 0
        loop, % dictCount
        {
            tempObject := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSaveSlot].Specializations
            currKeyOffset := tempObject.CalculateDictOffset(["key", i])
            currValOffset := tempObject.CalculateDictOffset(["value", i])
            tempObject.ValueType := "Int"
            currentHeroID := this.GenericGetValue(tempObject)
            if (currentHeroID == heroID)
            {
                specObject := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSaveSlot].Specializations.List[specNum]
                insertLoc := specObject.FullOffsets.Length() - 1
                specObject.FullOffsets.InsertAt(insertLoc, currValOffset + 0)
                specVal := this.GenericGetValue(specObject)
                return this.GenericGetValue(specObject)
            }
            ++i
        }
        return ""
    }
    

    ;==============================
    ;offlineprogress and modronsave
    ;==============================

    ReadActiveGameInstance()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ActiveUserGameInstance)
    }

;     GetCoreTargetAreaByInstance(InstanceID := 1)
;     {
;         ;reads memory for the number of cores        
;         saveSize := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size)
;         ;cycle through saved formations to find save slot of Favorite
;         i := 0
;         loop, %saveSize%
;         {
;             if (this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.InstanceID.GetGameObjectFromListValues(this.GameInstance, i)) == InstanceID)
;             {
;                 return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.targetArea.GetGameObjectFromListValues(this.GameInstance, i))
;             }
;             ++i
;         }
;         return -1
;     }

;     GetCoreXPByInstance(InstanceID := 1)
;     {
;         ;reads memory for the number of cores        
;         saveSize := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size)
;         ;cycle through saved formations to find save slot of Favorite
;         i := 0
;         loop, %saveSize%
;         {
;             if (this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.InstanceID.GetGameObjectFromListValues(this.GameInstance, i)) == InstanceID)
;             {
;                 return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.ExpTotal.GetGameObjectFromListValues(this.GameInstance, i))
;             }
;             ++i
;         }
;         return -1
;     }  

    ;=================
    ; New
    ;=================
    ReadOfflineTime()
    {
        ; OfflineTimeRequested is populated right during initialization of the handler. OfflineTimeSimulated is not populated until the simulation is complete.
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.OfflineTimeRequested_k__BackingField)
    }

    ReadOfflineDone()
    {
        handlerState := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.CurrentState_k__BackingField)
        stopReason := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.CurrentStopReason_k__BackingField)
        return handlerState == 0 AND stopReason != "" ; handlerstate is "inactive" and stopReason is not null
    }

    ReadResetsCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].ResetsSinceLastManual)
    }

    ;=================
    ;UI
    ;=================

    ReadAutoProgressToggled()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButton.toggled)
    }

    ;reads the champ id associated with an ultimate button
    ReadUltimateButtonChampIDByItem(item := 0)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.ultimatesBar.ultimateItems[item].hero.def.ID)
    }

    ReadUltimateButtonListSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.ultimatesBar.ultimateItems.size)
    }

    ReadWelcomeBackActive()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.notificationManager.notificationDisplay.welcomeBackNotification.Active)
    }

;     ;======================
;     ; Retrieving Formations
;     ;======================
;     /*
;         read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot
;         when parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array
;     */
;     GetFormationSaveBySlot(slot := 0, ignoreEmptySlots := 0 )
;     {
;         Formation := Array()
;         _size := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Formation.size)
;         loop, %_size%
;         {
;             heroLoc := this.GameManager.Is64Bit() ? ((A_Index - 1) / 2) : (A_Index - 1) ; -1 for 1->0 indexing conversion
;             champID := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Formation.GetGameObjectFromListValues(this.GameInstance, slot, heroLoc))
;             if (!ignoreEmptySlots or champID != -1)
;             {
;                 Formation.Push( champID )
;             }
;         }
;         return Formation
;     }

;     /*
;         A function that looks for a saved formation matching a favorite. Returns -1 on failure.
;         Optional Paramater Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)

;         Requires #include classMemory.ahk and OpenProcessReader() is called each time client is restarted
;     */
;     GetSavedFormationSlotByFavorite(favorite := 1)
;     {
;         ;reads memory for the number of saved formations
;         formationSavesSize := this.ReadFormationSavesSize() ;+ 1
;         ;cycle through saved formations to find save slot of Favorite
;         formationSaveSlot := -1
;         i := 0
;         loop, %formationSavesSize%
;         {
;             if (this.ReadFormationFavoriteIDBySlot(i) == favorite)
;             {
;                 formationSaveSlot := i
;                 Break
;             }
;             ++i
;         }
;         return formationSaveSlot ; formationSaveSlot is ID which starts at 1,  index starts at 0, so we subtract 1
;     }

;     ;Returns the formation stored at the favorite value passed in.
;     GetFormationByFavorite( favorite := 0 )
;     {
;         slot := this.GetSavedFormationSlotByFavorite(favorite)
;         formation := this.GetFormationSaveBySlot(slot)
;         return Formation
;     }

;     ; Returns an array containing the current formation. Note: Slots with no hero are converted from 0 to -1 to match other formation saves.
;     GetCurrentFormation()
;     {
;         formation := Array()
;         size := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots.size)
;         if(!size)
;             return ""
;         loop, %size%
;         {
;             heroID := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots.hero.def.ID.GetGameObjectFromListValues(this.GameInstance, A_index - 1))
;             heroID := heroID > 0 ? heroID : -1
;             formation.Push(heroID)
;         }
;         return formation
;     }

;     ReadBoughtLastUpgrade( seat := 1)
;     {
;         ; The nextUpgrade pointer could be null if no upgrades are found.
;         if(this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes.nextupgrade.GetGameObjectFromListValues(this.GameInstance, seat - 1)))
;         {
;             val := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes.nextupgrade.IsPurchased.GetGameObjectFromListValues(this.GameInstance, seat - 1))
;             return val
;         }
;         else
;         {
;             return True
;         }
;     }

;     GetHeroOrderedUpgrade(champID := 1, upgradeID := 0)
;     {
;         orderedUpgrade := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].allUpgradesOrdered.GetFullGameObjectFromListOrDictValues("List", 0, champID)
;         orderedUpgrade := orderedUpgrade.GetFullGameObjectFromListOrDictValues("Dict", 0)
;         orderedUpgrade := orderedUpgrade.List.GetFullGameObjectFromListOrDictValues("List", upgradeID)
;         return orderedUpgrade
;     }

;     ; Returns the formation array of the formation used in the currently active modron.
;     GetActiveModronFormation()
;     {
;         formation := ""
;         formationSaveSlot := this.GetActiveModronFormationSaveSlot()
;         ; Get the formation using the  index (slot)
;         if(formationSaveSlot >= 0)
;             formation := this.GetFormationSaveBySlot(formationSaveSlot)
;         return formation
;     }

    ; TODO: FIX
    GetActiveModronFormationSaveSlot()
    {
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
        return formationSaveSlot
    }

    ; TODO: FIX
    ; Uses FormationCampaignID to search the modron for the SaveID of the formation the active modron is using.
    GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
    {
        ; ; note: current best interpretation of a <int,int> dictionary.
        ; formationSaveSlot := ""
        ; ; Find which modron core is being used
        modronSavesSlot := this.GetCurrentModronSaveSlot()
        ; ; Find SaveID for given formationCampaignID
        ; modronFormationsSavesSize := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves.size)
        ; loop, %modronFormationsSavesSize%
        ; {
        ;     ; 64 bit starts values at offset 0x20, 32 bit at 0x10
        ;     ; testIndex := this.Is64Bit ? (0x20 + (A_index - 1) * 0x10) : (0x10 + (A_Index - 1) * 0x10)
        ;     testValueObject := new GameObjectStructure(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves,,[testIndex])
        ;     testValue := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves[formationCampaignID])
        ;     if (testValue == formationCampaignID)
        ;     {
        ;         testIndex := testIndex + 0xC ; same for 64/32 bit
        ;         testValueObject := new GameObjectStructure(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves,,[testIndex])
        ;         formationSaveSlot := this.GenericGetValue(testValueObject)
        ;         break
        ;     }
        ; }
        ; return formationSaveSlot
        value := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves[formationCampaignID])
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves[formationCampaignID])
    }

;     ; Finds the Modron Reset area for the current instance's core.
;     GetModronResetArea()
;     {
;         return this.GetCoreTargetAreaByInstance(this.ReadActiveGameInstance())
;     }

    ; TODO: FIX
    ; Finds the index of the current modron in ModronHandlers
    GetCurrentModronSaveSlot()
    {
        modronSavesSlot := ""
        activeGameInstance := this.ReadActiveGameInstance()
        moronSavesSize := this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size)
        loop, %moronSavesSize%
        {
            if (this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID) == activeGameInstance)
            {
                modronSavesSlot := A_Index - 1
                return (A_Index - 1)
            }
        }
    }

;     ;======================
;     ; Inventory...
;     ;======================
;     GetInventoryBuffAmountByID(buffID)
;     {
;         size := this.ReadInventoryItemsCount()
;         if(!size)
;             return ""
;         ; After adding gameInstances list value, remove gameInstances ListIndex and increment ListIndexes values following it
;         testObject := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs.ID
;         testObject := this.AdjustObjectListIndexes(testObject)
;         ; Find the buff
;         index := this.BinarySearchList(testObject, 1, size, buffID)
;         if (index >= 0)
;             return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs.InventoryAmount.GetGameObjectFromListValues(this.GameInstance, index - 1))
;         else
;             return ""
;     }

;     GetInventoryBuffNameByID(buffID)
;     {
;         size := this.ReadInventoryItemsCount()
;         if(!size)
;             return ""
;         testObject := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs.ID
;         testObject := this.AdjustObjectListIndexes(testObject)
;         ; Find the buff
;         index := this.BinarySearchList(testObject, 1, size, buffID)
;         if (index >= 0)
;             return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs.Name)
;         else
;             return ""
;     }

    ReadInventoryBuffIDBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].ID)
    }

    ReadInventoryBuffNameBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].Name)
    }

    ReadInventoryBuffCountBySlot(index)
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].InventoryAmount)
    }

    ReadInventoryItemsCount()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.InventoryBuffs.size)
    }

;     /* Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer.
;     */
;     GetChestCountByID(chestID)
;     {
;         size := this.ReadInventoryChestListSize()
;         if(!size)
;             return "" 
;         loop, %size%
;         {
;             currentChestID := this.GetInventoryChestIDBySlot(A_Index)
;             if(currentChestID == chestID)
;             {
;                 return this.GetInventoryChestCountBySlot(A_Index)
;             }
;         }
;         return "" 
;     }

;     GetInventoryChestIDBySlot(slot)
;     {
;             ; Not using 64 bit , but need +0x10 offset for where  starts
;             testIndex := this.Is64Bit ? 0x20 + ((slot-1) * 0x10) : 0x10 + ((slot-1) * 0x10)
;             ; Add gameInstances[0] index to list
;             testObject := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts
;             this.AdjustObjectListIndexes(testObject)
;             ; Calculate chestID index offset and add it to object's offsets
;             testObject.FullOffsets.Push(testIndex)
;             ; return Chest ID
;             return this.GenericGetValue(testObject)
;     }

;     GetInventoryChestCountBySlot(slot)
;     {
;             ; Calculate offset 
;             ; Addresses are 64 bit but the dictionary entry offsets are 4 bytes instead of 8.
;             ; Calculate count index offset and add it
;             testIndex := this.Is64Bit ? 0x2C + ((slot-1) * 0x10) : 0x1C + ((slot-1) * 0x10)
;             testObject := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts
;             this.AdjustObjectListIndexes(testObject) 
;             testObject.FullOffsets.Push(testIndex)
;             ; return Chest Count
;             return this.GenericGetValue(testObject)
;     }

    ReadInventoryChestListSize()
    {
        return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts.size)
    }

    GetChestNameByID(chestID)
    {
        size := this.ReadChestDefinesSize()   
        if(!size)
            return "" 
        index := this.BinarySearchList(this.CrusadersGameDataSet.ChestTypeDefines, ["ID"], 1, size, chestID)
        if (index >= 0)
            return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines[index - 1].NamePlural)
        else
            return ""
    }

    GetChestNameBySlot(index)
    { 
        return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines[index - 1].Name)
    }

    GetChestIDBySlot(index)
    {
        return this.GenericGetValue(this.CrusadersGameDataSet.ChestTypeDefines[index - 1].ID)
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
        return this.GenericGetValue(this.DialogManager.dialogs[slot].currentCurrency.ID)
    }

    ReadDialogNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.dialogs[slot].sprite.gameObjectName)
    }

    ReadForceConvertFavorBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.dialogs[slot].forceConvertFavor)
    }

    GetBlessingsDialogSlot()
    {
        size := this.ReadDialogsListSize()
        loop, %size%
        {
            name := this.GenericGetValue(this.DialogManager.dialogs[A_Index - 1].sprite.gameObjectName)
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
        if (this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].PatronHandler.ActivePatron_k__BackingField))
            return this.GenericGetValue(this.GameManager.game.gameInstances[this.GameInstance].PatronHandler.ActivePatron_k__BackingField.ID)
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

    BinarySearchList(gameListObject, lookupKeys, leftIndex, rightIndex, searchValue)
    {
        if(rightIndex < leftIndex)
        {
            return -1
        }
        else
        {
            middle := Ceil(leftIndex + ((rightIndex-leftIndex) / 2))
            newGameObject := gameListObject[middle - 1]
            for k,v in lookupKeys
            {
                newGameObject := newGameObject[v]
            }
            IDValue := this.GenericGetValue(newGameObject)
            ; failed memory read
            if(IDValue == "")
                return -1
            ; if value found, return index
            else if (IDValue == searchValue)
                return middle
            ; else if value larger that middle value, check larger half
            else if (IDValue > searchValue)
                return this.BinarySearchList(gameListObject, lookupKeys, leftIndex, middle-1, searchValue)
            ; else if value smaller than middle value, check smaller half
            else
                return this.BinarySearchList(gameListObject, lookupKeys, middle+1, rightIndex, searchValue)
        }
    }

    ; Returns the index of HeroHandler the champion is expected to be at. As of v472 hero defines became missing in the defines so champID can no longer be used as an index.
    GetHeroHandlerIndexByChampID(champID)
    {
        if(champID < 107)
            return champID - 1
        return champID - 2
    }

    #include *i IC_MemoryFunctions_Extended.ahk
}
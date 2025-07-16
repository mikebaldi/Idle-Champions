;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include %A_LineFile%\..\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\..\SharedFunctions\MemoryRead\SH__MemoryManager.ahk
#include %A_LineFile%\..\..\..\..\SharedFunctions\MemoryRead\SH_MemoryPointer.ahk
#include %A_LineFile%\..\..\..\..\SharedFunctions\MemoryRead\SH_StaticMemoryPointer.ahk
#include %A_LineFile%\..\IC_IdleGameManager_Class.ahk
#include %A_LineFile%\..\IC_GameSettings_Class.ahk
#include %A_LineFile%\..\IC_EngineSettings_Class.ahk
#include %A_LineFile%\..\IC_CrusadersGameDataSet_Class.ahk
#include %A_LineFile%\..\IC_DialogManager_Class.ahk
#include %A_LineFile%\..\IC_UserStatHandler_Class.ahk
#include %A_LineFile%\..\IC_UserData_Class.ahk
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
    ; Active GameInstance is 0 in the DLL so GameInstance should not need to change.
    GameInstance := 0
    PointerVersionString := ""
    ChestIndexByID := {} ; Map of ID/Chests for faster lookups

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
        versionArray := StrSplit(currentPointers.Version, ".")
        if(versionArray.Count() > 1)
            currentPointers.Version := Round(currentPointers.Version, 1)
        this.PointerVersionString := currentPointers.Version . (currentPointers.Platform ? (" (" currentPointers.Platform  . ") ") : "")
        _MemoryManager.exeName := g_UserSettings[ "ExeName" ]
        _MemoryManager.Refresh()
        this.GameManager := new IC_IdleGameManager_Class(currentPointers.IdleGameManager.moduleAddress, currentPointers.IdleGameManager.moduleOffset)
        this.GameSettings := new IC_GameSettings_Class(currentPointers.GameSettings.moduleAddress, currentPointers.GameSettings.staticOffset, currentPointers.GameSettings.moduleOffset)
        this.EngineSettings := new IC_EngineSettings_Class(currentPointers.EngineSettings.moduleAddress, currentPointers.EngineSettings.staticOffset, currentPointers.EngineSettings.moduleOffset)
        this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class(currentPointers.CrusadersGameDataSet.moduleAddress, currentPointers.CrusadersGameDataSet.moduleOffset)
        this.DialogManager := new IC_DialogManager_Class(currentPointers.DialogManager.moduleAddress, currentPointers.DialogManager.moduleOffset)
        this.UserStatHandler := new IC_UserStatHandler_Class(currentPointers.UserStatHandler.moduleAddress, currentPointers.UserStatHandler.staticOffset, currentPointers.UserStatHandler.moduleOffset)
        this.UserData := new IC_UserData_Class(currentPointers.UserData.moduleAddress, currentPointers.UserData.staticOffset, currentPointers.UserData.moduleOffset)
        this.ActiveEffectKeyHandler := new IC_ActiveEffectKeyHandler_Class(this)
    }

    ;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
    GetVersion()
    {
        return "v2.4.9, 2025-07-16"
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
        global g_UserSettings
        _MemoryManager.exeName := g_UserSettings[ "ExeName" ]
        _MemoryManager.Refresh()
        if(_MemoryManager.handle == "")
            MsgBox, , , Could not read from exe. Try running as Admin. , 7
        this.Is64Bit := _MemoryManager.is64Bit
        this.GameManager.Refresh()
        this.GameSettings.Refresh()
        this.EngineSettings.Refresh()
        this.CrusadersGameDataSet.Refresh()
        this.DialogManager.Refresh()
        this.UserStatHandler.Refresh()
        this.UserData.Refresh()
        this.ActiveEffectKeyHandler.Refresh()
    }

    ;=====================
    ;General Purpose Calls
    ;=====================

    ; Not for general use.
    GenericGetValue(GameObject)
    {
        baseAddress := GameObject.BasePtr == "" ? GameObject.BaseAddress : GameObject.BasePtr.BaseAddress
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        ; val := ArrFnc.GetHexFormattedArrayString(GameObject.FullOffsets)
        if(GameObject.ValueType == "UTF-16") ; take offsets of string and add offset to "value" of string based on 64/32bit
        {
            offsets := GameObject.FullOffsets.Clone()
            offsets.Push(this.Is64Bit ? 0x14 : 0xC)
            var := _MemoryManager.instance.readstring(baseAddress, bytes := 0, GameObject.ValueType, offsets*)
        }
        else if (GameObject.ValueType == "List" or GameObject.ValueType == "Dict" or GameObject.ValueType == "HashSet") ; custom ValueTypes not in classMemory.ahk
        {
            var := _MemoryManager.instance.read(baseAddress, "Int", (GameObject.GetOffsets())*)
        }
        else if (GameObject.ValueType == "Quad") ; custom ValueTypes not in classMemory.ahk
        {
            offsets := GameObject.GetOffsets()
            first8 := _MemoryManager.instance.read(baseAddress, "Int64", (offsets)*)
            lastIndex := offsets.Count()
            offsets[lastIndex] := offsets[lastIndex] + 0x8
            second8 := _MemoryManager.instance.read(baseAddress, "Int64", (offsets)*)
            var := GameObject.ConvQuadToString3( first8, second8 )
        }
        else
        {
            var := _MemoryManager.instance.read(baseAddress, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        return var
    }

    ; Finds the dictionary index "bonus_modron_exp_mult" is found (if it is found)
    GetXPBlessingSlot()
    {

        effectsSize := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ResetUpgradeHandler.activeEffectsByInstance.size.read()
        if (effectsSize < 0 OR effectsSize > 200)
            return ""
        loop, %effectsSize%
        {
            value := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ResetUpgradeHandler.activeEffectsByInstance["value", A_Index - 1].Dictionary["value", 0].def.BaseEffectKeyParams_k__BackingField.OriginalEffectKey.read()
            if (value == "bonus_modron_exp_mult")
                return (A_Index - 1)
        }
        return ""
    }

    ;=========================================
    ;General Game Values
    ;=========================================
    ; The following Read functions are shorthand for GenericGetValue(GameObjectStructure) or GameObjectStructure.Read().
    ; Please use them where possible to reduce chances of code breaking when Script Hub is updated.
    ; They also help increase readability of code and ease of use.

    ReadGameVersion()
    {
        if (this.GameSettings.VersionPostFix.Read() != "")
            return this.GameSettings.MobileClientVersion.Read() . this.GameSettings.VersionPostFix.Read() 
        else
            return this.GameSettings.MobileClientVersion.Read()
    }

    ReadBaseGameVersion()
    {
        return this.GameSettings.MobileClientVersion.Read()
    }

    ReadGameStarted()
    {
        return this.GameManager.game.gameStarted.Read()
    }

    ReadMonstersSpawned()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.area.basicMonstersSpawnedThisArea.Read()
    }

    ReadActiveMonstersCount()
    {
         return this.GameManager.game.gameInstances[this.GameInstance].Controller.area.activeMonsters.size.Read()
    }

    ReadResetting()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ResetHandler.Resetting.Read()
    }

    ReadTimeScaleMultiplier()
    {
        return this.GameManager.TimeScale.Read()
    }

    ReadTimeScaleMultiplierByIndex(index := 0)
    {
        ; Note: collections with different object types can have different entry offsets. (e.g. list of ints would be offset 0x4, not 0x8 like a list of objects)
        ; dictionary <IEffectSource, Float> / <System.Collections.Generic.Dictionary<CrusadersGame.Effects.IEffectSource, System.Single>
        return Round(this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers["value", index].read("Float"), 2)
    }

    ReadTimeScaleMultiplierKeyNameByIndex(index := 0)
    {
        ; Note: collections with different object types can have different entry offsets. (e.g. list of ints would be offset 0x4, not 0x8 like a list of objects)
        timeScaleIEffectName := this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers["key", index].QuickClone()
        timeScaleIEffectName.FullOffsets.Push(0x20) ; Push .Name offset for BuffDef. Will not get a name for all IEffect types.
        return timeScaleIEffectName.Read("UTF-16")
    }

    ReadTimeScaleMultipliersCount()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].timeScales[0].Multipliers.size.Read()
    }

    ReadUncappedTimeScaleMultiplier()
    {
        multiplierTotal := 1
        i := 0
        size := this.ReadTimeScaleMultipliersCount()
        if(size <= 0 OR size > 100) ; sanity check, should be a positive integer and less than 10's. (Potions, 12 possible champions + feats, modron nodes)
            return ""
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
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.IsTransitioning_k__BackingField.Read()
    }

    ReadTransitionDelay()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.ScreenWipeEffect.DelayTimer.T.Read()
    }

    ; 0 = right, 1 = left, 2 = static (instant)
    ReadTransitionDirection()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.areaTransitioner.transitionDirection.Read()
    }

    ; 0 = OnFromLeft, 1 = OnFromRight, 2 = OffToLeft, 3 = OffToRight
    ReadFormationTransitionDir()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.transitionDir.Read()
    }

    ReadSecondsSinceAreaStart()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.area.SecondsSinceStarted.Read()
    }

    ReadAreaActive()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.area.Active.Read()
    }

    ReadUserIsInited()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.inited.Read()
    }

    ;=================
    ;Screen Resolution
    ;=================

    ReadScreenWidth()
    {
        return this.GameManager.game.screenController.activeScreen.currentScreenWidth.Read()
    }

    ReadScreenHeight()
    {
        return this.GameManager.game.screenController.activeScreen.currentScreenHeight.Read()
    }

    ;=========================================================
    ;herohandler - champion related information accessed by ID
    ;=========================================================

    ReadChampListSize()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes.size.Read()
    }

    ReadChampHealthByID(ChampID := 0 )
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].health.Read()
    }

    ReadChampIDByIndex(ChampListIndex := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[ChampListIndex].def.ID.Read()
    }

    ReadChampSlotByID(ChampID := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].slotId.Read()
    }

    ReadChampBenchedByID(ChampID := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].Benched.Read()
    }

    ReadChampLvlByID(ChampID:= 0)
    {
        val := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].level.Read()
        if !val
            val := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].Level_k__BackingField.Read()
        if !val
            val := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)]._level.Read()
        return val
    }

    ReadChampSeatByID(ChampID := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].def.SeatID.Read()
    }

    ReadChampNameByID(ChampID := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].def.name.Read()
    }

    ;=============================
    ;ServerCall Related - userid, hash, etc.
    ;=============================

    ReadUserID()
    {
        return this.GameSettings.UserID.Read()
    }

    ReadUserHash()
    {
        return this.GameSettings.Hash.Read()
    }

    ReadInstanceID()
    {
        return this.GameSettings._instance.instanceID.Read()
    }

    ReadWebRoot()
    {
        return this.Enginesettings.WebRoot.Read() 
    }

    ReadPlatform()
    {
        return this.GameSettings.Platform.Read() 
    }

    ReadGameLocation()
    {
        return _MemoryManager.instance.GetModuleFileNameEx()
    }

    GetWebRequestLogLocation()
    {
        gameLoc := this.ReadGameLocation()
        splitStringArray := StrSplit(gameLoc, "\")
        newString := ""
        size := splitStringArray.Count() - 1
        if(size <= 0 OR size > 100) ; sanity check for number directory path folders
            return ""
        loop, %size%
        {
            newString := newString . splitStringArray[A_Index] . "\"
        }
        newString := newString . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
        return newString
    }
    
    
    ;==================================================
    ;userData - gems, red rubies, SB/Haste stacks, etc.
    ;==================================================

    ReadGems()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.redRubies.Read()
    }

    ReadGemsSpent()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.redRubiesSpent.Read()
    }

    ReadRedGems() 
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BlackViperTotalGems.Read() 
    }

    ReadSBStacks()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BrivSteelbonesStacks.Read()
    }

    ReadHasteStacks()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.StatHandler.BrivSprintStacks.Read()
    }

    ;======================================================================================
    ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
    ;======================================================================================

    ReadCurrentObjID()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentObjective.ID.Read()
    }

    ReadQuestRemaining()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentArea.QuestRemaining.Read()
    }

    ReadCurrentZone()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.currentAreaID.Read()
    }

    ReadHighestZone()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.highestAvailableAreaID.Read()
    }

    ;======================================================================================
    ;Gold Related functions.
    ;======================================================================================
    
    ;reads the first 8 bytes of the quad value of gold
    ReadGoldFirst8Bytes()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold.Read("Int64")
     }

    ;reads the last 8 bytes of the quad value of gold
    ReadGoldSecond8Bytes()
    {
        newObject := this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold.QuickClone()
        goldOffsetIndex := newObject.FullOffsets.Count()
        newObject.FullOffsets[goldOffsetIndex] := newObject.FullOffsets[goldOffsetIndex] + 0x8
        return newObject.Read("Int64")
    }

    ReadGoldString()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ActiveCampaignData.gold.Read()
    }

    ;===================================
    ;Formation save related memory reads
    ;===================================
    ;read the number of saved formations for the active campaign
    ReadFormationSavesSize()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2.size.Read()
    }

    ;reads if a formation save is a favorite
    ;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
    ReadFormationFavoriteIDBySlot(slot := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Favorite.Read()
    }

    ReadFormationNameBySlot(slot := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Name.Read() 
    }

    ; Reads the SaveID for the FormationSaves index passed in.
    ReadFormationSaveIDBySlot(slot := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].SaveID.Read()
    }

    GetFormationFieldFamiliarsBySlot( slot := 0)
    {
        size := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Familiars["Clicks"].List.size.Read()
        if(size <= 0 OR size > 10) ; sanity check, should be < 6 but set to 10 in case of future game field familiar increase.
            return ""
        familiarList := {}
        Loop, %size%
        {
            value := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Familiars["Clicks"].List[A_Index - 1].Read()
            familiarList.Push(value)
        }
        return familiarList
    }

    GetFormationFamiliarsByFavorite(favorite := 1)
    {
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationFieldFamiliarsBySlot(slot)
        return formation
    }

    ; Reads the FormationCampaignID for the FormationSaves index passed in.
    ReadFormationCampaignID()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.FormationCampaignID.Read()
    }

    ;=========================================================================
    ;Formation related memory reads (not save, but the in adventure formation)
    ;=========================================================================
    
    ReadNumAttackingMonstersReached()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.numAttackingMonstersReached.Read()
    }

    ReadNumRangedAttackingMonsters()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.numRangedAttackingMonsters.Read()
    }

    ReadChampIDBySlot(slot := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots[slot].hero.def.ID.Read()
    }

    ReadHeroAliveBySlot(slot := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots[slot].heroAlive.Read()
    }

    ; TransitionOverrides + [0x18, 0x30, 0x18] | TransitionOverrides[0] + [0x18] 
    ; TransitionOverrides["value", 0].size | TransitionOverrides.entries.value0.size
    ; should read 1 if briv jump animation override is loaded to , 0 otherwise
    ReadTransitionOverrideSize()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.TransitionOverrides["value",0].List.size.Read()
    }

    ; Will return the spec ID for the hero if it's in the modron formation and has the spec. Otherwise returns "".
    GetCoreSpecializationForHero(heroID, specNum := 1)
    {
        formationSaveSlot := this.GetActiveModronFormationSaveSlot()
        return this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSaveSlot].Specializations[heroID].List[specNum - 1].Read()
    }

    ;==============================
    ;offlineprogress and modronsave
    ;==============================

    ReadActiveGameInstance()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ActiveUserGameInstance.Read()
    }

    GetCoreTargetAreaByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size.Read()
        if(saveSize <= 0 OR saveSize > 50000) ; sanity check, should be a positive integer and less than 2005 as that is max allowed area as of 2023-09-03
            return ""
        ;cycle through saved formations to find save slot of Favorite
        loop, %saveSize%
        {
            if (this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID.Read() == InstanceID)
            {
                return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].targetArea.Read()
            }
        }
        return -1
    }

    GetCoreXPByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size.Read()
        if(saveSize <= 0 OR saveSize > 20) ; sanity check, should be less than 4 as of 2023-09-03
            return ""
        ;cycle through saved formations to find save slot of Favorite
        loop, %saveSize%
        {
            if (this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID.Read() == InstanceID)
            {
                return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].ExpTotal.Read()
            }
        }
        return -1
    }  

    ; Returns json of grid used for saving modron layout.
    ; Expecting modronSave from this location: this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[x]
    ; The int value for x is also acceptable.
    ReadModronGridArray(modronSave)
    {
        if (modronSave is number)
            modronSave := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSave]
        gridSave := modronSave.GridSave.QuickClone()
        gridHeight := gridSave.size.Read()
        gridJSON := "["
        loop, %gridHeight%
        {
            x := A_Index - 1
            if (x > 0)
                gridJSON .= ","
            gridJSON .= "["
            gridWidth := gridSave[x].size.Read()
            if !gridHeight
                gridHeight := 16
            loop, %gridWidth%
            {
                y := A_Index - 1
                if (y > 0)
                    gridJSON .= ","
                currRead := gridSave[x][y,,,0x4].Read("UInt")
                gridJSON .= currRead
                if(currRead != 0)
                    currRead = 1
            }
            gridJSON .= "]"
        }
        gridJSON .= "]"
        ; OutputDebug, % gridJSON
        return gridJSON
    }
    ;=================
    ; New
    ;=================
    ; OfflineTimeRequested is populated right during initialization of the handler. OfflineTimeSimulated is not populated until the simulation is complete.
    ReadOfflineTime()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.OfflineTimeRequested_k__BackingField.Read()
    }

    ReadOfflineDone()
    {
        handlerState := this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.CurrentState_k__BackingField.Read()
        stopReason := this.GameManager.game.gameInstances[this.GameInstance].OfflineHandler.CurrentStopReason_k__BackingField.Read()
        return handlerState == 0 AND stopReason != "" ; handlerstate is "inactive" and stopReason is not null
    }

    ReadResetsCount()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].ResetsSinceLastManual.Read()
    }

    ;=================
    ;UI
    ;=================

    ReadAutoProgressToggled()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButton.toggled.Read()
    }

    ;reads the champ id associated with an ultimate button
    ReadUltimateButtonChampIDByItem(item := 0)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.ultimatesBar.ultimateItems[item].hero.def.ID.Read()
    }

    ReadUltimateButtonListSize()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.ultimatesBar.ultimateItems.size.Read()
    }

    ReadUltimateCooldownByItem(item := 0)
    {
        return g_SF.Memory.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.ultimatesBar.ultimateItems[item].ultimateAttack.internalCooldownTimer.Read()
    }

    ReadWelcomeBackActive()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.notificationManager.notificationDisplay.welcomeBackNotification.Active.Read()
    }

    ;======================
    ; Retrieving Formations
    ;======================
    ; Read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot. When parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array. 
    GetFormationSaveBySlot(slot := 0, ignoreEmptySlots := 0 )
    {
        Formation := Array()
        _size := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Formation.size.Read()
        if(_size <= 0 OR _size > 500) ; sanity check, should be less than 51 as of 2023-09-03
            return ""
        loop, %_size%
        {
            champID := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[slot].Formation[A_Index - 1].Read()
            if (!ignoreEmptySlots or champID != -1)
            {
                Formation.Push( champID )
            }
        }
        return Formation
    }

    ; Looks for a saved formation matching a favorite. Returns -1 on failure. Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)
    GetSavedFormationSlotByFavorite(favorite := 1)
    {
        ;reads memory for the number of saved formations
        formationSavesSize := this.ReadFormationSavesSize()
        if(formationSavesSize <= 0 OR formationSavesSize > 500) ; sanity check, should be less than 51 as of 2023-09-03
            return ""
        ;cycle through saved formations to find save slot of Favorite
        formationSaveSlot := -1
        loop, %formationSavesSize%
        {
            if (this.ReadFormationFavoriteIDBySlot(A_Index - 1) == favorite)
            {
                formationSaveSlot := A_Index - 1
                Break
            }
        }
        return formationSaveSlot
    }

    ;Returns the formation stored at the favorite value passed in.
    GetFormationByFavorite( favorite := 0 )
    {
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        return formation
    }

    ; Returns an array containing the current formation. Note: Slots with no hero are converted from 0 to -1 to match other formation saves.
    GetCurrentFormation()
    {
        size := this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots.size.Read()
        if(size <= 0 OR size > 14) ; sanity check, 12 is the max number of concurrent champions possible.
            return ""
        formation := size > 0 ? Array() : ""
        loop, %size%
        {
            heroID := this.GameManager.game.gameInstances[this.GameInstance].Controller.formation.slots[A_index - 1].hero.def.ID.Read()
            heroID := heroID > 0 ? heroID : -1
            formation.Push(heroID)
        }
        return formation
    }

    ReadBoughtLastUpgrade( seat := 1)
    {
        val := true
        ; The nextUpgrade pointer could be null if no upgrades are found.
        if (this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.heroBoxsBySeat[seat].nextupgrade.Read())
        {
            ;TODO Re-Verify this value
            val := this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.heroBoxsBySeat[seat].nextupgrade.IsPurchased.Read()
        }
        return val
    }

    ;=========================
    ; Champion Specializations
    ;=========================
    ; upgradeID default is 7 for memory read testing. Tests Bruenor's Battle/Shield Master spec.

    ReadHeroUpgradeRequiredLevel(champID := 1, upgradeID := 7)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.upgradesByUpgradeId[upgradeID].RequiredLevel.Read()
    }

    ; Checks for specialization graphic. No graphic means no spec.
    ReadHeroUpgradeIsSpec(champID := 1, upgradeID := 7)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.upgradesByUpgradeId[upgradeID].Def.defaultSpecGraphic.Read() > 0
    }

    ReadHeroUpgradeRequiredUpgradeID(champID := 1, upgradeID := 7)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.upgradesByUpgradeId[upgradeID].Def.RequiredUpgradeID.Read()
    }

    ReadHeroUpgradeID(champID := 1, upgradeID := 7)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.upgradesByUpgradeId[upgradeID].Id.Read()
    }

    ReadHeroUpgradeSpecializationName(champID := 1, upgradeID := 7) ;upgradeID is "slot" ; battle master 
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.upgradesByUpgradeId[upgradeID].Def.SpecializationName.Read()
    }

    ReadHeroUpgradeIsPurchased(champID := 1, upgradeID := 7)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(ChampID)].upgradeHandler.PurchasedUpgrades[upgradeID].Read() != ""
    }

    ReadHeroUpgradesSize(champID := 1)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(champID)].upgradeHandler.upgradesByUpgradeId.size.Read()
    }

    ReadHeroIsOwned(champID := 1)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(champID)].Owned.Read()
    }

    GetHeroNextUpgradeIsPurchased(champID := 1)
    {
        currIndex := -1
        size := this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes.size.Read()
        if size != 12
            return ""
        loop, %size%
        {
            currID := this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[A_Index - 1].hero.def.ID.read()
            if ( currID == champID)
            {
                currIndex := A_Index - 1
                break
            }
        }
        if (currIndex < 0)
            return ""
        return this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[currIndex].nextUpgrade.IsPurchased.Read()
    }

        ReadPurchasedUpgradeID(champID := 1, index := 0) ; Deprecated 
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.GetHeroHandlerIndexByChampID(champID)].upgradeHandler.PurchasedUpgrades.size.Read()
    }

    ;=========================
    ; Champion Loot
    ;=========================

    
    ReadHeroLootID(champID := 58, slot := 4)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].ID.Read()
    }

    ReadHeroLootHeroID(champID := 58, slot := 4)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].HeroID.Read()
    }

    ReadHeroLootName(champID := 58, slot := 4)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].Name.Read()
    }

    ReadHeroLootEnchant(champID := 58, slot := 4)
    {
        ; TODO: Handle multiple methods of reading a Nullable double depending on unity version.
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].Enchant.Read("Double?")
    }

    ReadHeroLootRarityValue(champID := 58, slot := 4)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].rarityValue.Read()
    }

    ReadHeroLootGild(champID := 58, slot := 4)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].gild.Read()
    }

    ReadBrivSlot4ilvl()
    {
        champID := 58, slot := 4
        return Floor(this.GameManager.game.gameInstances[this.GameInstance].Controller.UserData.LootHandler.LootByHeroID[champID].List[slot-1].Enchant.Read("Double?") + 1)
    }

    ; Returns the formation array of the formation used in the currently active modron.
    GetActiveModronFormation()
    {
        formation := ""
        formationSaveSlot := this.GetActiveModronFormationSaveSlot()
        ; Get the formation using the  index (slot)
        if(formationSaveSlot >= 0)
            formation := this.GetFormationSaveBySlot(formationSaveSlot)
        return formation
    }

    GetActiveModronFormationSaveSlot()
    {
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc. )
        formationCampaignID := this.ReadFormationCampaignID()
        ; Find the SaveID associated to the Campaign ID 
        formationSaveID := this.GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
        ; Find the  index (slot) of the formation with the correct SaveID
        ;formationSaveID := 132
        formationSavesSize := this.ReadFormationSavesSize()
        if(formationSavesSize <= 0 OR formationSavesSize > 500) ; sanity check, should be < 51 saves per map.
            return ""
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

    ; Uses FormationCampaignID to search the modron for the SaveID of the formation the active modron is using.
    GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
    {
        ; note: current best interpretation of a <int,int> dictionary.
        formationSaveSlot := ""
        ; Find which modron core is being used
        modronSavesSlot := this.GetCurrentModronSaveSlot()
        ; Find SaveID for given formationCampaignID
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves[formationCampaignID].Read()
    }

    ; Finds the Modron Reset area for the current instance's core.
    GetModronResetArea()
    {
        return this.GetCoreTargetAreaByInstance(this.ReadActiveGameInstance())
    }

    ; Finds the index of the current modron in ModronHandlers
    GetCurrentModronSaveSlot()
    {
        modronSavesSlot := ""
        activeGameInstance := this.ReadActiveGameInstance()
        modronSavesSize := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves.size.Read()
        if(modronSavesSize <= 0 OR modronSavesSize > 20) ; sanity check, should be < 5 as of 2023-09-03
            return ""
        loop, %modronSavesSize%
        {
            if (this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID.Read() == activeGameInstance)
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
        if (size < 0 OR size > 2000)
            return ""
        ; Find the buff
        index := this.BinarySearchList(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs, ["ID"], 1, size, buffID)
        if (index >= 0)
            return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index].InventoryAmount.Read()
        else
            return ""
    }

    GetInventoryBuffNameByID(buffID)
    {
        size := this.ReadInventoryItemsCount()
        if (size < 0 OR size > 2000)
            return ""
        ; Find the buff
        index := this.BinarySearchList(this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs, ["ID"], 1, size, buffID)
        if (index >= 0)
            return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index].Name.Read()
        else
            return ""
    }

    ReadInventoryBuffIDBySlot(index)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].ID.Read()
    }

    ReadInventoryBuffNameBySlot(index)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].Name.Read()
    }

    ReadInventoryBuffCountBySlot(index)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.inventoryBuffs[index - 1].InventoryAmount.Read()
    }

    ReadInventoryItemsCount()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.BuffHandler.InventoryBuffs.size.Read()
    }

    ; Depricated - Use ReadChestCountByID.
    GetChestCountByID(chestID)
    {
        return this.ReadchestCountByID(chestID)
    }

    ; Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer.
    ReadChestCountByID(chestID)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts[chestID].Read()
    }

    ReadInventoryChestIDBySlot(slot)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts["key", slot, quickLookup := True].Read()
    }

    ReadInventoryChestCountBySlot(slot)
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts["value", slot].Read()
    }

    ReadInventoryChestListSize()
    {
        return this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.ChestHandler.chestCounts.size.Read()
    }

    GetChestNameByID(chestID)
    {
        ; IndexList build because:
        ; maxContiguousChestID := 283 ; (ordered and continuous)
        ; maxOrderedChestID := 419 ; then 482 comes before 420
        if(this.CrusadersGameDataSet.ChestTypeDefines[this.ChestIndexByID[chestID]].ID.Read() != chestID)
            this.BuildChestIndexList()
        return this.CrusadersGameDataSet.ChestTypeDefines[this.ChestIndexByID[chestID]].NamePlural.Read()
    }

    GetChestNameBySlot(index)
    { 
        return this.CrusadersGameDataSet.ChestTypeDefines[index - 1].Name.Read()
    }

    GetChestIDBySlot(index)
    {
        return this.CrusadersGameDataSet.ChestTypeDefines[index - 1].ID.Read()
    }

    ReadChestDefinesSize()
    {
        return this.CrusadersGameDataSet.ChestTypeDefines.size.Read() 
    }

    ;===================
    ;Currency Conversion
    ;===================

    ReadDialogsListSize()
    {
        return this.DialogManager.dialogs.size.Read()
    }

    ReadConversionCurrencyBySlot(slot := 0)
    {
        if ( this.ReadDialogNameBySlot(slot) != "BlessingsStoreDialog")
            return ""
        return this.DialogManager.dialogs[slot].currentCurrency.ID.Read()
    }

    ReadDialogNameBySlot(slot := 0)
    {
        return this.DialogManager.dialogs[slot].sprite.gameObjectName.Read()
    }

    ReadForceConvertFavorBySlot(slot := 0)
    {        
        if (this.ReadDialogNameBySlot(slot) != "BlessingsStoreDialog")
            return ""
        return this.DialogManager.dialogs[slot].forceConvertFavor.Read()
    }

    GetBlessingsDialogSlot()
    {
        size := this.ReadDialogsListSize()
        if(size > 50 OR size < 0) ; sanity check
            return ""
        loop, %size%
        {
            name := this.DialogManager.dialogs[A_Index - 1].sprite.gameObjectName.Read()
            if (name == "BlessingsStoreDialog")
                return (A_Index - 1)
        }
        return ""
    }

    ; Checks for noteable dialogs:
    ; this.ReadDialogActiveBySlot(this.GetDialogSlotByName("OfflineProgressDialog"))    ; 
    ; this.ReadDialogActiveBySlot(this.GetDialogSlotByName("DontShowAgainDialog"))      ; Warning message appearing upon game load indicating game was closed before previous offline progress could be completed.
    ; this.ReadDialogActiveBySlot(this.GetDialogSlotByName("MainMenuDialog"))           ; Menu appearing when hitting escape. Good to check before sending escape to close other dialogs.
    ; this.ReadDialogActiveBySlot(this.GetDialogSlotByName("SpecializationDialog"))     ; When a specialization choice dialog appears. Can have multiple occurances across multiple heroes.
    ; this.ReadDialogActiveBySlot(this.GetDialogSlotByName("ModronResetWarningDialog")) ; 
    
    GetDialogSlotByName(dialogName := "LoadingTextBox", occurance := 1)
    {
        if (dialogName == 1)                        ; Allows FullMemoryFunctions to not automatically error.
            dialogName := "LoadingTextBox"
        size := this.ReadDialogsListSize()
        if(size > 50 OR size < 0) ; sanity check in case of bad read.
            return ""
        found := 0
        loop, %size%
        {
            name := this.DialogManager.dialogs[A_Index - 1].sprite.gameObjectName.Read()
            if (name != dialogName)
                continue
            found++
            if (found == occurance)
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
        patronID := this.GameManager.game.gameInstances[this.GameInstance].PatronHandler.ActivePatron_k__BackingField.ID.Read()
        if(patronID < 0 OR patronID > 100) ; Ignore clearly bad memory reads.
            patronID := ""
        return patronID
    }

    ReadDialogActiveBySlot(slot := 0)
    {
        return this.DialogManager.dialogs[slot].Active.Read()
    }

    ;==============
    ;Helper Methods
    ;==============

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
            IDValue := newGameObject.Read()
            ; failed memory read
            if(IDValue == "")
                return -1
            else if (IDValue == searchValue) ; if value found, return index
                return middle
            else if (IDValue > searchValue) ; else if value larger that middle value, check larger half
                return this.BinarySearchList(gameListObject, lookupKeys, leftIndex, middle-1, searchValue)
            else  ; else if value smaller than middle value, check smaller half
                return this.BinarySearchList(gameListObject, lookupKeys, middle+1, rightIndex, searchValue)
        }
    }

    ; Returns the index of HeroHandler the champion is expected to be at. As of v472 hero defines became missing in the defines so champID can no longer be used as an index.
    GetHeroHandlerIndexByChampID(champID)
    {
        if(champID < 107)
            return champID - 1
        ; No define exists for ID 107
        if(champID == 107)
            return ""
        if(champID < 135)
            return champID - 2
        ; No define exists for ID 135            
        if(champID == 135)
            return ""
        if(champID < 137)
            return champID - 3
        ; No define exists for ID 137
        if(champID == 137)
            return ""
        return champID - 4
    }

    ; Builds this.ChestIndexByID from memory values.
    BuildChestIndexList()
    {
        size := this.ReadChestDefinesSize()
        if(size <= 0 OR size > 10000) ; Sanity checks
            return "" 
        loop, %size%
        {
            chestID := this.CrusadersGameDataSet.ChestTypeDefines[A_Index - 1].ID.Read()
            this.ChestIndexByID[chestID] := A_Index - 1
        }
    }

    ; Creates GameObjectSTructure indexes of all chests in chest defines.
    InitializeChestsIndices()
    {
        if(this.CrusadersGameDataSet.ChestTypeDefines.Count() > 500) ; chests already added.
            return
        size := this.ReadChestDefinesSize()
        if(size <= 0 OR size > 10000) ; Sanity checks
            return "" 
        loop, %size%
        {
            this.CrusadersGameDataSet.ChestTypeDefines[A_Index - 1]
        }
    }

    GetImportsVersion()
    {
        version := !_MemoryManager.is64Bit ? ( (g_ImportsGameVersion32 == "" ? " ---- " : (g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32 )) . " (32 bit), " ) : ( (g_ImportsGameVersion64 == "" ? " ---- " : (g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64)) . " (64 bit)")
        return version
    }
    
    HeroHasFeatSavedInFormation(heroID, featID, formationSlot)
    {
        size := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List.size.Read()
        if(size <= 0 OR size > 10) ; sanity check, should be < 6 but set to 10 in case of future game field familiar increase.
            return false
        Loop, %size%
        {
            value := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List[A_Index - 1].Read()
            if (value==featID)
                return true
        }
        return false
    }
    
    HeroHasAnyFeatsSavedInFormation(heroID, formationSlot)
    {
        size := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List.size.Read()
        if(size <= 0 OR size > 10) ; sanity check, should be < 6 but set to 10 in case of future game field familiar increase.
            return false
        return true
    }

    GetHeroFeats(heroID)
    {
        if (heroID < 1)
            return ""
        size := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.FeatHandler.heroFeatSlots[heroID].List.size.Read()
        ; Sanity check, should be < 4 but set to 10 in case of future feat num increase.
        if (size < 0 || size > 10)
            return ""
        featList := []
        Loop, %size%
        {
            value := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.FeatHandler.heroFeatSlots[heroID].List[A_Index - 1].ID.Read()
            featList.Push(value)
        }
        return featList
    }

    #include *i %A_LineFile%\..\IC_MemoryFunctions_Extended.ahk
}
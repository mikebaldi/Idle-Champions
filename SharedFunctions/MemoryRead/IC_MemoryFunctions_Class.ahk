;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include %A_LineFile%\..\classMemory.ahk
#include %A_LineFile%\..\IC_GameManager_Class.ahk
#include %A_LineFile%\..\IC_GameSettings_Class.ahk
#include %A_LineFile%\..\IC_EngineSettings_Class.ahk
#include %A_LineFile%\..\IC_CrusadersGameDataSet_Class.ahk

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
        this.GameManager := new IC_GameManager_Class
        this.GameSettings := new IC_GameSettings_Class
        this.EngineSettings := new IC_EngineSettings_Class
        this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class
    }

    ;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
    GetVersion()
    {
        return "v1.91, 01/12/2022, IC v0.415.1+"
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
            this.GameManager := new IC_GameManagerEGS_Class
            this.GameSettings := new IC_GameSettingsEGS_Class
            this.EngineSettings := new IC_EngineSettingsEGS_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSetEGS_Class
            this.Is64Bit := true
        }
        else if (this.Is64Bit and !this.GameManager.is64Bit())
        {
            this.GameManager := new IC_GameManager_Class
            this.GameSettings := new IC_GameSettings_Class
            this.EngineSettings := new IC_EngineSettings_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class
            this.Is64Bit := false
        }
        else
        {
            this.GameSettings.Refresh()
            this.EngineSettings.Refresh()
            this.CrusadersGameDataSet.Refresh()
        }
    }

    ;=====================
    ;General Purpose Calls
    ;=====================
    GenericGetValue(GameObject)
    {
        if(GameObject.ValueType == "UTF-16")
        {
            var := this.GameManager.Main.readstring(GameObject.baseAddress, bytes := 0, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        else if (GameObject.ValueType == "List") ; Temp solution?
        {
            var := this.GameManager.Main.read(GameObject.baseAddress, "Int", (GameObject.GetOffsets())*)
        }
        else
        {
            var := this.GameManager.Main.read(GameObject.baseAddress, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        return var
    }

    ;=========================================
    ;General Game Values
    ;=========================================
    ; The following Read___ functions are shorthand for GenericGetValue(GameObjectStructure). 
    ; They are not necessary but they do increase readability of code and increase ease of use.

    ReadGameVersion()
    {
        if(this.GenericGetValue(this.GameSettings.GameSettings.PostFix)  != "")
            return this.GenericGetValue(this.GameSettings.GameSettings.Version) . this.GenericGetValue(this.GameSettings.GameSettings.PostFix) 
        else
            return this.GenericGetValue(this.GameSettings.GameSettings.Version)  
    }

    ReadGameStarted()
    {
        return this.GenericGetValue(this.GameManager.Game.GameStarted)
    }

    ReadMonstersSpawned()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.BasicMonstersSpawned)
    }

    ReadResetting()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ResetHandler.Resetting)
    }

    ReadTimeScaleMultiplier()
    {
        return this.GenericGetValue(this.GameManager.GameManager.TimeScale )
    }

    ReadTimeScaleMultiplierByIndex(index := 0)
    {
        offset := Mod(index,2) ? 10
        if (this.Is64Bit)
            timeScaleObject := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries, "Float", [0x20 + 0x10 + (index * 0x18)]) ; 20 start, values at 50,68,3C..etc
        else
            timeScaleObject := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries, "Float", [0x10 + 0xC + (index * 0x10)]) ; 10 start, values at 1C,2C,3C..etc
        return Round(this.GenericGetValue(timeScaleObject), 2)
    }

    ;this read will only return a valid key if it is reading from TimeScaleWhenNotAttackedHandler object
    ReadTimeScaleMultipliersKeyByIndex(index := 0)
    {
        ;if (this.Is64Bit)
        ;    timeScaleObject := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries, "Float", [0x20 + 0x10 + (index * 0x18)]) ; 20 start, values at 50,68,3C..etc
        ;else
            key := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries,, [0x10 + 0x8 + (index * 0x10), 0x14, 0x8, 0x8, 0xC, 0x8]) ; 10 start, values at 18,28,38..etc to get to handler, effectKey, parentEffectKeyHandler, parent, source, ID
        return this.GenericGetValue(key)
    }

    ReadTimeScaleMultipliersCount()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Count)
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
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.IsTransitioning)
    }

    ReadTransitionDelay()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer.T)
    }

    ReadTransitionDirection()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.TransitionDirection)
    }

    ReadSecondsSinceAreaStart()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.SecondsSinceStarted)
    }

    ReadAreaActive()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.Active)
    }

    ReadUserIsInited()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.Inited)
    }

    ;=================
    ;Screen Resolution
    ;=================

    ReadScreenWidth()
    {
        return this.GenericGetValue(this.GameManager.Game.ActiveScreen.Width)
    }

    ReadScreenHeight()
    {
        return this.GenericGetValue(this.GameManager.Game.ActiveScreen.Height)
    }

    ;=========================================================
    ;herohandler - champion related information accessed by ID
    ;=========================================================

    ; -1 for 1->0 indexing conversion
    ReadChampUpgradeCountByID(ChampID:= 0)
    {
        
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampHealthByID(ChampID := 0 )
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Health.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampSlotByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Slot.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampBenchedByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Benched.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampLvlByID(ChampID:= 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Level.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampSeatByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Seat.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampNameByID(ChampID := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def.Name.GetGameObjectFromListValues(ChampID - 1))
    }

    ;=============================
    ;ServerCall Related - userid, hash, etc.
    ;=============================

    ReadUserID()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.UserID)
    }

    ReadUserHash()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.Hash)
    }

    ReadInstanceID()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings._Instance.InstanceID)
    }

    ReadWebRoot()
    {
        return this.GenericGetValue(this.Enginesettings.EngineSettings.WebRoot) 
    }

    ReadPlatform()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.Platform) 
    }
    
    
    ;==================================================
    ;userData - gems, red rubies, SB/Haste stacks, etc.
    ;==================================================

    ReadGems()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.Gems)
    }

    ReadGemsSpent()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.GemsSpent)
    }

    ReadRedGems() ; BlackViper Red Gems
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems) 
    }

    ReadSBStacks()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks)
    }

    ReadHasteStacks()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks)
    }

    ;======================================================================================
    ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
    ;======================================================================================

    ReadCurrentObjID()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID)
    }

    ReadQuestRemaining()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining)
    }

    ReadCurrentZone()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentAreaID)
    }

    ReadHighestZone()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID)
    }

    ;======================================================================================
    ;Gold Related functions.
    ;======================================================================================
    
    ;reads the first 8 bytes of the quad value of gold
    ReadGoldFirst8Bytes()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
    }

    ;reads the last 8 bytes of the quad value of gold
    ReadGoldSecond8Bytes()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
    }

    ;Reads memory for gold and converts it to double then to a string. < e308 only.
    ReadGoldString()
    {
        ; Gold value must be < max double to work
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString(FirstEight, SecondEight)
        return stringVar 
    }

    ReadGoldString2()
    {
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString2(FirstEight, SecondEight)
        return stringVar 
    }

    ;Reads memory for gold and converts it to a string.
    ReadGoldString3()
    {
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString3(FirstEight, SecondEight)
        return stringVar 
    }

    ;===================================
    ;Formation save related memory reads
    ;===================================
    ;read the number of saved formations for the active campaign
    ReadFormationSavesSize()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesListSize)
    }

    ;reads if a formation save is a favorite
    ;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
    ReadFormationFavoriteIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Favorite.GetGameObjectFromListValues(slot))
    }

    ReadFormationNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationName.GetGameObjectFromListValues(slot)) 
    }

    ; Reads the SaveID for the FormationSaves index passed in.
    ReadFormationSaveIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.SaveID.GetGameObjectFromListValues(slot))
    }

    ; Reads the FormationCampaignID for the FormationSaves index passed in.
    ReadFormationCampaignID()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationCampaignID)
    }

    ;=========================================================================
    ;Formation related memory reads (not save, but the in adventure formation)
    ;=========================================================================
    
    ReadNumAttackingMonstersReached()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.numAttackingMonstersReached)
    }

    ReadNumRangedAttackingMonsters()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.NumRangedAttackingMonsters)
    }

    ReadChampIDBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.ChampID.GetGameObjectFromListValues(slot))
    }

    ReadHeroAliveBySlot(slot := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.HeroAlive.GetGameObjectFromListValues(slot))
    }

    ;==============================
    ;offlineprogress and modronsave
    ;==============================

    ReadMonstersSpawnedThisAreaOL()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea)
    }

    ReadCoreXP()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal)
    }

    ReadCoreTargetArea()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea)
    }

    ReadActiveGameInstance()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ActiveUserGameInstance)
    }

    GetCoreTargetAreaByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        loop, %saveSize%
        {
            if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(i)) == InstanceID)
            {
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.TargetArea.GetGameObjectFromListValues(i))
            }
            ++i
        }
        return -1
    }

    GetCoreXPByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        saveSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        loop, %saveSize%
        {
            if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(i)) == InstanceID)
            {
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.ExpTotal.GetGameObjectFromListValues(i))
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
        return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.InGameNumSecondsToProcess)
    }

    ReadOfflineDone()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.FinishedOfflineProgress)
    }

    ReadResetsCount()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ResetsSinceLastManual)
    }

    ;=================
    ;UI
    ;=================

    ReadAutoProgressToggled()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled)
    }

    ;reads the champ id associated with an ultimate button
    ReadUltimateButtonChampIDByItem(item := 0)
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero.def.ID.GetGameObjectFromListValues(item))
    }

    ReadUltimateButtonListSize()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsListSize)
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
        _size := this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.Size.GetGameObjectFromListValues(slot))
        loop, %_size%
        {
            heroLoc := this.GameManager.Is64Bit() ? ((A_Index - 1) / 2) : (A_Index - 1) ; -1 for 1->0 indexing conversion
            champID := this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.FormationList.GetGameObjectFromListValues(slot, heroLoc))
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
        return formationSaveSlot ; formationSaveSlot is ID which starts at 1, list index starts at 0, so we subtract 1
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
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationListSize)
        if(!size)
            return ""
        loop, %size%
        {
            heroID := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.ChampID.GetGameObjectFromListValues(A_index - 1))
            heroID := heroID > 0 ? heroID : -1
            formation.Push(heroID)
        }
        return formation
    }

    ReadBoughtLastUpgrade( seat = 1)
    {
        ; The nextUpgrade pointer could be null if no upgrades are found.
        if(this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.GetGameObjectFromListValues(seat - 1)))
        {
            val := this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.IsPurchased.GetGameObjectFromListValues(seat - 1))
            return val
        }
        else
        {
            return True
        }
    }

    ; Returns the formation array of the formation used in the currently active modron.
    GetActiveModronFormation()
    {
        formation := ""
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc. )
        formationCampaignID := this.ReadFormationCampaignID()
        ; Find the SaveID associated to the Campaign ID 
        formationSaveID := this.GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
        ; Find the list index (slot) of the formation with the correct SaveID
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
        ; Get the formation using the list index (slot)
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
        modronFormationsSavesSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionarySize.GetGameObjectFromListValues(modronSavesSlot))
        loop, %modronFormationsSavesSize%
        {
            if(this.Is64Bit)
                testIndex := 0x20 + (A_index - 1) * 0x10 
            else
                testIndex := 0x10 + (A_Index - 1) * 0x10
            testValueObject := new GameObjectStructure(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionary.GetGameObjectFromListValues(modronSavesSlot),,[testIndex])
            ;testValueObjectOffsets := ArrFnc.GetHexFormattedArrayString(testValueObject.GetOffsets())
            testValue := this.GenericGetValue(testValueObject)
            if (testValue == formationCampaignID)
            {
                testIndex := testIndex + 0xC ; same for 64/32 bit
                testValueObject := new GameObjectStructure(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionary.GetGameObjectFromListValues(modronSavesSlot),,[testIndex])
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
        moronSavesSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        loop, %moronSavesSize%
        {
            if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(A_Index - 1)) == activeGameInstance)
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
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
        if(!size)
            return ""
        loop, %size%
        {
            if(this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID.GetGameObjectFromListValues(A_index - 1)) == buffID)
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.InventoryAmount.GetGameObjectFromListValues(A_index - 1))
        }
        return ""
    }

    GetInventoryBuffNameByID(buffID)
    {
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
        if(!size)
            return ""
        loop, %size%
        {
            testValue := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID.GetGameObjectFromListValues(A_index - 1) )
            if(testValue == buffID)
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NameSingular.GetGameObjectFromListValues(A_index - 1))
        }
        return ""
    }

    ReadInventoryItemsCount()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
    }

    /* Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer.
    */
    GetChestCountByID(chestID)
    {
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionarySize)    
        if(!size)
            return "" 
        loop, %size%
        {
            if(this.Is64Bit)
                testIndex := (A_index - 1) * 4 + 4 ; Not using 64 bit list, but need +0x10 offset for where list starts
            else
                testIndex := (A_Index - 1) * 4
            testValue := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(testIndex))
            if(this.Is64Bit)
                testIndex := (A_index - 1) * 4 + 7 ; Addresses are 64 bit but the dictionary entry offsets are 4 bytes instead of 8.
            else
                testIndex := (A_index - 1) * 4 + 3
            if(testValue == chestID)
            {
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(testIndex))
            }
        }
        return "" 
    }

    GetChestNameByID(chestID)
    {
        size := this.GenericGetValue(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesListSize)    
        if(!size)
            return "" 
        loop, %size%
        {
            testValue := this.GenericGetValue(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.ID.GetGameObjectFromListValues(A_Index - 1))
            if(testValue == chestID)
                return this.GenericGetValue(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.NamePlural.GetGameObjectFromListValues(A_Index - 1))
        }
        return "" 
    }

    ;==============
    ;Helper Methods
    ;==============

    ; maxes at max double
    ConvQuadToString(FirstEight, SecondEight)
    {
        var := (FirstEight + (2.0**63)) * (2.0**SecondEight)
        exponent := log(var)
        stringVar := Round(var, 0) . ""
        if(var >= 10000)
        {
            stringVar := Round((SubStr(var, 1 , 3) / 100), 2)  . "e" . Floor(exponent)  
        }
        return stringVar 
    }

    ; testing - not accurate at times?
    ConvQuadToString2( FirstEight, SecondEight )
    {
        a := log( 2.0 ** 63 )
        b := log( FirstEight )
        ;can't directly add a and b though probably could add FirstEight and max int64, but would lose precision maybe, but probably doesn't matter
        c := Floor( b ) - Floor( a )
        aRemainder := a - Floor( a )
        d := 10 ** aRemainder
        bRemainder := b - Floor( b )
        e := 10 ** bRemainder
        f := e / ( 10 ** c )
        f += d
        f := log( f )

        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + Floor( a ) + f

        significand := round( 10 ** ( decimated - floor( decimated ) ), 2 )
        exponent := floor( decimated )
        if(exponent < 4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""
        return significand . "e" . exponent
    }

    ;and it turns out I went through a lot of extra steps
    ;testing - Converts 16 bit Quad value into a string representation.
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

    #include *i IC_MemoryFunctions_Extended.ahk
}
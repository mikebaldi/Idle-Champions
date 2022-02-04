
; (Thanks to Fenume for updating offsets for 412)
class IC_GameManagerEGS_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.9.7, 2022-02-04, IC v0.418.2+, EGS"
    }

    is64Bit()
    {
        return this.Main.isTarget64bit
    }

    Refresh()
    {
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;hProcessCopy is an optional variable in which the opened handled is stored.
        ;==================
        ;structure pointers
        ;==================
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
        ;=========================================
        ;Base addresses and Handlers
        ;=========================================
        this.GameManager := New GameObjectStructure([0xC88])
        this.GameManager.Is64Bit := 1
        this.GameManager.BaseAddress := this.BaseAddress
        this.Game := New GameObjectStructure(This.GameManager,, [0xD8]) ; GameManager skipped because the only thing besides game that is used is TimeScale. Simplifies structure
        this.Game.Is64Bit := 1
        this.Game.BaseAddress := this.BaseAddress
        this.Game.GameUser := New GameObjectStructure(this.Game,, [0xA8])
        this.Game.GameInstance := New GameObjectStructure(this.Game,, [0xB0, 0x10, 0x20])         ; Push - GameInstances._items.Item[0]
        this.Game.GameInstance.TimeScales := New GameObjectStructure(this.Game.GameInstance,, [0xF0])
        this.Game.GameInstance.Controller := New GameObjectStructure(this.Game.GameInstance,, [0x18])
        this.Game.GameInstance.ResetHandler := New GameObjectStructure(this.Game.GameInstance,, [0x38])
        this.Game.GameInstance.Controller.UserData := New GameObjectStructure(this.Game.GameInstance.Controller,, [0xA0])
        this.Game.GameInstance.Controller.UserData.HeroHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x10])
        this.Game.GameInstance.Controller.UserData.ActiveUserGameInstance := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x254])
        this.Game.GameInstance.Controller.UserData.BuffHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x28])
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler,"List", [0x18, 0x10]) ; Push inventoryBuffs._Items
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler,, [0x18, 0x18]) ; Push inventoryBuffs._size
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,, [0x10]) 
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.InventoryAmount := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,, [0xA4+0x8]) ; The actual value is InventoryAmount + 8
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NameSingular := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,"UTF-16", [0x20,0x14]) ; Push NamePlura.Value
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NamePlural := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,"UTF-16", [0x28,0x14]) ; Push NamePlura.Value
        this.Game.GameInstance.Controller.UserData.LootHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x18]) 
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler,"List", [0x30,0x10]) ; push inventoryLoot._Items
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler,, [0x130,0x18]) ; push inventoryLoot._size
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.NameValue := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x18,0x14]) ; push Name.Value
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.ID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x10])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.RarityValue := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x5C])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.HeroID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x54])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.SlotID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x60])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Count := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x70])
        ;this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Golden := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x64]) ; empty
        ;this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Gild := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x74]) ; empty
        this.Game.GameInstance.Controller.UserData.ChestHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x20])
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ChestHandler,"List", [0x18,0x18]) ; Push chestCounts.entries
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.Is64Bit := false ; Dictionary uses 4 bit offsets (but does start at 20 not 10)
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionarySize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ChestHandler,, [0x18,0x40]) ; Push chestCounts.count
        this.Game.GameInstance.Controller.UserData.StatHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x30])
        this.Game.GameInstance.Controller.UserData.ModronHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0xD8])
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler,"List", [0x20, 0x10]) ; Push modronSaves._items
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler,, [0x20, 0x18]) ; Push modronSaves.size
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionary := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,"List", [0x18,0x18]) ; Push FormationSaves.entries
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionarySize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x18,0x40]) ; Push FormationSaves.count
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.TargetArea := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x54]) 
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.ExpTotal := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x50])  
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.CoreID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x48]) 
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x4C])
        ;=========================================
        ;until I find a better spot here these are
        ;=========================================
        this.Game.GameInstance.ClickLevel := New GameObjectStructure(this.Game.GameInstance,, [0x118])
        this.Game.GameStarted := New GameObjectStructure(this.Game, "Char", [0xF8])
        this.Game.GameInstance.ResetsSinceLastManual := New GameObjectStructure(this.Game.GameInstance,, [0x104])
        this.Game.GameInstance.instanceLoadTimeSinceLastSave := New GameObjectStructure(this.Game.GameInstance,, [0x10C])
        this.Game.GameInstance.Controller.Area := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x18])
        this.Game.GameInstance.Controller.Area.Active := New GameObjectStructure(this.Game.GameInstance.Controller.Area, "Char", [0x1D0]) 
        this.Game.GameInstance.Controller.Area.BasicMonstersSpawned := New GameObjectStructure(this.Game.GameInstance.Controller.Area,, [0x230]) ; Push basicMonstersSpawnedThisArea
        this.Game.GameInstance.Controller.Area.SecondsSinceStarted := New GameObjectStructure(this.Game.GameInstance.Controller.Area, "Float", [0x1F4]) 
        this.Game.GameInstance.ResetHandler.Resetting := New GameObjectStructure(this.Game.GameInstance.ResetHandler, "Char", [0x38])
        this.GameManager.TimeScale := New GameObjectStructure(This.GameManager, "Float", [0x80]) 
        this.Game.GameInstance.Controller.AreaTransitioner := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x40])
        this.Game.GameInstance.Controller.AreaTransitioner.IsTransitioning := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner, "Char", [0x38]) ; Push <IsTransitioning>k__BackingField
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner,, [0x28])        
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect,, [0x38])
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer.T := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer, "Double", [0x48])
        this.Game.GameInstance.Controller.AreaTransitioner.TransitionDirection := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner,, [0x3C]) ; 0 = right, 1 = left, 2 = static (instant)
        this.Game.GameInstance.PatronHandler := New GameObjectStructure(this.Game.GameInstance,, [0x50])
        this.Game.GameInstance.PatronHandler.ActivePatron := New GameObjectStructure(this.Game.GameInstance.PatronHandler,, [0x20]) ; Push - <ActivePatron>k_BackingField
        this.Game.GameInstance.PatronHandler.ActivePatron.ID := New GameObjectStructure(this.Game.GameInstance.PatronHandler.ActivePatron,, [0x10]) 
        this.Game.GameInstance.PatronHandler.ActivePatron.Tier := New GameObjectStructure(this.Game.GameInstance.PatronHandler.ActivePatron,, [0xC0]) 
        ;=================
        ;Screen Resolution
        ;=================
        this.Game.ActiveScreen := New GameObjectStructure(this.Game,, [0x10, 0x18]) ; Push screenController.activeScreen
        this.Game.ActiveScreen.Width := New GameObjectStructure(this.Game.ActiveScreen,, [0x2F4]) ; v414-416
        ;this.Game.ActiveScreen.Width := New GameObjectStructure(this.Game.ActiveScreen,, [0x314]) ; v417
        this.Game.ActiveScreen.Height := New GameObjectStructure(this.Game.ActiveScreen,, [0x2F8]) ; v414-416
        ;this.Game.ActiveScreen.Height := New GameObjectStructure(this.Game.ActiveScreen,, [0x318]) ; v417
        ;=========================================================
        ;herohandler - champion related information accessed by ID
        ;=========================================================
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler,"List", [0x18, 0x10]) ;Push heroes._items
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x18])
        ;this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def.Name := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def, "UTF-16", [0x28, 0x14]) ;Push Name, Value v414-416
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def.Name := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def, "UTF-16", [0x30, 0x14]) ;Push Name, Value v417
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x80])
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects, "List", [0x58, 0x18]) ;Push effectKeysByKeyName, entries
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyNameCount := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects,, [0x58, 0x40]) ;Push effectKeysByKeyName, count
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.Name := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName, "UTF-16", [0x14])
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName,, [0x10, 0x20]) ;Push _items, item[0] - this is a list that should generally be one long, but there may be abilities with more items in which case we will need to revisit this and make a list.
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey.parentEffectKeyHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey,, [0x10])
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey.parentEffectKeyHandler.activeEffectHandlers := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey.parentEffectKeyHandler, "Int64", [0x128, 0x10]) ;Push activeEffectHandlers, _items. Eliminated item[0] so this acts as a pointer - OLD note no longer applies: this is a list that should generally be one long, but there may be abilities with more items in which case we will need to revisit this and make a list.
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x220, 0x30]) ; Push purchasedUpgradeIDs._count
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Health := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList, "Double", [0x350]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Slot := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x2F0]) ; Push slotId
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Benched := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x2FC]) 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Level := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x318]) ;Push _level
        ;this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Seat := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x18, 0x130]) ; Push def.SeatID ;v414-416
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Seat := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x18, 0x138]) ; Push def.SeatID ;v417
        ;=============================
        ;GameUser - userid, hash, etc. (Depricated. Used GameSettings class to access these values)
        ;=============================
        this.Game.GameUser.Hash := New GameObjectStructure(this.Game.GameUser, "UTF-16", [0x20, 0x14]) ; Push Hash.Value
        this.Game.GameUser.ID := New GameObjectStructure(this.Game.GameUser,, [0x58])
        ;==================================================
        ;userData - gems, red rubies, SB/Haste stacks, etc.
        ;==================================================
        this.Game.GameInstance.Controller.UserData.Inited := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x240])
        this.Game.GameInstance.Controller.UserData.Gems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x224]) ; Push redRubies
        this.Game.GameInstance.Controller.UserData.GemsSpent := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x228]) ; Push redRubiesSpent
        this.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x290])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2F0])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2F4])
        ;======================================================================================
        ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
        ;======================================================================================
        this.Game.GameInstance.ActiveCampaignData := New GameObjectStructure(this.Game.GameInstance,, [0x20])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x28])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x18])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentObjective,, [0x10])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x54])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.Level := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x4C])
        this.Game.GameInstance.ActiveCampaignData.CurrentAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x88])
        this.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x90])
        this.Game.GameInstance.ActiveCampaignData.Gold := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x258])
        this.Game.GameInstance.ActiveCampaignData.GoldExp := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x260])
        ;===================================
        ;Formation save related memory reads
        ;===================================
        this.Game.GameInstance.FormationSaveHandler:= New GameObjectStructure(this.Game.GameInstance,, [0x60])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesListSize := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x30, 0x18]) ; Push formationSavesV2._size
        this.Game.GameInstance.FormationSaveHandler.FormationCampaignID := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x78])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,"List", [0x30, 0x10]) ; Push formationSavesV2._Items
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Favorite := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x40]) ; Push favorite from Item[x].Favorite
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.SaveID := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x38]) 
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationName := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList, "UTF-16", [0x30, 0x14]) 
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x18])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.Size := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation,, [0x18])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation,"List", [0x10]) ; Push _items ;
        ;=========================================================================
        ;Formation related memory reads (not save, but the in adventure formation)
        ;=========================================================================
        this.Game.GameInstance.Controller.Formation := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x28])
        this.Game.GameInstance.Controller.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,"List", [0x18, 0x10]) ; Push slots._Items (not confirmed, based on previous code)
        this.Game.GameInstance.Controller.Formation.FormationListSize := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x18, 0x18]) ; Push slots._size 
        this.Game.GameInstance.Controller.Formation.FormationList.ChampID := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x28, 0x18, 0x10]) ; Push hero.def.ID
        this.Game.GameInstance.Controller.Formation.FormationList.HeroAlive := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x251])
        this.Game.GameInstance.Controller.Formation.TransitionOverrides := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xA8]) ;this is a dict
        ;ActionListSize is a count of how many transition overrides have been added to the action list within the dictionary TransitionOverrides.
        ;When this value increases from 0 to 1 a briv jump animation can occur. It is possible a future transtiion override occurs increasing the Count
        ; to a value greater than 1. But for standard gem farm team should be goood for a while.
        ; quick transitions increment from 0 to 1, but more quickly.
        this.Game.GameInstance.Controller.Formation.TransitionOverrides.ActionListSize := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.TransitionOverrides,, [0x18, 0x30, 0x18]) ;Push entries, value[0] (CE doesn't build this on it's own), _size
        this.Game.GameInstance.Controller.Formation.transitionDir := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x18C])
        this.Game.GameInstance.Controller.Formation.inAreaTransition := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x190])
        this.Game.GameInstance.Controller.Formation.numAttackingMonstersReached := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x198])
        this.Game.GameInstance.Controller.Formation.numRangedAttackingMonsters := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x19C])
        ;==============================
        ;offlineprogress and modronsave
        ;==============================        
        this.Game.GameInstance.OfflineProgressHandler := New GameObjectStructure(this.Game.GameInstance,, [0x80])
        this.Game.GameInstance.OfflineProgressHandler.InGameNumSecondsToProcess := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0xE0])
        this.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0xD0])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x40])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x50])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x54])
        this.Game.GameInstance.OfflineProgressHandler.FinishedOfflineProgress := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler, "Char", [0x134]) ; Push finishedOfflineProgressType ; F???
        ;=================
        ;Screen and UI
        ;=================
        this.Game.GameInstance.Screen := New GameObjectStructure(this.Game.GameInstance,, [0x10])
        this.Game.GameInstance.Screen.uiController := New GameObjectStructure(this.Game.GameInstance.Screen,, [0x368])
        this.Game.GameInstance.Screen.uiController.topBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0x18])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar,, [0x308])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox,, [0x340])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar, "Char", [0x310, 0x362]) ; Push autoProgressButton.toggled
        this.Game.GameInstance.Screen.uiController.bottomBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0x20])
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar,, [0x328])
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel, "List", [0x368, 0x10]) ; Push activeBoxes._items
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList,, [0x3A8])
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.IsPurchased := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade,"Char", [0xA0])
        this.Game.GameInstance.Screen.uiController.ultimatesBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0x28])
        this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.ultimatesBar, "List", [0x350, 0x10]) ; Push ultimatesItems._items
        this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsListSize := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.ultimatesBar,, [0x350, 0x18]) ; Push ultimatesItems._size
        this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList,, [0x340])
        this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero.def := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero,, [0x18])
        this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero.def.ID := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero.def,, [0x10])    
        ;=========================================
        ;Shandie's Dash
        ;=========================================
        this.Game.GameInstance.TimeScales.Multipliers := New GameObjectStructure(this.Game.GameInstance.TimeScales,, [0x10, 0x20, 0x10]) ; Push _items.item[0].Multipliers
        this.Game.GameInstance.TimeScales.Multipliers.Count := New GameObjectStructure(this.Game.GameInstance.TimeScales.Multipliers,, [0x40])
        this.Game.GameInstance.TimeScales.Multipliers.Entries := New GameObjectStructure(this.Game.GameInstance.TimeScales.Multipliers,, [0x18])
        ;=========================================
        ;Background - Can Skip?
        ;=========================================
        
    }
}


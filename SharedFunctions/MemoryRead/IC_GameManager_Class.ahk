#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; GameManager class contains the in game data structure layout

; GameManager class contains the offsets as found in mono-disected memory structures. Specifically, the offsets for the IdleGameManager structure.
; It was designed to make future updates easier by clarifying where each offset is found and (hopefully) reduce the difficulty of updating offsets for structures that remain largely the same.
; - Variable names are based on the layout within the structure not including GameManager itself. e.g. this.Game.GameUser will be IdleGameManager->Game->GameUser.
; - Each offset is built off of a previous offsets. e.g. this.Game.GameUser.ID will be this.game.GameUser + ID, or IdleGameManager->Game->GameUser->ID
; - GameObjectStructure is what is used to combine offsets.
; - Occasionally, multiple offsets are added where irrelevant sub-items are skipped for the simplicity of naming. Those cases are commented with the actual items being pushed.
; - Items defined by "List" will have an Item[x] offset that is dynamically selected in code via object.GetGameObjectFromListValues(x).
; - Take this into account when updating offsets as there will be an offset that will be skipped at the location of a List object.
; - There can be multiple missing list offsets as the game can traverse multiple lists to get to the value you want.
; - Items that contain Lists should not use their name when accessing. Instead, they should use the GetGameObjectFromListValues functon.Clone()
; - i.e. Instead of using:
;            this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount
;   you would use
;            this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount.GetGameObjectFromListValues( hero_id )
;   as hero_id will tell it which hero from the HeroList is being accessed.
;   Each extra list used will require an extra location passed. e.g. GetGameObjectFromListValues( first_id, second_id, third_id )
class IC_GameManager_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.92, 1/02/21, IC v0.415.1+, Steam"
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
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
        ;=========================================
        ;Base addresses and Handlers
        ;=========================================
        this.GameManager := New GameObjectStructure([0x658])
        this.GameManager.BaseAddress := this.BaseAddress
        this.Game := New GameObjectStructure(This.GameManager,, [0xA0]) ; GameManager skipped because the only thing besides game that is used is TimeScale. Simplifies structure
        this.Game.BaseAddress := this.BaseAddress
        this.Game.GameUser := New GameObjectStructure(this.Game,, [0x54])
        this.Game.GameInstance := New GameObjectStructure(this.Game,, [0x58, 0x8, 0x10])         ; Push - GameInstances._items.Item[0]
        this.Game.GameInstance.TimeScales := New GameObjectStructure(this.Game.GameInstance,, [0x78])
        this.Game.GameInstance.Controller := New GameObjectStructure(this.Game.GameInstance,, [0xC])
        this.Game.GameInstance.ResetHandler := New GameObjectStructure(this.Game.GameInstance,, [0x1C])
        this.Game.GameInstance.Controller.UserData := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x50])
        this.Game.GameInstance.Controller.UserData.ActiveUserGameInstance := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x164])
        this.Game.GameInstance.Controller.UserData.HeroHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x8])
        this.Game.GameInstance.Controller.UserData.BuffHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x14])
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler,"List", [0xC, 0x8]) ; Push inventoryBuffs._Items
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler,, [0xC, 0xC]) ; Push inventoryBuffs._size
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,, [0x8]) 
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.InventoryAmount := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,, [0x70+0x8]) ; The actual value is InventoryAmount + 8
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NameSingular := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,"UTF-16", [0x10,0xC]) ; Push NamePlura.Value
        this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NamePlural := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList,"UTF-16", [0x14,0xC]) ; Push NamePlura.Value
        this.Game.GameInstance.Controller.UserData.LootHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0xC]) 
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler,"List", [0x18,0x8]) ; push inventoryLoot._Items
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler,, [0x18,0xC]) ; push inventoryLoot._size
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.NameValue := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0xC,0xC]) ; push Name.Value
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.ID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x8])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.RarityValue := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x34])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.HeroID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x2C])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.SlotID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x38])
        this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Count := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x48])
        ;this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Golden := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x3C]) ; empty
        ;this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList.Gild := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.LootHandler.InventoryLootList,, [0x4C]) ; empty
        this.Game.GameInstance.Controller.UserData.ChestHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x10])
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ChestHandler,"List", [0xC,0xC]) ; Push chestCounts.entries
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.Is64Bit := false
        this.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionarySize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ChestHandler,, [0xC,0x20]) ; Push chestCounts.count
        this.Game.GameInstance.Controller.UserData.StatHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x18])
        this.Game.GameInstance.Controller.UserData.ModronHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x6C])
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler,"List", [0x10, 0x8]) ; Push modronSaves._items
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler,, [0x10, 0xC]) ; Push modronSaves.size
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.TargetArea := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x30]) 
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.ExpTotal := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x2C])  
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.CoreID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x24]) 
        this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList,, [0x28])
        ;=========================================
        ;until I find a better spot here these are
        ;=========================================
        this.Game.GameInstance.ClickLevel := New GameObjectStructure(this.Game.GameInstance,, [0x98])
        this.Game.GameStarted := New GameObjectStructure(this.Game, "Char", [0x7C])
        this.Game.GameInstance.ResetsSinceLastManual := New GameObjectStructure(this.Game.GameInstance,, [0x84])
        this.Game.GameInstance.instanceLoadTimeSinceLastSave := New GameObjectStructure(this.Game.GameInstance,, [0x8C])
        this.Game.GameInstance.Controller.Area := New GameObjectStructure(this.Game.GameInstance.Controller,, [0xC])
        this.Game.GameInstance.Controller.Area.Active := New GameObjectStructure(this.Game.GameInstance.Controller.Area,, [0xEC]) 
        this.Game.GameInstance.Controller.Area.BasicMonstersSpawned := New GameObjectStructure(this.Game.GameInstance.Controller.Area,, [0x148]) 
        this.Game.GameInstance.Controller.Area.SecondsSinceStarted := New GameObjectStructure(this.Game.GameInstance.Controller.Area, "Float", [0x10C]) 
        this.Game.GameInstance.ResetHandler.Resetting := New GameObjectStructure(this.Game.GameInstance.ResetHandler, "Char", [0x1C])
        this.GameManager.TimeScale := New GameObjectStructure(This.GameManager, "Float", [0x48]) 
        this.Game.GameInstance.Controller.AreaTransitioner := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x20]) 
        this.Game.GameInstance.Controller.AreaTransitioner.IsTransitioning := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner, "Char", [0x1C]) ; Push <IsTransitioning>k__BackingField
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner,, [0x14])        
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect,, [0x1C])
        this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer.T := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer, "Double", [0x28])
        ;=================
        ;Screen Resolution
        ;=================
        this.Game.ActiveScreen := New GameObjectStructure(this.Game,, [0x8, 0xC]) ; Push screenController.activeScreen
        this.Game.ActiveScreen.Width := New GameObjectStructure(this.Game.ActiveScreen,, [0x1FC]) 
        this.Game.ActiveScreen.Height := New GameObjectStructure(this.Game.ActiveScreen,, [0x200])
        ;=========================================================
        ;herohandler - champion related information accessed by ID
        ;=========================================================
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler,"List", [0xC, 0x8]) ;Push heroes._items
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x110, 0x18]) ; Push purchasedUpgradeIDs._count
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Health := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList, "Double", [0x1E0]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Slot := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x184]) ; Push slotId
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Benched := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x190]) 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Level := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x1AC]) ;Push _level
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Seat := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x0C, 0xD0]) ; Push def.SeatID
        ;=============================
        ;GameUser - userid, hash, etc. (Depricated. Used GameSettings class to access these values)
        ;=============================
        this.Game.GameUser.Hash := New GameObjectStructure(this.Game.GameUser, "UTF-16", [0x10, 0xC]) ; Push Hash.Value
        this.Game.GameUser.ID := New GameObjectStructure(this.Game.GameUser,, [0x30])
        ;==================================================
        ;userData - gems, red rubies, SB/Haste stacks, etc.
        ;==================================================
        this.Game.GameInstance.Controller.UserData.Inited := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x150])
        this.Game.GameInstance.Controller.UserData.Gems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x130]) ; Push redRubies
        this.Game.GameInstance.Controller.UserData.GemsSpent := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x134]) ; Push redRubiesSpent
        this.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x260])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2C0])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2C4])
        ;======================================================================================
        ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
        ;======================================================================================
        this.Game.GameInstance.ActiveCampaignData := New GameObjectStructure(this.Game.GameInstance,, [0x10])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x14])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0xC])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentObjective,, [0x8])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x30])
        this.Game.GameInstance.ActiveCampaignData.CurrentAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x44]) ; shows -1 on modron reset and world map
        this.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x4C])
        this.Game.GameInstance.ActiveCampaignData.Gold := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x210])
        this.Game.GameInstance.ActiveCampaignData.GoldExp := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x218])
        ;===================================
        ;Formation save related memory reads
        ;===================================
        this.Game.GameInstance.FormationSaveHandler:= New GameObjectStructure(this.Game.GameInstance,, [0x30])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesListSize := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x18, 0xC]) ; Push formationSavesV2._size
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,"List", [0x18, 0x8]) ; Push formationSavesV2._Items
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Favorite := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x24]) ; Push favorite from Item[x].Favorite
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationName := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList, "UTF-16", [0x18, 0xC]) 
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0xC])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.Size := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation,, [0xC])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation,"List", [0x8]) ; Push _items ;
        ;=========================================================================
        ;Formation related memory reads (not save, but the in adventure formation)
        ;=========================================================================
        this.Game.GameInstance.Controller.Formation := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x14])
        this.Game.GameInstance.Controller.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,"List", [0xC, 0x8]) ; Push slots._Items
        this.Game.GameInstance.Controller.Formation.FormationListSize := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xC, 0xC]) ; Push _size
        this.Game.GameInstance.Controller.Formation.FormationList.ChampID := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x14, 0xC, 0x8]) ; Push hero.def.ID
        this.Game.GameInstance.Controller.Formation.FormationList.HeroAlive := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x151])
        this.Game.GameInstance.Controller.Formation.numAttackingMonstersReached := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xEC])
        this.Game.GameInstance.Controller.Formation.numRangedAttackingMonsters := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xF0])
        ;==============================
        ;offlineprogress and modronsave
        ;==============================        
        this.Game.GameInstance.OfflineProgressHandler := New GameObjectStructure(this.Game.GameInstance,, [0x40])
        this.Game.GameInstance.OfflineProgressHandler.InGameNumSecondsToProcess := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0xAC])
        this.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x98])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x20])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x2C])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x30])
        this.Game.GameInstance.OfflineProgressHandler.FinishedOfflineProgress := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler, "Char", [0xFC]) ; Push finishedOfflineProgressType
        ;=================
        ;Screen and UI
        ;=================
        this.Game.GameInstance.Screen := New GameObjectStructure(this.Game.GameInstance,, [0x8])
        this.Game.GameInstance.Screen.uiController := New GameObjectStructure(this.Game.GameInstance.Screen,, [0x230])
        this.Game.GameInstance.Screen.uiController.topBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0xC])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar,, [0x1FC])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox,, [0x218])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar, "Char", [0x200, 0x23A]) ; Push autoProgressButton.toggled
        this.Game.GameInstance.Screen.uiController.bottomBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0x10])
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar,, [0x20C])
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel, "List", [0x22C, 0x8]) ; Push activeBoxes._items
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList,, [0x24C]) 
        this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.IsPurchased := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade,"Char", [0x70]) 
        ;=========================================
        ;Shandie's Dash
        ;=========================================
        this.Game.GameInstance.TimeScales.Multipliers := New GameObjectStructure(this.Game.GameInstance.TimeScales,, [0x8, 0x10, 0x8]) ; Push _items.item[0].Multipliers
        this.Game.GameInstance.TimeScales.Multipliers.Count := New GameObjectStructure(this.Game.GameInstance.TimeScales.Multipliers,, [0x20])
        this.Game.GameInstance.TimeScales.Multipliers.Entries := New GameObjectStructure(this.Game.GameInstance.TimeScales.Multipliers,, [0xC])
        ;=========================================
        ;Background - Can Skip?
        ;=========================================
        this.Game.GameInstance.Controller.AreaTransitioner.TransitionDirection := New GameObjectStructure(this.Game.GameInstance.Controller.AreaTransitioner,, [0x20])
    }
}

#include %A_LineFile%\..\IC_GameManager_Class_EGS.ahk
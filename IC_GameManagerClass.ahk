#include IC_GameObjectStructureClass.ahk
; GameManager class contains the in game data structure layout

; GameManager class contains the offsets as found in mono-disected memory structures. Specifically, the offsets for the IdleGameManager structure.
; It was designed to make future updates easier by clarifying where each offset is found and (hopefully) reduce the difficulty of updating offsets for structures that remain largely the same.
; - Variable names are based on the layout within the structure not including GameManager itself. e.g. this.Game.GameUser will be IdleGameManager->Game->GameUser.
; - Each offset is built off of a previous offsets. e.g. this.Game.GameUser.ID will be this.game.GameUser + ID, or IdleGameManager->Game->GameUser->ID
; - GameObjectStructure is what is used to combine offsets.
; - Occasionally, multiple offsets are added where irrelevant sub-items are skipped for the simplicity of naming. Those cases are commented with the actual items being pushed.
; - An Alias is created when a list is used between the main structure and the offsets added. I.e. When the full offsets are in the form of [ParentFullOffsets, 0x10 + ( listItemIndex * 0x4 ) , PostListOffsets]
; - Aliases should not use .GetOffSets(). Instead, they should be built as seen above. 
class GameManager
{
    __new()
    {
        this.Refresh()
    }

    is64BBit()
    {
        return this.Main.isTarget64bit
    }

    GetVersion()
    {
        return "v1.0, 11/11/21, IC v0.412, Steam"
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
        This.GameManager := New GameObjectStructure([0x658])
        this.GameManager.BaseAddress := this.BaseAddress
        this.Game := New GameObjectStructure(This.GameManager,, [0xA0]) ; GameManager skipped because the only thing besides game that is used is TimeScale. Simplifies structure
        this.Game.BaseAddress := this.BaseAddress
        this.Game.GameUser := New GameObjectStructure(this.Game,, [0x54])
        this.Game.GameInstance := New GameObjectStructure(this.Game,, [0x58, 0x8, 0x10])         ; Push - GameInstances._items.Item[0]
        this.Game.GameInstance.Controller := New GameObjectStructure(this.Game.GameInstance,, [0xC])
        this.Game.GameInstance.ResetHandler := New GameObjectStructure(this.Game.GameInstance,, [0x1C])
        this.Game.GameInstance.Controller.UserData := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x50])
        this.Game.GameInstance.Controller.UserData.HeroHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x8])
        this.Game.GameInstance.Controller.UserData.StatHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x18])
        ;=========================================
        ;until I find a better spot here these are
        ;=========================================
        this.Game.GameStarted := New GameObjectStructure(this.Game, "Char", [0x7C])
        this.Game.GameInstance.Controller.Area:= New GameObjectStructure(this.Game.GameInstance.Controller,, [0xC])
        this.Game.GameInstance.Controller.Area.MonsterSpawned:= New GameObjectStructure(this.Game.GameInstance.Controller.Area,, [0x148]) ; Push basicMonstersSpawnedThisArea
        this.Game.GameInstance.ResetHandler.Resetting := New GameObjectStructure(this.Game.GameInstance.ResetHandler, "Char", [0x1C])
        this.GameManager.TimeScale := New GameObjectStructure(This.GameManager, "Float", [0x48]) 
        ;this.Game.GameInstance.Controller.TimeScale := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x8, 0xE8]) ; Push <GameInstance>k__BackingField, currentTimeScaleMultiplier
        this.Game.GameInstance.Controller.AreaTransition := New GameObjectStructure(this.Game.GameInstance.Controller, "Char", [0x20, 0x1C]) ; Push AreaTransitioner, <IsTransitioning>k__BackingField
        ;=================
        ;Screen Resolution
        ;=================
        this.Game.ActiveScreen := New GameObjectStructure(this.Game,, [0x8, 0xC]) ; Push screenController.activeScreen
        this.Game.ActiveScreen.Width := New GameObjectStructure(this.Game.ActiveScreen,, [0x1FC]) 
        this.Game.ActiveScreen.Height := New GameObjectStructure(this.Game.ActiveScreen,, [0x200])
        ;=========================================================
        ;herohandler - champion related information accessed by ID
        ;=========================================================
        ; TODO: Refactor classes to have a more intuitive and flexibile notation for dealing with lists (currently labled as Alias)
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler,, [0xC, 0x8]) ;Push heroes._items
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCountAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x110, 0x18]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.HealthAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList, "Double", [0x1E0]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SlotAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x184]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.BenchAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x190]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.LevelAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x1AC]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SeatAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x0C, 0xD0]) ; Alias
        ;=============================
        ;GameUser - userid, hash, etc. (Depricated. Used GameSettings class to access these values)
        ;=============================
        this.Game.GameUser.Hash := New GameObjectStructure(this.Game.GameUser, "UTF-16", [0x10, 0xC]) ; Push Hash.Value
        this.Game.GameUser.ID := New GameObjectStructure(this.Game.GameUser,, [0x30])
        ;==================================================
        ;userData - gems, red rubies, SB/Haste stacks, etc.
        ;==================================================
        this.Game.GameInstance.Controller.UserData.Gems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x130]) ; Push redRubies
        this.Game.GameInstance.Controller.UserData.GemsSpent := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x134]) ; Push redRubiesSpent
        this.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x260])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2C0])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2C4])
        ;======================================================================================
        ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
        ;======================================================================================
        this.Game.GameInstance.ActiveCampaignData := New GameObjectStructure(this.Game.GameInstance,, [0x10])
        ;TODO which location shows current level first?
        this.Game.GameInstance.ActiveCampaignData.CurrentArea := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x14])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0xC])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentObjective,, [0x8])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.Level := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x28])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x30])
        this.Game.GameInstance.ActiveCampaignData.CurrentAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x44])
        ; ----
        this.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x4C])
        this.Game.GameInstance.ActiveCampaignData.Gold := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x210])
        this.Game.GameInstance.ActiveCampaignData.GoldExp := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x218])
        ;===================================
        ;Formation save related memory reads
        ;===================================
        this.Game.GameInstance.FormationSaveHandler:= New GameObjectStructure(this.Game.GameInstance,, [0x30])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x18,0x8]) ; Push formationSavesV2._Items
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Count := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x18, 0xC]) ; Push _size
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FavoriteAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x24]) 
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x8]) ; Push Formation._items
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationNameAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList, "UTF-16", [0x18, 0xC]) 
        ;=========================================================================
        ;Formation related memory reads (not save, but the in adventure formation)
        ;=========================================================================
        this.Game.GameInstance.Controller.Formation := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x14])
        this.Game.GameInstance.Controller.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xC, 0x8]) ; Push slots._Items (not confirmed, based on previous code)
        this.Game.GameInstance.Controller.Formation.FormationList.Count := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xC, 0xC]) ; Push _size (not confirmed, based on previous code)
        this.Game.GameInstance.Controller.Formation.FormationList.ChampIDAlias := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x14, 0xC, 0x8])
        this.Game.GameInstance.Controller.Formation.FormationList.HeroAliveAlias := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x151])
        this.Game.GameInstance.Controller.Formation.numAttackingMonstersReached := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xEC])
        this.Game.GameInstance.Controller.Formation.numRangedAttackingMonsters := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0xF0])
        ;==============================
        ;offlineprogress and modronsave
        ;==============================        
        this.Game.GameInstance.OfflineProgressHandler := New GameObjectStructure(this.Game.GameInstance,, [0x40])
        this.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x98])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x20])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x2C])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x30])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.FinishedOfflineProgress := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave, "Char", [0xFC]) ; Push finishedOfflineProgressType
        ;=================
        ;Screen and UI
        ;=================
        this.Game.GameInstance.Screen := New GameObjectStructure(this.Game.GameInstance,, [0x8])
        this.Game.GameInstance.Screen.uiController := New GameObjectStructure(this.Game.GameInstance.Screen,, [0x22C])
        this.Game.GameInstance.Screen.uiController.topBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0xC])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar,, [0x1FC])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox,, [0x218])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar, "Char", [0x200, 0x23A]) ; Push autoProgressButton.toggled
    }
} 

; (Thanks to Fenume for updating offsets for 412)
class GameManagerEGS
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0, 11/16/21, IC v0.412, EGS"
    }
    
    is64BBit()
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
        This.GameManager := New GameObjectStructure([0xC88])
        this.GameManager.BaseAddress := this.BaseAddress
        this.Game := New GameObjectStructure(This.GameManager,, [0xD8]) ; GameManager skipped because the only thing besides game that is used is TimeScale. Simplifies structure
        this.Game.BaseAddress := this.BaseAddress
        this.Game.GameUser := New GameObjectStructure(this.Game,, [0xA8])
        this.Game.GameInstance := New GameObjectStructure(this.Game,, [0xB0, 0x10, 0x20])         ; Push - GameInstances._items.Item[0]
        this.Game.GameInstance.Controller := New GameObjectStructure(this.Game.GameInstance,, [0x18])
        this.Game.GameInstance.ResetHandler := New GameObjectStructure(this.Game.GameInstance,, [0x38])
        this.Game.GameInstance.Controller.UserData := New GameObjectStructure(this.Game.GameInstance.Controller,, [0xA0])
        this.Game.GameInstance.Controller.UserData.HeroHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x10])
        this.Game.GameInstance.Controller.UserData.StatHandler := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x30])
        ;=========================================
        ;until I find a better spot here these are
        ;=========================================
        this.Game.GameStarted := New GameObjectStructure(this.Game, "Char", [0xF8])
        this.Game.GameInstance.Controller.Area:= New GameObjectStructure(this.Game.GameInstance.Controller,, [0x18])
        this.Game.GameInstance.Controller.Area.MonsterSpawned:= New GameObjectStructure(this.Game.GameInstance.Controller.Area,, [0x230]) ; Push basicMonstersSpawnedThisArea
        this.Game.GameInstance.ResetHandler.Resetting := New GameObjectStructure(this.Game.GameInstance.ResetHandler, "Char", [0x38])
        this.GameManager.TimeScale := New GameObjectStructure(This.GameManager, "Float", [0x80]) 
        ;this.Game.GameInstance.Controller.TimeScale := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x8, 0xE8]) ; Push <GameInstance>k__BackingField, currentTimeScaleMultiplier
        this.Game.GameInstance.Controller.AreaTransition := New GameObjectStructure(this.Game.GameInstance.Controller, "Char", [0x40, 0x38]) ; Push AreaTransitioner, <IsTransitioning>k__BackingField
        ;=================
        ;Screen Resolution
        ;=================
        this.Game.ActiveScreen := New GameObjectStructure(this.Game,, [0x10, 0x18]) ; Push screenController.activeScreen
        this.Game.ActiveScreen.Width := New GameObjectStructure(this.Game.ActiveScreen,, [0x2F4]) 
        this.Game.ActiveScreen.Height := New GameObjectStructure(this.Game.ActiveScreen,, [0x2F8])
        ;=========================================================
        ;herohandler - champion related information accessed by ID
        ;=========================================================
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler,, [0x18, 0x10]) ;Push heroes._items
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCountAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x220, 0x30]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.HealthAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList, "Double", [0x350]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SlotAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x2F0]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.BenchAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x2FC]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.LevelAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x318]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SeatAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x18, 0x130]) ; Alias
        ;=============================
        ;GameUser - userid, hash, etc. (Depricated. Used GameSettings class to access these values)
        ;=============================
        this.Game.GameUser.Hash := New GameObjectStructure(this.Game.GameUser, "UTF-16", [0x20, 0x14]) ; Push Hash.Value
        this.Game.GameUser.ID := New GameObjectStructure(this.Game.GameUser,, [0x58])
        ;==================================================
        ;userData - gems, red rubies, SB/Haste stacks, etc.
        ;==================================================
        this.Game.GameInstance.Controller.UserData.Gems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x224]) ; Push redRubies
        this.Game.GameInstance.Controller.UserData.GemsSpent := New GameObjectStructure(this.Game.GameInstance.Controller.UserData,, [0x228]) ; Push redRubiesSpent
        this.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x290])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2F0])
        this.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.StatHandler,, [0x2F4])
        ;======================================================================================
        ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
        ;======================================================================================
        this.Game.GameInstance.ActiveCampaignData := New GameObjectStructure(this.Game.GameInstance,, [0x20])
        ;TODO which location shows current level first?
        this.Game.GameInstance.ActiveCampaignData.CurrentArea := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x28])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x18])
        this.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentObjective,, [0x10])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.Level := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x4C])
        this.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData.CurrentArea,, [0x54])
        this.Game.GameInstance.ActiveCampaignData.CurrentAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x88])
        ; ----
        this.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData,, [0x90])
        this.Game.GameInstance.ActiveCampaignData.Gold := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x258])
        this.Game.GameInstance.ActiveCampaignData.GoldExp := New GameObjectStructure(this.Game.GameInstance.ActiveCampaignData, "Int64", [0x260])
        ;===================================
        ;Formation save related memory reads
        ;===================================
        this.Game.GameInstance.FormationSaveHandler:= New GameObjectStructure(this.Game.GameInstance,, [0x60])
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x30, 0x10]) ; Push formationSavesV2._Items
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.Count := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler,, [0x30, 0x18]) ; Push _size
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FavoriteAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x40]) 
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList,, [0x18, 0x10]) ; Push Formation._items ; F???
        this.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationNameAlias := New GameObjectStructure(this.Game.GameInstance.FormationSaveHandler.FormationSavesList, "UTF-16", [0x30, 0x14])  ; F???
        ;=========================================================================
        ;Formation related memory reads (not save, but the in adventure formation)
        ;=========================================================================
        this.Game.GameInstance.Controller.Formation := New GameObjectStructure(this.Game.GameInstance.Controller,, [0x28])
        this.Game.GameInstance.Controller.Formation.FormationList := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x18, 0x10]) ; Push slots._Items (not confirmed, based on previous code)
        this.Game.GameInstance.Controller.Formation.FormationList.Count := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x18, 0x18]) ; Push _size (not confirmed, based on previous code)
        this.Game.GameInstance.Controller.Formation.FormationList.ChampIDAlias := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x28, 0x18, 0x10]) ; Hero-def-ID
        this.Game.GameInstance.Controller.Formation.FormationList.HeroAliveAlias := New GameObjectStructure(this.Game.GameInstance.Controller.Formation.FormationList,, [0x251])
        this.Game.GameInstance.Controller.Formation.numAttackingMonstersReached := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x198])
        this.Game.GameInstance.Controller.Formation.numRangedAttackingMonsters := New GameObjectStructure(this.Game.GameInstance.Controller.Formation,, [0x19C])
        ;==============================
        ;offlineprogress and modronsave
        ;==============================        
        this.Game.GameInstance.OfflineProgressHandler := New GameObjectStructure(this.Game.GameInstance,, [0x80])
        this.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0xD0])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x40])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x50])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x54])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.FinishedOfflineProgress := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave, "Char", [0xFC]) ; Push finishedOfflineProgressType ; F???
        ;=================
        ;Screen and UI
        ;=================
        this.Game.GameInstance.Screen := New GameObjectStructure(this.Game.GameInstance,, [0x10])
        this.Game.GameInstance.Screen.uiController := New GameObjectStructure(this.Game.GameInstance.Screen,, [0x350])
        this.Game.GameInstance.Screen.uiController.topBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController,, [0x18])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar,, [0x2F8])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox,, [0x330])
        this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled := New GameObjectStructure(this.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar, "Char", [0x300, 0x352]) ; Push autoProgressButton.toggled
    }
} 
#include IC_ArrayFunctions.ahk
; GameManager class contains the in game data structure layout
;Script Date := "10/30/21"
;Script Ver := "v0.410"

; An Alias is crusedeated when a list is used between the main structure and the offsets added. I.e. When the full offsets are in the form of [ParentFullOffsets, 0x10 + ( listItemIndex * 0x4 ) , PostListOffsets]
; Aliases should not use .GetOffSets(). Instead, they should be built as seen above. 
;==================
;structure pointers
;==================
class GameManager
{
    __new()
    {
        ;=========================================
        ;Base addresses and Handlers
        ;=========================================
        This.GameManager := New GameObjectStructure([0x658])
        this.Game := New GameObjectStructure(This.GameManager,, [0xA0]) ; GameManager skipped because the only thing besides game taht is used is TimeScale. Simplifies structure
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
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler,, [0xC, 0x8]) ;Push heroes._items
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCountAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x110, 0x18]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.HealthAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList, "Double", [0x1E0]) ; Alias 
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SlotAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x184]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.BenchAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x190]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.LevelAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x1AC]) ; Alias
        this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SeatAlias := New GameObjectStructure(this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList,, [0x0C, 0xD0]) ; Alias
        ;=============================
        ;GameUser - userid, hash, etc.
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

        ;==============================
        ;offlineprogress and modronsave
        ;==============================        
        this.Game.GameInstance.OfflineProgressHandler := New GameObjectStructure(this.Game.GameInstance,, [0x40])
        this.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x98])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler,, [0x20])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x2C])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave,, [0x30])
        this.Game.GameInstance.OfflineProgressHandler.ModronSave.FinishedOfflineProgress := New GameObjectStructure(this.Game.GameInstance.OfflineProgressHandler.ModronSave, "Char", [0xFC]) ; Push finishedOfflineProgressType
    }
} 

class GameObjectStructure
{
    FullOffsets := Array()
    Offsets := Array()
    ValueType := "Int"
    Name := ""
    GetOffsets()
    {
        return this.FullOffsets
    }

     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*)
    {
        if(!appendedOffsets[1])
        {
            this.ValueType := ValueType
            this.FullOffsets.Push(baseStructureOrFullOffsets*)
            this.Offsets.Push(baseStructureOrFullOffsets*)
        }
        else
        {
            this.ValueType := ValueType
            this.FullOffsets.Push(ArrFnc.Concat(baseStructureOrFullOffsets.GetOffsets(), appendedOffsets[1])*)
            this.Offsets.Push(appendedOffsets[1]*)
            this.ParentStructure := baseStructureOrFullOffsets.Clone()
        }
    }

    Clone()
    {
        var := new GameObjectStructure
        var.Offsets := this.Offsets.Clone()
        var.FullOffsets := this.FullOffsets.Clone()
        var.ParentStructure := this.ParentStructure.Clone()
        return var
    }
}
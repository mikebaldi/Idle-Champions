Gui, ICScriptHub:Tab, Memory View
;GuiControl, Choose, ModronTabControl, MemoryView

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y68, Memory Reads:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, ReadCurrentZone:
Gui, ICScriptHub:Add, Text, vReadCurrentZoneID x+2 w100,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadHighestZone:
Gui, ICScriptHub:Add, Text, vReadHighestZoneID x+2 w100,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTimeScaleMultiplier:
Gui, ICScriptHub:Add, Text, vReadTimeScaleMultiplierID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadUncappedTimeScaleMultiplier:
Gui, ICScriptHub:Add, Text, vReadUncappedTimeScaleMultiplierID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadQuestRemainin:
Gui, ICScriptHub:Add, Text, vReadQuestRemainingID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTransitioning:
Gui, ICScriptHub:Add, Text, vReadTransitioningID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTransitionDelay:
Gui, ICScriptHub:Add, Text, vReadNewAreaID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadSecSinceStart:
Gui, ICScriptHub:Add, Text, vReadSecSinceStartID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadAreaActive:
Gui, ICScriptHub:Add, Text, vReadAreaActiveID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadMonstrSpawned:
Gui, ICScriptHub:Add, Text, vReadMonstersSpawnedID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadSBStacks:
Gui, ICScriptHub:Add, Text, vReadSBStacksID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadHasteStacks:
Gui, ICScriptHub:Add, Text, vReadHasteStacksID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadResetting:
Gui, ICScriptHub:Add, Text, vReadResettingID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadInstanceID:
Gui, ICScriptHub:Add, Text, vReadInstanceIDID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadScreenWidth:
Gui, ICScriptHub:Add, Text, vReadScreenWidthID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadScreenHeight:
Gui, ICScriptHub:Add, Text, vReadScreenHeightID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadCoreTargetArea: 
Gui, ICScriptHub:Add, Text, vReadCoreTargetAreaID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadGems:
Gui, ICScriptHub:Add, Text, vReadGemsID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadGemsSpent:
Gui, ICScriptHub:Add, Text, vReadGemsSpentID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadRedGems:
Gui, ICScriptHub:Add, Text, vReadRedGemsID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadChampLvlByID:
Gui, ICScriptHub:Add, Text, vReadChampLvlByIDID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadChampBenchedByID:
Gui, ICScriptHub:Add, Text, vReadChampBenchedByIDID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadCurrentObjID:
Gui, ICScriptHub:Add, Text, vReadCurrentObjIDID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadFormationSavesSize:
Gui, ICScriptHub:Add, Text, vReadFormationSavesSizeID x+2 w200,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadFormationFavoriteIDBySlot:
Gui, ICScriptHub:Add, Text, vReadFormationFavoriteIDBySlotID x+2 w200,

; Primary Memory Read
class ReadMemoryFunctions
{
    CheckReads()
    {
        this.MainReads()
    }

    MainReads()
    {
        champID := 58
        GuiControl, ICScriptHub:, ReadCurrentZoneID, % g_SF.Memory.ReadCurrentZone()
        GuiControl, ICScriptHub:, ReadHighestZoneID, % g_SF.Memory.ReadHighestZone()
        GuiControl, ICScriptHub:, ReadQuestRemainingID, % g_SF.Memory.ReadQuestRemaining()
        GuiControl, ICScriptHub:, ReadTimeScaleMultiplierID, % g_SF.Memory.ReadTimeScaleMultiplier()
        GuiControl, ICScriptHub:, ReadUncappedTimeScaleMultiplierID, % g_SF.Memory.ReadUncappedTimeScaleMultiplier()
        GuiControl, ICScriptHub:, ReadTransitioningID, % g_SF.Memory.ReadTransitioning()
        GuiControl, ICScriptHub:, ReadSBStacksID, % g_SF.Memory.ReadSBStacks()
        GuiControl, ICScriptHub:, ReadHasteStacksID, % g_SF.Memory.ReadHasteStacks()
        GuiControl, ICScriptHub:, ReadResettingID, % g_SF.Memory.ReadResetting()
        GuiControl, ICScriptHub:, ReadInstanceIDID, % g_SF.Memory.ReadInstanceID()
        GuiControl, ICScriptHub:, ReadScreenWidthID, % g_SF.Memory.ReadScreenWidth()
        GuiControl, ICScriptHub:, ReadScreenHeightID, % g_SF.Memory.ReadScreenHeight()
        GuiControl, ICScriptHub:, ReadMonstersSpawnedID, % g_SF.Memory.ReadMonstersSpawned()
        GuiControl, ICScriptHub:, ReadCoreTargetAreaID, % g_SF.Memory.GetCoreTargetAreaByInstance(g_SF.Memory.ReadActiveGameInstance())
        GuiControl, ICScriptHub:, ReadGemsID, % g_SF.Memory.ReadGems()
        GuiControl, ICScriptHub:, ReadGemsSpentID, % g_SF.Memory.ReadGemsSpent()
        GuiControl, ICScriptHub:, ReadRedGemsID, % g_SF.Memory.ReadRedGems()
        GuiControl, ICScriptHub:, ReadChampLvlByIDID, % "ChampID: " . champID . ", Level: " . g_SF.Memory.ReadChampLvlByID(champID)
        GuiControl, ICScriptHub:, ReadChampBenchedByIDID, % "ChampID: " . champID . ", Benched: " . g_SF.Memory.ReadChampBenchedByID(champID)
        GuiControl, ICScriptHub:, ReadCurrentObjIDID, % g_SF.Memory.ReadCurrentObjID()
        GuiControl, ICScriptHub:, ReadFormationSavesSizeID, % g_SF.Memory.ReadFormationSavesSize()
        GuiControl, ICScriptHub:, ReadFormationFavoriteIDBySlotID, % "ID: 1, Favorite: " . g_SF.Memory.ReadFormationFavoriteIDBySlot(1)
        GuiControl, ICScriptHub:, ReadNewAreaID, % g_SF.Memory.ReadTransitionDelay()
        GuiControl, ICScriptHub:, ReadSecSinceStartID, % g_SF.Memory.ReadSecondsSinceAreaStart()
        GuiControl, ICScriptHub:, ReadAreaActiveID, % g_SF.Memory.ReadAreaActive()
    }
}
;======================================================================================
; Unused
;======================================================================================
    
    ; Gui, ICScriptHub:Add, Text, x15 y+5, ReadChampLvlBySlot: 
    ; Gui, ICScriptHub:Add, Text, vReadChampLvlBySlotID x+2 w300,
    ; Gui, ICScriptHub:Add, Text, x15 y+5, ReadChampSeatBySlot: 
    ; Gui, ICScriptHub:Add, Text, vReadChampSeatBySlotID x+2 w300,
    ; Gui, ICScriptHub:Add, Text, x15 y+5, ReadChampIDBySlot: 
    ; Gui, ICScriptHub:Add, Text, vReadChampIDBySlotID x+2 w300,

    ;ReadChampLvlBySlot(3)
    ;ReadChampSeatBySlot(3)
    ;ReadChampIDBySlot(3)

    ;ReadClickFamiliarBySlot(0)
    ;ReadHeroAliveBySlot(3)

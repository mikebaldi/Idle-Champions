#include IC_GameManagerClass.ahk
;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
global g_mfScriptDate := "11/02/21"
global g_mfScriptVer := "v0.410"
GetIC_MemoryFunctionsVersion()
{
    return "v1.0, 11/02/21, IC v0.410, Steam"
}

global g_idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)

;Game Controller Structure
global g_moduleBase :=
global g_gameManager := new GameManager

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored.
OpenProcess()
{
    g_idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
}

ModuleBaseAddress()
{
    g_moduleBase := g_idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
    return g_moduleBase
}

;=================
;General Purpose Calls
;=================

;, GUILabel := ReadCurrentZoneID, ValueType := OffsetValue :=
GenericGetValue(UpdateGUI, GUIwindow, LblGUI, GameObject)
{
    if(GameObject.ValueType == "UTF-16")
    {
        var := g_idle.readstring(g_moduleBase, bytes := 0, GameObject.ValueType, (GameObject.GetOffsets())*)
    }
    else
    {
        var := g_idle.read(g_moduleBase, GameObject.ValueType, (GameObject.GetOffsets())*)
    }
    if(GameObject.ValueType == "Double" or GameObject.ValueType == "Float")
    {
        var := Round(var, 3)
    }
    if UpdateGUI
            UpdateGUI(GUIwindow, LblGUI, var )
    return var
}

GenericGetListValue(UpdateGUI, GUIwindow, LblGUI, GameObject, ItemID, isListAlias := 0, ItemOffset := 1)
{
    if(isListAlias)
    {
        offsets := ArrFnc.Concat(GameObject.ParentStructure.GetOffsets(), ArrFnc.Concat([getListItemOffset( ItemID, ItemOffset )], GameObject.Offsets))
    }
    else
    {
        offsets := GameObject.GetOffsets()
    }
    if(GameObject.ValueType == "UTF-16")
    {
        var := g_idle.readstring(g_moduleBase, bytes := 0, GameObject.ValueType, offsets*)
    }
    else
    {
        var := g_idle.read(g_moduleBase, GameObject.ValueType, offsets*)
    }
    if(GameObject.ValueType == "Double" or GameObject.ValueType == "Float")
    {
        var := Round(var, 3)
    }
    if UpdateGUI
            UpdateGUI(GUIwindow, LblGUI, var )
    return var
}

UpdateGUI(GUIwindow, LblGUI, StatusTxt* )
{

    StatusTxt := StatusTxt[1]
    stringBuil := ""
    if(IsObject(StatusTxt))
    {
        arrayString := BuildStatus(StatusTxt)
    }
    if(arrayString == "")
    {
        GuiControl, %GUIwindow%, %LblGUI%, %StatusTxt% 
    }
    else
    {
        GuiControl, %GUIwindow%, %LblGUI%, %arrayString% 
    }
}

BuildStatus(StatusTxt)
{
    i := StatusTxt.Count()
    stringVal := ""
    loop, %i%
    {
            stringVal .= StatusTxt[A_Index] . " "
    }
    RTrim(stringVal, " ")
    return stringVal
}

;Test function used to verify data is working properly
Test1(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    memoryDict := { "ReadBriv": ReadSBStacks()
                  , "ReadBV" : ReadRedGems() }

    ;val := memoryDict.ReadBV
    ;MsgBox, %val%
    ; for k, v in memoryDict
    ; {
    ;     val := v
    ;     var := ArrFnc.GetHexFormattedArrayString(v.GetOffsets())
    ;     MsgBox, %k% : %val%
    ; }
}
;=========================================
;until I find a better spot here these are
;=========================================

ReadGameStarted(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadGameStartedID",  g_gameManager.Game.GameStarted)
}

ReadMonstersSpawned(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadMonstersSpawnedID", g_gameManager.Game.GameInstance.Controller.Area.MonsterSpawned)
}

ReadResettting(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadResettingID", g_gameManager.Game.GameInstance.Controller.ResetHandler.Resetting)
}

ReadResetting(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return ReadResettting(UpdateGUI, GUIwindow)
}

ReadTimeScaleMultiplier(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadTimeScaleMultiplierID", g_gameManager.GameManager.TimeScale )
}

ReadTransitioning(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadTransitioningID", g_gameManager.Game.GameInstance.Controller.AreaTransition)
}

;=================
;Screen Resolution
;=================

ReadScreenWidth(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadScreenWidthID", g_gameManager.Game.ActiveScreen.Width)
}

ReadScreenHeight(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadScreenHeightID", g_gameManager.Game.ActiveScreen.Height)
}

;=========================================================
;herohandler - champion related information accessed by ID
;=========================================================
ReadChampUpgradeCountByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID:= 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampUpgradeCountByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCountAlias, ChampID, isAlias := 1)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadChampUpgradeCountByIDID, `ID: %ChampID% `Count: %var%
    return var
}

ReadChampHealthByID( UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0 )
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampHealthByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.HealthAlias, ChampID, isAlias := 1)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadChampHealthByIDID, `ID: %ChampID% Alive: %var%
    return var
}

ReadChampSlotByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampSlotByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SlotAlias, ChampID, isAlias := 1)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadChampSlotByIDID, `ID: %ChampID% Slot: %var% 
    return var
}

ReadChampBenchedByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampBenchedByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.BenchAlias, ChampID, isAlias := 1)
    if UpdateGUI
        ;GuiControl, %GUIwindow%, ReadChampBenchedByIDID, `ID: %ChampID% Benched: %var% 
        UpdateGUI(GUIWindow, "ReadChampBenchedByIDID", ["ID:", ChampID, "Benched:", var])
    return var
}

ReadChampLvlByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID:= 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampLvlByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.LevelAlias, ChampID, isAlias := 1)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadChampLvlByIDID, `ID: %ChampID% Lvl: %var%
    return var
}

ReadChampSeatByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadChampSeatByIDID", g_gameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.SeatAlias, ChampID, isAlias := 1)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadChampSeatByIDID, `ID: %ChampID% Seat: %var% 
    return var
}

;=============================
;GameUser - userid, hash, etc.
;=============================

ReadUserID(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadUserIDID", g_gameManager.Game.GameUser.ID)
}

ReadUserHash(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadUserHashID", g_gameManager.Game.GameUser.Hash)
}

;==================================================
;userData - gems, red rubies, SB/Haste stacks, etc.
;==================================================

ReadGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadGemsID", g_gameManager.Game.GameInstance.Controller.UserData.Gems)
}

ReadGemsSpent(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadGemsSpentID", g_gameManager.Game.GameInstance.Controller.UserData.GemsSpent)
}

ReadRedGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadRedGemsID", g_gameManager.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems) ; BlackViper Red Gems
}

ReadSBStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadSBStacksID", g_gameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks)
}

ReadHasteStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadHasteStacksID", g_gameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks)
}

;======================================================================================
;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
;======================================================================================

ReadCurrentObjID(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadCurrentObjIDID", g_gameManager.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID)
}

ReadQuestRemaining(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadQuestRemainingID", g_gameManager.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining)
}

ReadCurrentZone(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadCurrentZoneID", g_gameManager.Game.GameInstance.ActiveCampaignData.CurrentAreaID)
}

ReadHighestZone(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadHighestZoneID", g_gameManager.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID)
}

;gold memory read functions, very limited testing done
;reads the first 8 bytes of the quad value of gold
ReadGoldFirst8Bytes(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadGoldFirst8BytesID", g_gameManager.Game.GameInstance.ActiveCampaignData.Gold)
}

;reads the last 8 bytes of the quad value of gold
ReadGoldSecond8Bytes(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadGoldSecond8BytesID", g_gameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
}

ReadGoldString(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    FirstEight := GenericGetValue(0, GUIwindow, "", g_gameManager.Game.GameInstance.ActiveCampaignData.Gold)
    SecondEight := GenericGetValue(0, GUIwindow, "", g_gameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
    stringVar := ConvQuadToString(FirstEight, SecondEight)
    if UpdateGUI
        GuiControl, %GUIwindow%, GoldStringID, %stringVar% 
    return stringVar 
}

;===================================
;Formation save related memory reads
;===================================
;read the number of saved formations for the active campaign
ReadFormationSavesSize(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadFormationSavesSizeID",  g_gameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Count)
}

;reads if a formation save is a favorite
;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
ReadFormationFavoriteIDBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0 )
{
    var := GenericGetListValue(0, GUIwindow, "ReadFormationFavoriteIDBySlotID", g_gameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.FavoriteAlias, slot, isAlias := 1, ItemOffset := 0)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadFormationFavoriteIDBySlotID, ` slot: %Slot% Favorite: %var%   
    return var
}

;read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot
;when parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array
ReadFormationSaveBySlot( UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0, ignoreEmptySlots := 0 )
{
    ;[ Item[ slot ], Formation, _items ]
    gameObject := new GameObjectStructure(g_gameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList,,[ getListItemOffset( slot, 0 ), 0xC, 0x8 ])
    gameObjectSize := new GameObjectStructure(g_gameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList,,[ getListItemOffset( slot, 0 ), 0xC, 0xC ])
    _size := GenericGetValue(0,"","",gameObjectSize)
    Formation := Array()
    loop, %_size%
    {
        ;[Item[i]]
        tempObject := new GameObjectStructure(gameObject, "Int", [ getListItemOffset( A_Index, 1 )])
        champID := GenericGetValue(0,"","", tempObject)
        if (!ignoreEmptySlots or champID != -1)
        {
            Formation.Push( champID )
        }
    }
    if UpdateGUI
    {
        var := ArrFnc.GetDecFormattedArrayString(Formation)
        GuiControl, %GUIwindow%, ReadFormationSaveBySlotID, slot: %Slot% Formation: %var%  
    }
    return Formation
}

ReadFormationNameBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    var := GenericGetListValue(0, GUIwindow, "ReadFormationNameBySlotID", g_gameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationNameAlias, slot, isAlias := 1, ItemOffset := 0)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadFormationNameBySlotID, slot: %slot% Name: %var%    
    return var
}

;==============================
;offlineprogress and modronsave
;==============================

ReadFinishedOfflineProgressWindow(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadFinishedOfflineProgressWindowID", g_gameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.FinishedOfflineProgress)
}

ReadMonstersSpawnedThisAreaOL(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadMonstersSpawnedThisAreaOLID",  g_gameManager.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea)
}

ReadCoreXP(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadCoreXPID", g_gameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal)
}

ReadCoreTargetArea(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    return GenericGetValue(UpdateGUI, GUIwindow, "ReadCoreTargetAreaID", g_gameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea)
}

;==============
;Helper Methods
;==============
;used for getting offset of an item in a list when list starts at 0, used for most lists
getListItemOffset( listItem, listStartValue )
{
    listItem -= listStartValue
    return 0x10 + ( listItem * 0x4 )
}

ConvQuadToString(FirstEight, SecondEight)
{
    var := (FirstEight + (2.0**63)) * (2.0**SecondEight)
    exponent := log(var)
    stringVar := Round((SubStr(var, 1 , 3) / 100), 2)  . "e" . Floor(exponent)  
    return stringVar 
}
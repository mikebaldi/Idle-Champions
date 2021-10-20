;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
global mfScriptDate := "10/19/21"
global mfScriptVer := "v0.407.1 untested"

global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)

;Game Controller Structure
global pointerBaseController :=
global arrayPointerOffsetsController := [0x658, 0xA0, 0x28, 0x8]

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored.
OpenProcess()
{
    idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
}

ModuleBaseAddress()
{
    pointerBaseController := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
    return pointerBaseController
}

ReadCurrentZone(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x14, 0x28]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCurrentZoneID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadHighestZone(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x4C]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadHighestZoneID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

;not used
ReadAreaLevel(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xC, 0x24, 0x28]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadAreaLevelID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x130]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGemsID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadGemsSpent(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x134]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGemsSpentID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadRedGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x18, 0x260]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadRedGemsID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadQuestRemaining(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x14, 0x30]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadQuestRemainingID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadTimeScaleMultiplier(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0xE8]
    var := Round(idle.read(Controller, "Float", pointerArray*), 3)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadTimeScaleMultiplierID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadTransitioning(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x20, 0x1C]
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, MyWindow:, ReadTransitioningID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadSBStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x18, 0x2C0]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    {
        GuiControl, %GUIwindow%, ReadSBStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
        GuiControl, %GUIwindow%, gStackCountSBID, %var%
    }
    return var
}

ReadHasteStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x18, 0x2C4]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    {
        GuiControl, %GUIwindow%, ReadHasteStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
        GuiControl, %GUIwindow%, gStackCountHID, %var%
    }
    return var
}

ReadCoreXP(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x40, 0x20, 0x2C]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCoreXPID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

;core reads via user data
;pointerArray := [0x50, 0x6C, 0x10]
;var := 0x10 + (slot * 0x4)
;InstanceID
;pointerArray.Push(var, 0x28)
;ExpTotal
;pointerArray.Push(var, 0x24)
;targetArea
;pointerArray.Push(var, 0x30)

ReadCoreTargetArea(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x40, 0x20, 0x2C]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCoreTargetAreaID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadResettting(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x1C, 0x1C]
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadResettingID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadUserID(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x54, 0x30]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadUserIDID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadUserHash(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x54, 0x10, 0xC]
    var := idle.readstring(Controller, bytes := 64, encoding := "UTF-16", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadUserHashID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadScreenWidth(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x8, 0x1FC]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadScreenWidthID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadScreenHeight(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x8, 0x200]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadScreenHeightID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampLvlBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x14, 0xC, 0x8]
    var := 0x10 + (slot * 0x4)
    pointerArray.Push(var, 0x14, 0x1A8)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampLvlBySlotID, Slot: %slot% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampSeatBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x14, 0xC, 0x8]
    var := 0x10 + (slot * 0x4)
    pointerArray.Push(var, 0x14, 0xC, 0xD0)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampSeatBySlotID, Slot: %slot% Seat: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampIDbySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x14, 0xC, 0x8]
    var := 0x10 + (slot * 0x4)
    pointerArray.Push(var, 0x14, 0xC, 0x8)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampIDbySlotID, Slot: %slot% `ID: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampLvlByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x1A8)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampLvlByIDID, `ID: %ChampID% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampUpgradeCountByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    ;[userData, HeroHandler, heroes, _items]
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    ;[Item[#]]
    var := 0x10 + (ChampID * 0x4)
    ;[purchasedUpgradeIDs, _count]
    pointerArray.Push(var, 0x110, 0x18)
    _count := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampUpgradeCountByIDID, `ID: %ChampID% `Count: %_count% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return _count
}

ReadChampSeatByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0xC, 0xD0)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampSeatByIDID, `ID: %ChampID% Seat: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampSlotByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x180)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampSlotByIDID, `ID: %ChampID% Slot: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadChampBenchedByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x18C)
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampBenchedByIDID, `ID: %ChampID% Benched: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadMonstersSpawned(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xC, 0x148]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadMonstersSpawnedID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadCurrentObjID(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0xC, 0x8]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCurrentObjIDID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadHeroAliveBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x14, 0xC, 0x8]
    var := 0x10 + (slot * 0x4)
    pointerArray.Push(var, 0x151)
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadHeroAliveBySlotID, slot: %Slot% heroAlive: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

;untested
ReadChampAliveByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x151)
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampAliveByIDID, `ID: %ChampID% Alive: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

;gold memory read functions, very limited testing done
;reads the first 8 bytes of the quad value of gold
ReadGoldFirst8Bytes(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x210]
    var := idle.read(Controller, "Int64", pointerArray*)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadGoldFirst8BytesID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

;reads the last 8 bytes of the quad value of gold
ReadGoldSecond8Bytes(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x218]
    var := idle.read(Controller, "Int64", pointerArray*)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadGoldSecond8BytesID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}

ReadGameStarted(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    ;[game, gameStarted]
    pointerArray := [0x10, 0x7C]
    gameStarted := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGameStartedID, %gameStarted% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return gameStarted
}

ReadFinishedOfflineProgressWindow(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    ;[<gameInstance>k__BackingField, offlineProgressHandler, finishedOfflineProgressWindow]
    pointerArray := [0x8, 0x40, 0xFA]
    finishedOfflineProgressWindow := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadFinishedOfflineProgressWindowID, %finishedOfflineProgressWindow% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return finishedOfflineProgressWindow
}

ReadMonstersSpawnedThisAreaOL(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    ;[<gameInstance>k__BackingField, offlineProgressHandler, monsterSpawnedThisArea]
    pointerArray := [0x8, 0x40, 0x98]
    monstersSpawnedThisArea := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadMonstersSpawnedThisAreaOLID, %monstersSpawnedThisArea% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return monstersSpawnedThisArea
}



;===================================
;Formation save related memory reads
;===================================
;read the number of saved formations for the active campaign
ReadFormationSavesSize( UpdateGUI := 0, GUIwindow := "MyWindow:" )
{
    pointerArray := FormationSavesV2()
    ;_size
    pointerArray.Push(0xC)
    var := idle.read(pointerBaseController, "Int", pointerArray*)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadFormationSavesSizeID, %var%    %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}
++ICmemoryFunctionsCount

;reads if a formation save is a favorite
;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
ReadFormationFavoriteIDBySlot( UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0 )
{
    pointerArray := FormationSavesV2List()
    ;[ Item[ slot ], Favorite ]
    pointerArray.Push( getListItemOffset( slot, 0 ), 0x24 )
    var := idle.read(pointerBaseController, "Int", pointerArray*)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadFormationFavoriteIDBySlotID, slot: %Slot% Favorite: %var%    %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}
++ICmemoryFunctionsCount

;read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot
;when parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array
ReadFormationSaveBySlot( UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0, ignoreEmptySlots := 0 )
{
    pointerArray := FormationSavesV2List()
    ;[ Item[ slot ], Formation, _items ]
    pointerArray.Push( getListItemOffset( slot, 0 ), 0xC, 0x8 )
    ;for reading size of formation
    pointerArray_size := pointerArray.Clone()
    ;remove _items
    pointerArray_size.Pop()
    ;[ _size ]
    pointerArray_size.Push( 0xC )
    _size := idle.read( pointerBaseController, "Int", pointerArray_size* )
    Formation := {}
    i := 0
    loop, %_size%
    {
        ;[Item[i]]
        pointerArray.Push( getListItemOffset( i, 0 ) )
        champID := idle.read(pointerBaseController, "Int", pointerArray*)
        if !ignoreEmptySlots
        {
            Formation.Push( champID )
        }
        else if ( champID != -1 )
        {
            Formation.Push( champID )
        }
        pointerArray.Pop()
        ++i
    }
    if UpdateGUI
    {
        var := "[ "
        var2 := Formation.Count()
        loop, %var2%
        {
            if ( A_Index < var2 )
            var .= Formation[A_Index] . ", "
            Else
            var .= Formation[A_Index]
        }
        GuiControl, %GUIwindow%, ReadFormationSaveBySlotID, slot: %Slot% Formation: %var% ]   %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    }
    return Formation
}
++ICmemoryFunctionsCount

;reads the name of a formation by a given slot
ReadFormationNameBySlot( UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0 )
{
    pointerArray := FormationSavesV2List()
    ;[Item[slot], Name, Length]
    pointerArray.Push( getListItemOffset( slot, 0 ), 0x18, 0xC )
    ;if they suddenly become not null terminated strings, use the read below, length of string is at OS 0x8
    var := idle.readstring(pointerBaseController, length := 0, encoding := "UTF-16", pointerArray*)
    if UpdateGUI
        GuiControl, %GUIwindow%, ReadFormationNameBySlotID, slot: %Slot% Name: %var%    %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
    return var
}
++ICmemoryFunctionsCount

;==============
;Helper Methods
;==============
;used for getting offset of an item in a list when list starts at 0, used for most lists
getListItemOffset( listItem, listStartValue )
{
    listItem -= listStartValue
    return 0x10 + ( listItem * 0x4 )
}

;==================
;structure pointers
;==================
Game()
{
    ;offsetArray := ["test1", "test2"]
    return [0x658, 0xA0]
}

    GameUser()
    {
        offsetArray := Game()
        offsetArray.Push( 0x54 )
        return offsetArray
    }
    
    ChampionsGameInstance()
    {
        offsetArray := Game()
        ;[ gameInstances, _items, Item[0] ]
        offsetArray.Push( 0x58, 0x8, 0x10 )
        return offsetArray
    }

        Screen()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0x8 )
            return offsetArray
        }

        Controller()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0xC )
            return offsetArray
        }

            area()
            {
                offsetArray := Controller()
                offsetArray.Push( 0xC )
                return offsetArray
            }

            areaTransitioner()
            {
                offsetArray := Controller()
                offsetArray.Push( 0x20 )
                return offsetArray
            }

            userData()
            {
                offsetArray := Controller()
                offsetArray.Push( 0x50 )
                return offsetArray
            }

                HeroHandler()
                {
                    offsetArray := userData()
                    offsetArray.Push( 0x8 )
                    return offsetArray
                }

                    heroesList()
                    {
                        offsetArray := HeroHandler()
                        ;[ heroes, _items ]
                        offsetArray.Push( 0xC, 0x8 )
                        return offsetArray
                    }

        ActiveCampaignData()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0x10 )
            return offsetArray
        }

            currentArea()
            {
                offsetArray := ActiveCampaignData()
                offsetArray.Push( 0x14 )
                return offsetArray
            }

        ResetHandler()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0x1C )
            return offsetArray
        }

        FormationSaveHandler()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0x30 )
            return offsetArray
        }

            FormationSavesV2()
            {
                offsetArray := FormationSaveHandler()
                offsetArray.Push( 0x18 )
                return offsetArray
            }

                FormationSavesV2List()
                {
                    offsetArray := FormationSavesV2()
                    ;[ _items ]
                    offsetArray.Push( 0x8 )
                    return offsetArray
                }

                FormationSavesV2Formation()
                {
                    return 0xC
                }

                    FormationSavesV2FormationList()
                    {
                        offsetArray := FormationSavesV2Formation()
                        ;[ _items ]
                        offsetArray.Push( 0x8 )
                        return offsetArray
                    }

        offlineProgressHandler()
        {
            offsetArray := ChampionsGameInstance()
            offsetArray.Push( 0x40 )
            return offsetArray
        }

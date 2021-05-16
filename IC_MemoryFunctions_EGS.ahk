;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 5/16/21
;Epic Games IC Version v0.389

global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)

;Game Controller Structure
global pointerBaseController :=
global arrayPointerOffsetsController := [0x150, 0xD38, 0x18]

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
    pointerBaseController := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493DE8
}

ReadCurrentZone(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x30, 0x28, 0x4C]
	var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCurrentZoneID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x21C]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGemsID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadGemsSpent(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x220]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGemsSpentID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadRedGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x30, 0x280]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadRedGemsID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadQuestRemaining(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x30, 0x28, 0x54]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadQuestRemainingID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadTimeScaleMultiplier(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x168]
    var := Round(idle.read(Controller, "Float", pointerArray*), 3)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadTimeScaleMultiplierID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadTransitioning(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x40, 0x38]
	var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
	GuiControl, MyWindow:, ReadTransitioningID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadSBStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x30, 0x2E0]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadSBStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadHasteStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x30, 0x2E4]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadHasteStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}
;CAN'T FIND FINAL OFFSET SINCE I DON'T HAVE A MODRON CORE ON EGS
ReadCoreXP(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x80, 0x38, 0x2C] ;0X2C IS UNLIKELY A VALID OFFSET
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCoreXPID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}
;CAN'T FIND FINAL OFFSET SINCE I DON'T HAVE A MODRON CORE ON EGS
ReadCoreTargetArea(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x80, 0x38, 0x30] ;0X30 IS UNLIKELY A VALID OFFSET
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCoreTargetAreaID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadResettting(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x38, 0x38]
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadResettingID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadUserID(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x20, 0xA8, 0x58]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadUserIDID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadUserHash(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x20, 0xA8, 0x20, 0x14]
    var := idle.readstring(Controller, bytes := 64, encoding := "UTF-16", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadUserHashID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadScreenWidth(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x10, 0x2F4]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadScreenWidthID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadScreenHeight(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x10, 0x10, 0x2F8]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadScreenHeightID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampLvlBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x28, 0x18, 0x10]
    var := 0x20 + (slot * 0x8)
    pointerArray.Push(var, 0x28, 0x2E0)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampLvlBySlotID, Slot: %slot% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampSeatBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x28, 0x18, 0x10]
    var := 0x20 + (slot * 0x8)
    pointerArray.Push(var, 0x28, 0x10, 0x120)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampSeatBySlotID, Slot: %slot% Seat: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampIDbySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x28, 0x18, 0x10]
    var := 0x20 + (slot * 0x8)
    pointerArray.Push(var, 0x28, 0x10, 0x10)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampIDbySlotID, Slot: %slot% `ID: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampLvlByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x10, 0x18, 0x10]
    --ChampID
    var := 0x20 + (ChampID * 0x8)
    pointerArray.Push(var, 0x2E0)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampLvlByIDID, `ID: %ChampID% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampSeatByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0xA0, 0x10, 0x18, 0x10]
    --ChampID
    var := 0x20 + (ChampID * 0x8)
    pointerArray.Push(var, 0x10, 0x120)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    ++ChampID
    GuiControl, %GUIwindow%, ReadChampSeatByIDID, `ID: %ChampID% Seat: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadMonstersSpawned(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x18, 0x228]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadMonstersSpawnedID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadCurrentObjID(UpdateGUI := 0, GUIWindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x30, 0x18, 0x10]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCurrentObjIDID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadClickFamiliarBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x70, 0x328, 0x10]
    var := 0x20 + (slot * 0x8)
    pointerArray.Push(var, 0x2E8, 0x1D8)
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadClickFamiliarBySlotID, slot: %Slot% objectActive: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadHeroAliveBySlot(UpdateGUI := 0, GUIwindow := "MyWindow:", slot := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x28, 0x18, 0x10]
    var := 0x20 + (slot * 0x8)
    pointerArray.Push(var, 0x229)
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadHeroAliveBySlotID, slot: %Slot% heroAlive: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}
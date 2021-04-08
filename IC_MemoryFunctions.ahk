;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 4/8/21
;IC Version v0.383.2

global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)

;Game Controller Structure
global pointerBaseController :=
global arrayPointerOffsetsController := [0x658, 0xA0, 0x28, 0x8]

;shandie level direct (int)
global arrayPointerOffsetsShandieLvl := [0x50, 0x8, 0xC, 0x8, 0xC8, 0x190]

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

ReadGems(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x128]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadGemsID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
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
    pointerArray := [0x50, 0x18, 0x2B0]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadSBStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadHasteStacks(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x18, 0x2B4]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadHasteStacksID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadCoreXP(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x40, 0x1C, 0x2C]
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadCoreXPID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadResettting(UpdateGUI := 0, GUIwindow := "MyWindow:")
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x8, 0x1C, 0x1C]
    var := idle.read(Controller, "Char", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadResetttingID, %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
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
    pointerArray.Push(var, 0x14, 0x190)
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
    pointerArray.Push(var, 0x14, 0x8, 0xD0)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampSeatBySlotID, Slot: %slot% Seat: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampLvlByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x190)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampLvlByIDID, `ID: %ChampID% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
	return var
}

ReadChampSeatByID(UpdateGUI := 0, GUIwindow := "MyWindow:", ChampID := 0)
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    pointerArray := [0x50, 0x8, 0xC, 0x8]
    --ChampID
    var := 0x10 + (ChampID * 0x4)
    pointerArray.Push(var, 0x8, 0xC8)
    var := idle.read(Controller, "Int", pointerArray*)
    if UpdateGUI
    GuiControl, %GUIwindow%, ReadChampSeatByIDID, `ID: %ChampID% Lvl: %var% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%
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
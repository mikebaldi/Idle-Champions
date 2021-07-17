#SingleInstance force

;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include classMemory.ahk

;Check if you have installed the class correctly.
if (_ClassMemory.__Class != "_ClassMemory")
{
	msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
	ExitApp
}

;pointer addresses and offsets
#include IC_MemoryFunctions.ahk

Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Add, Button, x415 y25 w100 gCheck_Clicked, Check Memory Structure
Gui, MyWindow:Add, Button, x415 y+100 w60 gReload_Clicked, `Reload
Gui, MyWindow:Add, Tab3, x5 y5 w400, Data|
Gui, Tab, Data
Gui, MyWindow:Add, Text, x15 y+5, ReadCurrentZone: 
Gui, MyWindow:Add, Text, vReadCurrentZoneID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadGems: 
Gui, MyWindow:Add, Text, vReadGemsID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadGemsSpent: 
Gui, MyWindow:Add, Text, vReadGemsSpentID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadRedGems: 
Gui, MyWindow:Add, Text, vReadRedGemsID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadQuestRemaining: 
Gui, MyWindow:Add, Text, vReadQuestRemainingID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadTimeScaleMultiplier: 
Gui, MyWindow:Add, Text, vReadTimeScaleMultiplierID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadTransitioning: 
Gui, MyWindow:Add, Text, vReadTransitioningID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadSBStacks: 
Gui, MyWindow:Add, Text, vReadSBStacksID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadHasteStacks: 
Gui, MyWindow:Add, Text, vReadHasteStacksID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadCoreXP: 
Gui, MyWindow:Add, Text, vReadCoreXPID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadCoreTargetArea: 
Gui, MyWindow:Add, Text, vReadCoreTargetAreaID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadResettting: 
Gui, MyWindow:Add, Text, vReadResettingID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadUserID: 
Gui, MyWindow:Add, Text, vReadUserIDID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadUserHash: 
Gui, MyWindow:Add, Text, vReadUserHashID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadScreenWidth: 
Gui, MyWindow:Add, Text, vReadScreenWidthID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadScreenHeight: 
Gui, MyWindow:Add, Text, vReadScreenHeightID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampLvlBySlot: 
Gui, MyWindow:Add, Text, vReadChampLvlBySlotID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampSeatBySlot: 
Gui, MyWindow:Add, Text, vReadChampSeatBySlotID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampIDBySlot: 
Gui, MyWindow:Add, Text, vReadChampIDBySlotID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampLvlByID: 
Gui, MyWindow:Add, Text, vReadChampLvlByIDID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampSeatByID: 
Gui, MyWindow:Add, Text, vReadChampSeatByIDID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadMonstersSpawned: 
Gui, MyWindow:Add, Text, vReadMonstersSpawnedID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadCurrentObjID: 
Gui, MyWindow:Add, Text, vReadCurrentObjIDID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadClickFamiliarBySlot: 
Gui, MyWindow:Add, Text, vReadClickFamiliarBySlotID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, ReadHeroAliveBySlot: 
Gui, MyWindow:Add, Text, vReadHeroAliveBySlotID x+2 w300,

Gui, MyWindow:Show
Return

Check_Clicked:
{
	CheckReads()
	return
}

Reload_Clicked:
{
	Reload
	return
}

MyWindowGuiClose() 
{
	MsgBox 4,, Are you sure you want to `exit?
	IfMsgBox Yes
	ExitApp
    IfMsgBox No
    return True
}

CheckReads()
{
    OpenProcess()
    ModuleBaseAddress()
    ReadCurrentZone(1)
    ReadGems(1)
    ReadGemsSpent(1)
    ReadRedGems(1)
    ReadQuestRemaining(1)
    ReadTimeScaleMultiplier(1)
    ReadTransitioning(1)
    ReadSBStacks(1)
    ReadHasteStacks(1)
    ReadCoreXP(1)
    ReadCoreTargetArea(1)
    ReadResettting(1)
    ReadUserID(1)
    ReadUserHash(1)
    ReadScreenWidth(1)
    ReadScreenHeight(1)
    ReadChampLvlBySlot(1,, 3)
    ReadChampSeatBySlot(1,, 3)
    ReadChampIDBySlot(1,, 3)
    ReadChampLvlByID(1,, 28)
    ReadChampSeatByID(1,, 28)
    ReadMonstersSpawned(1)
    ReadCurrentObjID(1)
    ReadClickFamiliarBySlot(1,, 0)
    ReadHeroAliveBySlot(1,, 3)
}
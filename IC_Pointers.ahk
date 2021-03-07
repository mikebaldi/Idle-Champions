;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 3/7/21
;IC Version v0.375.1

global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
;Game Controller
global pointerBaseController :=
global arrayPointerOffsetsController := [0x658, 0xA0, 0x28, 0x8]
;Level
global arrayPointerOffsetsLevel := [0x18, 0x14, 0x28]
;Quest Remaining
global arrayPointerOffsetsQR := [0x18, 0x14, 0x30]
;Transitioning (char)
global arrayPointerOffsetsTransitioning := [0x20, 0x1C]
;Time Scale Multiplier
global arrayPointerOffsetsTimeScaleMultiplier := [0x8, 0xE8]
;Champion level by formation slot (int)
global arrayPointerOffsetsSlotLvl0 := [0x14, 0xC, 0x8, 0x10, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl1 := [0x14, 0xC, 0x8, 0x14, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl2 := [0x14, 0xC, 0x8, 0x18, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl3 := [0x14, 0xC, 0x8, 0x1C, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl4 := [0x14, 0xC, 0x8, 0x20, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl5 := [0x14, 0xC, 0x8, 0x24, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl6 := [0x14, 0xC, 0x8, 0x28, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl7 := [0x14, 0xC, 0x8, 0x2C, 0x14, 0x190]
global arrayPointerOffsetsSlotLvl8 := [0x14, 0xC, 0x8, 0x30, 0x14, 0x190]
;shandie level direct (int)
global arrayPointerOffsetsShandieLvl := [0x50, 0x8, 0xC, 0x8, 0xC8, 0x190]
;Steelbones Stacks
global arrayPointerOffsetsSB := [0x50, 0x18, 0x2B0]
;Haste Stacks
global arrayPointerOffsetsH := [0x50, 0x18, 0x2B4]
;Modron Core ExpTotal
global arrayPointerOffsetsCoreXP := [0x8, 0x40, 0x1C, 0x2C]
;Adventure Reset (char)
global arrayPointerOffsetsResetting := [0x8, 0x1C, 0x1C]

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
    ;Game Controller
    pointerBaseController := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
}
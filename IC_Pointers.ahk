;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 2/24/21
;IC Version v373/v374

global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
;Game Controller
global pointerBaseController :=
global arrayPointerOffsetsController := [0x658, 0xA0, 0x28, 0x8]
;Level
global arrayPointerOffsetsLevel := [0x18, 0x14, 0x28]
;Quest Remaining
global arrayPointerOffsetsQR := [0x18, 0x14, 0x30]
;Transitioning
global arrayPointerOffsetsTransitioning := [0x20, 0x1C]
;Time Scale Multiplier
global arrayPointerOffsetsTimeScaleMultiplier := [0x8, 0xE8]
;Shandie's Level (Slot 4: center of diamond)
global arrayPointerOffsetsShandieLvl := [0x14, 0xC, 0x8, 0x20, 0x14, 0x188]
global arrayPointerOffsetsShandieLvl0 := [0x14, 0xC, 0x8, 0x10, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl1 := [0x14, 0xC, 0x8, 0x14, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl2 := [0x14, 0xC, 0x8, 0x18, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl3 := [0x14, 0xC, 0x8, 0x1C, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl4 := [0x14, 0xC, 0x8, 0x20, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl5 := [0x14, 0xC, 0x8, 0x24, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl6 := [0x14, 0xC, 0x8, 0x28, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl7 := [0x14, 0xC, 0x8, 0x2C, 0x14, 0x190]
global arrayPointerOffsetsShandieLvl8 := [0x14, 0xC, 0x8, 0x30, 0x14, 0x190]
;Steelbones Stacks
global arrayPointerOffsetsSB := [0x50, 0x18, 0x2B0]
;Haste Stacks
global arrayPointerOffsetsH := [0x50, 0x18, 0x2B4]
;Modron Core ExpTotal
global arrayPointerOffsetsCoreXP := [0x8, 0x40, 0x1C, 0x2C]

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

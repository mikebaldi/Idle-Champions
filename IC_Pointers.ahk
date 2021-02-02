;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 1/31/21
;IC Version 

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
;Haste Handler
;base := "mono-2.0-bdwgc.dll")+0x003A0574
;offsets := [0x658, 0xA0, 0x2C, 0x234, 0x31C, 0x10, 0x0]
global pointerBaseHS :=
global arrayPointerOffsetsHS := [0x658, 0xA0, 0x2C, 0x234, 0x31C, 0x10, 0x18, 0x58] ;Haste Stacks Pointer Offsets
;Steelbones Handler
;base := "mono-2.0-bdwgc.dll")+0x003A0574
;offsets := [0x658, 0xA0, 0x2C, 0x234, 0x3C8, 0x50, 0x0]
global pointerBaseSB :=
global arrayPointerOffsetsSB := [0x658, 0xA0, 0x2C, 0x234, 0x3C8, 0x50, 0x18, 0x58] ;Steelbones Stacks Pointer Offsets
;Dash Handler
;base := "mono-2.0-bdwgc.dll")+0x003A0574
;offsets := [0x658, 0xA0, 0x2C, 0x234, 0x3C8, 0x34, 0x10, 0x10, 0x0]
global pointerBaseDashTime := ;Dash effect Time (double)
global arrayPointerOffsetsDashTime := [0x658, 0xA0, 0x2C, 0x234, 0x3C8, 0x34, 0x10, 0x10, 0x38]


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
    pointerBaseHS := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574 
    pointerBaseSB := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
    pointerBaseDashTime := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
}
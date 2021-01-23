;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 1/22/21
;IC Version 1.29.3 (v370) 1/21/2021

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored. 
global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 

;This is how we find our way in memory to the data we want. Updating the game may require updating the values stored in these variables.
global pointerBaseLN := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C68 ;Level Number Pointer Base
global arrayPointerOffsetsLN := [0x2A8, 0xAA8, 0x4C, 0xCC, 0x1EC, 0x50, 0x28, 0x90, 0x228, 0x28] ;Level Number Pointer Ofsets
global pointerBaseQR := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C68 ;Quest Remaining Pointer Base
global arrayPointerOffsetsQR := [0x2A8, 0xAA8, 0x4C, 0xCC, 0x1EC, 0x50, 0x28, 0x90, 0x228, 0x30] ;Quest Remaining Pointer Ofsets
global pointerBaseSB := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574 ;Steelbones Stacks Pointer Base
global arrayPointerOffsetsSB := [0x658, 0xA0, 0x2C, 0x234, 0x3C8, 0x50, 0x18, 0x58] ;Steelbones Stacks Pointer Offsets
global pointerBaseHS := idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574 ;Haste Stacks Pointer Base
global arrayPointerOffsetsHS := [0x658, 0xA0, 0x2C, 0x234, 0x31C, 0x90, 0x18, 0x58] ;Haste Stacks Pointer Offsets

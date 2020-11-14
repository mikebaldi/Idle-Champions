;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 10/29/20
;IC Version 1.21.1 (v357) 10/29/2020 10:00:00 am

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored. 
global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 

;This is how we find our way in memory to the data we want. Updating the game may require updating the values stored in these variables.
global pointerBaseLN 			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Level Number Pointer Base
global arrayPointerOffsetsLN 		:= [0x2A8, 0xAA8, 0x74, 0x8, 0x6C, 0x18, 0x98]			;Level Number Pointer Ofsets
global pointerBaseSB			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Steelbones Stacks Pointer Base
global arrayPointerOffsetsSB 		:= [0x2A8, 0xD50]						;Steelbones Stacks Pointer Offsets
global pointerBaseHS			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Steelbones Stacks Pointer Base
global arrayPointerOffsetsHS 		:= [0x2A8, 0xD54]						;Steelbones Stacks Pointer Offsets
global pointerBaseMRL			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Modron Reset Level Pointer Base
global arrayPointerOffsetsMRL 		:= [0x2A8, 0xAA8, 0x78, 0x24, 0x34, 0x10, 0x70]						;Modron Reset Level Pointer Offsets

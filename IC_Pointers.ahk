;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 1/11/21
;IC Version 1.28.1 (v368) 1/11/2021 9:17:48AM

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored. 
global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 

;This is how we find our way in memory to the data we want. Updating the game may require updating the values stored in these variables.
global pointerBaseLN 			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x0497DE8 	;Level Number Pointer Base
global arrayPointerOffsetsLN 		:= [0x150, 0x580, 0x238, 0x10, 0x20, 0x40, 0x114] 		;Level Number Pointer Ofsets
global pointerBaseSB			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x0497DE8	;Steelbones Stacks Pointer Base
global arrayPointerOffsetsSB 		:= [0x150, 0x838, 0x2E0]					;Steelbones Stacks Pointer Offsets
global pointerBaseHS			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x0497DE8 	;Haste Stacks Pointer Base
global arrayPointerOffsetsHS 		:= [0x150, 0x838, 0x2E4]					;Haste Stacks Pointer Offsets

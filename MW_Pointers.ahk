;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
;date of script: 7/12/2020
;classMemory functions sourced from: https://github.com/Kalamity/classMemory

;Use classMemory functions without having to copy them into script. Make sure classMemory.AHK is in same folder as script.

#Include classMemory.ahk

;This function has to be called each time IdleDragons.exe is restarted
RefreshPointers()
{
	;Check if you have installed the class correctly.

	if (_ClassMemory.__Class != "_ClassMemory")
	{
		msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
		ExitApp
	}

	;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
	;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
	;Also, if the target process is running as admin, then the script will also require admin rights!
	;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
	;hProcessCopy is an optional variable in which the opened handled is stored. 

	global idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 

	;Check if the above method was successful.

	if !isObject(idle) 
	{
		msgbox failed to open a handle
		if (hProcessCopy = 0)
			msgbox The program isn't running (not found) or you passed an incorrect program identifier parameter. In some cases _ClassMemory.setSeDebugPrivilege() may be required. 
		else if (hProcessCopy = "")
			msgbox OpenProcess failed. If the target process has admin rights, then the script also needs to be ran as admin. _ClassMemory.setSeDebugPrivilege() may also be required. Consult A_LastError for more information.
		ExitApp
	}

	;This is how we find our way in memory to the data we want. Updating the game may require updating the values stored in these variables.
	global pointerBaseLN 			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Level Number Pointer Base
	global arrayPointerOffsets 		:= [0x100, 0xE0C, 0x18, 0xC, 0x2C, 0xC, 0x94]					;Level Number Pointer Ofsets
	global pointerBaseSB			:= idle.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x039FC60	;Steelbones Stacks Pointer Base
	global arrayPointerOffsetsSB 	:= [0x2A8, 0xD58]												;Steelbones Stacks Pointer Offsets
	
}



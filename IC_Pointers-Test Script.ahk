;this script is meant to test pointer base and offsets
;date of script: 8/8/2020

;classMemory functions sourced from: https://github.com/Kalamity/classMemory
;Use classMemory functions without having to copy them into script. Make sure classMemory.AHK is in same folder as script.

#Include classMemory.ahk

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

;The pointer base and offsets we are testing
#Include IC_Pointers.ahk

;Tool Tip Pop Up
UpdateToolTip()
return

;HotKeys
{

	;Reload
	#IfWinActive Idle Champions
	F9:: 
	{	
		Reload
		return
	}

}

;ToolTips
{

	UpdateToolTip()
	{
		gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
		gSBStacks := idle.read(pointerBaseSB, "Int", arrayPointerOffsetsSB*)
		gHasteStacks := idle.read(pointerBaseHS, "Int", arrayPointerOffsetsHS*)

		sToolTip := "F9 to Reload`nCurrent Level: "gLevel_Number
		sToolTip := sToolTip "`nCurrent SB Stacks: " gSBStacks 
		sToolTip := sToolTip "`nCurrent Haste Stacks: " gHasteStacks 

		ToolTip, % sToolTip, 25, 475, 1
	}

}



#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
;version: 200906 (9/6/20)
;put together with the help from many different people. thanks for all the help.

;----------------------------
;	User Settings
;	various settings to allow the user to Customize how the Script behaves
;----------------------------			

global ScriptSpeed := 100	    ;sets the delay after a directinput, ms
global gSBStacksMax := 1200	    ;target Steelbones stack count for Briv to farm
global gSBTimeMax := 300000 	;maximum time Briv will farm Steelbones stacks, ms
global AreaLow := 475 		    ;last level before you start farming Steelbones stacks for Briv
global TimeBetweenResets := 4   ;units = hours. set to 0 to disable.
global gDembo := 2000           ;time in milliseconds that script will repeatedly try and summon Dembo
global gStackRestart := 1		;toggle to restart during Briv Stacking
;Set of FKeys to be spammed as part of initial leveling
global gFKeys := "{F1}{F3}{F4}{F5}{F6}{F7}{F8}{F10}{F12}"

SetWorkingDir, %A_ScriptDir%

;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include classMemory.ahk

;Check if you have installed the class correctly.
if (_ClassMemory.__Class != "_ClassMemory")
{
	msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
	ExitApp
}

;pointer addresses and offsets
#include IC_Pointers.ahk

global ResetCount 		:= 0
global gTotal_RunCount	:= 0
global BrivStacks		:=		;variable to track total SB and Haste stacks, less 48
global gNotBrivStacked	:= 1	;check for Briv stacked for when current level and sb stacks don't reset together and script falls back into stack farming loop
global gLoop		    :=	    ;variable to store what loop the script is currently in
global gdebug		    := 0	;displays (1) or hides (0) the debug tooltip
global gStats1			:= 1	;displays (1) or hides (0) the Stats 1 tooltip
global gStats2			:= 1	;displays (1) or hides (0) the Stats 2 tooltip
global gErrors			:= 0	;counts how many times ErrorLevel triggered GetAddress()

;globals used to count bosses killed
global gTotal_Bosses 	:= 0
global gprevBosses	    :=
global gLoopBosses	    :=
global gprevLevel 	    := 	  

;globals for various timers
global gPrevRunTime 	:= 
global gSlowRuntTime	:= 		
global gFastRuntTime	:= 100	
global gRunStartTime 	:= 		;used to calc current runt ime
global gStartTime 	    := 
global ElapsedTime      :=      ;variable used to track time in while loops
global gPrevLevelTime	:=	
global gPrevRestart 	:= A_TickCount

;globals used for memory reading
global gLevel_Number 	:= 	    ;used to store current level
global gSBStacks 	    :=	    ;used to store current Steelbones stack count
global gHasteStacks 	:=	    ;used to store current Haste stack count
global addressLN        :=
global addressSB        :=
global addressHS        :=



	sToolTip := "Hotkeys"
    sToolTip := sToolTip "`nF2: Start Gem Farm Loop"
	sToolTip := sToolTip "`nF5: Toggle Debug"
	sToolTip := sToolTip "`nF6: Toggle Stats 1"
	sToolTip := sToolTip "`nF7: Toggle Stats 2"
	sToolTip := sToolTip "`nF9: Reload Script"
	sToolTip := sToolTip "`nF10: Close Script"
	sToolTip := sToolTip "`nUp/Down: AreaLow +/- 50"
	sToolTip := sToolTip "`nCTRL+Up/Down: Target SB Stacks +/- 1000"
    ToolTip, % sToolTip, 15, 233, 1

;start Modron gem runs
$F2::
    gStartTime := A_TickCount
	gRunStartTime := A_TickCount
    loop 
	{
        GemFarm()
    }
return

;Debug
$F5::
	if (gdebug = 1)
	{
		gdebug := 0
	}
	else
	{
		gdebug :=1
	}
return

;Stats 1
$F6::
	if (gStats1 = 1)
	{
		gStats1 := 0
	}
	else
	{
		gStats1 :=1
	}
return

;Stats 2
$F7::
	if (gStats2 = 1)
	{
		gStats2 := 0
	}
	else
	{
		gStats2 :=1
	}
return

;Reload the script
$F9::
    Reload
return

;kills the script
$F10::ExitApp

;+50 levels to Target Level
#IfWinActive Idle Champions
~Up::
{
	AreaLow += 50
	return
}

;-50 levels to Target Level
#IfWinActive Idle Champions
~Down::
{
	AreaLow -= 50
	return
}

;+1000 Stacks to Target Stealbones Stacks
#IfWinActive Idle Champions
^~Up::
{
	gSBStacksMax += 1000
	return
}

;-1000 Stacks to Target Stealbones Stacks
#IfWinActive Idle Champions
^~Down::
{
	gSBStacksMax -= 1000
	return
}

$`::Pause

;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
;Also, if the target process is running as admin, then the script will also require admin rights!
;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
;hProcessCopy is an optional variable in which the opened handled is stored. 
OpenProcess()
{
	idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 
}

;loads final memory address of pointer to reduce overhead
GetAddress()
{
    addressLN := idle.getAddressFromOffsets(pointerBaseLN, arrayPointerOffsetsLN*)
    addressSB := idle.getAddressFromOffsets(pointerBaseSB, arrayPointerOffsetsSB*)
    addressHS := idle.getAddressFromOffsets(pointerBaseHS, arrayPointerOffsetsHS*)
}

SafetyCheck(Skip := False) 
{
    While(Not WinExist("ahk_exe IdleDragons.exe")) 
    {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
	    Sleep 10000
	    OpenProcess()
	    Sleep 5000
		GetAddress()
		Sleep 5000
		gPrevRestart := A_TickCount
		gPrevLevelTime := A_TickCount
	    ;SummonDembo()
	    ++ResetCount
    }
    if Not Skip 
    {
        WinActivate, ahk_exe IdleDragons.exe
    }
}

LevelUp()
{
	;set start of loop variables
	if (gTotal_RunCount)
	{
		gPrevRunTime := (A_TickCount - gRunStartTime) / 60000
		if (gSlowRuntTime < gPrevRunTime)
		{
			gSlowRuntTime := round(gPrevRunTime, 2)
		}
		if (gFastRuntTime > gPrevRunTime)
		{
			gFastRuntTime := round(gPrevRunTime, 2)
		}	
	}
		
	gRunStartTime := A_TickCount
	gNotBrivStacked := 1

	;check memory is reading correct level and continue to try and reload memory address for 3 minutes
	gLevel_Number := idle.read(addressLN, "Int")
	StartTime := A_TickCount
    ElapsedTime := 0
	while (gLevel_Number = "" AND ElapsedTime < 180000)
	{
		GetAddress()
		ElapsedTime := A_TickCount - StartTime
		gLevel_Number := idle.read(addressLN, "Int")
	}

	gPrevLevel := gLevel_Number

	gLoop := "LevelUp"
	UpdateToolTip()
	
	;spam fkey leveling during level 1
	While(gLevel_Number = gPrevLevel)
	{
		DirectedInput(gFKeys)
		DirectedInput("{Right}")
		gLevel_Number := idle.read(addressLN, "Int")
	}

	;to keep boss tracker accurate
	UpdateToolTip()

	SummonDembo()

	gLoop := "LevelUpFinish"
	UpdateToolTip()
	Sleep 250

	;spam 30 more fkey loops to ensure everyone leveled up
	loop 30
	{
		DirectedInput(gFKeys)
	}
}

SummonDembo()
{
	gLoop := "SummonDembo"
	UpdateToolTip()

	;spam send 2 through 8 for 4 seconds to summon Dembo
	StartTime := A_TickCount
    ElapsedTime := 0
	while (ElapsedTime < gDembo)
	{
		DirectedInput("2345678")
        ElapsedTime := A_TickCount - StartTime
	}
}

DirectedInput(s) 
{
	SafetyCheck(True)
	ControlFocus,, ahk_exe IdleDragons.exe
	ControlSend,, {Blind}%s%, ahk_exe IdleDragons.exe
	Sleep, %ScriptSpeed%
}

UpdateToolTip()
{
	gLevel_Number := idle.read(addressLN, "Int")
	if (gLevel_Number = "")
	{
		GetAddress()
		++gErrors
	}
	gSBStacks := idle.read(addressSB, "Int")
	if (gSBStacks = "")
	{
		GetAddress()
		++gErrors
	}
	gHasteStacks := idle.read(addressHS, "Int")
	if (gHasteStacks = "")
	{
		GetAddress()
		++gErrors
	}

	if !isObject(calc) 
    {
		OpenProcess()
	}

	gprevBosses := Floor(gprevLevel / 5)
	gLoopBosses := Floor(gLevel_Number / 5)

	if (gLoopBosses > gprevBosses)
	{
		count := gLoopBosses - gprevBosses
		gTotal_Bosses := gTotal_Bosses + count
		gprevLevel := gLevel_Number
		gPrevLevelTime := A_TickCount
	}

	if (gLevel_Number > gprevLevel)
	{
		gprevLevel := gLevel_Number
		gPrevLevelTime := A_TickCount
	}

	dtCurrentRunTime := (A_TickCount - gRunStartTime) / 60000
	dtCurrentLevelTime := (A_TickCount - gPrevLevelTime)/1000

	;if time on current level exceeds 30 seconds, g is sent twice. May fix issue with boss levels stopping autoprogress and send right
	if (dtCurrentLevelTime > 30 AND gLoop != "FarmBrivStacks")
	{
		DirectedInput("g")
		sleep 250
		DirectedInput("g")
	}

	;if time on current level exceeds 240 seconds, the game is restarted.
	if (dtCurrentLevelTime > 240 AND gLoop != "FarmBrivStacks")
	{
		PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
		While(WinExist("ahk_exe IdleDragons.exe")) 
		{
			sleep 1000
		}
		SafetyCheck()
		LevelUp()
	}

	dtTotalTime := (A_TickCount - gStartTime) / 3600000

	bossesPhr := gTotal_Bosses / dtTotalTime

	if (gStats1)
	{
		sToolTip := "Stats 1 (F6 to toggle)"
		sToolTip := sToolTip "`nCurrent Level: " gLevel_Number
    	sToolTip := sToolTip "`nTarget Level: " AreaLow
    	sToolTip := sToolTip "`nCurrent SB Stacks: " gSBStacks 
		sToolTip := sToolTip "`nTarget SB Stacks: " gSBStacksMax
    	sToolTip := sToolTip "`nCurrent Haste Stacks: " gHasteStacks 
		sToolTip := sToolTip "`nCurrent Run Time: " Round(dtCurrentRunTime, 2)
		ToolTip, % sToolTip, 355, 35, 1
	}
	else
	{
		Tooltip ,,,,1
	}

	if (gStats2)
	{
		sToolTip := "Stats 2 (F7 to toggle)"
		sToolTip := sToolTip "`nPrevious Run Time: " Round(gPrevRunTime, 2)
		sToolTip := sToolTip "`nFastest Run Time " gFastRuntTime
		sToolTip := sToolTip "`nSlowest Run Time: " gSlowRuntTime
		sToolTip := sToolTip "`nTotal Run Count: " gTotal_RunCount
		sToolTip := sToolTip "`nTotal Run Time (hr): " Round(dtTotalTime, 2)	
		sToolTip := sToolTip "`nTotal B/hr: " Round(bossesPhr, 2)
		ToolTip, % sToolTip, 525, 35, 2
	}
	else
	{
		Tooltip ,,,,2
	}

	if (gdebug)
	{
		sToolTip := "Debug (F5 to toggle)"
		sToolTip := sToolTip "`nTotal Restarts: " ResetCount
		sToolTip := sToolTip "`nLoop: " gLoop
        sToolTip := sToolTip "`nElapsedTime: " ElapsedTime
		sToolTip := sToolTip "`nBriv Stacked: " gNotBrivStacked
		sToolTip := sToolTip "`nPrev Lvl: " gprevLevel
		sToolTip := sToolTip "`nPrev Bosses: " gprevBosses
		sToolTip := sToolTip "`nLoop Bosses: " gLoopBosses
		sToolTip := sToolTip "`nTotal Bosses: " gTotal_Bosses
		sToolTip := sToolTip "`nCurrent Level Time: " Round(dtCurrentLevelTime, 2)
		sToolTip := sToolTip "`nGet Address Triggers: " gErrors
		sToolTip := sToolTip "`nBrivStacks: " BrivStacks
		ToolTip, % sToolTip, 15, 233, 3
	}
	else
	{
		Tooltip ,,,,3
	}

	
}

GemFarm() 
{  
	OpenProcess()
	GetAddress()
	
	;for tracking boss kills
	gLevel_Number := idle.read(addressLN, "Int")
	gprevLevel := gLevel_Number
	gPrevLevelTime := A_TickCount

	TimeBetweenResets := TimeBetweenResets * 60 * 60 * 1000
	gPrevRestart := A_TickCount

	UpdateToolTip()
    
	loop 
	{
		gLoop := "Main"
        UpdateToolTip()
        DirectedInput("{q}")

        if (gLevel_Number = 1) 
		{
			LevelUp()
			
			;check if time between reset has exceeded and restart the game if so	
			if (TimeBetweenResets > 0 and (A_TickCount - gPrevRestart) > TimeBetweenResets) 
			{
				PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
			}	
        }

		BrivStacks := gSBStacks + gHasteStacks - 48

        ;if (gNotBrivStacked And gLevel_Number > AreaLow) 
		if (BrivStacks < gSBStacksMax AND gLevel_Number > AreaLow)
		{
			Loop, 3
			{
				DirectedInput("w")
			}

			AreaLowBoss := AreaLow + 4

			while (gLevel_Number > AreaLowBoss)
			{
				DirectedInput("{Left}")
				UpdateToolTip()
			}

			if (gStackRestart) 
			{
				PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
				StartTime := A_TickCount
				ElapsedTime := 0
				While(WinExist("ahk_exe IdleDragons.exe") AND ElapsedTime < 60000) 
				{
					Sleep 1000
					ElapsedTime := A_TickCount - StartTime
				}
				Sleep 12000
			}	

			SafetyCheck()

			BrivStacks := gSBStacks + gHasteStacks - 48

    		StartTime := A_TickCount
			ElapsedTime := 0

			while (BrivStacks < gSBStacksMax AND ElapsedTime < gSBTimeMax)
			{
				SafetyCheck()
		
        		if (gLevel_Number <= AreaLow) 
				{
        			DirectedInput("{Right}")
				}

				gLoop := "FarmBrivStacks"
				UpdateToolTip()
				BrivStacks := gSBStacks + gHasteStacks - 48
				Sleep 1000
				ElapsedTime := A_TickCount - StartTime
			}

			Loop, 3
			{
				DirectedInput("q")
			}
			
			Sleep 250
			gNotBrivStacked := 0
			gPrevLevelTime := A_TickCount
			++gTotal_RunCount
			Sleep 250
			UpdateToolTip()
		}
		
        MouseClick, L, 650, 450, 2
        DirectedInput("{Right}")
		MouseClick, L, 650, 450, 2
    }
}
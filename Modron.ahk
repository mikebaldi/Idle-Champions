#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
;2/12/21
;put together with the help from many different people. thanks for all the help.

;----------------------------
;	User Settings
;	various settings to allow the user to Customize how the Script behaves
;----------------------------			
global ScriptSpeed := 100	    ;sets the delay after a directedinput, ms
global gSBTimeMax := 160000		;maximum time Briv will farm Steelbones stacks, ms
global AreaLow := 571 		    ;last level before you start farming Steelbones stacks for Briv
global gDembo := 2000           ;time in milliseconds that script will repeatedly try and summon Dembo
global gAvoidBosses := 1		;toggle to avoid boss levels for quad skip
global gContinuedLeveling := 50 ;the script will continue to send Fkeys on levels less than this variable
global gClickLeveling := 1		;toggle to level click damage with hotkey `
global gBrivSwap := 1			;will attempt to swap Briv when final quest item is earned to skip his transition animation
global gBrivSwapSleep := 1000	;how long the script will sleep before swapping Briv back in, 1000 seems good for no pots.
global gDashSleepToggle := 1	;wait on level 1 for Dash to start, 1=true, 0=false

;Set of FKeys to be spammed as part of initial leveling. Must Include `` if using gClickLeveling
global gFKeys := "``{F1}{F4}{F5}{F6}{F7}{F10}{F12}"

;Set of FKeys to be spammed as part of continued leveling
global gFKeysCont := "{F4}{F5}"

;variables to consider changing if restarts are causing issues
global gOpenProcess	:= 10000	;time in milliseconds for your PC to open Idle Champions
global gGetAddress := 5000		;time in milliseconds after Idle Champions is opened for it to load pointer base into memory
global gStackRestart := 1		;toggle to restart during Briv Stacking. Consider setting to 0 if restart issues persist.
global TimeBetweenResets := 4   ;units = hours. set to 0 to disable. Consider setting to 0 if restart issues persist.

;end of user settings

;#EscapeChar \ ;Change escape character to backslashe instead of the default accent (`)

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
global gQuestRemaining	:=		;used to store quest item count remaining to be found on current level
global gAutoProgress	:=		;used to store bool for auto progress
global gTrans			:=		;used to store transition state
global gTime			:=		;used to store game speed multiplier

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

$F3::
	gPrevLevelTime := A_TickCount
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

$`::
Pause
gPrevLevelTime := A_TickCount
return

SafetyCheck(Skip := True) 
{
    While(Not WinExist("ahk_exe IdleDragons.exe")) 
    {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
	    Sleep gOpenProcess
	    OpenProcess()
	    Sleep gGetAddress
		ModuleBaseAddress()
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
	UpdateToolTip()
	StartTime := A_TickCount
    ElapsedTime := 0
	while (gLevel_Number = "" AND ElapsedTime < 180000)
	{
		OpenProcess()
		ModuleBaseAddress()
		ElapsedTime := A_TickCount - StartTime
		UpdateToolTip()
	}

	gPrevLevel := gLevel_Number

	gLoop := "LevelUp"
	UpdateToolTip()

	StartTime := A_TickCount
	ElapsedTime := 0
	while (gQuestRemaining AND gQuestRemaining > 24 AND ElapsedTime < 60000)
	{
		gloop := "LoadingLvl1"
		UpdateToolTip()
		Sleep, 100
		ElapsedTime := A_TickCount - StartTime
	}

	if (gDashSleepToggle)
	{
		gloop := "Puase4DashWait"
		UpdateToolTip()
		directedinput("g")

		DashSleep := 60000/gTime
		ults := 1
	
		While (ElapsedTime < DashSleep)
		{
			gloop := "WaitingForDash"
			DirectedInput(gFKeys)
			ElapsedTime := A_TickCount - StartTime
			UpdateToolTip()
			UltSleep := DashSleep - 2000
			if (ults AND ElapsedTime > UltSleep)
			{
				directedinput("23456789")
				ults := 0
			}
		}
		gloop := "DashDone"
		UpdateToolTip()
		DirectedInput("g")
	}
	else
	{
		gLoop := "StandardLvling"
		UpdateToolTip()
		While(gLevel_Number = gPrevLevel)
		{
			DirectedInput(gFKeys)
			DirectedInput("{Right}")
			UpdateToolTip()
		}
		SummonDembo()
	}
	;to keep boss tracker accurate
	UpdateToolTip()
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
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
	gLevel_Number := idle.read(Controller, "Int", arrayPointerOffsetsLevel*)
	gQuestRemaining := idle.read(Controller, "Int", arrayPointerOffsetsQR*)
	gTrans := idle.read(Controller, "Char", arrayPointerOffsetsTransitioning*)
	gTime := idle.read(Controller, "Float", arrayPointerOffsetsTimeScaleMultiplier*)

	if (gLevel_Number = "")
	{
		OpenProcess()
		ModuleBaseAddress()
		++gErrors
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
	;if (dtCurrentLevelTime > 30 AND gLoop != "FarmBrivStacks")
	;{
	;	DirectedInput("g")
	;	sleep 250
	;	DirectedInput("g")
	;}

	;if time on current level exceeds 60 seconds, the game is restarted.
	if (dtCurrentLevelTime > 120 AND gLoop != "FarmBrivStacks")
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
		sToolTip := sToolTip "`nQuestRemaining: " gQuestRemaining
		sToolTip := sToolTip "`nDash Sleep Toggle: " gDashSleepToggle
		sToolTip := sToolTip "`nTransitioning: " gTrans
		sToolTip := sToolTip "`nTime Scale Multi: " gTime
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
	ModuleBaseAddress()
	
	;for tracking boss kills
	UpdateToolTip()
	gprevLevel := gLevel_Number
	gPrevLevelTime := A_TickCount

	TimeBetweenResets := TimeBetweenResets * 60 * 60 * 1000
	gPrevRestart := A_TickCount

	UpdateToolTip()
    
	loop 
	{
		gLoop := "Main"
        UpdateToolTip()
		zone := mod(gLevel_Number, 50)
		if (gLevel_Number)
		{
			if (mod(gLevel_Number, 5) AND gQuestRemaining > 0)
			DirectedInput("q")
			else if (gBrivSwap AND gQuestRemaining = 0)
			{
				if (zone != 1 AND zone < 22 OR zone > 25)
				DirectedInput("e")
				;if (zone != 1 AND zone < 21 OR zone > 28)
				;{
					StartTime := A_TickCount
					ElapsedTime := 0
					while (ElapsedTime < 5000 AND gQuestRemaining = 0)
					{
						ElapsedTime := A_TickCount - StartTime
						DirectedInput("{Right}")
						UpdateToolTip()
						sleep, 100
					}
					sleep, gBrivSwapSleep
					DirectedInput("q")
				;}
			}
			else if (gAvoidBosses)
			DirectedInput("e")
			else
			DirectedInput("q")
		}
		else
		DirectedInput("q") 

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

		if (gNotBrivStacked AND gLevel_Number > AreaLow)
		{
			Loop, 3
			{
				DirectedInput("w")
			}

			AreaLowBoss := mod(gLevel_Number, 5)

			while (!AreaLowBoss)
			{
				DirectedInput("{Left}")
				UpdateToolTip()
				AreaLowBoss := mod(gLevel_Number, 5)
			}

			if (gStackRestart) 
			{
				gloop := "StackRestart"
				UpdateToolTip()
				Sleep 1000
				PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
				StartTime := A_TickCount
				ElapsedTime := 0
				While(WinExist("ahk_exe IdleDragons.exe") AND ElapsedTime < 60000) 
				{
					Sleep 1000
					ElapsedTime := A_TickCount - StartTime
				}
				Sleep 12000
				SafetyCheck()
			}
			else
			{
				StartTime := A_TickCount
				ElapsedTime := 0
				gLoop := "FarmBrivStacks"
				while (ElapsedTime < gSBTimeMax)
				{
					DirectedInput("w")
		
        			if (gLevel_Number <= AreaLow) 
					{
        				DirectedInput("{Right}")
					}
					Sleep 1000
					ElapsedTime := A_TickCount - StartTime
					UpdateToolTip()
				}
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
		
        DirectedInput("{Right}")
		If (gClickLeveling)
		{
			DirectedInput("``")
		}
		if (gContinuedLeveling > gLevel_Number AND gLevel_Number)
		{
			DirectedInput(gFKeysCont)
		}
    }
}

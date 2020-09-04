#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
;version: 200829 (8/29/20)
;put together with the help from many different people. thanks for all the help.

;----------------------------
;	User Settings
;	various settings to allow the user to Customize how the Script behaves
;----------------------------			

global ScriptSpeed := 100	    ;sets the delay after a directinput, ms
global gSBStacksMax := 1300	    ;target Steelbones stack count for Briv to farm
global gSBTimeMax := 300000 	;maximum time Briv will farm Steelbones stacks, ms
global AreaLow := 475 		    ;last level before you start farming Steelbones stacks for Briv
global TimeBetweenResets := 2   ;in hours
global gDembo := 2000           ;time in milliseconds that script will repeatedly try and summon Dembo
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

Global RunCount := 0, FailedCount := 0
global gTotal_RunCount	:= 0
global gTotal_Bosses 	:= 0
global gprevBosses	    :=
global gLoopBosses	    :=
global dtPrevRunTime 	:= "00:00:00"
global dtPrev           :=      ;used to calc dtPrevRunTime
global dtLoopStartTime 	:= "00:00:00"
global dtStartTime 	    := "00:00:00"
global gTotal_RunTime 	:= "00:00:00"
global gLevel_Number 	:= 	    ;used to store current level
global gprevLevel 	    := 	    ;used for tracking boss kills
global gSBStacks 	    :=	    ;used to store current Steelbones stack count
global gHasteStacks 	:=	    ;used to store current Haste stack count
global gBrivStacked	    := 1	;check for Briv stacked for when current level and sb stacks don't reset together and script falls back into stack farming loop
global gLoop		    :=	    ;variable to store what loop the script is currently in
global ElapsedTime      :=      ;variable used to count time in while loops
global gdebug		    := 1	;displays (1) or hides (0) the debug portion of the tooltip
global gPrevLevelTime	:=	
global timeSinceLastRestart := A_TickCount


LoadTooltip()

;start Modron gem runs
$F2::
    dtStartTime := A_Now
	dtLoopStartTime := A_Now
    loop 
	{
        WaitForResults()
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
RefreshPointers()
{
	idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy) 
}

SafetyCheck(Skip := False) 
{
    While(Not WinExist("ahk_exe IdleDragons.exe")) 
    {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
	    Sleep 10000
	    RefreshPointers()
	    Sleep 5000
		timeSinceLastRestart := A_TickCount
	    SummonDembo()
	    ++FailedCount
    }
    if Not Skip 
    {
        WinActivate, ahk_exe IdleDragons.exe
    }
}

DoLevel1()
{
	;set start of run variables
	dtStart := A_Now
	dtLoopStartTime := A_Now
	dtPrevRunTime := DateTimeDiff(dtPrev, dtStart)				
	dtPrev := dtStart
	gBrivStacked := 1
	gPrevLevel := 1

	gLoop := "DoLevel1"
	UpdateToolTip()
	
	;spam fkey leveling during level 1
	While(gLevel_Number = 1)
	{
		DirectedInput(gFKeys)
		DirectedInput("{Right}")
		gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
	}

	;to keep boss tracker accurate
	UpdateToolTip()

	SummonDembo()

	gLoop := "DoLevel1Finish"
	UpdateToolTip()
	Sleep 250

	;spam 30 more fkey loops to ensure everyone leveled up
	loop 30
	{
		DirectedInput(gFKeys)
	}
}

Close() 
{
	PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe

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
	gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
	gSBStacks := idle.read(pointerBaseSB, "Int", arrayPointerOffsetsSB*)
	gHasteStacks := idle.read(pointerBaseHS, "Int", arrayPointerOffsetsHS*)

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

	dtNow := A_Now
	dtCurrentRunTime := DateTimeDiff(dtLoopStartTime, dtNow)
	dtCurrentLevelTime := (A_TickCount-gPrevLevelTime)/1000

	;if time on current level exceeds 30 seconds, g is sent twice. May fix issue with boss levels stopping autoprogress and send right
	if (dtCurrentLevelTime > 30 AND gLoop != "FarmBrivStacks")
	{
		DirectedInput("g")
		sleep 250
		DirectedInput("g")
	}

	gTotal_RunTime := DateTimeDiffS(dtStartTime, dtNow) / 3600

	bossesPhr := gTotal_Bosses / gTotal_RunTime

	sToolTip := "Current Level: " gLevel_Number
    sToolTip := sToolTip "`nTarget Level: " AreaLow
    sToolTip := sToolTip "`nCurrent SB Stacks: " gSBStacks 
	sToolTip := sToolTip "`nTarget SB Stacks: " gSBStacksMax
    sToolTip := sToolTip "`nCurrent Haste Stacks: " gHasteStacks 
	sToolTip := sToolTip "`nCurrent Run Time: " dtCurrentRunTime
	sToolTip := sToolTip "`nPrevious Run Time: " dtPrevRunTime
	sToolTip := sToolTip "`nTotal Run Count: " gTotal_RunCount
	sToolTip := sToolTip "`nTotal Run Time (hr): " Round(gTotal_Runtime, 2)	
	sToolTip := sToolTip "`nTotal B/hr: " Round(bossesPhr, 2)
	sToolTip := sToolTip "`nDebug (F5 to toggle)"
	
	if (gdebug = 1)
	{
		sToolTip := sToolTip "`nTotal Restarts: " FailedCount
		sToolTip := sToolTip "`nLoop: " gLoop
        sToolTip := sToolTip "`nElapsedTime: " ElapsedTime
		sToolTip := sToolTip "`nBriv Stacked: " gBrivStacked
		sToolTip := sToolTip "`nPrev Lvl: " gprevLevel
		sToolTip := sToolTip "`nPrev Bosses: " gprevBosses
		sToolTip := sToolTip "`nLoop Bosses: " gLoopBosses
		sToolTip := sToolTip "`nTotal Bosses: " gTotal_Bosses
		sToolTip := sToolTip "`nCurrent Level Time: " Round(dtCurrentLevelTime, 2)
	}

	ToolTip, % sToolTip, 25, 250, 1

}

WaitForResults() 
{  
	RefreshPointers()

	;for tracking boss kills
	gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
	gprevLevel := gLevel_Number
	gPrevLevelTime := A_Now

	TimeBetweenResets := TimeBetweenResets * 60 * 60 * 1000
	timeSinceLastRestart := A_TickCount

	UpdateToolTip()
    
	loop 
	{
		gLoop := "Main"
        UpdateToolTip()
        DirectedInput("{q}")

        if (gLevel_Number = 1) 
		{
			DoLevel1()	
			if (TimeBetweenResets > 0 and (A_TickCount - timeSinceLastRestart) > TimeBetweenResets) 
			{
				Close()
			}	
        }


        if (gBrivStacked And gLevel_Number > AreaLow) 
		{
			FarmBrivStacks()
			Sleep 250
			gBrivStacked := 0
			++gTotal_RunCount
			Sleep 250
			UpdateToolTip()
		}
		
        MouseClick, L, 650, 450, 2
        DirectedInput("{Right}")
		MouseClick, L, 650, 450, 2
    }
}

FarmBrivStacks()
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

    StartTime := A_TickCount
	ElapsedTime := 0

	while (gSBStacks < gSBStacksMax AND ElapsedTime < gSBTimeMax)
	{
		SafetyCheck()
		
        if (gLevel_Number <= AreaLow) 
		{
        	DirectedInput("{Right}")
		}

		gLoop := "FarmBrivStacks"
		UpdateToolTip()
		Sleep 1000
		ElapsedTime := A_TickCount - StartTime
	}

	Loop, 3
	{
		DirectedInput("q")
	}
}

{ ;time HELPERS
    ;return String HH:mm:ss of the timespan
    DateTimeDiff(dtStart, dtEnd) {
        dtResult := dtEnd
        
        EnvSub, dtResult, dtStart, Seconds
        
        return TimeResult(dtResult)
    }

    DateTimeDiffS(dtStart, dtEnd) {
        dtResult := dtEnd
        
        EnvSub, dtResult, dtStart, Seconds
        
        return dtResult
    }
    
    
    ;might use later
    TimeSpanAverage(ts1, nCount) {
        time_parts1 := StrSplit(ts1, ":")
        t1_seconds := (((time_parts1[1] * 60) + time_parts1[2]) * 60) + time_parts1[3]
        if (!nCount) {
            return "00:00:00"
        }
        return TimeResult(t1_seconds / nCount)
    }
    
    TimeResult(dtResult) {
        nSeconds := Floor(Mod(dtResult, 60))
        nMinutes := Floor(dtResult / 60)
        nHours := Floor(nMinutes / 60)
        nMinutes := Mod(nMinutes, 60)
        
        sResult := (StrLen(nHours) = 1 ? "0" : "") nHours ":" (StrLen(nMinutes) = 1 ? "0" : "") nMinutes ":" (StrLen(nSeconds) = 1 ? "0" : "") nSeconds
        
        return sResult
    }
    
    MinuteTimeDiff(dtStart, dtEnd) {
        dtResult := dtEnd
        EnvSub, dtResult, dtStart, Seconds
        nSeconds := Floor(Mod(dtResult, 60))
        nMinutes := Floor(dtResult / 60)
        nHours := Floor(nMinutes / 60)
        nMinutes := Mod(nMinutes, 60)
        
        return (nMinutes + (nHours * 60) + (nSeconds / 60))
    }

	TimeSpanAdd(ts1, ts2)
	{
		time_parts1 := StrSplit(ts1, ":")
		time_parts2 := StrSplit(ts2, ":")
		
		t1_seconds := (((time_parts1[1] * 60) + time_parts1[2]) * 60) + time_parts1[3]
		t2_seconds := (((time_parts2[1] * 60) + time_parts2[2]) * 60) + time_parts2[3]
		
		dtResult := t1_seconds + t2_seconds
		
		nSeconds := Mod(dtResult, 60)
		nMinutes := Floor(dtResult / 60)
		nHours := Floor(nMinutes / 60)
		nMinutes := Mod(nMinutes, 60)
		
		sResult := (StrLen(nHours) = 1 ? "0" : "") nHours ":" (StrLen(nMinutes) = 1 ? "0" : "") nMinutes ":" (StrLen(nSeconds) = 1 ? "0" : "") nSeconds
		
		return sResult
	}
}

{ ;tooltips
    LoadTooltip() {
        ToolTip, % "Shortcuts`nF2: Run MW`nF9: Reload`nF10: Kill the script`nThere are others", 50, 250, 1
        SetTimer, RemoveToolTip, -5000
        return
    }

    RemoveToolTip:
        ToolTip
    return
}

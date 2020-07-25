#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
;version: 200718 (7/18/20)
;lots of functions sourced from many different people. thanks for all the help.

SetWorkingDir, %A_ScriptDir%

;modify variables in this file
#include Modron_Configuration.ahk

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
global gprevBosses	:=
global gLoopBosses	:=
global dtPrevRunTime 	:= "00:00:00"
global dtLoopStartTime 	:= "00:00:00"
global dtStartTime 	:= "00:00:00"
global gTotal_RunTime 	:= "00:00:00"
global gLevel_Number 	:= 	;used to store current level
global gprevLevel 	:= 	;used for tracking boss kills
global gSBStacks 	:=	;used to store current Steelbones stack count
global gHaviLevel	:=	;used to store Havilar's current level from memory
global gHaviPrevLevel	:=	;used to compare Havilar's previous level to current level


LoadTooltip()

;click while keys are held down
$F1::
    While GetKeyState("F1", "P") {
        MouseClick
        Sleep 0
    }
return

;start Modron gem runs
$F2::
    	dtStartTime := A_Now
	dtLoopStartTime := A_Now
    	loop 
	{
        	;dtLastRunTime := A_Now
        	WaitForResults()
    	}
return

;SafetyCheck
$F3::
	SafetyCheck()
	sleep, 1000
	
return

;Reload the script
$F9::
    if RunCount > 0
        DataOut()
    Reload
return

;kills the script
$F10::ExitApp

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

SafetyCheck(Skip := False) {
    While(Not WinExist("ahk_exe IdleDragons.exe")) {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
	Sleep 5000
	RefreshPointers()
	Sleep 5000
	SummonDembo()
	++FailedCount
    }
    if Not Skip {
        WinActivate, ahk_exe IdleDragons.exe
    }
}

SummonDembo()
{
	gHaviLevel := idle.read(pointerBaseHL, "Int", arrayPointerOffsetsHL*)
	gHaviPrevLevel := gHaviLevel
	ctr := 0
	timer := 30000 ;how long the script will check if it can level Havilar
	while (gHaviLevel = gHaviPrevLevel AND ctr < timer)
	{
		DirectedInput("{F10}")
		Sleep 250
		gHaviLevel := idle.read(pointerBaseHL, "Int", arrayPointerOffsetsHL*)
		Sleep 250
		ctr := ctr + 500
		UpdateToolTip()
	}
	loop 3 
	{
		DirectedInput("{F10}")
		Sleep 250
		if (gLevel_Number = 1) 
		{
			DirectedInput("1")
			Sleep 250
		}
		else
		{
			DirectedInput("8")
			Sleep 250
		}
		;UpdateToolTip()

	}
}

DirectedInput(s) {
	SafetyCheck(True)
	ControlFocus,, ahk_exe IdleDragons.exe
	ControlSend,, {Blind}%s%, ahk_exe IdleDragons.exe
	Sleep, %ScriptSpeed%
}

UpdateToolTip()
{
	dtNow := A_Now
	dtCurrentRunTime := DateTimeDiff(dtLoopStartTime, dtNow)

	gTotal_RunTime := DateTimeDiffS(dtStartTime, dtNow) / 3600

	bossesPhr := gTotal_Bosses / gTotal_RunTime

	sToolTip := "Current Level: " gLevel_Number
	sToolTip := sToolTip "`nCurrent SB Stacks: " gSBStacks
	sToolTip := sToolTip "`nCurrent Run Time: " dtCurrentRunTime
	sToolTip := sToolTip "`nTotal Run Time (hr): " Round(gTotal_Runtime, 2)	
	sToolTip := sToolTip "`nTotal Run Count: " gTotal_RunCount
	sToolTip := sToolTip "`nBosses per Hour: " Round(bossesPhr, 2)
	sToolTip := sToolTip "`nCrash Count: " FailedCount
	sToolTip := sToolTip "`nHavi Level: " gHaviLevel

	ToolTip, % sToolTip, 25, 475, 1
}

WaitForResults() 
{  
	RefreshPointers()
	gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
	gSBStacks := idle.read(pointerBaseSB, "Int", arrayPointerOffsetsSB*)
	
	;for tracking boss kills
	gprevLevel := gLevel_Number

	UpdateToolTip()
    
	loop 
	{
        	;simple click incase of fire
        	SafetyCheck()
       	 	MouseClick, L, 650, 450, 2

		gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
		gSBStacks := idle.read(pointerBaseSB, "Int", arrayPointerOffsetsSB*)
		gHaviLevel := idle.read(pointerBaseHL, "Int", arrayPointerOffsetsHL*)
        
		UpdateToolTip()

        	;if (gLevel_Number = 1) 
		if (gHaviLevel = 0)
		{

			dtStart := A_Now
			dtLoopStartTime := A_Now
			
			dtPrevRunTime := DateTimeDiff(dtPrev, dtStart)		
		
			UpdateToolTip()		
		
			dtPrev := dtStart			
		
			Sleep 1000

			;level up Havilar and summon Dembo
			SummonDembo()

			;level up everyone
			loop 40 
			{
				DirectedInput("{F1}{F3}{F4}{F5}{F6}{F7}{F8}{F10}{F12}")
			}

			gprevLevel := 1

			;wait for level 1 to finish
			while (gLevel_Number = 1)
			{
				gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
				Sleep 25
				DirectedInput("{Right}")
			}		
        	}

		gprevBosses := Floor(gprevLevel / 5)
		gLoopBosses := Floor(gLevel_Number / 5)

		if (gLoopBosses > gprevBosses)
		{
			count := gLoopBosses - gprevBosses
			gTotal_Bosses := gTotal_Bosses + count
			gprevLevel := gLevel_Number
		}

        	if (gLevel_Number > AreaLow And gSBStacks < gSBStacksMax) 
		{
			FarmBrivStacks()
			++gTotal_RunCount
			Sleep 100
			UpdateToolTip()
		}

        	DirectedInput("{Right}")
    	}
}

FarmBrivStacks()
{

	Loop, 3
	{
		DirectedInput("w")
	}

	ctr := 0

	while (gSBStacks < gSBStacksMax AND ctr < timer)
	{
		SafetyCheck()
		gSBStacks := idle.read(pointerBaseSB, "Int", arrayPointerOffsetsSB*)
		Sleep 250
		UpdateToolTip()
		Sleep 250
		ctr := ctr + 500
	}

	;Loop, 3
	;{
	;	DirectedInput("q")
	;}
		
	while (Not gLevel_Number Or gLevel_Number > 1)
	{
		SafetyCheck()
		gLevel_Number := idle.read(pointerBaseLN, "Int", arrayPointerOffsetsLN*)
		Sleep 250
		DirectedInput("{Right}")
		DirectedInput("q")
	}
}


DataOut() {
    FormatTime, currentDateTime,, MM/dd/yyyy HH:mm:ss
    dtNow := A_Now
    toWallRunTime := DateTimeDiff(dtStartTime, dtLastRunTime)
    lastRunTime := DateTimeDiff(dtLastRunTime, dtNow)
    totBosses := Floor(AreaLow / 5) * RunCount
    currentPatron := NpVariant ? "NP" : MirtVariant ? "Mirt" : VajraVariant ? "Vajra" : StrahdVariant ? "Strahd" : "How?"
    areaStopped = 0 ;InputBox, areaStopped, Area Stopped, Generaly stop on areas ending in`nz1 thru z4`nz6 thru z9
    ;meant for Google Sheets/Excel/Open Office
    FileAppend,%currentDateTime%`t%AreaLow%`t%toWallRunTime%`t%lastRunTime%`t%RunCount%`t%totBosses%`t%currentPatron%`t%FailedCount%`t%areaStopped%`n, MadWizard-Bosses.txt
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
    LoopedTooltip(variants, currentRunTime) {
        ToolTip, % "NpMiVaSt: " variants "`nMins since start: " currentRunTime, 50, 200, 2
        SetTimer, RemoveToolTip, -1000
        return
    }
    RemoveToolTip:
        ToolTip
    return
}

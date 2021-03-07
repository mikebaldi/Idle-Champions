#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
global ScriptDate := "3/7/21"
;put together with the help from many different people. thanks for all the help.

;----------------------------
;	User Settings
;	various settings to autopopulate settings tab
;----------------------------			
global ScriptSpeed := 100	    ;sets the delay after a directedinput, ms
global gSBTargetStacks := 1500	;how many SB stacks the script will try and farm
global gSBTimeMax := 120000		;maximum time Briv will farm Steelbones stacks, ms
global gAreaLow := 230 		    ;last level before you start farming Steelbones stacks for Briv
global gAvoidBosses := 0		;toggle to avoid boss levels for quad skip
global gContinuedLeveling := 1	;the script will continue to send Fkeys on levels less than this variable
global gClickLeveling := 1		;toggle to level click damage with hotkey `
global gBrivSwap := 1			;will attempt to swap Briv when final quest item is earned to skip his transition animation
global gDashSleepTime := 60000	
global gUlts := 1				;use ults after waiting for Dash
global gStackRestart := 1		;toggle to restart during Briv Stacking. Consider setting to 0 if restart issues persist.
global gHewUlt := 5				;Hew's Ult to spam

;Adjust to automatically check seats to be leveled with Fkeys
global gSeatToggle := [1,0,0,1,1,1,0,1,0,1,0,0]

;variables to consider changing if restarts are causing issues
global gOpenProcess	:= 10000	;time in milliseconds for your PC to open Idle Champions
global gGetAddress := 5000		;time in milliseconds after Idle Champions is opened for it to load pointer base into memory
;end of user settings

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

;globals used to count bosses killed
global gbossesPhr		:=
global gCoreXPStart		:=

;globals for various timers
global gSlowRunTime		:= 		
global gFastRunTime		:= 100
global gRunStartTime 	:=
global gTotal_RunCount	:= 0
global gStartTime 	    := 
global gPrevLevelTime	:=	
global gPrevRestart 	:=
global gprevLevel 	    :=
global dtCurrentLevelTime :=

;globals used for memory reading
global gLevel_Number 	:= 	    ;used to store current level
global gQuestRemaining	:=		;used to store quest item count remaining to be found on current level
global gTrans			:=		;used to store transition state
global gTime			:=		;used to store game speed multiplier
global gStackCountSB	:=		;used to store Steelbones stack count
global gStackCountH		:=		;used to store Haste stack count
global gShandieLvl		:=		;used to store Shandie Level
global gCoreXP			:=		;used to store Modron Core XP value

global gShandieSlot		:=
global gFKeys 			:=
global ResetCount		:= 0

Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Add, Button, x415 y25 w60 gSave_Clicked, Save
Gui, MyWindow:Add, Button, x415 y+50 w60 gRun_Clicked, `Run
Gui, MyWindow:Add, Button, x415 y+100 w60 gReload_Clicked, `Reload
Gui, MyWindow:Add, Tab3, x5 y5 w400, Read First|Settings|Stats|Debug|
Gui, Tab, Read First
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y30, Gem Farm, %ScriptDate%
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, Instructions:
Gui, MyWindow:Add, Text, x15 y+2 w10, 1.
Gui, MyWindow:Add, Text, x+2 w370, Save your speed formation in formation save slot 1, in game `hotkey "Q". This formation must include Shandie and at least one familiar on the field.
Gui, MyWindow:Add, Text, x15 y+2 w10, 2.
Gui, MyWindow:Add, Text, x+2 w370, Save your stack farming formation in formation save slot 2, in game `hotkey "W". Don't include any familiars on the field.
Gui, MyWindow:Add, Text, x15 y+2 w10, 3.
Gui, MyWindow:Add, Text, x+2 w370, Save your speed formation without Briv, Hew, or Melf in formation save slot 3, in game `hotkey "E".
Gui, MyWindow:Add, Text, x15 y+2, 4. Adjust the settings on the settings tab.
Gui, MyWindow:Add, Text, x15 y+2, 5. `Click the save button to save your settings.
Gui, MyWindow:Add, Text, x15 y+2, 6. Load into zone 1 of an adventure to farm gems.
Gui, MyWindow:Add, Text, x15 y+2, 7. Press the run button to start farming gems.
Gui, MyWindow:Add, Text, x15 y+10, Notes:
Gui, MyWindow:Add, Text, x15 y+2, 1. Use the pause hotkey, ``, to adjust settings after a run starts.
Gui, MyWindow:Add, Text, x15 y+2, 2. Don't forget to unpause after saving your settings.
Gui, MyWindow:Add, Text, x15 y+2, 3. First run is ignored for stats, in case it is a partial run.
Gui, MyWindow:Add, Text, x15 y+2, 4. Settings must be adjusted each time the script is loaded.
Gui, MyWindow:Add, Text, x15 y+2, 5. Recommended SB stack level is:
Gui, MyWindow:Add, Text, x15 y+2 w10,
Gui, MyWindow:Add, Text, x+2, Modron Reset Level - [2 * (Briv Skip Amount + 1)]
Gui, MyWindow:Add, Text, x15 y+2 w10,
Gui, MyWindow:Add, Text, x+2, Then adjust to avoid stacking on boss zones.
Gui, MyWindow:Add, Text, x15 y+10, Known Issues:
Gui, MyWindow:Add, Text, x15 y+2, 1. Cannot fully interact with `GUI `while script is running.
Gui, MyWindow:Add, Text, x15 y+2 w10, 2. 
Gui, MyWindow:Add, Text, x+2 w370, Using Hew's ult throughout a run with Briv swapping can result in Havi's ult being triggered instead. Consider removing Havi from formation save slot 3, in game `hotkey "E".

Gui, Tab, Settings
Gui, MyWindow:Add, Text, x15 y30 w120, Seats to level with Fkeys:
Loop, 12
{
	i := gSeatToggle[A_Index]
	if (A_Index = 1)
	Gui, MyWindow:Add, Checkbox, vCheckboxSeat%A_Index% Checked%i% x15 y+5 w60, Seat %A_Index%
	Else if (A_Index <= 6)
	Gui, MyWindow:Add, Checkbox, vCheckboxSeat%A_Index% Checked%i% x+5 w60, Seat %A_Index%
	Else if (A_Index = 7)
	Gui, MyWindow:Add, Checkbox, vCheckboxSeat%A_Index% Checked%i% x15 y+5 w60, Seat %A_Index%
	Else
	Gui, MyWindow:Add, Checkbox, vCheckboxSeat%A_Index% Checked%i% x+5 w60, Seat %A_Index%
}
Gui, MyWindow:Add, Edit, vNewContinuedLeveling x15 y+10 w50, % gContinuedLeveling
Gui, MyWindow:Add, Text, x+5, Continue using Fkey leveling until this zone
Gui, MyWindow:Add, Edit, vNewgAreaLow x15 y+10 w50, % gAreaLow
Gui, MyWindow:Add, Text, x+5, Farm SB stacks AFTER this zone
Gui, MyWindow:Add, Edit, vNewSBTargetStacks x15 y+10 w50, % gSBTargetStacks
Gui, MyWindow:Add, Text, x+5, Target Haste stacks for next run
Gui, MyWindow:Add, Edit, vNewDashSleepTime x15 y+10 w50, % gDashSleepTime
Gui, MyWindow:Add, Text, x+5, Wait `up to this long `on zone `1 for Dash
Gui, MyWindow:Add, Edit, vNewHewUlt x15 y+10 w50, % gHewUlt
Gui, MyWindow:Add, Text, x+5, `Hew's ultimate key, set to 0 to disable
Gui, MyWindow:Add, Checkbox, vgUlts Checked%gUlts% x15 y+10, Use ults after intial champion leveling
Gui, MyWindow:Add, Checkbox, vgBrivSwap Checked%gBrivSwap% x15 y+5, Swap to 'e' formation to avoid Briv's jump animation
Gui, MyWindow:Add, Checkbox, vgAvoidBosses Checked%gAvoidBosses% x15 y+5, Swap to 'e' formation when `on boss zones
Gui, MyWindow:Add, Checkbox, vgClickLeveling Checked%gClickLeveling% x15 y+5, `Uncheck `if using a familiar `on `click damage
Gui, MyWindow:Add, Checkbox, vgStackRestart Checked%gStackRestart% x15 y+5, Farm SB stacks by restarting IC
Gui, MyWindow:Add, Text, x15 y+5, Shandie's position in formation:
Gui, MyWindow:Add, Radio, x45 y+5 vShandieRadio3
Gui, MyWindow:Add, Radio, x30 y+1 vShandieRadio6
Gui, MyWindow:Add, Radio, x+1 vShandieRadio1
Gui, MyWindow:Add, Radio, x15 y+1 vShandieRadio8
Gui, MyWindow:Add, Radio, x+1 vShandieRadio4 checked%ShandieRadio4%
Gui, MyWindow:Add, Radio, x+1 vShandieRadio0
Gui, MyWindow:Add, Radio, x30 y+1 vShandieRadio7
Gui, MyWindow:Add, Radio, x+1 vShandieRadio2
Gui, MyWindow:Add, Radio, x45 y+1 vShandieRadio5

statTabTxtWidth := 
Gui, Tab, Stats
Gui, MyWindow:Add, Text, x15 y33 %statTabTxtWidth%, SB Stack `Count: 
Gui, MyWindow:Add, Text, vgStackCountSBID x+2 w50, % gStackCountSB
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Haste Stack `Count:
Gui, MyWindow:Add, Text, vgStackCountHID x+2 w50, % gStackCountH
Gui, MyWindow:Add, Text, x15 y+10 %statTabTxtWidth%, Current `Run `Time:
Gui, MyWindow:Add, Text, vdtCurrentRunTimeID x+2 w50, % dtCurrentRunTime
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Total `Run `Time:
Gui, MyWindow:Add, Text, vdtTotalTimeID x+2 w50, % dtTotalTime
Gui, MyWindow:Add, Text, x15 y+10, Stats updated once per run:
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Total `Run `Count:
Gui, MyWindow:Add, Text, vgTotal_RunCountID x+2 w50, % gTotal_RunCount
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Previous `Run `Time:
Gui, MyWindow:Add, Text, vgPrevRunTimeID x+2 w50, % gPrevRunTime
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Fastest `Run `Time:
Gui, MyWindow:Add, Text, vgFastRunTimeID x+2 w50, 
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Slowest `Run `Time:
Gui, MyWindow:Add, Text, vgSlowRunTimeID x+2 w50, % gSlowRunTime		
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Avg. `Run `Time:
Gui, MyWindow:Add, Text, vgAvgRunTimeID x+2 w50, % gAvgRunTime
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Bosses per hour:
Gui, MyWindow:Add, Text, vgbossesPhrID x+2 w50, % gbossesPhr
Gui, MyWindow:Font, w400

Gui, Tab, Debug
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, `Loop: 
Gui, MyWindow:Add, Text, vgLoopID x+2 w200, Not Started
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, ElapsedTime:
Gui, MyWindow:Add, Text, vElapsedTimeID x+2 w200, % ElapsedTime
Gui, MyWindow:Add, Text, x15 y+2, gFKeys:
Gui, MyWindow:Add, Text, vgFKeysID x+2 w300, % gFKeys
Gui, MyWindow:Add, Text, x15 y+2, gAreaLow:
Gui, MyWindow:Add, Text, vgAreaLowID x+2 w200, % gAreaLow
Gui, MyWindow:Add, Text, x15 y+2, gSBTargetStacks:
Gui, MyWindow:Add, Text, vgSBTargetStacksID x+2 w200, % gSBTargetStacks
Gui, MyWindow:Add, Text, x15 y+2, gDashSleepTime:
Gui, MyWindow:Add, Text, vDashSleepTimeID x+2 w200, % gDashSleepTime
Gui, MyWindow:Add, Text, x15 y+2, gContinuedLeveling:
Gui, MyWindow:Add, Text, vgContinuedLevelingID x+2 w200, % gContinuedLeveling
Gui, MyWindow:Add, Text, x15 y+2, gUlts:
Gui, MyWindow:Add, Text, vgUltsID x+2 w200, % gUlts
Gui, MyWindow:Add, Text, x15 y+2, gBrivSwap:
Gui, MyWindow:Add, Text, vgBrivSwapID x+2 w200, % gBrivSwap
Gui, MyWindow:Add, Text, x15 y+2, gAvoidBosses:
Gui, MyWindow:Add, Text, vgAvoidBossesID x+2 w200, % gAvoidBosses
Gui, MyWindow:Add, Text, x15 y+2, gClickLeveling:
Gui, MyWindow:Add, Text, vgClickLevelingID x+2 w200, % gClickLeveling
Gui, MyWindow:Add, Text, x15 y+2, gStackRestart:
Gui, MyWindow:Add, Text, vgStackRestartID x+2 w200, % gStackRestart
Gui, MyWindow:Add, Text, x15 y+2, gShandieSlot:
Gui, MyWindow:Add, Text, vgShandieSlotID x+2 w200, % gShandieSlot
Gui, MyWindow:Add, Text, x15 y+2, gLevel_Number:
Gui, MyWindow:Add, Text, vgLevel_NumberID x+2 w200, % gLevel_Number
Gui, MyWindow:Add, Text, x15 y+2, gQuestRemaining:
Gui, MyWindow:Add, Text, vgQuestRemainingID x+2 w200, % gQuestRemaining
Gui, MyWindow:Add, Text, x15 y+2, gTrans:
Gui, MyWindow:Add, Text, vgTransID x+2 w200, % gTrans
Gui, MyWindow:Add, Text, x15 y+2, gTime:
Gui, MyWindow:Add, Text, vgTimeID x+2 w200, % gTime
Gui, MyWindow:Add, Text, x15 y+2, gShandieLvl:
Gui, MyWindow:Add, Text, vgShandieLvlID x+2 w200, % gShandieLvl
Gui, MyWindow:Add, Text, x15 y+2, gCoreXP:
Gui, MyWindow:Add, Text, vgCoreXPID x+2 w200, % gCoreXP
Gui, MyWindow:Add, Text, x15 y+2, gCoreXPStart:
Gui, MyWindow:Add, Text, vgCoreXPStartID x+2 w200, % gCoreXPStart
Gui, MyWindow:Add, Text, x15 y+2, gHewUlt:
Gui, MyWindow:Add, Text, vgHewUltID x+2 w200, % gHewUlt
Gui, MyWindow:Add, Text, x15 y+2, dtCurrentLevelTime:
Gui, MyWindow:Add, Text, vdtCurrentLevelTimeID x+2 w200, % dtCurrentLevelTime
Gui, MyWindow:Add, Text, x15 y+2, ResetCount:
Gui, MyWindow:Add, Text, vResetCountID x+2 w200, % ResetCount
Gui, MyWindow:Add, Text, x15 y+2, ModResetting:
Gui, MyWindow:add, Text, vModResettingID x+2 w50,

Gui, MyWindow:Show

Save_Clicked:
{
	Gui, Submit, NoHide
	Loop, 12
	{
		gSeatToggle[A_Index] := CheckboxSeat%A_Index%
	}
	gFKeys :=
	Loop, 12
	{
		if (gSeatToggle[A_Index])
		{
			gFKeys = %gFKeys%{F%A_Index%}
		}
	}
	GuiControl, MyWindow:, gFKeysID, % gFKeys
	if ShandieRadio0
	{
		gShandieSlot := 0
	}
	else
	{
		loop, 8
		{
			if (ShandieRadio%A_Index%)
			{
				gShandieSlot := A_Index
				Break
			}
		}
	}
	GuiControl, MyWindow:, gShandieSlotID, % gShandieSlot
	gAreaLow := NewgAreaLow
	GuiControl, MyWindow:, gAreaLowID, % gAreaLow
	gSBTargetStacks := NewSBTargetStacks
	GuiControl, MyWindow:, gSBTargetStacksID, % gSBTargetStacks
	gDashSleepTime := NewDashSleepTime
	GuiControl, MyWindow:, DashSleepTimeID, % gDashSleepTime
	gContinuedLeveling := NewContinuedLeveling
	GuiControl, MyWindow:, gContinuedLevelingID, % gContinuedLeveling
	gHewUlt := NewHewUlt
	GuiControl, MyWindow:, gHewUltID, % gHewUlt
	GuiControl, MyWindow:, gUltsID, % gUlts
	GuiControl, MyWindow:, gBrivSwapID, % gBrivSwap
	GuiControl, MyWindow:, gAvoidBossesID, % gAvoidBosses
	GuiControl, MyWindow:, gClickLevelingID, % gClickLeveling
	GuiControl, MyWindow:, gStackRestartID, % gStackRestart
	return
}

Reload_Clicked:
{
	Reload
	return
}

Run_Clicked:
{
	gStartTime := A_TickCount
	gRunStartTime := A_TickCount
	GemFarm()
	return
}

MyWindowGuiClose() 
{
	MsgBox 4,, Are you sure you want to `exit?
	IfMsgBox Yes
	ExitApp
    IfMsgBox No
    return True
}

$`::
Pause
gPrevLevelTime := A_TickCount
return

SafetyCheck() 
{
    While (Not WinExist("ahk_exe IdleDragons.exe")) 
    {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
        StartTime := A_TickCount
        ElapsedTime := 0
        GuiControl, MyWindow:, gloopID, Opening IC
        While (Not WinExist("ahk_exe IdleDragons.exe") AND ElapsedTime < 60000) 
        {
			Sleep 1000
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
        If (Not WinExist("ahk_exe IdleDragons.exe"))
        Return

        GuiControl, MyWindow:, gloopID, Opening `Process
		Sleep gOpenProcess
		OpenProcess()
        GuiControl, MyWindow:, gloopID, Loading Module Base
		Sleep gGetAddress
		ModuleBaseAddress()
	    ++ResetCount
        GuiControl, MyWindow:, ResetCountID, % ResetCount
		gPrevLevelTime := A_TickCount
    }
}

LevelUp()
{
	StartTime := A_TickCount
    ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Leveling Shandie
	while (ShandieLvl() < 120 AND ElapsedTime < 5000)
    {
	    DirectedInput("q{F6}")
        ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
    }

    gTime := TimeScaleMulti()
    DashSpeed := gTime * 1.5
    sleepy := gDashSleepTime / gTime
    StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Dash Wait
	While (TimeScaleMulti() < DashSpeed AND ElapsedTime < sleepy)
	{
		DirectedInput(gFKeys)
		DirectedInput("q")
		if gClickLeveling
		DirectedInput("``")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if !gDashSleepTime
	{
		Loop, 20
		{
			DirectedInput(gFKeys)
			if (gClickLeveling)
			directedinput("``")
		}
	}
	if gUlts
	{
		StartTime := A_TickCount
        ElapsedTime := 0
        GuiControl, MyWindow:, gloopID, Transitioning
		while Transitioning()
		{
			sleep, 100
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
		Loop, 3
		{
			DirectedInput("23456789")
		}
		Sleep, 2000
	}
	DirectedInput("g")
	gPrevLevelTime := A_TickCount
}

DirectedInput(s) 
{
	SafetyCheck()
	ControlFocus,, ahk_exe IdleDragons.exe
	ControlSend,, {Blind}%s%, ahk_exe IdleDragons.exe
	Sleep, %ScriptSpeed%
}

CurrentLevel()
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
	gLevel_Number := idle.read(Controller, "Int", arrayPointerOffsetsLevel*)
	GuiControl, MyWindow:, gLevel_NumberID, % gLevel_Number
	return gLevel_Number
}

QuestRemaining()
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    gQuestRemaining := idle.read(Controller, "Int", arrayPointerOffsetsQR*)
    GuiControl, MyWindow:, gQuestRemainingID, % gQuestRemaining
	return gQuestRemaining
}

ShandieLvl()
{

    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    gShandieLvl := idle.read(Controller, "Int", arrayPointerOffsetsShandieLvl*)
    GuiControl, MyWindow:, gShandieLvlID, % gShandieLvl
	return gShandieLvl
}

TimeScaleMulti()
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    gTime := Round(idle.read(Controller, "Float", arrayPointerOffsetsTimeScaleMultiplier*), 3)
    GuiControl, MyWindow:, gTimeID, % gTime
	return gTime
}

Transitioning()
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
	gTrans := idle.read(Controller, "Char", arrayPointerOffsetsTransitioning*)
	GuiControl, MyWindow:, gTransID, % gTrans
	return gTrans
}

StackRead()
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
	gStackCountH := idle.read(Controller, "Int", arrayPointerOffsetsH*)
	GuiControl, MyWindow:, gStackCountHID, % gStackCountH
	gStackCountSB := idle.read(Controller, "Int", arrayPointerOffsetsSB*)
	GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
	return gStackCountH + gStackCountSB
}

ReadCoreXP()
{

    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    gCoreXP := idle.read(Controller, "Int", arrayPointerOffsetsCoreXP*)
    GuiControl, MyWindow:, gCoreXPID, % gCoreXP
	return gCoreXP
}

Resetting()
{
    Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    ModResetting := idle.read(Controller, "Char", arrayPointerOffsetsResetting*)
    GuiControl, MyWindow:, ModResettingID, % ModResetting
	return ModResetting
}

ChampionLvlbySlot(slot)
{
	Controller := idle.getAddressFromOffsets(pointerBaseController, arrayPointerOffsetsController*)
    level := idle.read(Controller, "Int", arrayPointerOffsetsSlotLvl%slot%*)
    ;GuiControl, MyWindow:, ChampLvlSlot%slot%ID, % Level
	return level
}

SetFormation(gLevel_Number)
{
	if (gAvoidBosses and !Mod(gLevel_Number, 5))
	{
		DirectedInput("e")
	}
	else if (!QuestRemaining() AND Transitioning() AND gBrivSwap)
	{
		DirectedInput("e")
		StartTime := A_TickCount
		ElapsedTime := 0
		GuiControl, MyWindow:, gloopID, Transitioning
		while (ElapsedTime < 5000 AND !QuestRemaining())
		{
			DirectedInput("{Right}")
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
		StartTime := A_TickCount
		ElapsedTime := 0
		gTime := TimeScaleMulti()
		sleepy := 1500 / gTime
		GuiControl, MyWindow:, gloopID, Still Transitioning
		while (ElapsedTime < sleepy AND Transitioning())
		{
			DirectedInput("{Right}")
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
		DirectedInput("q")
	}
	else
	DirectedInput("q")
}

LoadingZone()
{
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Loading Zone
	while (!ChampionLvlbySlot(gShandieSlot) AND ElapsedTime < 180000)
	{
		DirectedInput("q{F6}")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Confirming Zone Load
	while (ChampionLvlbySlot(gShandieSlot) AND ElapsedTime < 180000)
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

StackRestart()
{
	GuiControl, MyWindow:, gloopID, Start Stack Restart
	Sleep 1000
	PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Closing IC
	While (WinExist("ahk_exe IdleDragons.exe") AND ElapsedTime < 60000) 
	{
        Sleep 100
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack `Sleep
	while (ElapsedTime < 12000)
	{
		Sleep 100
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	SafetyCheck()
    LoadingZone()
}

StackFarm()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack Farm
	while (StackRead() < gSBTargetStacks AND ElapsedTime < gSBTimeMax)
	{
		directedinput("w")
        if (gLevel_Number <= gAreaLow) 
		{
        	DirectedInput("{Right}")
		}
		Sleep 1000
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

UpdateStartLoopStats()
{
	if (gTotal_RunCount = 0)
	{
		gStartTime := A_TickCount
		gCoreXPStart := ReadCoreXP()
		GuiControl, MyWindow:, gCoreXPStartID, % gCoreXPStart
	}
	if (gTotal_RunCount)
	{
		gPrevRunTime := round((A_TickCount - gRunStartTime) / 60000, 2)
        GuiControl, MyWindow:, gPrevRunTimeID, % gPrevRunTime
		if (gSlowRunTime < gPrevRunTime)
		{
			gSlowRunTime := gPrevRunTime
            GuiControl, MyWindow:, gSlowRunTimeID, % gSlowRunTime
		}
		if (gFastRunTime > gPrevRunTime)
		{
			gFastRunTime := gPrevRunTime
            GuiControl, MyWindow:, gFastRunTimeID, % gFastRunTime
		}
		dtTotalTime := (A_TickCount - gStartTime) / 3600000
		gAvgRunTime := Round((dtTotalTime / gTotal_RunCount) * 60, 2)
		GuiControl, MyWindow:, gAvgRunTimeID, % gAvgRunTime
		dtTotalTime := (A_TickCount - gStartTime) / 3600000
		TotalBosses := (ReadCoreXP() - gCoreXPStart) / 5
		gbossesPhr := Round(TotalBosses / dtTotalTime, 2)
		GuiControl, MyWindow:, gbossesPhrID, % gbossesPhr
		GuiControl, MyWindow:, gTotal_RunCountID, % gTotal_RunCount
	}
	gRunStartTime := A_TickCount
	gPrevLevel := gLevel_Number
    GuiControl, MyWindow:, gPrevLevelID, % gPrevLevel
}

UpdateStatTimers()
{
	dtCurrentRunTime := Round((A_TickCount - gRunStartTime) / 60000, 2)
	GuiControl, MyWindow:, dtCurrentRunTimeID, % dtCurrentRunTime
	dtTotalTime := Round((A_TickCount - gStartTime) / 3600000, 2)
	GuiControl, MyWindow:, dtTotalTimeID, % dtTotalTime
	dtCurrentLevelTime := Round((A_TickCount - gPrevLevelTime) / 1000, 2)
	GuiControl, MyWindow:, dtCurrentLevelTimeID, % dtCurrentLevelTime	
}

UpdateElapsedTime(StartTime)
{
	ElapsedTime := A_TickCount - StartTime
	GuiControl, MyWindow:, ElapsedTimeID, % ElapsedTime
	return ElapsedTime
}

GemFarm() 
{  
	OpenProcess()
	ModuleBaseAddress()
	
	gprevLevel := CurrentLevel()
	gPrevLevelTime := A_TickCount

	loop 
	{
        GuiControl, MyWindow:, gLoopID, Main `Loop
		gLevel_Number := CurrentLevel()
		
		SetFormation(gLevel_Number)

		if (ShandieLvl() < 120)
		{
			LoadingZone()
			directedinput("g")
			LevelUp()
        }

		if (StackRead() < gSBTargetStacks AND gLevel_Number > gAreaLow)
		{
			Loop, 3
			{
				DirectedInput("w")
			}
			DirectedInput("g")
			;send input Left while on a boss zone
			while (!mod(CurrentLevel(), 5))
			{
				DirectedInput("{Left}")
			}
			if gStackRestart
            StackRestart()
			else if (StackRead() < gSBTargetStacks)
			StackFarm()
			gPrevLevelTime := A_TickCount
			DirectedInput("g")
		}
		
        DirectedInput("{Right}")
		If (gClickLeveling)
		{
			DirectedInput("``")
		}
		if (gContinuedLeveling > gLevel_Number OR !gLevel_Number)
		{
			DirectedInput(gFKeys)
		}
		if (gHewUlt)
		{
			DirectedInput(gHewUlt)
		}

		if (Resetting())
		{
			ModronReset()
			LoadingZone()
			UpdateStartLoopStats()
			++gTotal_RunCount
			directedinput("g")
			LevelUp()
			gPrevLevelTime := A_TickCount
			gprevLevel := CurrentLevel()
		}

		CheckifStuck(gLevel_Number)
		UpdateStatTimers()
    }
}

CheckifStuck(gLevel_Number)
{
	if (gLevel_Number != gprevLevel)
	{
		gprevLevel := gLevel_Number
		GuiControl, MyWindow:, gprevLevelID, % gprevLevel
		gPrevLevelTime := A_TickCount
	}
	
	dtCurrentLevelTime := Round((A_TickCount - gPrevLevelTime) / 1000, 2)
	GuiControl, MyWindow:, dtCurrentLevelTimeID, % dtCurrentLevelTime		
	if (dtCurrentLevelTime > 60)
	{
		PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
		sleep 2000
		GuiControl, MyWindow:, gloopID, Closing IC Stuck
		StartTime := A_TickCount
		ElapsedTime := 0
		While (WinExist("ahk_exe IdleDragons.exe")) 
		{
			PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
			sleep 1000
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
		SafetyCheck()
		LoadingZone()
		gPrevLevelTime := A_TickCount
	}
}

ModronReset()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Modron Reset
	while (Resetting() AND ElapsedTime < 300000)
	{
		Sleep, 250
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Resetting to z1
	while (CurrentLevel() != 1 AND ElapsedTime < 300000)
	{
		Sleep, 250
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}
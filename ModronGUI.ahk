#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
global ScriptDate := "4/25/21"
;put together with the help from many different people. thanks for all the help.
SetWorkingDir, %A_ScriptDir%
CoordMode, Mouse, Client

;========================================
;User settings not accessible via the GUI
;========================================
;variables to consider changing if restarts are causing issues
global gOpenProcess	:= 10000	;time in milliseconds for your PC to open Idle Champions
global gGetAddress := 5000		;time in milliseconds after Idle Champions is opened for it to load pointer base into memory

;variables for opening chests during stack restart
global gDoChests := 1 ;enable/disable will buy specified chests when you have enough gold and will open specified chests when hoarded amount reaches a certain number

global ScriptSpeed := 25
;====================
;end of user settings
;====================

;class and methods for parsing JSON (User details sent back from a server call)
#include JSON.ahk

;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include classMemory.ahk

;Check if you have installed the class correctly.
if (_ClassMemory.__Class != "_ClassMemory")
{
	msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
	ExitApp
}

;pointer addresses and offsets
#include IC_MemoryFunctions.ahk

;Thanks ThePuppy for the ini code
;Champions to level with Fkeys
global gFKeys := 
loop, 12
{
	IniRead, Seat%A_Index%Toggle, UserSettings.ini, Section1, Seat%A_Index%Toggle
	if (Seat%A_Index%Toggle)
	{
		gFKeys = %gFKeys%{F%A_Index%}
	}
}
global gSeatToggle := [Seat1Toggle,Seat2Toggle,Seat3Toggle,Seat4Toggle,Seat5Toggle,Seat6Toggle,Seat7Toggle,Seat8Toggle,Seat9Toggle,Seat10Toggle,Seat11Toggle,Seat12Toggle]
;Continued leveling stop zone
IniRead, ContinuedLeveling, UserSettings.ini, Section1, ContinuedLeveling, 10
global gContinuedLeveling := ContinuedLeveling
;Farm SB stacks after this zone
IniRead, AreaLow, UserSettings.ini, Section1, AreaLow, 30
global gAreaLow := AreaLow
;Lowest zone SB stacks can be farmed on
IniRead, MinStackZone, UserSettings.ini, Section1, MinStackZone, 25
global gMinStackZone := MinStackZone
;Target Haste stacks
IniRead, SBTargetStacks, UserSettings.ini, Section1, SBTargetStacks, 400
global gSBTargetStacks := SBTargetStacks
;Dash wait max time
IniRead, DashSleepTime, UserSettings.ini, Section1, DashSleepTime, 60000
global gDashSleepTime := DashSleepTime
;Hew's ult key
IniRead, HewUlt, UserSettings.ini, Section1, HewUlt, 6
global gHewUlt := HewUlt
;spam ults after initial leveling
IniRead, Ults, UserSettings.ini, Section1, Ults
global gUlts := Ults
;Briv swap to avoid animation
IniRead, BrivSwap, UserSettings.ini, Section1, BrivSwap
global gBrivSwap := BrivSwap
;Briv swap to avoid bosses
IniRead, AvoidBosses, UserSettings.ini, Section1, AvoidBosses
global gAvoidBosses := AvoidBosses
;Click damage toggle
IniRead, ClickLeveling, UserSettings.ini, Section1, ClickLeveling
global gClickLeveling := ClickLeveling
;Stack fail recovery toggle
IniRead, StackFailRecovery, UserSettings.ini, Section1, StackFailRecovery
global gStackFailRecovery := StackFailRecovery
;Stack fail recovery toggle
IniRead, StackFailConvRecovery, UserSettings.ini, Section1, StackFailConvRecovery
global gStackFailConvRecovery := StackFailConvRecovery
;Briv swap sleep time
IniRead, SwapSleep, UserSettings.ini, Section1, SwapSleep, 1500
global gSwapSleep := SwapSleep
;Restart stack sleep time
IniRead, RestartStackTime, UserSettings.ini, Section1, RestartStackTime, 12000
global gRestartStackTime := RestartStackTime
;Intall location
IniRead, GameInstallPath, Usersettings.ini, Section1, GameInstallPath, C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe
global gInstallPath := GameInstallPath
;Modron Reset Check
IniRead, ModronResetCheckEnabled, UserSettings.ini, Section1, ModronResetCheckEnabled
global gModronResetCheckEnabled := ModronResetCheckEnabled
;Normal SB farm max time
IniRead, SBTimeMax, UserSettings.ini, Section1, SBTimeMax, 60000
global gSBTimeMax := SBTimeMax

;Shandie's seat 
global gShandieSlot := 

;variable for correctly tracking stats during a failed stack, to prevent fast/slow runs to be thrown off
global gStackFail := 0

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

;globals for reset tracking
global gFailedStacking := 0
global gFailedStackConv := 0
global ResetCount		:= 0
;globals used for stat tracking
global gGemStart		:=
global gCoreXPStart		:=
global gGemSpentStart	:=

global gCoreTargetArea := ;global to help protect against script attempting to stack farm immediately before a modron reset

global gTestReset := 0 ;variable to test a reset function not ready for release

Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Add, Button, x415 y25 w60 gSave_Clicked, Save
Gui, MyWindow:Add, Button, x415 y+50 w60 gRun_Clicked, `Run
Gui, MyWindow:Add, Button, x415 y+100 w60 gReload_Clicked, `Reload
Gui, MyWindow:Add, Tab3, x5 y5 w400, Read First|Settings|Help|Stats|Debug|

Gui, Tab, Read First
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y30, Gem Farm, %ScriptDate%
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, Instructions:
Gui, MyWindow:Add, Text, x15 y+2 w10, 1.
Gui, MyWindow:Add, Text, x+2 w370, Save your speed formation in formation save slot 1, in game `hotkey "Q". This formation must include Shandie, Briv, and at least one familiar on the field.
Gui, MyWindow:Add, Text, x15 y+2 w10, 2.
Gui, MyWindow:Add, Text, x+2 w370, Save your stack farming formation in formation save slot 2, in game `hotkey "W". Don't include any familiars on the field or any champions in the formation slot Shandie is in as part of formation save slot 1.
Gui, MyWindow:Add, Text, x15 y+2 w10, 3.
Gui, MyWindow:Add, Text, x+2 w370, Save your speed formation without Briv, Hew, or Melf in formation save slot 3, in game `hotkey "E". This step may be ommitted if you will not be swapping out Briv to cancel his jump animation.
Gui, MyWindow:Add, Text, x15 y+2, 4. Adjust the settings on the settings tab.
Gui, MyWindow:Add, Text, x15 y+2, 5. `Click the save button to save your settings.
Gui, MyWindow:Add, Text, x15 y+2, 6. Load into zone 1 of an adventure to farm gems.
Gui, MyWindow:Add, Text, x15 y+2, 7. Press the run button to start farming gems.
Gui, MyWindow:Add, Text, x15 y+10, Notes:
Gui, MyWindow:Add, Text, x15 y+2, 1. Use the pause hotkey, ``, to adjust settings after a run starts.
Gui, MyWindow:Add, Text, x15 y+2, 2. Don't forget to unpause after saving your settings.
Gui, MyWindow:Add, Text, x15 y+2, 3. First run is ignored for stats, in case it is a partial run.
Gui, MyWindow:Add, Text, x15 y+2, 4. Settings save to and load from UserSettings.ini file.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 5.
Gui, MyWIndow:Add, Text, x+2 w370, Recommended SB stack level is [Modron Reset Zone] - X, with X = 4 for single skip, X = 6 for double skip, X = 8 for triple skip, and X = 10 for quadruple skip.
Gui, MyWindow:Add, Text, x15 y+2 w10, 6.
Gui, MyWindow:Add, Text, x+2 w370, Script will activate and focus the game window for manual resets as part of failed stacking.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 7.
Gui, MyWIndow:Add, Text, x+2 w370, Script communicates directly with Idle Champions play servers to recover from a failed stacking and for when Modron resets to the World Map.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 8.
Gui, MyWIndow:Add, Text, x+2 w370, Script reads system memory.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 9.
Gui, MyWIndow:Add, Text, x+2 w370, The script does not work without Shandie.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 10.
Gui, MyWIndow:Add, Text, x+2 w370, Disable manual resets to recover from failed Briv stack conversions when running event free plays.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 11.
Gui, MyWIndow:Add, Text, x+2 w370, Recommended Briv swap `sleep time is betweeb 1500 - 3000. If you are seeing Briv's landing animation then increase the the swap sleep time. If Briv is not back in the formation before monsters can be killed then decrease the swap sleep time.
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
Gui, MyWindow:Add, Text, x+5, Use Fkey leveling while below this zone
Gui, MyWindow:Add, Edit, vNewgAreaLow x15 y+10 w50, % gAreaLow
Gui, MyWindow:Add, Text, x+5, Farm SB stacks AFTER this zone
Gui, MyWindow:Add, Edit, vNewgMinStackZone x15 y+10 w50, % gMinStackZone
Gui, MyWindow:Add, Text, x+5, Minimum zone Briv can farm SB stacks on
Gui, MyWindow:Add, Edit, vNewSBTargetStacks x15 y+10 w50, % gSBTargetStacks
Gui, MyWindow:Add, Text, x+5, Target Haste stacks for next run
Gui, MyWindow:Add, Edit, vNewgSBTimeMax x15 y+10 w50, % gSBTimeMax
Gui, MyWindow:Add, Text, x+5, Maximum time (ms) script will spend farming SB stacks
Gui, MyWindow:Add, Edit, vNewDashSleepTime x15 y+10 w50, % gDashSleepTime
Gui, MyWindow:Add, Text, x+5, Maximum time (ms) script will wait for Dash (0 disables)
Gui, MyWindow:Add, Edit, vNewHewUlt x15 y+10 w50, % gHewUlt
Gui, MyWindow:Add, Text, x+5, `Hew's ultimate key (0 disables)
Gui, MyWindow:Add, Edit, vNewRestartStackTime x15 y+10 w50, % gRestartStackTime
Gui, MyWindow:Add, Text, x+5, `Time (ms) client remains closed for Briv Restart Stack (0 disables)
Gui, MyWindow:Add, Checkbox, vgUlts Checked%gUlts% x15 y+10, Use ults 2-9 after intial champion leveling
Gui, MyWindow:Add, Checkbox, vgBrivSwap Checked%gBrivSwap% x15 y+5, Swap to 'e' formation to cancel Briv's jump animation
Gui, MyWindow:Add, Edit, vNewSwapSleep x15 y+5 w40, % gSwapSleep
Gui, MyWindow:Add, Text, x+5, Briv swap sleep time (ms)
Gui, MyWindow:Add, Checkbox, vgAvoidBosses Checked%gAvoidBosses% x15 y+10, Swap to 'e' formation when `on boss zones
Gui, MyWindow:Add, Checkbox, vgClickLeveling Checked%gClickLeveling% x15 y+5, `Uncheck `if using a familiar `on `click damage
Gui, MyWindow:Add, Checkbox, vgStackFailRecovery Checked%gStackFailRecovery% x15 y+5, Enable manual resets to recover from failed Briv stacking
Gui, MyWindow:Add, Checkbox, vgStackFailConvRecovery Checked%gStackFailConvRecovery% x15 y+5, Enable manual resets to recover from failed Briv stack conversion
Gui, MyWindow:Add, Checkbox, vgModronResetCheckEnabled Checked%gModronResetCheckEnabled% x15 y+5, Have script check for Modron reset level
Gui, MyWindow:Add, Button, x15 y+20 gChangeInstallLocation_Clicked, Change Install Path

Gui, Tab, Help
;Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y30, Confirm your settings are saved. 
Gui, MyWindow:Add, Text, x15 y+2, 1 = true, yes, or enabled
Gui, MyWindow:Add, Text, x15 y+2, 0 = false, no, or disabled
;Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+15, Fkeys used for leveling: 
Gui, MyWindow:Add, Text, vgFKeysID x+2 w300, % gFKeys
Gui, MyWindow:Add, Text, x15 y+5, Use Fkey leveling while below this zone: 
Gui, MyWindow:Add, Text, vgContinuedLevelingID x+2 w200, % gContinuedLeveling
Gui, MyWindow:Add, Text, x15 y+5, Farm SB stacks AFTER this zone: 
Gui, MyWindow:Add, Text, vgAreaLowID x+2 w200, % gAreaLow
Gui, MyWindow:Add, Text, x15 y+5, Minimum zone Briv can farm SB stacks on: 
Gui, MyWindow:Add, Text, vgMinStackZoneID x+2 w200, % gMinStackZone 
Gui, MyWindow:Add, Text, x15 y+5, Target Haste stacks for next run: 
Gui, MyWindow:Add, Text, vgSBTargetStacksID x+2 w200, % gSBTargetStacks
Gui, MyWindow:Add, Text, x15 y+5, Max time script will farm SB Stacks normally: 
Gui, MyWindow:Add, Text, vgSBTimeMaxID x+2 w200, % gSBTimeMax
Gui, MyWindow:Add, Text, x15 y+5, Maximum time (ms) script will wait for Dash: 
Gui, MyWindow:Add, Text, vDashSleepTimeID x+2 w200, % gDashSleepTime
Gui, MyWindow:Add, Text, x15 y+5, Hew's ultimate key: 
Gui, MyWindow:Add, Text, vgHewUltID x+2 w200, % gHewUlt
Gui, MyWindow:Add, Text, x15 y+5, Time (ms) client remains closed for Briv Restart Stack:
Gui, MyWindow:Add, Text, vgRestartStackTimeID x+2 w200, % gRestartStackTime
Gui, MyWindow:Add, Text, x15 y+5, Use ults 2-9 after initial champion leveling:
Gui, MyWindow:Add, Text, vgUltsID x+2 w200, % gUlts
Gui, MyWindow:Add, Text, x15 y+5, Swap to 'e' formation to cancle Briv's jump animation:
Gui, MyWindow:Add, Text, vgBrivSwapID x+2 w200, % gBrivSwap
Gui, MyWindow:Add, Text, x15 y+5, Briv swap sleep time (ms):
Gui, MyWindow:Add, Text, vgSwapSleepID x+2 w200, % gSwapSleep
Gui, MyWindow:Add, Text, x15 y+5, Swap to 'e' formation when on boss zones:
Gui, MyWindow:Add, Text, vgAvoidBossesID x+2 w200, % gAvoidBosses
Gui, MyWindow:Add, Text, x15 y+5, Using a familiar on click damage:
Gui, MyWindow:Add, Text, vgClickLevelingID x+2 w200, % gClickLeveling
Gui, MyWindow:Add, Text, x15 y+5, Enable manual resets to recover from failed Briv stacking:
Gui, MyWindow:Add, Text, vgStackFailRecoveryID x+2 w200, % gStackFailRecovery
Gui, MyWindow:Add, Text, x15 y+5, Enable manual resets to recover from failed Briv stack conversion:
Gui, MyWindow:Add, Text, vgStackFailConvRecoveryID x+2 w200, % gStackFailConvRecovery
Gui, MyWindow:Add, Text, x15 y+5, Enable script to check for Modron reset level:
Gui, MyWindow:Add, Text, vgModronResetCheckenabledID x+2 w200, % gModronResetCheckEnabled
Gui, MyWindow:Add, Text, x15 y+5, Install Path:
Gui, MyWindow:Add, Text, vgInstallPathID x15 y+2 w350 r5, %gInstallPath%
Gui, MyWindow:Add, Text, x15 y+15 w375 r5, Still having trouble? Take note of the information on the debug tab and ask for help in the scripting channel on the official discord.

statTabTxtWidth := 
Gui, Tab, Stats
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, Stats updated continuously (mostly):
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10 %statTabTxtWidth%, SB Stack `Count: 
Gui, MyWindow:Add, Text, vgStackCountSBID x+2 w50, % gStackCountSB
;Gui, MyWindow:Add, Text, vReadSBStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Haste Stack `Count:
Gui, MyWindow:Add, Text, vgStackCountHID x+2 w50, % gStackCountH
;Gui, MyWindow:Add, Text, vReadHasteStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+10 %statTabTxtWidth%, Current `Run `Time:
Gui, MyWindow:Add, Text, vdtCurrentRunTimeID x+2 w50, % dtCurrentRunTime
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Total `Run `Time:
Gui, MyWindow:Add, Text, vdtTotalTimeID x+2 w50, % dtTotalTime
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+10, Stats updated once per run:
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10 %statTabTxtWidth%, Total `Run `Count:
Gui, MyWindow:Add, Text, vgTotal_RunCountID x+2 w50, % gTotal_RunCount
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Previous `Run `Time:
Gui, MyWindow:Add, Text, vgPrevRunTimeID x+2 w50, % gPrevRunTime
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Fastest `Run `Time:
Gui, MyWindow:Add, Text, vgFastRunTimeID x+2 w50, 
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Slowest `Run `Time:
Gui, MyWindow:Add, Text, vgSlowRunTimeID x+2 w50, % gSlowRunTime
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Fail `Run `Time:
Gui, MyWindow:Add, Text, vgFailRunTimeID x+2 w50, % gFailRunTime	
Gui, MyWindow:Add, Text, x15 y+2 %statTabTxtWidth%, Avg. `Run `Time:
Gui, MyWindow:Add, Text, vgAvgRunTimeID x+2 w50, % gAvgRunTime
Gui, MyWindow:Font, cBlue w700
Gui, MyWindow:Add, Text, x15 y+10 %statTabTxtWidth%, Bosses per hour:
Gui, MyWindow:Add, Text, vgbossesPhrID x+2 w50, % gbossesPhr
Gui, MyWindow:Font, cGreen
Gui, MyWINdow:Add, Text, x15 y+10, Total Gems:
Gui, MyWindow:Add, Text, vGemsTotalID x+2 w50, % GemsTotal
Gui, MyWINdow:Add, Text, x15 y+2, Gems per hour:
Gui, MyWindow:Add, Text, vGemsPhrID x+2 w200, % GemsPhr
Gui, MyWindow:Font, cDefault w400
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+10, `Loop: 
Gui, MyWindow:Add, Text, vgLoopID x+2 w200, Not Started
Gui, MyWindow:Font, w400
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, vFamiliarFoundID x15 y+10 w300,
Gui, MyWindow:Font, w400
if (gDoChests)
{
	Gui, MyWindow:Font, w700
	Gui, MyWindow:Add, Text, x15 y+10 w300, Chest Data:
	Gui, MyWindow:Font, w400
	Gui, MyWindow:Add, Text, x15 y+5, Starting Gems: 
	Gui, MyWindow:Add, Text, vgSCRedRubiesStartID x+2 w200,
	Gui, MyWindow:Add, Text, x15 y+5, Starting Gems Spent: 
	Gui, MyWindow:Add, Text, vgSCRedRubiesSpentStartID x+2 w200,
	Gui, MyWindow:Add, Text, x15 y+5, Silvers Opened: 
	Gui, MyWindow:Add, Text, vgSCSilversOpenedID x+2 w200,
	Gui, MyWindow:Add, Text, x15 y+5, Golds Opened: 
	Gui, MyWindow:Add, Text, vgSCGoldsOpenedID x+2 w200,
	Gui, MyWindow:Add, Text, x15 y+5, Gems Spent Counted: 
	Gui, MyWindow:Add, Text, vgSCGemsSpentID x+2 w200,
	Gui, MyWindow:Add, Text, x15 y+5, Gems Spent Server: 
	Gui, MyWindow:Add, Text, vGemsSpentID x+2 w200,
}


Gui, Tab, Debug
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y35, Timers:
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, ElapsedTime:
Gui, MyWindow:Add, Text, vElapsedTimeID x+2 w200, % ElapsedTime
Gui, MyWindow:Add, Text, x15 y+2, dtCurrentLevelTime:
Gui, MyWindow:Add, Text, vdtCurrentLevelTimeID x+2 w200, % dtCurrentLevelTime

Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+15, Memory Reads: 
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+5, ReadCurrentZone: 
Gui, MyWindow:Add, Text, vReadCurrentZoneID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadQuestRemaining: 
Gui, MyWindow:Add, Text, vReadQuestRemainingID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadTimeScaleMultiplier: 
Gui, MyWindow:Add, Text, vReadTimeScaleMultiplierID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadTransitioning: 
Gui, MyWindow:Add, Text, vReadTransitioningID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadSBStacks: 
Gui, MyWindow:Add, Text, vReadSBStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadHasteStacks: 
Gui, MyWindow:Add, Text, vReadHasteStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadResetting: 
Gui, MyWindow:Add, Text, vReadResettingID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadUserID: 
Gui, MyWindow:Add, Text, vReadUserIDID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadUserHash: 
Gui, MyWindow:Add, Text, vReadUserHashID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadScreenWidth: 
Gui, MyWindow:Add, Text, vReadScreenWidthID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadScreenHeight: 
Gui, MyWindow:Add, Text, vReadScreenHeightID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampLvlBySlot: 
Gui, MyWindow:Add, Text, vReadChampLvlBySlotID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadMonstersSpawned:
Gui, MyWindow:Add, Text, vReadMonstersSpawnedID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampLvlByID:
Gui, MyWindow:Add, Text, vReadChampLvlByIDID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampSeatByID:
Gui, MyWindow:Add, Text, vReadChampSeatByIDID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadChampIDbySlot:
Gui, MyWindow:Add, Text, vReadChampIDbySlotID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadCoreTargetArea:
Gui, MyWindow:Add, Text, vReadCoreTargetAreaID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadCoreXP: 
Gui, MyWindow:Add, Text, vReadCoreXPID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadGems: 
Gui, MyWindow:Add, Text, vReadGemsID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadGemsSpent: 
Gui, MyWindow:Add, Text, vReadGemsSpentID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+5, ReadClickFamiliarBySlot: 
Gui, MyWindow:Add, Text, vReadClickFamiliarBySlotID x+2 w200,

Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+15, Server Call Variables: 
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+5, advtoload:
Gui, MyWindow:Add, Text, vadvtoloadID x+2 w300, % advtoload
Gui, MyWindow:Add, Text, x15 y+5, current_adventure_id:
Gui, MyWindow:Add, Text, vCurrentAdventureID x+2 w300,
Gui, MyWindow:Add, Text, x15 y+5, InstanceID:
Gui, MyWindow:Add, Text, vInstanceIDID x+2 w300, % InstanceID
Gui, MyWindow:Add, Text, x15 y+5, ActiveInstance:
Gui, MyWindow:Add, Text, vActiveInstanceID x+2 w300, % ActiveInstance

;server call functions and variables Included after GUI so chest tabs maybe non optimal way of doing it
#include IC_ServerCallFunctions.ahk

Gui, MyWindow:Show

Gui, InstallGUI:New
Gui, InstallGUI:Add, Edit, vNewInstallPath x15 y+10 w300 r5, % gInstallPath
Gui, InstallGUI:Add, Button, x15 y+25 gInstallOK_Clicked, Save and `Close
Gui, InstallGUI:Add, Button, x+100 gInstallCancel_Clicked, `Cancel

InstallCancel_Clicked:
{
	GuiControl, InstallGUI:, NewInstallPath, %gInstallPath%
	Gui, InstallGUI:Hide
	Return
}

InstallOK_Clicked:
{
	Gui, Submit, NoHide
	gInstallPath := NewInstallPath
	GuiControl, MyWindow:, gInstallPathID, %gInstallPath%
	IniWrite, %gInstallPath%, Usersettings.ini, Section1, GameInstallPath
	Gui, InstallGUI:Hide
	Return
}

ChangeInstallLocation_Clicked:
{
	Gui, InstallGUI:Show
	Return
}

Save_Clicked:
{
	Gui, Submit, NoHide
	Loop, 12
	{
		gSeatToggle[A_Index] := CheckboxSeat%A_Index%
		var := CheckboxSeat%A_Index%
		IniWrite, %var%, UserSettings.ini, Section1, Seat%A_Index%Toggle
	}
	gFKeys :=
	Loop, 12
	{
		if (gSeatToggle[A_Index])
		{
			gFKeys = %gFKeys%{F%A_Index%}
			IniWrite, 1, UserSettings.ini, Section1, Seat%A_Index%Toggle
		}
		Else
		IniWrite, 0, UserSettings.ini, Section1, Seat%A_Index%Toggle
	}
	GuiControl, MyWindow:, gFkeysID, % gFKeys
	gAreaLow := NewgAreaLow
	GuiControl, MyWindow:, gAreaLowID, % gAreaLow
	IniWrite, %gAreaLow%, UserSettings.ini, Section1, AreaLow
	gMinStackZone := NewgMinStackZone
	GuiControl, MyWindow:, gMinStackZoneID, % gMinStackZone
	IniWrite, %gMinStackZone%, Usersettings.ini, Section1, MinStackZone
	gSBTargetStacks := NewSBTargetStacks
	GuiControl, MyWindow:, gSBTargetStacksID, % gSBTargetStacks
	IniWrite, %gSBTargetStacks%, UserSettings.ini, Section1, SBTargetStacks
	gSBTimeMax := NewgSBTimeMax
	GuiControl, MyWindow:, gSBTimeMaxID, %gSBTimeMax%
	IniWrite, %gSBTimeMax%, Usersettings.ini, Section1, SBTimeMax
	gDashSleepTime := NewDashSleepTime
	GuiControl, MyWindow:, DashSleepTimeID, % gDashSleepTime
	IniWrite, %gDashSleepTime%, UserSettings.ini, Section1, DashSleepTime
	gContinuedLeveling := NewContinuedLeveling
	GuiControl, MyWindow:, gContinuedLevelingID, % gContinuedLeveling
	IniWrite, %gContinuedLeveling%, UserSettings.ini, Section1, ContinuedLeveling
	gHewUlt := NewHewUlt
	GuiControl, MyWindow:, gHewUltID, % gHewUlt
	IniWrite, %gHewUlt%, UserSettings.ini, Section1, HewUlt
	GuiControl, MyWindow:, gUltsID, % gUlts
	IniWrite, %gUlts%, UserSettings.ini, Section1, Ults
	GuiControl, MyWindow:, gBrivSwapID, % gBrivSwap
	IniWrite, %gBrivSwap%, UserSettings.ini, Section1, BrivSwap
	GuiControl, MyWindow:, gAvoidBossesID, % gAvoidBosses
	IniWrite, %gAvoidBosses%, UserSettings.ini, Section1, AvoidBosses
	GuiControl, MyWindow:, gClickLevelingID, % gClickLeveling
	IniWrite, %gClickLeveling%, UserSettings.ini, Section1, ClickLeveling
	GuiControl, MyWindow:, gStackFailRecoveryID, % gStackFailRecovery
	IniWrite, %gStackFailRecovery%, UserSettings.ini, Section1, StackFailRecovery
	GuiControl, MyWindow:, gStackFailConvRecoveryID, % gStackFailConvRecovery
	IniWrite, %gStackFailConvRecovery%, UserSettings.ini, Section1, StackFailConvRecovery
	gSwapSleep := NewSwapSleep
	GuiControl, MyWindow:, gSwapSleepID, % gSwapSleep
	IniWrite, %gSwapSleep%, UserSettings.ini, Section1, SwapSleep
	gRestartStackTime := NewRestartStackTime
	GuiControl, MyWindow:, gRestartStackTimeID, % gRestartStackTime
	IniWrite, %gRestartStackTime%, UserSettings.ini, Section1, RestartStackTime
	GuiControl, MyWindow:, gModronResetCheckEnabledID, % gModronResetCheckEnabled
	IniWrite, %gModronResetCheckEnabled%, UserSettings.ini, Section1, ModronResetCheckEnabled
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
		Run, %gInstallPath%
        ;Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
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
		LoadingZone()
		if (gUlts)
		DoUlts()
		gPrevLevelTime := A_TickCount
    }
}

CloseIC()
{
    PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Saving and Closing IC
	While (WinExist("ahk_exe IdleDragons.exe") AND ElapsedTime < 60000) 
	{
        Sleep 100
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
    While (WinExist("ahk_exe IdleDragons.exe")) 
	{
        GuiControl, MyWindow:, gloopID, Forcing IC Close
		PostMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe
		sleep 1000
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

CheckForFailedConv()
{
    gStackCountH := ReadHasteStacks(1)
	GuiControl, MyWindow:, gStackCountHID, % gStackCountH
	gStackCountSB := ReadSBStacks(1)
	GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
	stacks := gStackCountSB + gStackCountH
    If (gStackCountH < gSBTargetStacks AND stacks > gSBTargetStacks AND gTestReset)
    {
        EndAdventure()
		;If this sleep is too low it can cancel the reset before it completes. In this case that could be good as it will convert SB to Haste and not end the adventure.
		;Sleep, 2000
		CloseIC()
		if (GetUserDetails() = -1)
        {
            LoadAdventure()
        }
		SafetyCheck()
		++gFailedStackConv
		GuiControl, MyWindow:, gFailedStackConvID, % gFailedStackConv
        return
    }
	if (gStackCountH < gSBTargetStacks AND stacks > gSBTargetStacks AND !gTestReset)
	{
		TestResetFunction()
	}
	return
}

FinishZone()
{
	StartTime := A_TickCount
    ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Finishing Zone
	while (ReadQuestRemaining(1) AND ElapsedTime < 15000)
	{
		StuffToSpam(0, gLevel_Number)
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	return
}

LevelChampByID(ChampID := 1, Lvl := 0, i := 5000, j := "q", seat := 1)
{
	seat := ReadChampSeatByID(,, ChampID)
	StartTime := A_TickCount
    ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Leveling Champ %ChampID% to %Lvl%
	var := "{F" . seat . "}"
	var := var j
	while (ReadChampLvlByID(1,,ChampID) < Lvl AND ElapsedTime < i)
    {
	    DirectedInput(var)
        ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
    }
	return
}

DoDashWait()
{
	DirectedInput("g")
	LevelChampByID(47, 120, 5000, "q", 6)
    StartTime := A_TickCount
    ElapsedTime := 0
    gTime := ReadTimeScaleMultiplier(1)
	if (gTime < 1)
	gTime := 1
    DashSpeed := gTime * 1.4
    modDashSleep := gDashSleepTime / gTime
	if (modDashSleep < 1)
	modDashSleep := gDashSleepTime
	GuiControl, MyWindow:, NewDashSleepID, % modDashSleep
	if (gStackFailConvRecovery)
	{
		CheckForFailedConv()
	}
	GuiControl, MyWindow:, gloopID, Dash Wait 
	While (ReadTimeScaleMultiplier(1) < DashSpeed AND ElapsedTime < modDashSleep)
	{
		StuffToSpam(0, 1, 0)
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (ReadQuestRemaining(1))
	FinishZone()
	if (gUlts)
	{
		DoUlts()
	}
	DirectedInput("g")
	SetFormation(1)
	return
}

DoUlts()
{
	StartTime := A_TickCount
    ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Spamming Ults for 2s
	while (ElapsedTime < 2000)
	{
		DirectedInput("23456789")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

DirectedInput(s) 
{
	SafetyCheck()
	ControlFocus,, ahk_exe IdleDragons.exe
	ControlSend,, {Blind}%s%, ahk_exe IdleDragons.exe
	Sleep, %ScriptSpeed%
}

SetFormation(gLevel_Number)
{
	if (gAvoidBosses and !Mod(gLevel_Number, 5))
	{
		DirectedInput("e")
	}
	else if (!ReadQuestRemaining(1) AND ReadTransitioning(1) AND gBrivSwap)
	{
		DirectedInput("e")
		StartTime := A_TickCount
		ElapsedTime := 0
		GuiControl, MyWindow:, gloopID, ReadTransitioning
		while (ElapsedTime < 5000 AND !ReadQuestRemaining(1))
		{
			DirectedInput("{Right}")
			ElapsedTime := UpdateElapsedTime(StartTime)
			UpdateStatTimers()
		}
		StartTime := A_TickCount
		ElapsedTime := 0
		gTime := ReadTimeScaleMultiplier(1)
		swapSleepMod := gSwapSleep / gTime
		GuiControl, MyWindow:, gloopID, Still ReadTransitioning
		while (ElapsedTime < swapSleepMod AND ReadTransitioning(1))
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

global qZones := [2, 9, 16, 23, 30, 37, 44]

LevelSelect(gLevel_Number := 1)
{
	i := mod(gLevelNumber, 50)
	for k, v in qZones
	{
		if (v = i)
		{
			DoLevel(gLevel_Number, "q")
			Return
		}
	}
	DoLevel(gLevel_Number, "e")
	Return
}

DoLevel(gLevel_Number := 1, formation := "q")
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Do Level %gLevel_Number%
	while (!ReadTransitioning(1) OR ReadQuestRemaining(1))
	{
		StuffToSpam(1, gLevel_Number, 0, formation)
		ElapsedTime := UpdateElapsedTime(StartTime)
		if (ElapsedTime > 10000)
		Break
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Transitioning
	while (ElapsedTime < 5000 AND !ReadQuestRemaining(1))
	{
		StuffToSpam(1, gLevel_Number, 0, "e")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	var := gSwapSleep / ReadTimeScaleMultiplier(1)
	GuiControl, MyWindow:, gloopID, Still Transitioning
	while (ElapsedTime < var AND ReadTransitioning(1))
	{
		StuffToSpam(1, gLevel_Number, 0, "e")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	Return
}

LoadingZone()
{
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Loading Zone
	while (!ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 60000)
	{
		DirectedInput("q{F6}")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (ElapsedTime > 60000)
	{
		CheckifStuck(gprevLevel)
	}
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Confirming Zone Load
	;ReadMonstersSpawned was added in case monsters were spawned before game allowed inputs, an issue when spawn speed is very high. Might be creating more problems.
	;Offline Progress appears to read monsters spawning, so if Shandie is in the formation this entire function can be bypassed creating issues with stack restart.
	while (ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 15000 AND !ReadMonstersSpawned(1))
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

CheckSetUp()
{
	;find core target reset area so script does not try and Briv stack before a modron reset happens.
	gCoreTargetArea := ReadCoreTargetArea(1)
	;confirm target area has been read
	if (!gModronResetCheckEnabled)
	{
		gCoreTargetArea := 999
	}
	Else
	{
		While (!gCoreTargetArea)
		{
			MsgBox, 2,, Script cannot find Modron Reset Area.
			IfMsgBox, Abort
			{
				Return, 1
			}
			IfMsgBox, Retry
			{
				gCoreTargetArea := ReadCoreTargetArea(1)
			}
			IfMsgBox, ignore
			{
				gCoreTargetArea := 999
			}
		}
	}
	;will need to add more here eventually
	if (gCoreTargetArea < gAreaLow)
	{
		gCoreTargetArea := 999
	}
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Looking for Shandie
	DirectedInput("q{F6}q")
	while (!ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 10000)
	{
		gShandieSlot := FindChamp(47)
		DirectedInput("q{F6}q")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (!ReadChampLvlBySlot(1,,gShandieSlot))
	{
		MsgBox, Couldn't find Shandie in "Q" formation. Check saved formations. Ending Gem Farm.
		Return, 1
	}

	StartTime := A_TickCount
	ElapsedTime := 0
	slot := 0
    GuiControl, MyWindow:, gloopID, Looking for Briv
	DirectedInput("q{F5}q")
	while (!ReadChampLvlBySlot(1,,slot) AND ElapsedTime < 10000)
	{
		slot := FindChamp(58)
		DirectedInput("q{F5}q")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (!ReadChampLvlBySlot(1,,slot))
	{
		MsgBox, Couldn't find Briv in "Q" formation. Check saved formations. Ending Gem Farm.
		Return, 1
	}
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Looking for no Shandie
	while (ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 10000)
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (ReadChampLvlBySlot(1,,gShandieSlot))
	{
		MsgBox, Shandie is in "W" formation. Check Settings. Ending Gem Farm.
		return, 1
	}
	if (advtoload < 1)
	{
		MsgBox, Please load into a valid adventure and restart. Ending Gem Farm.
		return, 1
	}
	loop, 6
	{
		slot := A_Index - 1
		if (ReadClickFamiliarBySlot(1,, slot) = 1)
		{
			GuiControl, MyWindow:, FamiliarFoundID, WARNING: A familiar may be saved in "W" formation slot %slot%.
		}
		;while (ReadClickFamiliarBySlot(1,, slot) = 1)
		;{
			;MsgBox, 2,, Found familiar on field slot %slot% in "W" Formation.
			;IfMsgBox, Abort
			;{
			;	Return, 1
			;}
			;IfMsgBox, Retry
			;{
			;	(ReadClickFamiliarBySlot(1,, slot)
			;}
			;IfMsgBox, ignore
			;{
			;	Break
			;}
		;}
	}
	return, 0
}

FindChamp(ChampID := 1)
{
    loop, 10
    {
        ChampSlot := A_Index - 1
        if (ReadChampIDbySlot(1,, ChampSlot) = ChampID)
        {
            Return, ChampSlot
        }
    }
    Return, 0
}



StackRestart()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Transitioning to Stack Restart
	while (ReadTransitioning(1))
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Confirming "w" Loaded
	;added due to issues with Loading Zone function, see notes therein
	while (ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 15000)
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	Sleep 1000
	CloseIC()
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack `Sleep
    if (gDoChests)
    {
        DoChests()
    }
	while (ElapsedTime < gRestartStackTime)
	{
		Sleep 100
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	SafetyCheck()
	;Game may save "q" formation before restarting, creating an endless restart loop. LoadinZone() should bring "w" back before triggering a second restart, but monsters could spawn before it does.
	;this doesn't appear to help the issue above.
	DirectedInput("w")
}

StackNormal()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack Normal
	gStackCountH := ReadHasteStacks(1)
	GuiControl, MyWindow:, gStackCountHID, % gStackCountH
	gStackCountSB := ReadSBStacks(1)
	GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
	stacks := gStackCountSB + gStackCountH
	while (stacks < gSBTargetStacks AND ElapsedTime < gSBTimeMax)
	{
		directedinput("w")
        if (ReadCurrentZone(1) <= gAreaLow) 
		{
        	DirectedInput("{Right}")
		}
		Sleep 1000
		gStackCountH := ReadHasteStacks(1)
		GuiControl, MyWindow:, gStackCountHID, % gStackCountH
		gStackCountSB := ReadSBStacks(1)
		GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
		stacks := gStackCountSB + gStackCountH
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

StackFarm()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Transitioning to Stack Farm
	while (ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 5000)
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	DirectedInput("g")
	;send input Left while on a boss zone
	while (!mod(ReadCurrentZone(1), 5))
	{
		DirectedInput("{Left}")
	}
	if gRestartStackTime
    StackRestart()
	gStackCountH := ReadHasteStacks(1)
	GuiControl, MyWindow:, gStackCountHID, % gStackCountH
	gStackCountSB := ReadSBStacks(1)
	GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
	stacks := gStackCountSB + gStackCountH
	if (stacks < gSBTargetStacks)
	StackNormal()
	gPrevLevelTime := A_TickCount
	DirectedInput("g")
}

UpdateStartLoopStats(gLevel_Number)
{
	if (gTotal_RunCount = 0)
	{
		gStartTime := A_TickCount
		gCoreXPStart := ReadCoreXP(1)
		gGemStart := ReadGems(1)
		gGemSpentStart := ReadGemsSpent(1)
	}
	if (gTotal_RunCount)
	{
		gPrevRunTime := round((A_TickCount - gRunStartTime) / 60000, 2)
        GuiControl, MyWindow:, gPrevRunTimeID, % gPrevRunTime
		if (gSlowRunTime < gPrevRunTime AND !gStackFail)
		{
			gSlowRunTime := gPrevRunTime
            GuiControl, MyWindow:, gSlowRunTimeID, % gSlowRunTime
		}
		if (gFastRunTime > gPrevRunTime AND !gStackFail)
		{
			gFastRunTime := gPrevRunTime
            GuiControl, MyWindow:, gFastRunTimeID, % gFastRunTime
		}
		if (gStackFail)
		{
			gFailRunTime := gPrevRunTime
			GuiControl, MyWindow:, gFailRunTimeID, % gFailRunTime
		}
		dtTotalTime := (A_TickCount - gStartTime) / 3600000
		gAvgRunTime := Round((dtTotalTime / gTotal_RunCount) * 60, 2)
		GuiControl, MyWindow:, gAvgRunTimeID, % gAvgRunTime
		dtTotalTime := (A_TickCount - gStartTime) / 3600000
		TotalBosses := (ReadCoreXP(1) - gCoreXPStart) / 5
		gbossesPhr := Round(TotalBosses / dtTotalTime, 2)
		GuiControl, MyWindow:, gbossesPhrID, % gbossesPhr
		GuiControl, MyWindow:, gTotal_RunCountID, % gTotal_RunCount
		GemsTotal := (ReadGems(1) - gGemStart) + (ReadGemsSpent(1) - gGemSpentStart)
		GuiControl, MyWindow:, GemsTotalID, % GemsTotal
		GemsPhr := Round(GemsTotal / dtTotalTime, 2)
		GuiControl, MyWindow:, GemsPhrID, % GemsPhr
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
	;not sure why this one is here, commented out for now.
	;GetUserDetails()
	UserID := ReadUserID(1)
	UserHash := ReadUserHash(1)
    advtoload := ReadCurrentObjID(0)
    GuiControl, MyWindow:, advtoloadID, % advtoload
	var := 0
	var := CheckSetUp()
	if var
	Return
	if gDoChests
	BuildChestGUI()
	gPrevLevelTime := A_TickCount

	loop 
	{
        GuiControl, MyWindow:, gLoopID, Main `Loop
		gLevel_Number := ReadCurrentZone(1)
		
		SetFormation(gLevel_Number)

		if (gLevel_Number = 1)
		{
			if (gDashSleepTime)
			{
				;putting this check with the gLevel_Number = 1 appeared to completely disable DashWait
				if (ReadQuestRemaining(1))
				DoDashWait()
			}
			Else if(gStackFailConvRecovery)
			{
				CheckForFailedConv()
				if (gUlts)
				{
					DirectedInput("g")
					FinishZone()
					DoUlts()
					DirectedInput("g")
				}
				else
				FinishZone()
				SetFormation(1)
			}
        }

		gStackCountH := ReadHasteStacks(1)
		GuiControl, MyWindow:, gStackCountHID, % gStackCountH
		gStackCountSB := ReadSBStacks(1)
		GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
		stacks := gStackCountSB + gStackCountH

		if (stacks < gSBTargetStacks AND gLevel_Number > gAreaLow AND gLevel_Number < gCoreTargetArea)
		;if (stacks < gSBTargetStacks AND gLevel_Number > gAreaLow)
		{
			StackFarm()
		}

		if (gStackCountH < 50 AND gLevel_Number > gMinStackZone AND gStackFailRecovery AND gLevel_Number < gAreaLow)
        {
            if (gStackCountSB < gSBTargetStacks)
			{
				StackFarm()
			}
			stacks := ReadSBStacks(1) + ReadHasteStacks(1)
			if (stacks > gSBTargetStacks AND gTestReset)
            {
                EndAdventure()
				sleep 2000
				CloseIC()
				if (GetUserDetails() = -1)
        		{
            		LoadAdventure()
        		}
				SafetyCheck()
				UpdateStartLoopStats(gLevel_Number)
				gStackFail := 1
				++gFailedStacking
				GuiControl, MyWindow:, gFailedStackingID, % gFailedStacking
				gPrevLevelTime := A_TickCount
				gprevLevel := ReadCurrentZone(1)
            }
			if (stacks > gSBTargetStacks AND !gTestReset)
			{
				TestResetFunction()
			}
        }
		
		StuffToSpam(1, gLevel_Number)

		if (ReadResettting(1))
		{
			ModronReset()
			LoadingZone()
			UpdateStartLoopStats(gLevel_Number)
			if (!gStackFail)
			++gTotal_RunCount
			gStackFail := 0
			gPrevLevelTime := A_TickCount
			gprevLevel := ReadCurrentZone(1)
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
		CloseIC()
		if (GetUserDetails() = -1)
        {
            LoadAdventure()
        }
		SafetyCheck()
		gPrevLevelTime := A_TickCount
	}
}

ModronReset()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Modron Reset
	while (ReadResettting(1) AND ElapsedTime < 300000)
	{
		Sleep, 250
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
		if (ReadCurrentZone(1) = 1)
		Break
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Resettting to z1
	while (ReadCurrentZone(1) != 1 AND ElapsedTime < 300000)
	{
		Sleep, 250
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

EndAdventure() 
{
    DirectedInput("r")
    xClick := (ReadScreenWidth(1) / 2) - 80
    yClickMax := ReadScreenHeight(1)
	yClick := yClickMax / 2
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Manually Ending Adventure
    while(!ReadResettting(1) AND ElapsedTime < 30000)
    {
        WinActivate, ahk_exe IdleDragons.exe
        MouseClick, Left, xClick, yClick, 1
		if (yClick < yClickMax)
		yClick := yClick + 10
		Else
		yClick := yClickMax / 2
        Sleep, 25
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
    }
}

StuffToSpam(SendRight := 1, gLevel_Number := 1, hew := 1, formation := "")
{
	var :=
	if (SendRight)
	var := "{Right}"
	if (gClickLeveling)
	var := var "{Ctrl down}``{Ctrl up}"
	if (gContinuedLeveling > gLevel_Number)
	var := var gFKeys
	if (gHewUlt AND hew)
	var := var gHewUlt
	if (formation)
	var := var formation

	DirectedInput(var)
	Return
}

TestResetFunction()
{
	;test
}

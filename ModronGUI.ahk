#SingleInstance force
;Modron Automation Gem Farming Script
;by mikebaldi1980
global ScriptDate := "4/4/21"
;put together with the help from many different people. thanks for all the help.
SetWorkingDir, %A_ScriptDir%
CoordMode, Mouse, Client

;Thanks ThePuppy for the ini code
;==================
;Load user settings
;==================
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
;SB stack max time
IniRead, SBTimeMax, UserSettings.ini, Section1, SBTimeMax, 40000
global gSBTimeMax := SBTimeMax
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
;Stack restart toggle
;IniRead, StackRestart, UserSettings.ini, Section1, StackRestart
;global gStackRestart := StackRestart
;Stack fail recovery toggle
IniRead, StackFailRecovery, UserSettings.ini, Section1, StackFailRecovery
global gStackFailRecovery := StackFailRecovery
;Stack fail recovery toggle
IniRead, StackFailConvRecovery, UserSettings.ini, Section1, StackFailConvRecovery
global gStackFailConvRecovery := StackFailConvRecovery
;Shandie's position in formation
slot := 0
global gShandieSlot := 
loop, 9
{
	IniRead, ShandieRadio%slot%, UserSettings.ini, Section1, ShandieRadio%slot%
	if (ShandieRadio%slot%)
	gShandieSlot := slot
	++slot
}
;Briv swap sleep time
IniRead, SwapSleep, UserSettings.ini, Section1, SwapSleep, 1500
global gSwapSleep := SwapSleep
;Restart stack sleep time
IniRead, RestartStackTime, UserSettings.ini, Section1, RestartStackTime, 12000
global gRestartStackTime := RestartStackTime
;Intall location
IniRead, GameInstallPath, Usersettings.ini, Section1, GameInstallPath, C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe
global gInstallPath := GameInstallPath

;variables to consider changing if restarts are causing issues
global gOpenProcess	:= 10000	;time in milliseconds for your PC to open Idle Champions
global gGetAddress := 5000		;time in milliseconds after Idle Champions is opened for it to load pointer base into memory
;end of user settings

global ScriptSpeed := 25

global gStackFail := 0

;global variables used for server calls
global DummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
global ActiveInstance :=
global InstanceID :=
global UserID :=
global UserHash := ""
global InstanceID :=
global ActiveInstance :=
global advtoload :=

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

;class and methods for parsing JSON
#include JSON.ahk

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

;globals for server calls
global DummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
global ActiveInstance :=
global InstanceID :=
global UserID :=
global UserHash := ""
global advtoload :=

;globals for reset tracking
global gFailedStacking := 0
global gFailedStackConv := 0
global ResetCount		:= 0
;globals used for stat tracking
global gGemStart		:=
global gCoreXPStart		:=

Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Add, Button, x415 y25 w60 gSave_Clicked, Save
Gui, MyWindow:Add, Button, x415 y+50 w60 gRun_Clicked, `Run
Gui, MyWindow:Add, Button, x415 y+100 w60 gReload_Clicked, `Reload
Gui, MyWindow:Add, Tab3, x5 y5 w400, Read First|Settings|Stats|Debug|
;Gui, MyWindow:Add, Tab3, x5 y5 w400, Read First|Settings|Settings Help|Stats|Debug|

Gui, Tab, Read First
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y30, Gem Farm, %ScriptDate%
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, Instructions:
Gui, MyWindow:Add, Text, x15 y+2 w10, 1.
Gui, MyWindow:Add, Text, x+2 w370, Save your speed formation in formation save slot 1, in game `hotkey "Q". This formation must include Shandie, Briv at the very front of the formation, and at least one familiar on the field.
Gui, MyWindow:Add, Text, x15 y+2 w10, 2.
Gui, MyWindow:Add, Text, x+2 w370, Save your stack farming formation in formation save slot 2, in game `hotkey "W". Don't include any familiars on the field or any champions in the formation slot Shandie is in as part of formation save slot 1.
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
Gui, MyWindow:Add, Text, x15 y+2, 4. Settings should now save to and load from UserSettings.ini file.
Gui, MyWindow:Add, Text, x15 y+2, 5. Recommended SB stack level is:
Gui, MyWindow:Add, Text, x15 y+2 w10,
Gui, MyWindow:Add, Text, x+2, Modron Reset Level - [2 * (Briv Skip Amount + 1)]
Gui, MyWindow:Add, Text, x15 y+2 w10,
Gui, MyWindow:Add, Text, x+2, Then adjust to avoid stacking on boss zones.
Gui, MyWindow:Add, Text, x15 y+2 w10, 6.
Gui, MyWindow:Add, Text, x+2 w370, Script will activate and focus the game window for manual resets.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 7.
Gui, MyWIndow:Add, Text, x+2 w370, Script communicates directly with Idle Champions play servers to recover from a failed Briv stack on the previous run and for when Modron resets to the World Map.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 8.
Gui, MyWIndow:Add, Text, x+2 w370, Script reads system memory.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 9.
Gui, MyWIndow:Add, Text, x+2 w370, The script does not work without Shandie.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 10.
Gui, MyWIndow:Add, Text, x+2 w370, Disable manual resets to recover from failed Briv stack conversions when running event free plays.
Gui, MyWIndow:Add, Text, x15 y+2 w10, 11.
Gui, MyWIndow:Add, Text, x+2 w370, Recommended Briv swap `sleep time is 1500 - 3000.
Gui, MyWindow:Add, Text, x15 y+10, Known Issues:
Gui, MyWindow:Add, Text, x15 y+2, 1. Cannot fully interact with `GUI `while script is running.
Gui, MyWindow:Add, Text, x15 y+2 w10, 2. 
Gui, MyWindow:Add, Text, x+2 w370, Using Hew's ult throughout a run with Briv swapping can result in Havi's ult being triggered instead. Consider removing Havi from formation save slot 3, in game `hotkey "E".
Gui, MyWindow:Add, Text, x15 y+2, 3. 
Gui, MyWindow:Add, Text, x+2 w370, Script will re-enter the level up function as long as Shandie is below level 230.

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
Gui, MyWindow:Add, Edit, vNewgMinStackZone x15 y+10 w50, % gMinStackZone
Gui, MyWindow:Add, Text, x+5, Minimum zone you can farm SB stacks on
Gui, MyWindow:Add, Edit, vNewSBTargetStacks x15 y+10 w50, % gSBTargetStacks
Gui, MyWindow:Add, Text, x+5, Target Haste stacks for next run
Gui, MyWindow:Add, Edit, vNewgSBTimeMax x15 y+10 w50, % gSBTimeMax
Gui, MyWindow:Add, Text, x+5, Maximum time (ms) script will spend farming SB stacks
Gui, MyWindow:Add, Edit, vNewDashSleepTime x15 y+10 w50, % gDashSleepTime
Gui, MyWindow:Add, Text, x+5, Maximum time (ms) script will wait for Dash
Gui, MyWindow:Add, Edit, vNewHewUlt x15 y+10 w50, % gHewUlt
Gui, MyWindow:Add, Text, x+5, `Hew's ultimate key, set to 0 to disable
Gui, MyWindow:Add, Edit, vNewRestartStackTime x15 y+10 w50, % gRestartStackTime
Gui, MyWindow:Add, Text, x+5, `Time (ms) client remains closed for Briv Restart Stack (0 disables)
Gui, MyWindow:Add, Checkbox, vgUlts Checked%gUlts% x15 y+10, Use ults after intial champion leveling
Gui, MyWindow:Add, Checkbox, vgBrivSwap Checked%gBrivSwap% x15 y+5, Swap to 'e' formation to avoid Briv's jump animation
Gui, MyWindow:Add, Edit, vNewSwapSleep x15 y+5 w50, % gSwapSleep
Gui, MyWindow:Add, Text, x+5, Briv swap `sleep time (ms).
Gui, MyWindow:Add, Checkbox, vgAvoidBosses Checked%gAvoidBosses% x15 y+10, Swap to 'e' formation when `on boss zones
Gui, MyWindow:Add, Checkbox, vgClickLeveling Checked%gClickLeveling% x15 y+5, `Uncheck `if using a familiar `on `click damage
Gui, MyWindow:Add, Checkbox, vgStackFailRecovery Checked%gStackFailRecovery% x15 y+5, Enable manual resets to recover from failed Briv stacking
Gui, MyWindow:Add, Checkbox, vgStackFailConvRecovery Checked%gStackFailConvRecovery% x15 y+5, Enable manual resets to recover from failed Briv stack conversion
Gui, MyWindow:Add, Text, x15 y+5, Shandie's position in formation:
Gui, MyWindow:Add, Radio, x45 y+5 vShandieRadio3 Checked%ShandieRadio3%
Gui, MyWindow:Add, Radio, x30 y+1 vShandieRadio6 Checked%ShandieRadio6%
Gui, MyWindow:Add, Radio, x+1 vShandieRadio1 Checked%ShandieRadio1%
Gui, MyWindow:Add, Radio, x15 y+1 vShandieRadio8 Checked%ShandieRadio8%
Gui, MyWindow:Add, Radio, x+1 vShandieRadio4 Checked%ShandieRadio4%
Gui, MyWindow:Add, Radio, x+1 vShandieRadio0 Checked%ShandieRadio0%
Gui, MyWindow:Add, Radio, x30 y+1 vShandieRadio7 Checked%ShandieRadio7%
Gui, MyWindow:Add, Radio, x+1 vShandieRadio2 Checked%ShandieRadio2%
Gui, MyWindow:Add, Radio, x45 y+1 vShandieRadio5 Checked%ShandieRadio5%
Gui, MyWindow:Add, Button, x15 y+20 gChangeInstallLocation_Clicked, Change Install Path

;Gui, Tab, Settings Help
;Gui, MyWindow:Font, w700
;Gui, MyWindow:Add, Text, x15 y30, Detailed Settings Information
;Gui, MyWindow:Font, w400
;Gui, MyWindow:Add, Text, x15 y+2 w10, 1.
;Gui, MyWindow:Add, Text, x+2 w370, Fkeys must be enabled in the Idle Champions in game settings. F12 is the default screenshot key for Steam and should be changed in the Steam settings if used.

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

Gui, Tab, Debug
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, `Loop: 
Gui, MyWindow:Add, Text, vgLoopID x+2 w200, Not Started
Gui, MyWindow:Add, Text, x15 y+15, Timers:
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, ElapsedTime:
Gui, MyWindow:Add, Text, vElapsedTimeID x+2 w200, % ElapsedTime
Gui, MyWindow:Add, Text, x15 y+2, dtCurrentLevelTime:
Gui, MyWindow:Add, Text, vdtCurrentLevelTimeID x+2 w200, % dtCurrentLevelTime
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+15, Memory Reads: 
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, ReadCurrentZone: 
Gui, MyWindow:Add, Text, vReadCurrentZoneID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadGems: 
Gui, MyWindow:Add, Text, vReadGemsID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadQuestRemaining: 
Gui, MyWindow:Add, Text, vReadQuestRemainingID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadTimeScaleMultiplier: 
Gui, MyWindow:Add, Text, vReadTimeScaleMultiplierID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadTransitioning: 
Gui, MyWindow:Add, Text, vReadTransitioningID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadSBStacks: 
Gui, MyWindow:Add, Text, vReadSBStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadHasteStacks: 
Gui, MyWindow:Add, Text, vReadHasteStacksID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadCoreXP: 
Gui, MyWindow:Add, Text, vReadCoreXPID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadResettting: 
Gui, MyWindow:Add, Text, vReadResetttingID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadUserID: 
Gui, MyWindow:Add, Text, vReadUserIDID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadUserHash: 
Gui, MyWindow:Add, Text, vReadUserHashID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadScreenWidth: 
Gui, MyWindow:Add, Text, vReadScreenWidthID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadScreenHeight: 
Gui, MyWindow:Add, Text, vReadScreenHeightID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadChampLvlBySlot: 
Gui, MyWindow:Add, Text, vReadChampLvlBySlotID x+2 w200,
Gui, MyWindow:Add, Text, x15 y+2, ReadMonstersSpawned:
Gui, MyWindow:Add, Text, vReadMonstersSpawnedID x+2 w200,
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+15, Settings and Other Variables: 
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, gFKeys:
Gui, MyWindow:Add, Text, vgFKeysID x+2 w300, % gFKeys
Gui, MyWindow:Add, Text, x15 y+2, gAreaLow:
Gui, MyWindow:Add, Text, vgAreaLowID x+2 w200, % gAreaLow
Gui, MyWindow:Add, Text, x15 y+2, gSBTargetStacks:
Gui, MyWindow:Add, Text, vgSBTargetStacksID x+2 w200, % gSBTargetStacks
Gui, MyWindow:Add, Text, x15 y+2, gDashSleepTime:
Gui, MyWindow:Add, Text, vDashSleepTimeID x+2 w200, % gDashSleepTime
Gui, MyWindow:Add, Text, x15 y+2, NewDashSleep:
Gui, MyWindow:Add, Text, vNewDashSleepID x+2 w200, % NewDashSleep
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
;Gui, MyWindow:Add, Text, x15 y+2, gStackRestart:
;Gui, MyWindow:Add, Text, vgStackRestartID x+2 w200, % gStackRestart
Gui, MyWindow:Add, Text, x15 y+2, gStackFailRecovery:
Gui, MyWindow:Add, Text, vgStackFailRecoveryID x+2 w200, % gStackFailRecovery
Gui, MyWindow:Add, Text, x15 y+2, gStackFailConvRecovery:
Gui, MyWindow:Add, Text, vgStackFailConvRecoveryID x+2 w200, % gStackFailConvRecovery
Gui, MyWindow:Add, Text, x15 y+2, gShandieSlot:
Gui, MyWindow:Add, Text, vgShandieSlotID x+2 w200, % gShandieSlot
Gui, MyWindow:Add, Text, x15 y+2, gHewUlt:
Gui, MyWindow:Add, Text, vgHewUltID x+2 w200, % gHewUlt
Gui, MyWindow:Add, Text, x15 y+2, ResetCount:
Gui, MyWindow:Add, Text, vResetCountID x+2 w200, % ResetCount
Gui, MyWindow:Add, Text, x15 y+2, gFailedStackConv:
Gui, MyWindow:Add, Text, vgFailedStackConvID x+2 w200, % gFailedStackConv
Gui, MyWindow:Add, Text, x15 y+2, gFailedStacking:
Gui, MyWindow:Add, Text, vgFailedStackingID x+2 w200, % gFailedStacking

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
	slot := 0
	loop, 9
	{
		if (ShandieRadio%slot%)
		{
			gShandieSlot := slot
			IniWrite, 1, UserSettings.ini, Section1, ShandieRadio%slot%
		}
		Else
		IniWrite, 0, UserSettings.ini, Section1, ShandieRadio%slot%
		++slot	
	}
	GuiControl, MyWindow:, gShandieSlotID, % gShandieSlot
	gAreaLow := NewgAreaLow
	GuiControl, MyWindow:, gAreaLowID, % gAreaLow
	IniWrite, %gAreaLow%, UserSettings.ini, Section1, AreaLow
	gMinStackZone := NewgMinStackZone
	IniWrite, %gMinStackZone%, Usersettings.ini, Section1, MinStackZone
	gSBTargetStacks := NewSBTargetStacks
	GuiControl, MyWindow:, gSBTargetStacksID, % gSBTargetStacks
	IniWrite, %gSBTargetStacks%, UserSettings.ini, Section1, SBTargetStacks
	gSBTimeMax := NewgSBTimeMax
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
	;GuiControl, MyWindow:, gStackRestartID, % gStackRestart
	;IniWrite, %gStackRestart%, UserSettings.ini, Section1, StackRestart
	GuiControl, MyWindow:, gStackFailRecoveryID, % gStackFailRecovery
	IniWrite, %gStackFailRecovery%, UserSettings.ini, Section1, StackFailRecovery
	GuiControl, MyWindow:, gStackFailConvRecoveryID, % gStackFailConvRecovery
	IniWrite, %gStackFailConvRecovery%, UserSettings.ini, Section1, StackFailConvRecovery
	gSwapSleep := NewSwapSleep
	;GuiControl, MyWindow:, gSwapSleepID, % gSwapSleep
	IniWrite, %gSwapSleep%, UserSettings.ini, Section1, SwapSleep
	gRestartStackTime := NewRestartStackTime
	;GuiControl, MyWindow:, gRestartStackTimeID, % gRestartStackTime
	IniWrite, %gRestartStackTime%, UserSettings.ini, Section1, RestartStackTime
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
	LevelChampByID(58, 100, 5000, "q")

    gStackCountH := ReadHasteStacks(1)
	GuiControl, MyWindow:, gStackCountHID, % gStackCountH
	gStackCountSB := ReadSBStacks(1)
	GuiControl, MyWindow:, gStackCountSBID, % gStackCountSB
	stacks := gStackCountSB + gStackCountH
    If (gStackCountH < gSBTargetStacks AND stacks > gSBTargetStacks)
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

LevelChampBySlot(slot := 1, Lvl := 0, i := 5000, j := "q")
{
	seat := ReadChampSeatBySlot(,, slot)
	StartTime := A_TickCount
    ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Leveling Seat %seat% to %Lvl%
	var := "{F" . seat . "}"
	var := var j
	while (ReadChampLvlBySlot(1,,slot) < Lvl AND ElapsedTime < i)
    {
	    DirectedInput(var)
        ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
    }
	return
}

LevelChampByID(ChampID := 1, Lvl := 0, i := 5000, j := "q")
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
	LevelChampByID(47, 120, 5000, "q")
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
	while (ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 15000 AND !ReadMonstersSpawned(1))
	{
		DirectedInput("w")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
}

CheckSetUp()
{
	StartTime := A_TickCount
	ElapsedTime := 0
    GuiControl, MyWindow:, gloopID, Looking for Shandie
	while (!ReadChampLvlBySlot(1,,gShandieSlot) AND ElapsedTime < 10000)
	{
		DirectedInput("q{F6}")
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	if (!ReadChampLvlBySlot(1,,gShandieSlot))
	{
		MsgBox, Couldn't find Shandie in "Q" formation. Check Settings. Ending Gem Farm.
		return, 1
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
	return, 0
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
	Sleep 1000
	CloseIC()
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack `Sleep
	while (ElapsedTime < gRestartStackTime)
	{
		Sleep 100
		ElapsedTime := UpdateElapsedTime(StartTime)
		UpdateStatTimers()
	}
	SafetyCheck()
}

StackNormal()
{
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, Stack Normal
	StackRestart()
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
		GuiControl, MyWindow:, gCoreXPStartID, % gCoreXPStart
		gGemStart := ReadGems(1)
		GuiControl, MyWindow:, gGemStartID, % gGemStart
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
		GemsTotal := ReadGems(1) - gGemStart
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
	GetUserDetails()
	UserID := ReadUserID(1)
	UserHash := ReadUserHash(1)
    advtoload := GetUserDetails()
    GuiControl, MyWindow:, advtoloadID, % advtoload
	var := 0
	var := CheckSetUp()
	if var
	Return
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

		if (stacks < gSBTargetStacks AND gLevel_Number > gAreaLow)
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
			var := 1
            if (stacks > gSBTargetStacks AND var)
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
	}
	StartTime := A_TickCount
	ElapsedTime := 0
	GuiControl, MyWindow:, gloopID, ReadResettting to z1
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

ServerCall(callname, parameters) 
{
	URLtoCall := "http://ps6.idlechampions.com/~idledragons/post.php?call=" callname parameters
	GuiControl, MyWindow:, advparamsID, % URLtoCall
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("POST", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}

GetUserDetails() 
{
	getuserparams := DummyData "&include_free_play_objectives=true&instance_key=1&user_id=" UserID "&hash=" UserHash
	rawdetails := ServerCall("getuserdetails", getuserparams)
	UserDetails := JSON.parse(rawdetails)
	InstanceID := UserDetails.details.instance_id
    GuiControl, MyWindow:, InstanceIDID, % InstanceID
	ActiveInstance := UserDetails.details.active_game_instance_id
    GuiControl, MyWindow:, ActiveInstanceID, % ActiveInstance
	for k, v in UserDetails.details.game_instances
		if (v.game_instance_id == ActiveInstance) 
		{
			CurrentAdventure := v.current_adventure_id
			GuiControl, MyWindow:, CurrentAdventureID, % CurrentAdventure
			CurrentArea := v.current_area
			GuiControl, MyWindow:, CurrentAreaID, % CurrentArea
		}
	return CurrentAdventure
}

LoadAdventure() 
{
	advparams := DummyData "&patron_tier=0&user_id=" UserID "&hash=" UserHash "&instance_id=" InstanceID "&game_instance_id=" ActiveInstance "&adventure_id=" advtoload "&patron_id=0"
    ServerCall("setcurrentobjective", advparams)
	return
}

StuffToSpam(SendRight := 1, gLevel_Number := 1, hew := 1)
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

	DirectedInput(var)
	Return
}
#SingleInstance force
;Mad Wizard Gem Farming Script
;revised by mikebaldi
;version: 200202 (2/2/20)
;by Bootch
;version: 191020 (10/20/19)
;original script by Hikibla 

;LEVEL DETECTOR GEM FARM
;Resolution Setting 1366x768 or 1280x720
;This script is designed to farm gems and automatically progress through low level areas, then resetting and starting over the same mission
;It achieves this by leveling click damage and champs but mostly allows for familiars to instant kill the mobs (note works best with at least 3 familiars for the autoloot)
;It utilizes a pixel-color detector to determine when the game is changing levels
;Overall my average run time from point to point is just under 6 min with 6 familiars and Torm Fav > 1e20 (with Deeking/Shandie/Minsc) 
;there are points where this can be speed up (like a few seconds lost here and there while leveling up the champs and the Level is already complete)

;Settings: Several Pixel Colors and Positions may need to be tweaked to run correctly for your system (but this should be a 1 time process) 
;NOTE Updates from CNE occassionally break the script

;Additional Notes:
;	on levels : 			1,6,11,... Click Damage is Maxed
;	boss levels	: 			no special functions added at this time
;	remaining even levels :	will attempt to level up even numbered champs 5 levels at time and assign Specializations as needed
;	remaining odd levels :	will attempt to level up odd numbered champs 5 levels at time and assign Specializations as needed
;	special levels : 
;							1...waits for  initial Gold Collection and then Levels Deekin up to L100 to ensure Confidence in the Boss is unlocked and Maxs Click DMG
;								may add additional for other benefits like Shandie for Dash and Minsc for Boastful(??)				
;							14,64,..(orb levels) all the Ults will be triggered 

;WARNINGS/Potential Issues/Recommendations
;Potential Issue: 	Having Title Bar turned off will create a shift in the Y values and Script wont be able find several Locations (Jadisero)
;Warning:			Pausing Script while on Boss Level will throw off the Level Counter 
;					(while script should still work may run an extra level and Leveling Champs/ClickDmg will be out of sync for that run)
;Recommended:		Pause Script prior to opening in game windows (store/high rollers/etc)

;Specialization Section in the MW_Settings_1366x768.ahk or MW_Settings_1280x720.ahk file
;Champ1_SpecialOptionQ := [NUMBER]
;number is the 1-N for which Specialization the script is to select for the ChampNumber
;Q is the assoicated formation Q/W/E
;use -1 as the SpecialOption to prevent this Champ from Leveling Up/being added

;HOTKEYS
;	`		: Pauses the Script
;	F1		: (Help) -- Shows ToolTip with HotKey Info 
;	F2		: starts the script to farm MadWizard to L30
;	F3		: enables High Roller functionality -- (by default) iterates through Levels 50-90 (10 at time) then resets back to L30
;	F8		: shows stats for the current script run
;	F9		: Reloads the script
;	Up		: used to increase the Target Level by 10
;	DOWN	: used to decrease the Target Level by 10
;	Q/W/E	: will Temporarily Save the Formation Selected (w/ keyboard) till next Script Reset/Reload

;#include MW_Settings_1366x768.ahk
#include MW_Settings_1280x720.ahk

;internal globals
global gFound_Error 	:= 0

global gFormation		:= "-1"
global gHR_Enabled 		:= 0
global nHR_CurrentLimit := 50

global gLevel_Number 	:= 0
global gTotal_RunCount	:= 0
global gTotal_Bosses 	:= 0
global dtPrevRunTime 	:= "00:00:00"
global dtLoopStartTime 	:= "00:00:00"
global gTotal_RunTime 	:= "00:00:00"

;get and store the settings for the GameWindow
GetWindowSettings()
Adjust_YValues()
Init()
ShowHelpTip()

return

;HotKeys
{
	;Show Help
	#IfWinActive Idle Champions
	F1:: 
	{	
		ShowHelpTip()
		return
	}

	;strart runs
	#IfWinActive Idle Champions
	F2:: 
	{	
		Loop_GemRuns()
		return
	}

	;Toggle High Roller
	#IfWinActive Idle Champions
	F3:: 
	{
		gHR_Enabled := !gHR_Enabled
		nHR_CurrentLimit := nHR_Min
		UpdateToolTip()
		
		return
	}

	;holder for running to wall
	#IfWinActive Idle Champions
	F4::
	{
		return
	}

	;testing hotkey
	#IfWinActive Idle Champions
	F5::
	{
		;TestWindowSettings()
		;TestFindWorldMap()
		;TestFindPatron()
		;TestFindTown()
		;TestTownLocations()
		;TestAdventureSelect()
		;TestFindMob()		
		;TestAutoProgress()	
		;DoFamiliars(6)
		;DoEarlyLeveling()
		;DoLevel(0)
		;TestRosterButtons()
		;TestUpgradeButtons()
		;TestReadSpec(1)
		;TestReadPriorityLeveling(1)
		;AutoLevelChamps(2)
		;LevelUp(0)
		;LevelUp(4)
		;LevelUp(3,15)	
		;TestGetChampSpecValue(7) ;testing with slot1		
		;DoSpecial(3)
		;TestTransition()
		;TestSpecializationWinClose()
		;TestSpecializationSelectButtons()
		;TestResetContinue()
		
		;CheckPixelInfo(REPLACE_WITH_PIXEL_OBJECT)
		;MoveToPixel(gRosterButton)
		;TestFindPixel()
		;IsNewDay()
		;TestSend()
		;TestTraceBox()
		;MouseSweep()
		;MouseAutoClick()
		return
	}

	;Get Pixel Info
	global gLastX := ""
	global gLastY := ""
	#IfWinActive Idle Champions
	F6::
	{
		;get current pixel info 
		MouseGetPos, outx, outy		
		
		PixelGetColor, oColor, outx, outy, RGB
		sText :=  "Current Pixel`nColor: " oColor "`n" "X,Y: " outx ", " outy		
		ToolTip, %sText%, 25, 200, 15
		
		gLastX := outx
		gLastY := outy
		
		return
	}

	;Get Pixel info for previous F6
	#IfWinActive Idle Champions
	F7::
	{
		;get last pixel info
		nX:= gLastX
		nY:= gLastY
				
		PixelGetColor, oColor, nX, nY, RGB
		Sleep, 500
		MouseMove, nX, nY, 5	
		
		sText :=  "Prev Pixel`nColor: " oColor "`n" "X,Y: " nX ", " nY		
		ToolTip, %sText%, 25, 260, 16
		
		return
	}

	;Show Total Farm Stats
	#IfWinActive Idle Champions
	F8:: 
	{	
		ShowStatsTip()
		return
	}

	;Reset/Reload Script
	#IfWinActive Idle Champions
	F9:: 
	{
		Reload
		return
	}

	#IfWinActive Idle Champions
	~Q::
	{
		gFormation := "Q"
		return
	}
	#IfWinActive Idle Champions
	~W::
	{
		gFormation := "W"
		return
	}
	#IfWinActive Idle Champions
	~E::
	{
		gFormation := "E"	
		return
	}

	;+10 levels to Target Level
	#IfWinActive Idle Champions
	~Up::
	{
		nMax_Level := nMax_Level + 10
		ToolTip, % "Max Level: " nMax_Level, 25, 475, 2
		SetTimer, ClearToolTip, -1000 
		
		UpdateToolTip()
		
		return
	}

	;-10 levels to Target Level
	#IfWinActive Idle Champions
	~Down::
	{
		nMax_Level := nMax_Level - 10
		ToolTip, % "Max Level: " nMax_Level, 25, 475, 2
		SetTimer, ClearToolTip, -1000 
		
		UpdateToolTip()
		
		return
	}

	;toggle Pause on/off
	#IfWinActive Idle Champions
	~`::
	{
		Pause, , 1	
		return
	}
}

;ToolTips
{
	UpdateToolTip()
	{
		dtNow := A_Now
		dtCurrentRunTime := DateTimeDiff(dtLoopStartTime, dtNow)		
			
		sToolTip := "Prev Run: " dtPrevRunTime 	
		sToolTip := sToolTip "`nCurrent Run: " dtCurrentRunTime
		
		if(gHR_Enabled)
		{
			sToolTip := sToolTip "`nTarget Level: " nHR_CurrentLimit
		}
		else
		{
			sToolTip := sToolTip "`nTarget Level: " nMax_Level
		}	
		
		sToolTip := sToolTip "`nCurrent Level: " gLevel_Number
		sToolTip := sToolTip "`nPatron: " (gCurrentPatron = "NP" ? "None" : (gCurrentPatron = "M" ? "Mirt" : (gCurrentPatron = "V" ? "Vajra" : "None")))
		
		ToolTip, % sToolTip, 25, 475, 1
	}

	global gShowHelpTip := ""
	ShowHelpTip()
	{
		gShowHelpTip := !gShowHelpTip
		
		if (gShowHelpTip)
		{
			ToolTip, % "F1: Show Help`nF2: Start Gem Farm`nF3: Toggle HR Leveling`nF8: Show Stats`nF9: Reload Script`nUP: +10 to Target Levels`nDOWN: -10 to Target Levels`n``: Pause Script", 25, 325, 3
			SetTimer, ClearToolTip, -5000 
		}
		else
		{
			ToolTip, , , ,3
		}
	}

	global gShowStatTip := ""
	ShowStatsTip()
	{
		gShowStatTip := !gShowStatTip
		
		if (gShowStatTip)
		{
			nAvgRuntime := 0
			nEstGems := Format("{:i}" , (gTotal_Bosses * 7.5)) ;convert to int
			nAvgRuntime := TimeSpanAverage(gTotal_RunTime, gTotal_RunCount)
			
			ToolTip, % "Total Time: " gTotal_RunTime "`nAvg Run: " nAvgRuntime "`nRun Count: " gTotal_RunCount "`nBoss Count: " gTotal_Bosses "`nEst. Gems: " nEstGems "*`n* 7.5 per boss", 25, 350, 3
			SetTimer, ClearToolTip, -10000 
		}
		else
		{
			ToolTip, , , ,3
		}
	}
	
	;a common tooltip with up to 5 lines
	;limits the tooltip to last 5 messages in event script is spamming messages
	global gToolTip := ""
	ShowToolTip(sText := "")
	{	
		if (!sText)
		{
			gToolTip := ""
		}
		
		dataitems := StrSplit(gToolTip, "`n")
		nCount := dataitems.Count()
		gToolTip := ""
		
		nMaxLineCount := 5
		nStartIndex := 0
		if (nCount >= nMaxLineCount)
		{
			nStartIndex := nCount - nMaxLineCount + 1
		}
		
		for k,v in dataitems
		{
			if (A_Index > nStartIndex)
			{
				if (gToolTip)
				{
					gToolTip := gToolTip "`n"
				}
				gToolTip := gToolTip v
			}
		}
		
		if (gToolTip)
		{
			gToolTip := gToolTip "`n" sText
		}
		else
		{
			gToolTip := sText
		}
		
		ToolTip, % gToolTip, 50, 150, 5
		return
	}

	ClearToolTip:
	{
		ToolTip, , , ,2
		ToolTip, , , ,3
		;ToolTip, , , ,5
		gToolTip		:= ""
		gShowHelpTip 	:= 0
		gShowStatTip 	:= 0
		return
	}
}

global gWindowSettings := ""
GetWindowSettings()
{
	if (!gWindowSettings)
	{
		if WinExist("Idle Champions")
		{
			WinActivate
			WinGetPos, outWinX, outWinY, outWidth, outHeight, Idle Champions 
		
			gWindowSettings := []		
			gWindowSettings.X := outWinX
			gWindowSettings.Y := outWinY 
			gWindowSettings.Width := (outWidth - 1)
			gWindowSettings.Height := (outHeight - 1)
			gWindowSettings.HeightAdjust := (outHeight - gWindowHeight_Default)

			;MsgBox, % "error init window (this) -- " this.Width ", " this.Height " -- " this.X ", " this.Y
		}
		else
		{
			MsgBox Idle Champions not running
			return
		}
	}
	
	return gWindowSettings
}

;Init Globals/Settings
{
	Adjust_YValues()
	{
		;MsgBox, % gWindowSettings.HeightAdjust
		
		worldmap_favor_y 		:= worldmap_favor_y + gWindowSettings.HeightAdjust
		swordcoast_y 			:= swordcoast_y + gWindowSettings.HeightAdjust
		toa_y 					:= toa_y + gWindowSettings.HeightAdjust		
		select_win_y 			:= select_win_y + gWindowSettings.HeightAdjust
		list_top_y 				:= list_top_y + gWindowSettings.HeightAdjust
		adventure_dps_y 		:= adventure_dps_y + gWindowSettings.HeightAdjust
		transition_y 			:= transition_y + gWindowSettings.HeightAdjust
		roster_y 				:= roster_y + gWindowSettings.HeightAdjust
		roster_lcheck_y 		:= roster_lcheck_y + gWindowSettings.HeightAdjust
		autoprogress_y 			:= autoprogress_y + gWindowSettings.HeightAdjust		
		reset_continue_y 		:= reset_continue_y + gWindowSettings.HeightAdjust
		patron_Y				:= patron_Y + gWindowSettings.HeightAdjust
		
		fam_1_y := fam_1_y + gWindowSettings.HeightAdjust
		fam_2_y := fam_2_y + gWindowSettings.HeightAdjust
		fam_3_y := fam_3_y + gWindowSettings.HeightAdjust
		fam_4_y := fam_4_y + gWindowSettings.HeightAdjust
		fam_5_y := fam_5_y + gWindowSettings.HeightAdjust
		fam_6_y := fam_6_y + gWindowSettings.HeightAdjust
	}

		global gRosterButton := ""			;pixel object to find the click damage button also used often to find champ level up buttons
		global gLeftRosterPixel := ""		;pixel object to help in scrolling champ roster left
		global gSpecialWindowClose := ""	;pixel search box to help determine if Specialization Window is showing
		global gSpecialWindowSearch := ""	;pixel search box to find green select buttons in the Specialization Windows
		global oPixReset_Complete := ""		;pixel search box to find green Complete Button (1st window on reset)
		global oPixReset_Continue := ""		;pixel object to find green Continue Button (2nd window on reset)
	Init()
	{
		gFound_Error := 0
		
		;init click damage button -- rest of the buttons will be based of this positioning
		gRosterButton := {}
		gRosterButton.X 		:= roster_x
		gRosterButton.Y 		:= roster_y
		gRosterButton.Color_1 	:= roster_c1
		gRosterButton.Color_2 	:= roster_c2
		gRosterButton.Color_B1 	:= roster_b1
		gRosterButton.Color_B2 	:= roster_b2
		gRosterButton.Color_G1 	:= roster_g1
		gRosterButton.Color_G2 	:= roster_g2
		gRosterButton.Color_BG1 := roster_bg1
		gRosterButton.Color_BG2 := roster_bg2	
		gRosterButton.Spacing 	:= roster_spacing
		
		gLeftRosterPixel := {}
		gLeftRosterPixel.X 			:= roster_lcheck_x
		gLeftRosterPixel.Y 			:= roster_lcheck_y
		gLeftRosterPixel.Color_1	:= roster_lcheck_c1
		gLeftRosterPixel.Color_2	:= roster_lcheck_c2
		
		gSpecialWindowClose := {}
		gSpecialWindowClose.StartX	:= special_window_close_L
		gSpecialWindowClose.StartY 	:= special_window_close_T
		gSpecialWindowClose.EndX 	:= gWindowSettings.Width
		gSpecialWindowClose.EndY 	:= special_window_close_B
		gSpecialWindowClose.Color_1 := special_window_close_C	
		
		gSpecialWindowSearch := {}
		gSpecialWindowSearch.StartX		:= special_window_L
		gSpecialWindowSearch.StartY 	:= special_window_T
		gSpecialWindowSearch.EndX 		:= gWindowSettings.Width
		gSpecialWindowSearch.EndY 		:= special_window_B
		gSpecialWindowSearch.Color_1 	:= special_window_C
		gSpecialWindowSearch.Spacing 	:= special_window_spacing
		
		oPixReset_Complete := {}
		oPixReset_Complete.StartX 	:= reset_complete_L
		oPixReset_Complete.EndX 	:= reset_complete_R
		oPixReset_Complete.StartY 	:= reset_complete_T
		oPixReset_Complete.EndY 	:= reset_complete_B
		oPixReset_Complete.Color_1 	:= reset_complete_C
		oPixReset_Complete.Color_2 	:= reset_complete_C2
		
		oPixReset_Continue := {}
		oPixReset_Continue.X 		:= reset_continue_x
		oPixReset_Continue.Y 		:= reset_continue_y
		oPixReset_Continue.Color_1 	:= reset_continue_c1		
	}
}

;Main Loop
Loop_GemRuns()
{
	;fast check for Adventure Running --> will force a reset
	bAdventureWindowFound := AdventureWindow_Check(1)
	if (bAdventureWindowFound)
	{
		ResetAdventure()
	}
	
	while (!gFound_Error)
	{
		dtStart := A_Now
		dtLoopStartTime := A_Now
		
		dtPrevRunTime := DateTimeDiff(dtPrev, dtStart)		
		
		UpdateToolTip()		
		
		dtPrev := dtStart			
		
		gTotal_RunTime := TimeSpanAdd(gTotal_RunTime, dtPrevRunTime)
		
		;Set Campaign and Select Adventure if on World Map
		bAdventureSelected := SelectAdventure()
		
		if (bAdventureSelected)
		{
			;Loop Levels till Target Level Reached
			RunAdventure()
		}
		
		if(gHR_Enabled)
		{
			if ((nHR_CurrentLimit + 10) <= nHR_Max)
			{
				nHR_CurrentLimit := nHR_CurrentLimit + 10
			}
			else
			{
				gHR_Enabled := 0				
			}
		}
		
		;Start High Roller Levels if just past Specified Time and Auto HR Enabled
		if (bAutoHR_Enable and IsNewDay() and !gHR_Enabled)
		{
			gHR_Enabled := 1
			nHR_CurrentLimit := nHR_Min
			UpdateToolTip()
		}	
	
		bAdventureWindowFound := AdventureWindow_Check(1)
		if (bAdventureWindowFound)
		{
			;Complete the Adventure
			ResetAdventure()
		}		
		
		gTotal_RunCount := gTotal_RunCount + 1
	}
	
	ShowToolTip("No Longer Looping Runs")
}

;Start a Run
{	
	SelectAdventure()
	{
		;fast check for Adventure Running --> will force a reset
		bAdventureWindowFound := AdventureWindow_Check(1)
		if (bAdventureWindowFound)
			return 0
		
		;ensure on the World Map before trying find/click buttons(pixels)
		if (!WorldMapWindow_Check())
			return 0
		
		; Zooms out campaign map
		CenterMouse()
		Loop 15											
		{
			MouseClick, WheelDown
			Sleep 5
		}	
		Sleep 100		
		
		;get Current Patron
		FindPatron()
		Sleep, 100
		
		;campaign switching to force world map resets/positions		
		; Select Tomb of Annihilation
		Click %toa_x%, %toa_y%      			
		Sleep 100
		
		; Select A Grand Tour
		Click %swordcoast_x%, %swordcoast_y%	
		Sleep 500
		
		if (!FindTown(town_x, town_y))
		{
			MsgBox, ERROR: Failed to find the Town
			return 0
		}
		MouseClick, L, town_x, town_y
		Sleep 250
		
		if (!StartAdventure(townX, townY))
			return 0

		return 1		
	}

		global oCornerPixel := ""
	WorldMapWindow_Check()
	{
		if (!oCornerPixel)
		{
			oCornerPixel := {}
			oCornerPixel.X := worldmap_favor_x
			oCornerPixel.Y := worldmap_favor_y
		
		
			oCornerPixel.Color_1 := worldmap_favor_c1	
			oCornerPixel.Color_2 := worldmap_favor_c2
		}
		
		;wait for up to 5 second with 4 checks per second for the Target Pixel to show
		if (!WaitForPixel(oCornerPixel, 5000))
		{
			;CheckPixelInfo(oCornerPixel)
			;ShowToolTip("ERROR: Failed to find World Map in a Timely Manner.")
			return 0
		}
		return 1
	}
	
		global gCurrentPatron := ""
	FindPatron()
	{
		oPatron_NP := {}
		oPatron_NP.X 		:= patron_X
		oPatron_NP.Y 		:= patron_Y
		oPatron_NP.Color_1 	:= patron_NP_C
		
		oPatron_M := {}
		oPatron_M.X 		:= patron_X
		oPatron_M.Y 		:= patron_Y
		oPatron_M.Color_1 	:= patron_M_C
		
		oPatron_V := {}
		oPatron_V.X 		:= patron_X
		oPatron_V.Y 		:= patron_Y
		oPatron_V.Color_1 	:= patron_V_C
		
		gCurrentPatron := "NP"
		if (CheckPixel(oPatron_M))
		{	
			gCurrentPatron := "M"
			gFormation := gFormation_M
			return
		}
		if (CheckPixel(oPatron_V))
		{
			gCurrentPatron := "V"
			gFormation := gFormation_V
			return
		}
		
		if (gFormation = -1)
		{
			gFormation := gFormation_%gCurrentPatron%
		}		
		return		
	}
	
		global oTown := ""
	FindTown(ByRef townX, ByRef townY)
	{
		if(!oTown)
		{
			oTown := {}
			oTown.StartX 	:= townsearch_L 
			oTown.EndX 		:= townsearch_R
			oTown.StartY 	:= townsearch_T
			oTown.EndY 		:= townsearch_B
			oTown.Color_1 	:= townsearch_C
			oTown.HasFound 	:= -1
			oTown.FoundX 	:= ""
			oTown.FoundY	:= ""
		}
		
		;once found for this Script Run saves the position till reset/restart
		;skips searches for future loop iterations
		if (oTown.HasFound = 1)
		{
			townX := oTown.FoundX
			townY := oTown.FoundY
			return 1
		}
		
		;needs to reset Top (Y) position each time this is called
		oTown.StartY 	:= townsearch_T
				
		nTownCount 	:= 0
		bFound 		:= 1
		bFoundTown 	:= 0
		while (bFound = 1)
		{
		
			bFound := FindPixel(oTown, found%A_Index%_X, found%A_Index%_Y)
			if (bFound = 1)
			{
				nTownCount := nTownCount + 1
				oTown.StartY := found%A_Index%_Y + 25	
				
				bFoundTown := 1
				;TEST
				;MsgBox, Found Town: %A_Index%
				;MouseMove, found%A_Index%_X, found%A_Index%_Y
				;sleep, 1000
			}
			else
			{
				;MsgBox, Didnt Find Town
			}
			sleep, 50
		}
		
		if (nTownCount = 5)
		{
			townX := found4_X
			townY := found4_Y			
		}
		if (nTownCount = 4)
		{
			townX := found3_X
			townY := found3_Y			
		}
		;NOTE: for current map this should not occur and handled by (nTownCount = 2)
		if (nTownCount = 3)	
		{
			townX := found3_X
			townY := found3_Y
		}
		if (nTownCount = 2)	 
		{
			;an arbitrary position between the location of Town2 for Newer Players
			;for brand new players 	-> Town1 is Tutoril and Town2 is MadWizard
			;when WaterDeep unlocks -> Town1 is MadWizard and Town2 is WaterDeep (tutorial is off top of map)
			nX := 600
			
			;2 Towns Total - Tutorial + MadWizard
			if (found2_X < nX)	
			{
				townX := found2_X
				townY := found2_Y
			}
			;3 Towns Total - Tutorial + MadWizard + WaterDeep
			;Tutorial Town off/at edge top of screen
			else				
			{
				townX := found1_X
				townY := found1_Y
			}			
		}
		if (nTownCount = 1)	;MadWizard not available yet
		{
			bFoundTown := 0
			MsgBox, Error: It appears that you haven't completed the tutorial yet.
		}
		
		if (bFoundTown = 1)
		{
			oTown.HasFound := 1
			townY := townY + 10 ;move the Y locations slightly lower
			oTown.FoundX := townX
			oTown.FoundY := townY
			return 1
		}
		
		return 0
	}

		global oSelect_WinChecker := ""
		global oListScroll_Checker := ""
		global oAdventureSelect := ""
		global oAdventureStart := ""
	StartAdventure(townX, townY)
	{
		;ensure adventure select window is open
		if (!oSelect_WinChecker)
		{
			oSelect_WinChecker := {}
			oSelect_WinChecker.X 		:= select_win_x
			oSelect_WinChecker.Y 		:= select_win_y
			oSelect_WinChecker.Color_1 	:= select_win_c1
		}
	
		ctr := 0
		;check 10 times in 5sec intervals for the Adventure Select Window show;
		;server lag can cause issues between clicking the town and selector window displaying
		while (!bFound and ctr < 10)
		{
			;open adventure select window
			Click %town_x%, %town_y%				; Click the town button for mad wizard adventure
			Sleep 100
			
			;wait for 10 seconds for Selector window to show
			if (WaitForPixel(oSelect_WinChecker, 5000))
				bFound := 1
			
			ctr := ctr + 1
		}
		
		ctr := 0
			
		if (!bFound)
		{
			;failed to open the selector window in a timely manner
			;MsgBox, ERROR: Failed to find the Adventure Select Window 
			return 0
		}
		
		;ensure adventure select window is scrolled to top
		if (!oListScroll_Checker)
		{
			oListScroll_Checker := {}
			oListScroll_Checker.X 		:= list_top_x
			oListScroll_Checker.Y 		:= list_top_y
			oListScroll_Checker.Color_1 := list_top_c1
		}
		
		;mw adventure select
		if (!oAdventureSelect)
		{
			oAdventureSelect := {}
			oAdventureSelect.StartX 	:= MW_Find_L 
			oAdventureSelect.EndX 		:= MW_Find_R 
			oAdventureSelect.StartY 	:= MW_Find_T 
			oAdventureSelect.EndY 		:= MW_Find_B 
			oAdventureSelect.Color_1	:= MW_Find_C
			oAdventureSelect.HasFound 	:= -1
			oAdventureSelect.FoundX 	:= ""
			oAdventureSelect.FoundY		:= ""
		}
		
		nX := ((MW_Find_L + MW_Find_R) / 2)
		nY := ((MW_Find_T + MW_Find_B) / 2)
		MouseMove, %nX%, %nY%
		
		bIsNotAtTop := CheckPixel(oListScroll_Checker)
		while (bIsNotAtTop)
		{
			MouseClick, WheelUp
			
			bIsNotAtTop := CheckPixel(oListScroll_Checker)
			
			if (bIsNotAtTop)
				sleep, 50
		}
		
		if (oAdventureSelect.HasFound = 1)
		{
			foundX := oAdventureSelect.FoundX
			foundY := oAdventureSelect.FoundY
			
			MouseClick, Left, %foundX%,%foundY%
			sleep, 500
		}
		else
		{
			CenterMouse()
			sleep, 250				
			
			if (FindPixel(oAdventureSelect, foundX, foundY))
			{
				oAdventureSelect.HasFound 	:= 1
				oAdventureSelect.FoundX 	:= foundX
				oAdventureSelect.FoundY		:= foundY
				
				MouseClick, Left, %foundX%,%foundY%
				sleep, 500
			}
			else
			{
				MsgBox, Error Failed to find Mad Wizard in the Select List
				return 0
			}
		}
		;Mad Wizard should now be selected in displayed in the Right Side of window
		
		;ms adventure start
		if (!oAdventureStart)
		{
			oAdventureStart := {}
			oAdventureStart.StartX 		:= MW_Start_L 
			oAdventureStart.EndX 		:= MW_Start_R
			oAdventureStart.StartY 		:= MW_Start_T
			oAdventureStart.EndY 		:= MW_Start_B
			oAdventureStart.Color_1		:= MW_Start_C
			oAdventureStart.HasFound	:= -1
			oAdventureStart.FoundX 		:= ""
			oAdventureStart.FoundY		:= ""
		}	
		
		if (oAdventureStart.HasFound = 1)
		{
			foundX := oAdventureStart.FoundX
			foundY := oAdventureStart.FoundY
			
			MouseClick, L, foundX, foundY
			return 1
		}
		else
		{
			if (FindPixel(oAdventureStart, foundX, foundY))
			{
				oAdventureStart.HasFound := 1
				oAdventureStart.FoundX := foundX
				oAdventureStart.FoundY := foundY
				
				MouseClick, L, foundX, foundY
				return 1
			}
			else
			{
				;MsgBox, Error failed to find Adventure Start Button
				return 0
			}
		}
		
		return 0
	}
}	

;Handle Run Events.. Start/Transition/Reset
{
	RunAdventure()
	{
		;allowing for up to 30 seconds (vs the 5 sec default) to find the Adventure Window as server/game lag can cause varying time delays
		bAdventureWindowFound := AdventureWindow_Check(30000)
		if (!bAdventureWindowFound)
			return 0
		
		;wait for 1st mob to enter screen - wait upto 1min before Fails
		if (FindFirstMob())
		{
			;continue script
			sleep, 100			
		}
		else
		{
			return 0
		}
			
		;Ensure AutoProgress off to minimize issues with Specialization Windows getting stuck open
		;NOTE: spamming Send, {Right} to manage level progression
		EnableAutoProgress()
		
		;Place the Set Number Familiars
		DoFamiliars(gFamiliarCount)
			
		bContinueRun := 1
		gLevel_Number := 1
		UpdateToolTip()
		
		while (bContinueRun)
		{
			;ShowToolTip("Current Level: " gLevel_Number)		
			bRunComplete := DoLevel(gLevel_Number)		
			if (bRunComplete)
			{
				gLevel_Number := gLevel_Number + 1
							
				UpdateToolTip()
				
				if (gHR_Enabled and gLevel_Number > nHR_CurrentLimit)
				{
					bContinueRun := 0
				}
				else if (!gHR_Enabled and gLevel_Number > nMax_Level)
				{
					bContinueRun := 0
				}			
			}
			else
			{
				bContinueRun := 0
			}
		}
	}

		global oAdventureWindowCheck := 0
	;allowing for up to 5 seconds (as default) to find the Adventure Window		
	AdventureWindow_Check(wait_time := 5000)
	{
		;redish pixel in the Gold/Dps InfoBox while an adventure is running
		if (!oAdventureWindowCheck)
		{
			oAdventureWindowCheck := {}
			oAdventureWindowCheck.X := adventure_dps_x
			oAdventureWindowCheck.Y := adventure_dps_y
			oAdventureWindowCheck.Color_1 := adventure_dps_c1
			oAdventureWindowCheck.Color_2 := adventure_dps_c2
		}
		
		;wait for up to 5 second with 4 checks per second for the Target Pixel to show
		if (!WaitForPixel(oAdventureWindowCheck, wait_time))
		{
			;ShowToolTip("ERROR: Failed to find Adventure Window in a Timely Manner.")
			return 0
		}
		return 1
	}
	
		global oMobName := ""
	FindFirstMob()
	{
		if (!gMobName)
		{
			oMobName := {}
			oMobName.StartX := mob_area_L
			oMobName.EndX 	:= mob_area_R
			oMobName.StartY := mob_area_T
			oMobName.EndY 	:= mob_area_B	
			oMobName.Color_1 := mob_area_C
		}
		
		bFound := 0		
		;NOTE: WaitForPixel() -- default performs search 4 times a second for 1 minute (240 times over 1 minute)
		bFound := WaitForFindPixel(oMobName, outX, outY)
		
		return bFound	
	}
	
		global oAutoProgress := ""
	EnableAutoProgress()
	{
		if (!oAutoProgress)
		{
			oAutoProgress := {}
			oAutoProgress.X 		:= autoprogress_x
			oAutoProgress.Y 		:= autoprogress_y
			oAutoProgress.Color_1 	:= autoprogress_c1
		}
		
		;checks against White Color
		if (CheckPixel(oAutoProgress))
		{
			;Auto Progress is off .. transitions handled by Right Arrow Spamming
		}
		else
		{
			;disable AutoProgress if on
			Send, g
		}	
	}	

	DoLevel(nLevel_Number)
	{	
		;new run Level 1
		if (nLevel_Number = 1)
		{
			;ensure roster is scrolled to left (should be for new run)			
			ScrollRosterLeft()
			
			;sweep till Gold is picked up
			if(gFamiliarCount < 3)
			{
				;sweep mob arae till Champ1's level up button is green
				while (!CheckPixel(gRosterButton))
				{
					MouseSweep("UD")
				}
			}		
			
			;Wait for up to 10 seconds for the 1st Gold Gains
			if (!WaitForPixel(gRosterButton, 10000))
			{
				;took too long to find the Green ClickDamageButton - reset and try again
				;ToolTip, % "Failed to find the Click Damage Button", 50, 300, 10
				return 0			
			}
			
			Send, %gFormation%
			sleep, 100
			
			;SPECIAL LEVELING ON z1
			DoEarlyLeveling()

			Loop, 9		
			{
				Send, %A_Index%
			}		
		}
		
		;get wave number 1-5
		nWaveNumber := Mod(nLevel_Number, 5) 
		
		;Max Click Damage on 1st Level of each wave up till L100 - Disabled to avoid mouse click dragging click damage familiar to ultimates
		;if (nWaveNumber = 1 and nLevel_Number < 101) 
		;{
			;LevelUp(0)
		;}
		
		;note boss levels will be nWaveNumber = 0
		if (nWaveNumber and nLevel_Number <= gStopChampLeveling)
		{
			AutoLevelChamps(nLevel_Number)
			Send, %gFormation%
		}	
		
		DoLevel_MW(nLevel_Number)
		
		bContinueWave := 1
		while (bContinueWave)
		{
			IfWinActive, Idle Champions
			{
				Send, {Right}
			}
			else
			{	
				return
			}		
			
			bFoundTransition := CheckTransition()
			if (bFoundTransition)
			{
				;wait for black pixel to pass this point (right side of screen)
				while(CheckTransition())
				{
					sleep, 100
				}
				bContinueWave := 0
			}
			else
			{
				if (gFamiliarCount < 3 and gEnableMouseSweep = 1 and nWaveNumber)
				{
					MouseSweep()
				}
				if (gEnableAutoClick = 1)
				{
					;note: could add slight delay in transitions < 1s per zone
					MouseAutoClick()
				}
				else
				{
					sleep, 100
				}
			}
		}
		
		if (bFoundTransition)
		{
			;completed a boss level
			if (nWaveNumber = 0)
			{
				gTotal_Bosses := gTotal_Bosses + 1
			}
			
			return 1
		}
		else
		{
			return 0
		}
	}

	DoLevel_MW(nLevel_Number)
	{
		;spam ults for Levels 14/64/...
		nSpecial_Level := Mod(nLevel_Number, 50) 
		if (nSpecial_Level = 14 and gDoZ14Ultimates = 1)
		{
			sleep, 500
			Loop, 9		
			{
				Send, %A_Index%
			}
		}		
	}
	
	MouseSweep(sDirection := "UD")
	{
		;sDirection := "UD" ;LR or UD
		startx 	:= mob_area_L
		endx 	:= mob_area_R
		starty 	:= mob_area_T			
		endy	:= mob_area_B		
		vertical_step := ((endy - starty) / 4)    	;used for left->right up->down sweeping
		horizontal_step := ((endx - startx) / 4)	;used for up->down left->right sweeping
			
		if (sDirection = "UD")
		{
			Loop, 4
			{
				if (CheckTransition())
				{
					return
				}
				MouseMove, (startx + (horizontal_step * A_Index)), starty, 5
				MouseMove, (startx + (horizontal_step * A_Index)), endy, 5
			}			
		}
		else
		{
			Loop, 4
			{
				if (CheckTransition())
				{
					return
				}
				MouseMove, startx, (starty + (vertical_step * A_Index)), 5
				MouseMove, endx, (starty + (vertical_step * A_Index)), 5
			}
		}		
	}
	
	MouseAutoClick()
	{
		MouseMove, 650, 450		;old code: CenterMouse()
		Loop, 10
		{
			if (CheckTransition())
			{
				return
			}
			Click
			sleep, 10
		}
	}

		
	ResetAdventure()
	{
		IfWinActive, Idle Champions
		{
			Send, R
		}
		else
		{	
			return
		}
		
		bFound := 0		
		;NOTE: WaitForFindPixel_Moving() -- default 4 times a second for 1 minute (240 times over 1 minute)
		if (WaitForFindPixel_Moving(oPixReset_Complete, outX, outY))
		{
			;NOTE: this will be tend to be in the upper left corner (just move down and right a bit)
			oClickPixel := {}
			oClickPixel.X := outX + 15
			oClickPixel.Y := outY + 15
			
			bFound := 1
			ClickPixel(oClickPixel)		
		}
		
		if (bFound and WaitForPixel(oPixReset_Continue))
		{
			bFound := 2
			ClickPixel(oPixReset_Continue)	
		}
		return bFound
	}

		gTransitionPixel_Left := ""
		gTransitionPixel_Right := ""
	;Level Transition Check
	CheckTransition()
	{
		if (!gTransitionPixel_Left)
		{
			gTransitionPixel_Left := {}
			gTransitionPixel_Left.X 		:= 10
			gTransitionPixel_Left.Y 		:= transition_y
			gTransitionPixel_Left.Color_1 	:= transition_c1
		}
		
		if (!gTransitionPixel_Right)
		{
			gTransitionPixel_Right := {}
			gTransitionPixel_Right.X 		:= gWindowSettings.Width - 10
			gTransitionPixel_Right.Y 		:= transition_y
			gTransitionPixel_Right.Color_1 	:= transition_c1
		}
		
		return (CheckPixel(gTransitionPixel_Left) or CheckPixel(gTransitionPixel_Right))
	}

}

;Roster/Champ Functions (Leveling + Specialization)
{
	GetChampEarlyLeveling(nChampNumber)
	{
		sVal := Champ%nChampNumber%
		if (sVal)
		{			
			if (InStr(sVal, "|"))
			{
				split_vals := StrSplit(sVal, "|")
				for k, v in split_vals
				{
					v := Trim(v)
				}
				
				nCount := SizeOf(split_vals)
				if (gCurrentPatron = "NP" and nCount > 0)
				{
					sVal := split_vals[1]
				}					
				else if (gCurrentPatron = "M" and nCount > 1)
				{
					sVal := split_vals[2]
				}
				else if (gCurrentPatron = "V" and nCount > 2)
				{
					sVal := split_vals[3]
				}	
				else if (nCount > 0)
				{
					sVal := split_vals[1]
				}				
			}
			
			if (sVal is integer)
			{
				return sVal
			}
		}
		return -1
	}
	
	GetChampSpecValue(nChampNumber)
	{
		if(gFormation != -1)
		{
			sVal := Champ%nChampNumber%_SpecialOption%gFormation%	
		}
		else
		{	
			sVal := Champ%nChampNumber%_SpecialOptionQ
		}
		
		;MsgBox, % "Champ_Number: " nChampNumber " Formation:" gFormation "`nSetting Text: " value 
		if (sVal)
		{			
			if (InStr(sVal, "|"))
			{
				split_vals := StrSplit(sVal, "|")
				for k, v in split_vals
				{
					v := Trim(v)
				}
				
				nCount := SizeOf(split_vals)
				if (gCurrentPatron = "NP" and nCount > 0)
				{
					sVal := split_vals[1]
				}					
				else if (gCurrentPatron = "M" and nCount > 1)
				{
					sVal := split_vals[2]
				}
				else if (gCurrentPatron = "V" and nCount > 2)
				{
					sVal := split_vals[3]
				}	
				else if (nCount > 0)
				{
					sVal := split_vals[1]
				}				
			}
			
			if (sVal is integer)
			{
				return sVal
			}			
		}
		return -1
	}
	
	DoEarlyLeveling()
	{
		MaxChampNumber := 9
		if (gLevelingMethod = "F")
		{
			MaxChampNumber := 12
			if (gAllowF12_Leveling = 1)
			{
				MaxChampNumber := 13
			}			
		}
		
		loop, %MaxChampNumber%
		{	
			nEarlyLevelVal := GetChampEarlyLeveling(A_Index)
			if (nEarlyLevelVal > 0)
			{
				LevelUp(A_Index, nEarlyLevelVal)
			}
		}
		return
	}
	
	AutoLevelChamps(level_number := 0)
	{	
		MaxChampNumber := 9
		if (gLevelingMethod = "F")
		{
			MaxChampNumber := 12
			if (gAllowF12_Leveling = 1)
			{
				MaxChampNumber := 13
			}			
		}
		
		if (level_number)
		{
			ctr := 1	
			is_even_level := (Mod(level_number, 2) = 0)
			if (is_even_level)
			{
				ctr := ctr + 1
			}
			
			while ctr < MaxChampNumber
			{	
				LevelUp(ctr, 5)
				ctr := ctr + 2
			}
		}
		else
		{
			loop, MaxChampNumber
			{		
				LevelUp(A_Index, 10)
			}
		}
		
		CenterMouse()
		
		return
	}
	
	LevelUp(champ_number, num_clicks := 1)
	{
		;max level up - click damage 
		if (champ_number = 0)
		{
			ScrollRosterLeft()
			
			ClickPixel(gRosterButton, "MAX")
			return
		}
		
		if (gLevelingMethod = "F")
		{
			LevelUp_FKey(champ_number, num_clicks)
		}
		else 
		{
			LevelUp_Mouse(champ_number, num_clicks)
		}
	}

	LevelUp_FKey(champ_number, num_clicks := 1)
	{
		;override for F12 not enabled
		if (champ_number = 12 and gAllowF12_Leveling = 0)
		{
			return
		}
		
		nSpecialOption := GetChampSpecValue(champ_number)

		;Specialization option is 0 or -1 (ie dont use this champ)
		if (nSpecialOption < 1)
		{
			return
		}		
		
		CenterMouse()
		
		Loop, %num_clicks%
		{
			Send {F%champ_number%}
			sleep, %gFKeySleep%		;modified to global variable that can be adjusted in settings
		}
		
		;check if special window open
		sleep, 1000
		if (FindPixel(gSpecialWindowClose, foundX, foundY))
		{
			DoSpecial(nSpecialOption)
			sleep, 250
		}	
		if (FindPixel(gSpecialWindowClose, foundX, foundY))
		{
			DoSpecial(nSpecialOption)
		}
		return
	}

	;Levels/unlocks a champion or click damage
	LevelUp_Mouse(champ_number, num_clicks := 1)								
	{	
		;Click Leveling limited to 1st 8 champs
		if (champ_number > 8)
		{
			return
		}
		
		nSpecialOption := GetChampSpecValue(champ_number)
		
		;if Specialization option is 0 or -1 (ie dont use this champ)		
		if (nSpecialOption < 1)
		{
			return
		}
		
		;TODO: Add Scroll Right Functionality so get Champs on the Right
		if (champ_number < 9)
		{
			ScrollRosterLeft()
		}
		else
		{
			return
		}
			
		nX := gRosterButton.X + (gRosterButton.Spacing * champ_number)
		nY := gRosterButton.Y
		
		;get a fresh copy of ClickDamageButton (so dont alter values of the Original Object)
		;all properties of the champ buttons are same except for its X value (so only update this property)
		champ_button := gRosterButton.Clone()
		champ_button.X := nX
		
		;current champ button not green go to next champ
		if (!CheckPixel(champ_button))
		{		
			;ToolTip, % "champ not ready -- " champ_number , 50, (200 + (25 * champ_number)) , (10 + champ_number)
			Return
		}
		
		bGreyCheck := 0
		ctr := 0
		
		;spam clicks till Click Count reached or Button Greys out
		while (!bGreyCheck and ctr < num_clicks)
		{
			ClickPixel(champ_button)
			sleep, 100
			
			bGreyCheck := CheckGreyPixel(champ_button)			
			ctr := ctr + 1			
		}	
		
		;ensure the Game UI has completed the clicks
		;Game has a slight delay between Click and UI updating
		while (!bFound1)
		{		
			if (CheckGreyPixel(champ_button) or CheckPixel(champ_button))
			{
				bFound1 := 1
			}
			else
			{
				sleep, 100
			}
		}
		
		;upgrade button is relative to the champ_button
		up_button := {}
		up_button.X := nX + roster_upoff_x
		up_button.Y := nY + roster_upoff_y
		up_button.Color_1 := roster_up_c1
		up_button.Color_2 := roster_up_c2
		up_button.Color_G1 := roster_up_g1
		up_button.Color_G2 := roster_up_g2
			
		;check if Special Window is showing before continuing
		while (!bFound2 and bFound1)
		{		
			;upgrade button is Grey
			if (CheckGreyPixel(up_button))
			{
				bFound2 := 1
			}
			;upgrade button is purple
			if (CheckPixel(up_button))
			{
				DoSpecial(nSpecialOption)
			}		
			sleep, 100			
		}
		Return
	}

	ScrollRosterLeft()
	{
		;scroll roster left as required	
		nX := gWindowSettings.Width / 2
		nY := roster_y - 20
		
		bScrollRequired := !CheckPixel(gLeftRosterPixel)
		if (bScrollRequired)
		{		
			MouseMove, nX, nY
			sleep, 100
		}
		
		while (bScrollRequired)
		{
			MouseClick, WheelUp, nX, nY
			bScrollRequired := !CheckPixel(gLeftRosterPixel)
			sleep, 5
		}
	}

	DoSpecial(nSpecialOption)
	{
		bFound := 0

		;NOTE: WaitForFindPixel_Moving() -- default 4 times a second for 1 minute (240 times over 1 minute)
		if (WaitForFindPixel_Moving(gSpecialWindowClose, foundX, foundY))
		{
			window_closeX := foundX
			
			;find a Green Pixel for the First Select Button
			if (FindPixel(gSpecialWindowSearch, foundX, foundY))
			{
				bFound := 1
			}
			else
			{
				bFound := 0
			}
		}
		else
		{
			ToolTip, Failed to find Spec Window Close Box (Red Pixel), 50,200, 5
		}
		
		if (bFound)
		{
			nX := foundX + ((nSpecialOption - 1) * gSpecialWindowSearch.Spacing) + 5
			nY := foundY + 5
					
			;looks like Target Button not valid => click button 1 (not 100% accurate but should be 99%)
			if (nX > window_closeX)
			{
				;nSpacing := gSpecialWindowSearch.Spacing
				;rightX := gSpecialWindowClose.X
				;MsgBox, % "OUTSIDE SPECIAL WINDOW`n" "Special Opt:" nSpecialOption "`nSpacing: " nSpacing "`nStart:" foundX "`nCloseX:" rightX "`nClick_X:" nX
				nX := foundX + 5
			}
			
			;click special
			MouseClick, Left, nX, nY	
			
			;wait for Specialization Window to Slide off Screen
			;wait while still can still find the green pixels for the Spec Buttons
			while(FindPixel(gSpecialWindowSearch, foundX, foundY))
			{
				sleep, 100
			}		
			
			return 1
		}
		else
		{
			ToolTip, Failed to find Spec Option Boxes (1st Green Pixel), 50,225, 6
			;MsgBox,%  "Error failed to find Pixel for Special Window --" gSpecialWindowSearch.Color_1 " -- " gSpecialWindowSearch.StartX ", " gSpecialWindowSearch.StartY " -- " gSpecialWindowSearch.EndX ", " gSpecialWindowSearch.EndY
		}
		
		return 0	
	}
}

;Familiar functions
{
	DoFamiliars(fam_count)
	{
		Send Q
		sleep, 100
		Send Q
		sleep, 100
		;if (fam_count > 6)
		;{
		;	fam_count := 6
		;}
		;
		;if (gAllowFamiliarFlashes = 1)
		;{
		;	loop, %fam_count%
		;	{
		;		nX := fam_%A_Index%_x
		;		nY := fam_%A_Index%_y
		;	
		;		Send, {F down}
		;		
		;		;ensure background overlay is showing
		;		ctr := 0
		;		while(!AdventureWindow_Check() and ctr < 2)
		;		{
		;			ctr := ctr + 1
		;		}
		;		
		;		MouseMove, nX, nY
		;		sleep, 50
		;		Click
		;		sleep, 50
		;		Send, {F}
		;	}			
		;}
		;else
		;{			
		;	Send, {F down}
		;	
		;	;ensure background overlay is showing
		;	ctr := 0
		;	while(!AdventureWindow_Check() and ctr < 2)
		;	{
		;		ctr := ctr + 1
		;	}
		;	
		;	loop, %fam_count%
		;	{
		;		nX := fam_%A_Index%_x
		;		nY := fam_%A_Index%_y
		;	
		;		MouseMove, nX, nY
		;		sleep, 50
		;		Click
		;		sleep, 50
		;	}		
		;	Send, {F}
		;}
		return
	}
}

;Pixel Functions
{
	ClickPixel(oPixel, num_clicks := 1)
	{
		MoveToPixel(oPixel)
		sleep, 10
		
		if (num_clicks = "MAX")
		{
			Send, {LCtrl down}
			sleep, 50
			Click
			sleep, 50
			Send, {LCtrl up}
			sleep, 50
		}
		else
		{
			loop, %num_clicks%
			{
				Click
				sleep, 5
			}
		}	
	}

	MoveToPixel(oPixel)
	{
		nX := oPixel.X
		nY := oPixel.Y
		
		IfWinActive, Idle Champions
			MouseMove, nX, nY
	}

	CheckPixel(oPixel)
	{		
		nX := oPixel.X
		nY := oPixel.Y
		sColor_1 := oPixel.Color_1
		sColor_2 := oPixel.Color_2
		sColor_B1 := oPixel.Color_B1
		sColor_B2 := oPixel.Color_B2
		
		PixelGetColor, oColor, nX, nY, RGB	
		
		;NOTE: that pure black compares are tricky as same as null and can lead to false positives
		bFound := 0
		bFound := ((oColor = sColor_1) or bFound)
			
		if (sColor_2) 	
			bFound :=((oColor = sColor_2) or bFound)
		if (sColor_B1) 	
			bFound := ((oColor = sColor_B1) or bFound)
		if (sColor_B2) 	
			bFound := ((oColor = sColor_B2) or bFound)
		
		if(bFound)
		{
			return 1
		}
		else
		{
			;MsgBox, % sColor_1 " -- " sColor_2 " -- " sColor_B1 " -- " sColor_B2 " EOL"
			return 0
		}
	}

	CheckGreyPixel(oPixel)
	{		
		nX := oPixel.X
		nY := oPixel.Y
		sColor_1 := oPixel.Color_G1
		sColor_2 := oPixel.Color_G2
		sColor_B1 := oPixel.Color_BG1
		sColor_B2 := oPixel.Color_BG2
		
		PixelGetColor, oColor, nX, nY, RGB	
		
		bFound := 0
		bFound := ((oColor = sColor_1) or bFound)
			
		if (sColor_2) 	
			bFound :=((oColor = sColor_2) or bFound)		
		if (sColor_B1) 	
			bFound := ((oColor = sColor_B1) or bFound)
		if (sColor_B2) 	
			bFound := ((oColor = sColor_B2) or bFound)
		
		if(bFound)
		{
			return 1
		}
		else
		{
			;MsgBox, % sColor_1 " -- " sColor_2 " -- " sColor_B1 " -- " sColor_B2 " EOL"
			return 0
		}
	}

	;searchs for a Pixel within a Defined Rectangle
	FindPixel(oPixel, ByRef foundX, ByRef foundY)
	{
		nStartX := oPixel.StartX
		nStartY := oPixel.StartY
		nEndX := oPixel.EndX
		nEndY := oPixel.EndY
		
		if (!nStartX) 	
			nStartX := 0
		if (!nStartY) 	
			nStartY := 0
		if (!nEndX) 	
			nEndX := gWindowSettings.Width
		if (!nEndY) 	
			nEndY := gWindowSettings.Height
		
		bFound := 0
		
		PixelSearch, foundX, foundY,  nStartX, nStartY, nEndX, nEndY, oPixel.Color_1, , Fast|RGB
		if (ErrorLevel = 1)
		{
			;MsgBox, Error 1
		}
		else if (ErrorLevel = 2)
		{
			;MsgBox, Error 2
		} 
		else
		{
			;MsgBox, % "Found: " foundX ", " foundY "`nTop: " nStartX ", " nStartY "`nBottom: " nEndX ", " nEndY
			bFound := 1
		}
		return bFound
	}
		
	;default 4 times a second for 1 minute (240 times over 1 minute)
	WaitForPixel(oPixel, timer := 60000, interval := 250)
	{
		ctr := 0
		while (ctr < timer)
		{		
			ctr :=  ctr + interval			
			if (CheckPixel(oPixel))
				return 1

			sleep, %interval%	
		}
		return 0
	}	

	;default 4 times a second for 1 minute (240 times over 1 minute)
	WaitForFindPixel(oPixel, ByRef foundX, ByRef foundY, timer := 60000, interval := 250)
	{
		ctr := 0
		while (ctr < timer)
		{		
			ctr :=  ctr + interval			
			if (FindPixel(oPixel, foundX, foundY))
				return 1
			
			sleep, %interval%	
		}
		return 0
	}

	;default 4 times a second for 1 minute (240 times over 1 minute)
	WaitForFindPixel_Moving(oPixel, ByRef foundX, ByRef foundY, timer := 60000, interval := 250)
	{
		ctr := 0
		prevX := 0
		prevY := 0		
		
		;look for Pixel in Seach Box and Ensure it has stopped moving (ie found color in box with same X and Y values)
		while (ctr < timer)
		{		
			ctr :=  ctr + interval
			if (FindPixel(oPixel, foundX, foundY))
			{
				if (prevX = foundX and prevY = foundY)
				{
					return 1
				}
				else
				{
					;found pixel but still moving
					prevX := foundX
					prevY := foundY
				}
			}
			sleep, %interval%	
		}
		
		return 0		
	}
}

;HELPERS
{
	SizeOf(oArray)
	{
		ctr := 0
		for k, v in oArray
		{
			ctr := ctr + 1
		}
		return ctr
	}
	
	CenterMouse()
	{
		nX := gWindowSettings.Width / 2
		nY := gWindowSettings.Height / 2
		MouseMove, nX, nY
		
		Return
	}
	
	IsNewDay()
	{
		nHour_Now := 	A_Hour ;midnight is 00
		nMin_Now := 	A_Min
		nSec_Now := 	A_Sec
		;ToolTip, % "H:" nHour_Now " M:" nMin_Now " S:" nSec_Now " IsTrue: " (nHour_Now = (10 + nTimeZoneOffset) and nMin_Now > 0 and nMin_Now < 30) , 50, 100, 5
		
		;by default a New Day is flagged in 2:01AM to 2:15 range (CST) 
		return (nHour_Now = nAutoHR_Time and nMin_Now > 0 and nMin_Now < 16)
	}
		
	;return String HH:mm:ss of the timespan
	DateTimeDiff(dtStart, dtEnd)
	{
		dtResult := dtEnd
		
		EnvSub, dtResult, dtStart, Seconds
		
		nSeconds := Mod(dtResult, 60)
		nMinutes := Floor(dtResult / 60)
		nHours := Floor(nMinutes / 60)
		nMinutes := Mod(nMinutes, 60)
		
		sResult := (StrLen(nHours) = 1 ? "0" : "") nHours ":" (StrLen(nMinutes) = 1 ? "0" : "") nMinutes ":" (StrLen(nSeconds) = 1 ? "0" : "") nSeconds
		
		return sResult
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

	TimeSpanAverage(ts1, nCount)
	{
		time_parts1 := StrSplit(ts1, ":")
			
		t1_seconds := (((time_parts1[1] * 60) + time_parts1[2]) * 60) + time_parts1[3]
			
		if (!nCount)
		{
			return "00:00:00"
		}
		
		dtResult := t1_seconds / nCount	
		
		nSeconds := Floor(Mod(dtResult, 60))
		nMinutes := Floor(dtResult / 60)
		nHours := Floor(nMinutes / 60)
		nMinutes := Mod(nMinutes, 60)
		
		sResult := (StrLen(nHours) = 1 ? "0" : "") nHours ":" (StrLen(nMinutes) = 1 ? "0" : "") nMinutes ":" (StrLen(nSeconds) = 1 ? "0" : "") nSeconds
		
		return sResult
	}
}

;TEST Functions
{	
	TestWindowSettings()
	{
		nX := gWindowSettings.X
		nY := gWindowSettings.Y
		nW := gWindowSettings.Width
		nH := gWindowSettings.Height
		
		sText :=  "Window Size" "`nX, Y: " nX ", " nY "`nW,H: " nW ", " nH
		MsgBox, % sText
		return
	}

	TestFindWorldMap()
	{
		oCornerPixel := {}
		oCornerPixel.X 			:= worldmap_favor_x
		oCornerPixel.Y 			:= worldmap_favor_y	
		oCornerPixel.Color_1 	:= worldmap_favor_c1	
		oCornerPixel.Color_2 	:= worldmap_favor_c2
	
		sText := ""
		if (CheckPixel(oCornerPixel))
		{
			sText := "Success: You are currently on the World Map"
		}
		else
		{
			sText := "Error: Could not determine if you are on the World Map"
		}
		
		MouseMove, worldmap_favor_x, worldmap_favor_y
		sleep, 500	
		
		MsgBox, % sText		
	}

	TestFindPatron()
	{
		oPatron_NP := {}
		oPatron_NP.X 		:= patron_X
		oPatron_NP.Y 		:= patron_Y
		oPatron_NP.Color_1 	:= patron_NP_C
		
		oPatron_M := {}
		oPatron_M.X 		:= patron_X
		oPatron_M.Y 		:= patron_Y
		oPatron_M.Color_1 	:= patron_M_C
		
		oPatron_V := {}
		oPatron_V.X 		:= patron_X
		oPatron_V.Y 		:= patron_Y
		oPatron_V.Color_1 	:= patron_V_C
		
		if (CheckPixel(oPatron_NP))
		{
			MsgBox, Current Patron: NONE
			return
		}
		if (CheckPixel(oPatron_M))
		{	
			MsgBox, Current Patron: Mirt
			return
		}
		if (CheckPixel(oPatron_V))
		{
			MsgBox, Current Patron: Vajra
			return
		}
		MsgBox, ERROR: Failed to determine correct Patron
	}
	
	TestFindTown()
	{
		if (FindTown(foundX, foundY))
		{
		ToolTip, % "GoTo -- X,Y: " foundX "," foundY, 50, 250, 4
			sleep, 500
			MouseMove, foundX, foundY
		}
		else
		{
			ToolTip, Failed, 50, 250, 2
		}
	}
	
	TestTownLocations()
	{
		;town_3
		oPix3 := {}
		oPix3.StartX 	:= town3_L 
		oPix3.EndX 		:= town3_R
		oPix3.StartY 	:= town3_T
		oPix3.EndY 		:= town3_B
		oPix3.Color_1 	:= town3_C
		
		;town2
		oPix2 := {}
		oPix2.StartX 	:= town2_L 
		oPix2.EndX 		:= town2_R
		oPix2.StartY 	:= town2_T
		oPix2.EndY 		:= town2_B
		oPix2.Color_1 	:= town2_C
		
		;town1
		oPix1 := {}
		oPix1.StartX 	:= town1_L 
		oPix1.EndX 		:= town1_R
		oPix1.StartY 	:= town1_T
		oPix1.EndY 		:= town1_B
		oPix1.Color_1 	:= town1_C
		
		
		if (FindPixel(oPix3, foundX, foundY))
		{
			sText := sText "SUCCESS: Found Town 3`n"
			MouseMove, foundX, foundY
			sleep, 250
		}
				
		if (FindPixel(oPix2, foundX, foundY))
		{
			sText := sText "SUCCESS: Found Town 2`n"
			MouseMove, foundX, foundY
			sleep, 250
		}
		
		if (FindPixel(oPix1, foundX, foundY))
		{
			sText := sText "SUCCESS: Found Town 1`n"
			MouseMove, foundX, foundY
			sleep, 250
		}
		
		if (sText)
		{
			MsgBox, % sText
		}
		else
		{
			MsgBox, % "ERROR: Failed to find any towns"
		}
		/*
		nLeft :=	oPix1.StartX
		nRight :=	oPix1.EndX
		nTop := 	oPix1.StartY
		nBottom :=	oPix3.EndY	
			
	
		MouseMove, nLeft, nTop, 15
		sleep, 500
		MouseMove, nRight, nTop, 15
		sleep, 500
		MouseMove, nRight, nBottom, 15
		sleep, 500
		MouseMove, nLeft, nBottom,15 
		sleep, 500
		MouseMove, nLeft, nTop, 15
		sleep, 500
		*/

		return
	}
	
	TestAdventureSelect()
	{
		;ensure adventure select window is open
		oSelect_WinChecker := {}
		oSelect_WinChecker.X := select_win_x
		oSelect_WinChecker.Y := select_win_y
		oSelect_WinChecker.Color_1 := select_win_c1
	
		ctr := 0
		;check 10 times in 5sec intervals for the Adventure Select Window show;
		;server lag can cause issues between clicking the town and selector window displaying
		while (!bFound and ctr < 10)
		{
			;open adventure select window
			Click %town_x%, %town_y%				; Click the town button for mad wizard adventure
			Sleep 100
			
			;wait for 10 seconds for Selector window to show
			if (WaitForPixel(oSelect_WinChecker, 5000))
			{
				bFound := 1
			}
			
			ctr := ctr + 1
		}
		
		ctr := 0
			
		if (!bFound)
		{
			;failed to open the selector window in a timely manner
			MsgBox, ERROR: Failed to find the Adventure Select Window 
		}
		
		;ensure adventure select window is scrolled to top
		oListScroll_Checker := {}
		oListScroll_Checker.X := list_top_x
		oListScroll_Checker.Y := list_top_y
		oListScroll_Checker.Color_1 := list_top_c1
		
		;mw adventure select
		oPix1 := {}
		oPix1.StartX 	:= MW_Find_L 
		oPix1.EndX 		:= MW_Find_R 
		oPix1.StartY 	:= MW_Find_T 
		oPix1.EndY 		:= MW_Find_B 
		oPix1.Color_1	:= MW_Find_C
		
		nX := ((MW_Find_L + MW_Find_R) / 2)
		nY := ((MW_Find_T + MW_Find_B) / 2)
		MouseMove, %nX%, %nY%
		
		bIsNotAtTop := CheckPixel(oListScroll_Checker)
		while (bIsNotAtTop)
		{
			MouseClick, WheelUp
			
			bIsNotAtTop := CheckPixel(oListScroll_Checker)
			
			if (bIsNotAtTop)
			{
				sleep, 50
			}
		}
		CenterMouse()
		sleep, 250		
		
		if (FindPixel(oPix1, foundX, foundY))
		{
			ToolTip, % "Success Found It at" foundX "," foundY, 50, 100, 5
			MouseClick, Left, %foundX%,%foundY%
			sleep, 500
		}
		else
		{
			MsgBox, Error Failed to find Mad Wizard in the Select List
			return
		}
		;Mad Wizard should be in window at this position
		
		;ms adventure start
		oPix2 := {}
		oPix2.StartX 	:= MW_Start_L 
		oPix2.EndX 		:= MW_Start_R
		oPix2.StartY 	:= MW_Start_T
		oPix2.EndY 		:= MW_Start_B
		oPix2.Color_1 	:= MW_Start_C
		
		
		if (FindPixel(oPix2, foundX, foundY))
		{
			MouseMove, foundX, foundY
		}
		else
		{
			MsgBox, Error failed to find Adventure Start Button
		}
		
		return
	}
	
	TestAutoProgress()
	{
		nX := autoprogress_x
		nY := autoprogress_y
		spacing := roster_spacing
				
		MouseMove, nX, nY
		sleep, 1000	
		
		PixelGetColor, oColor, nX, nY, RGB
		ToolTip, % "Auto Progress -- Color: " oColor , 50, 100, 5
				
	}

	TestFindMob()
	{
		pixWhite := {}
		pixWhite.StartX := mob_name_L
		pixWhite.EndX 	:= mob_name_R
		pixWhite.StartY := mob_name_T
		pixWhite.EndY 	:= mob_name_B
		pixWhite.Color_1 := mob_name_C
		
		;trace the search box
		MouseMove, pixWhite.StartX, pixWhite.StartY, 25
		MouseMove, pixWhite.EndX, pixWhite.StartY, 25
		MouseMove, pixWhite.EndX, pixWhite.EndY, 25
		MouseMove, pixWhite.StartX, pixWhite.EndY, 25
		MouseMove, pixWhite.StartX, pixWhite.StartY, 25
		
		;NOTE: WaitForPixel() -- default performs search 4 times a second for 1 minute (240 times over 1 minute)
		if (WaitForFindPixel(pixWhite, outX, outY))
		{
			bFound := 1
		}
		
		if (bFound)
		{
			MsgBox, SUCCESS: Found a Mob's Name
		}
		else
		{
			MsgBox, ERROR: Failed to find a Mob's Name in time
		}
	}

	TestReadSpec(nChampNumber)
	{
		if(gFormation != -1)
		{
			sVal := Champ%nChampNumber%_SpecialOption%gFormation%	
		}
		else
		{	
			sVal := Champ%nChampNumber%_SpecialOptionQ
		}
		MsgBox, % "Champ_Number: " nChampNumber " Formation:" gFormation "`nSetting Text: " sVal 
		
		if (sVal)
		{			
			if (InStr(sVal, "|"))
			{
				split_vals := StrSplit(sVal, "|")
				for k, v in split_vals
				{
					v := Trim(v)
				}
				
				nCount := SizeOf(split_vals)
				
				MsgBox, % "Count: " split_vals.Count() " MaxIndex: " split_vals.MaxIndex() "SizeOf: " nCount
				if (gCurrentPatron = "NP" and nCount > 0)
				{
					sVal := split_vals[1]
				}					
				else if (gCurrentPatron = "M" and nCount > 1)
				{
					sVal := split_vals[2]
				}
				else if (gCurrentPatron = "V" and nCount > 2)
				{
					sVal := split_vals[3]
				}	
				else if (nCount > 0)
				{
					sVal := split_vals[1]
				}				
			}
			
			if (sVal is integer)
			{
				;return sVal
			}			
		}
		
		sval := GetChampSpecValue(nChampNumber)
		MsgBox,% sval
	}
	
	TestReadPriorityLeveling(nChampNumber)
	{
		sval := GetChampEarlyLeveling(nChampNumber)
		MsgBox,% sval
	}
	
	TestRosterButtons()
	{
		nX := roster_x
		nY := roster_y
		spacing := roster_spacing
		
		PixelGetColor, oColor1, nX, nY, RGB
			
		MouseMove, nX, nY
		sleep, 1000	
		
		PixelGetColor, oColor, nX, nY, RGB
		ToolTip, % "Champ Num: Click DMG -- Color Before: " oColor1 " Color After: " oColor , 50, 100, 5
				
		loop, 9
		{
			nX := roster_x + (A_Index * spacing)
			
			PixelGetColor, oColor1, nX, nY, RGB
			
			MouseMove, nX, nY
			sleep, 1000	
		
			PixelGetColor, oColor, nX, nY, RGB
			ToolTip, % "Champ Num: " A_Index " -- Color Before: " oColor1 " Color After: " oColor , 50, 100 + (A_Index * 25), (5 + A_Index)
		}
		return	
	}

	TestUpgradeButtons()
	{
		spacing := roster_spacing
		
		loop, 9
		{
			nX := roster_x + (A_Index * spacing) + roster_upoff_x
			nY := roster_y + roster_upoff_y
			
			PixelGetColor, oColor1, nX, nY, RGB
			
			MouseMove, nX, nY
			sleep, 1000	
		
			PixelGetColor, oColor, nX, nY, RGB
			ToolTip, % "Champ Num: " A_Index " -- Color Before: " oColor1 " Color After: " oColor , 50, 100 + (A_Index * 25), (5 + A_Index)
		}
		return	
	}

	TestTransition()
	{
		bResult := CheckTransition()
		if (bResult)
		{
			ToolTip, % "Success found black Transition", 50, 100, 5
		}
		else
		{
			nX := gTransitionPixel.X
			nY := gTransitionPixel.Y
			
			ToolTip, % "ERROR: failed to find black Transition ---" nX ", " nY, 50, 100, 5
			MouseMove, nX, nY
		}
		return
	}

	TestGetChampSpecValue(champ_num)
	{
		gFormation := "Q"
		FindPatron()
		zz := GetChampSpecValue(champ_num)
		MsgBox, % zz
		return
	}
	
	TestSpecializationWinClose()
	{
		if (FindPixel(gSpecialWindowClose, foundX, foundY))
		{
			ToolTip, % "Success found Close Button", 50, 100, 5
			return		
		}
			
		nLeft :=	gSpecialWindowClose.StartX
		nRight :=	gSpecialWindowClose.EndX
		nTop := 	gSpecialWindowClose.StartY
		nBottom :=	gSpecialWindowClose.EndY	
			
		MouseMove, nLeft, nTop, 15
		sleep, 500
		MouseMove, nRight, nTop, 15
		sleep, 500
		MouseMove, nRight, nBottom, 15
		sleep, 500
		MouseMove, nLeft, nBottom,15 
		sleep, 500
		MouseMove, nLeft, nTop, 15
		sleep, 500
		
		return
	}
	
	TestResetContinue()
	{
		;TestTraceBox(oPixReset_Complete)
		
		bFound := 0		
		;NOTE: WaitForFindPixel_Moving() -- default 4 times a second for 1 minute (240 times over 1 minute)
		if (WaitForFindPixel_Moving(oPixReset_Complete, outX, outY))
		{
			;NOTE: this will be tend to be in the upper left corner (just move down and right a bit)
			oClickPixel := {}
			oClickPixel.X := outX + 15
			oClickPixel.Y := outY + 15
			
			bFound := 1
			MoveToPixel(oClickPixel)
			;ClickPixel(oClickPixel)		
		}		
	}
	
	TestFindPixel()
	{
		oPix1 := {}		
		oPix1.StartX := 625 
		oPix1.EndX 	:= 855 ;765
		oPix1.StartY := 235 ;435
		oPix1.EndY 	:= 310
		oPix1.Color_1 := 0xB5AFA9 ;0x462A11 ; 0x4a2c12 ; 0x73665A
		
		if (FindPixel(oPix1, foundX, foundY))
		{
			ToolTip, % "Success Found It", 50, 100, 5
			MouseMove, foundX, foundY
			sleep, 1000
			;return		
		}
		else
		{
			ToolTip, % "Error Cant Find", 50, 100, 5
		}
		
		nLeft :=	oPix1.StartX
		nRight :=	oPix1.EndX
		nTop := 	oPix1.StartY
		nBottom :=	oPix3.EndY	
			
	
		MouseMove, nLeft, nTop, 15
		sleep, 500
		MouseMove, nRight, nTop, 15
		sleep, 500
		MouseMove, nRight, nBottom, 15
		sleep, 500
		MouseMove, nLeft, nBottom,15 
		sleep, 500
		MouseMove, nLeft, nTop, 15
		sleep, 500

		return
	}

	TestSpecializationSelectButtons()
	{
		if (FindPixel(gSpecialWindowSearch, foundX, foundY))
		{
			ToolTip, % "Success found 1st Green Button", 50, 100, 5
			;return		
		}
			
		nLeft :=	gSpecialWindowSearch.StartX
		nRight :=	gSpecialWindowSearch.EndX
		nTop := 	gSpecialWindowSearch.StartY
		nBottom :=	gSpecialWindowSearch.EndY	
			
		MouseMove, nLeft, nTop, 15
		sleep, 500
		MouseMove, nRight, nTop, 15
		sleep, 500
		MouseMove, nRight, nBottom, 15
		sleep, 500
		MouseMove, nLeft, nBottom,15 
		sleep, 500
		MouseMove, nLeft, nTop, 15
		sleep, 500
		
		return
	}

	CheckPixelInfo(oPixel)
	{
		if WinExist("Idle Champions")
		{
			WinActivate
		}
		
		PixelGetColor, oColor, oPixel.X, oPixel.Y, RGB	
		oPixel.FoundColor := oColor + 0 ;force convert to int	
		
		ToolTip, % "Color Found: " oPixel.FoundColor "`nSearch: " oPixel.X ", " oPixel.Y "`nC1: " oPixel.Color_1 "`nC2: " oPixel.Color_2 "`nG1: " oPixel.Color_G1 "`nG2: " oPixel.Color_G2, 50, 200, 18
		
		sleep, 250
		MoveToPixel(oPixel)
	}
	TestTraceBox(oPix)
	{
		if (oPix)
		{
			nLeft :=	oPix.StartX
			nRight :=	oPix.EndX
			nTop := 	oPix.StartY
			nBottom :=	oPix.EndY
		}
		else
		{
			nLeft :=	mob_area_L
			nRight :=	mob_area_R
			nTop := 	mob_area_T 
			nBottom :=	mob_area_B
		}
		
		MouseMove, nLeft, nTop, 15
		sleep, 500
		MouseMove, nRight, nTop, 15
		sleep, 500
		MouseMove, nRight, nBottom, 15
		sleep, 500
		MouseMove, nLeft, nBottom,15 
		sleep, 500
		MouseMove, nLeft, nTop, 15
		sleep, 500
	}
	TestSend()
	{
		wintitle = Idle Champions
		SetTitleMatchMode, 2

		;ahk_class UnityWndClass
		;ahk_exe IdleDragons.exe
		
		Loop
		{
			ControlSend, , T, ahk_exe IdleDragons.exe
			sleep, 1000
		}
		
		;IfWinExist %wintitle% 
		;{
		;	ToolTip, here, 50, 50, 17
			;Controlsend,,T, ahk_id IdleDragons.exe  ; <-- this is the proper format
			;Controlsend,,T, ahk_class UnityWndClass  ; <-- this is the proper format
		;	Send T
		;    sleep 500   
		;}
		Return
	}

}




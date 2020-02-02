Mad Wizard Gem Farming Script
revised by mikebaldi
version: 200202 (2/2/20)
by Bootch
version: 191020 (10/20/19)
original script by Hikibla 

I have no training in programing, scripting, coding, etc. I made these modifications through trial and error. They may not work for you. Use this script at your own risk. I make no promises or gaurantees that it will work as intended.

My modifications include the following:

1. Added a global variable to adjust F-Key level up delay. This can be adjusted in the settings file.
2. Added a global variable to enable or disabled z14 ultimates. This can be adjusted in the settings file. 
3. Disabled mouse click level up of click damage.
4. Adjusted pixel locations due to a UI update in a recent patch.
5. Added a loop to spam ultimates as part of do early leveling to summon Dembo.

Known Issues:

1. Mouse click leveling of champions does not work.
2. Some users cannot get the script to do anything once the adventure begins.
3. Ultimate loop to summon Dembo does not appear to always work.

The following is the original ReadMe.txt


original script was written by Hikibla but  numerous functions and code have evolved since then

Re-written/Modified by: Bootch
Current Version Date: 	191020 (10/20/19)
Resolution Setting:		1366x768 or 1280x720 (NOTE: 1366x768 long out of date)

******************************************************
*	LEVEL DETECTOR GEM FARM
******************************************************
This script is designed to farm gems and automatically progress through low level areas, then resetting and starting over the same mission
It achieves this by leveling click damage and champs but mostly allows for familiars to instant kill the mobs (note works best with at least 3 familiars for the autoloot)
It utilizes a pixel-color detector to determine when the game is changing levels and various events

/*NOTE: times are out of date*/
Overall my average run time from point to point is 8 min with 6 familiars and Torm Fav > 1e10 (fastest ive noted is 7:40) 
there are points where this can be speed up

******************************************************
*	Recent Changes:
****************************************************** 
	Version - 191020 (10/20/19)
		bug fix: modified how the PriorLeveling and SpecialOption Settings were being determined
			
******************************************************		
*	WARNINGS/Potential Issues/Recommendations
******************************************************
	Potential Issue: 	Having Title Bar turned off will create a shift in the Y values and Scrit wont be able find several Locations (Jadisero)
	Potential Issue:	If bottom IC Window is off screen script may not work properly (thx Cyber Nemesis)
	Required:			Ensure Level Up Button (bottom left corner) is set to UPG vs x1/10/100 (thx Cyber Nemesis)
	
	Warning:			Pausing Script while on Boss Level will throw off the Level Counter 
						(while script should still work may run an extra level and Leveling Champs/ClickDmg will be out of sync for that run)
	Wanring:			Typing Chest Codes with Script running may trigger the Formation Override instead of using the Setting assignment
	Recommended:		Pause Script prior to opening in game windows (store/high rollers/etc)
	Disclaimer: 		Pixel Colors and Positions may need to be tweaked to run correctly for your system (but this should be a 1 time process)
	
******************************************************	
*	Script Customizing: (MW_Settings_1280x720.ahk)
******************************************************	
		global nMax_Level 				:= 30	;sets the level that the script will run to for each iteration
	
	
	******************************************************
	*	Familiars
	******************************************************
		global gFamiliarCount 			:= 6	;number of familiars to use is REQUIRED if have < 3  familiars
												;NOTE: script handles a MAX of 6 familiars
		global gAllowFamiliarFlashes 	:= 1	;Values: 1 or 0 <-- default 1
			Sets whether the "F" Key will be pressed down and up for each Familiar
			1 will do a seperate Key Press for each familiar being placed => multiple screen flashes when placing familiars
			0 will hold the "F" key down till all familiars are placed => 2 screen flashes (1 at start and 1 at end of placement)
			NOTE: if using 0 then may cause secondary issues if game or script crashes without releasing the "F" key
	
	
	******************************************************
	*	Mouse Behavior
	******************************************************
		global gEnableAutoClick 		:= 0	;script will auto-click 10x for 100ms (upto 60 clicks/second)
		global gEnableMouseSweep 		:= 0	;script will sweep to collect gold/items (also requires gFamiliarCount < 3)

	
	******************************************************
	*	Formation to use during GemFarm
	******************************************************
			can set to whichever formation you have set up for Gem Farming
			if dont want to change it here the script will also Temporarily Save a Formation on Q/W/E KeyPress 
			NOTE: will revert back to default Formation on Scipt Reset/Reload
		global gFormation_NP 			:= "Q"	;Values: Q/W/E sets which formation to use when No Patron is Active 	(if changing use capital letters)
		global gFormation_M 			:= "Q"	;Values: Q/W/E sets which formation to use when Mirt is Active Patron 	(if changing use capital letters)
		global gFormation_V 			:= "Q"	;Values: Q/W/E sets which formation to use when Vajra is Active Active 	(if changing use capital letters)


	******************************************************
	*	Champ Leveling
	*		Set how Script Level Ups the Champs
	*			with either automated MouseClicks or use of the F-Keys
	*			MouseClick Leveling -- Limits Formation to Champs 1-8
	*			F-Key Leveling -- can use Champs 1-11 to include Champ 12 see belew		
	******************************************************
		global gLevelingMethod 			:= "M" 	;Values: M or F (set to M to use mouse while leveling or F to use Function keys)
		global gStopChampLeveling		:= 13	;script will stop leveling Champs after this Zone
		global gAllowF12_Leveling 		:= 0	;Values: 1 or 0 <-- default 1	
			CRITICAL WARNING: if using F-keys and leveling Slot 12 unless addressed this will SPAM Screenshots
			To Enable F12 Leveling:	need to set --> gLevelingMethod := "F" and gAllowF12_Leveling := 1
		

	******************************************************	
	*	Early Priority Champ Leveling
	******************************************************
		SEARCH FOR [ SPECIAL LEVELING ON z1 ] in MadWizard.ahk (approx line 1018)
			Additional Champs can be added by adding --> LevelUp(RosterSlot, NumTimesToLevel)
			Common Champs:
				LevelUp(1, 9)	;deekin speed buff
				LevelUp(6, 8) 	;shandie dash1
				LevelUp(6, 18)	;shandie dash2
				LevelUp(7, 4)	;minc extra mob

			
	******************************************************
	*	Champ Specialization Options
	******************************************************
		these values will determine which specialization to select for each champ based on default (or temp formation selected via keyboard)
			if dont want to include a specific champ set their SpecialOption to -1
			see more info on this in the MW_Settings.ahk file
			global Champ1_SpecialOptionQ/W/E := 2	;deekin - epic tale
			global Champ2_SpecialOptionQ/W/E := 1	;cele - war domain
			global Champ3_SpecialOptionQ/W/E := 1	;nay
			global Champ4_SpecialOptionQ/W/E := 2	;ishi - clear them out
			global Champ5_SpecialOptionQ/W/E := 1	;cali
			global Champ6_SpecialOptionQ/W/E := 1	;ash - humans
			global Champ7_SpecialOptionQ/W/E := 2	;minsc - beasts
			global Champ8_SpecialOptionQ/W/E := 2	;hitch - cha
			global Champ9_SpecialOptionQ/W/E := 1	;tyril - moonbeam (even though code is currently limited to 1st 8 champs)	
		
******************************************************			
*	Additional Notes:
******************************************************
	on levels : 			1,6,11,... Click Damage is Maxed
	boss levels	: 			no special functions added at this time
	remaining even levels :	will attempt to level up even numbered champs 5 levels at time and assign Specializations as needed
	remaining odd levels :	will attempt to level up odd numbered champs 5 levels at time and assign Specializations as needed
	special levels : 
							1...waits for Mobs to Show -> places familiars -> waits for  initial Gold Collection -> does Early Priority Champ Leveling -> Maxs Click DMG
							14,64,..(orb levels) all available Ults will be triggered						

******************************************************
*	HOTKEYS
******************************************************
	`		: Pauses the Script
	F1		: (Help) -- Shows ToolTip with HotKey Info 
	F2		: starts the script to farm MadWizard to L30
	F3		: enables High Roller functionality -- (by default) iterates through Levels 50-90 (10 at time) then resets back to L30
	F8		: shows stats for the current script run
	F9		: Reloads the script
	Up		: used to increase the Target Level by 10 till next Script Reset/Reload
	DOWN	: used to decrease the Target Level by 10 till next Script Reset/Reload
	Q/W/E	: will Temporarily Save the Formation Selected (w/ keyboard) till next Script Reset/Reload

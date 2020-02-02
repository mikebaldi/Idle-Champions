;NOTES / Potential Issues
;these values are based on the gaming running at 1280x720 (windowed)
;Having Title Bar turned off will create a shift in the Y values and Script wont be able find several Locations (Jadisero)
;values may not match if running game full screen

;revised by mikebaldi
;version: 200202 (2/2/20)
;original by Bootch

;----------------------------
;	User Settings
;	various settings to allow the user to Customize how the Script behaves
;----------------------------			
	global nMax_Level 				:= 210	;sets the level that the script will run to for each iteration
	
	;Familiars
	global gFamiliarCount 				:= 6	;number of familiars to use is REQUIRED if have < 3  familiars
											;NOTE: script handles a MAX of 6 familiars
	global gAllowFamiliarFlashes 	:= 1	;Values: 1 or 0 <-- default 1
		;Sets whether the "F" Key will be pressed down and up for each Familiar
		;1 will do a seperate Key Press for each familiar being placed => multiple screen flashes when placing familiars
		;0 will hold the "F" key down till all familiars are placed => 2 screen flashes (1 at start and 1 at end of placement)
		;NOTE: if using 0 then may cause secondary issues if game or script crashes without releasing the "F" key
	
	;mouse behavior
	global gEnableAutoClick 		:= 1	;script will auto-click 10x for 100ms (upto 60 clicks/second)
	global gEnableMouseSweep 		:= 0	;script will sweep to collect gold/items (also requires gFamiliarCount < 3)

	;Formation to use during GemFarm
	;	can set to whichever formation you have set up for this script 
	;	if dont want to change it here the script will also Temporarily Save a Formation on Q/W/E KeyPress 
	;	NOTE: will revert back to default Formation on Scipt Reset/Reload
	global gFormation_NP 			:= "Q"	;Values: Q/W/E sets which formation to use when No Patron is Active 	(if changing use capital letters)
	global gFormation_M 			:= "Q"	;Values: Q/W/E sets which formation to use when Mirt is Active Patron 	(if changing use capital letters)
	global gFormation_V 			:= "Q"	;Values: Q/W/E sets which formation to use when Vajra is Active Active 	(if changing use capital letters)

	;Champ Leveling
	;	Set how Script Level Ups the Champs
	;		with either automated MouseClicks or use of the F-Keys
	;		MouseClick Leveling -- Limits Formation to Champs 1-8 
	;		F-Key Leveling -- can use Champs 1-11 to include Champ 12 see below		
	global gLevelingMethod 			:= "F" 	;Values: M or F (set to M to use mouse while leveling or F to use Function keys)
	global gFKeySleep			:= 100	;Increase if F-Key leveling is not registering every press
	global gStopChampLeveling		:= 3	;script will stop leveling Champs after this Zone
	global gAllowF12_Leveling 		:= 0	;Values: 1 or 0 <-- default 1	
	global gDoZ14Ultimates			:= 0	;Set to 1 to spam ultimates on z1
		;----------------------
		;CRITICAL WARNING: if using F-keys and leveling Slot 12 unless addressed this will SPAM Screenshots
		;	To Enable F12 Leveling:
		;		need to set --> gLevelingMethod := "F" and gAllowF12_Leveling := 1
		;----------------------									

	;High Roller Settings -- will increment target level by 10 till completes the max then defaults back to [nMax_Level]
	;	NOTE: No longer in use but keeping this in case a similar event returns
	global nHR_Min 			:= 50		; start HR runs at z50
	global nHR_Max 			:= 90		; end HR runs after completing z90
	global bAutoHR_Enable	:= 0		; Values: 1 or 0 <-- 1 to auto run HR Levels 0 to disable this feature
	global nAutoHR_Time 	:= 2		; High Roller Levels will be enabled when game Loops within 15 minutes after this Hour 
										; for 2 it will begin HR Levels between 2:01 AM Local Time and 2:15 AM Local Time 
										; if Local CST this will be 12:01 AM PST and 12:15 AM PST
											
	;----------------------------
	;Champ Priority Leveling/Specialization 
	;	Setting Values
	;		NOTE: Script will determine the Current Patron or No Patron
	;		NOTE: if MouseClicking -- Script will look at Champs 1-8
	;		NOTE: if F(unction) Keys Enabled -- Script will look at Champs 1-11 and 12 if Enabled
	;----------------------------
	;Champ Priority Leveling
	;	Set which champs are leveled up with the inital gold drops
	;	prior to running the Automated Champ Leveling
	;
	;		Set Value to -1 if Champ is not to be Leveled Early
	;		Set Value Number to indicate the number upgrades (clicks) for the champ in that slot
	;	Additional Functionality
	;		If wish to use different options for Patrons
	;		NOTE: the DOUBLE QUOTES are required or only the 1st value will be read
	;		Set Value NoPatron_Option, Mirt_Option, Vajra_Option 
	;			Examples: 
	;				global Champ1 	:= "9|-1|9"	;deekin
	;					will level up Slot 1 (Deekin) when running NoPatron or Vajra but skip Slot 1 on Mirt
	;				global Champ6 	:= 18		;shandie
	;					will level up Slot 6 (Shandie) for all Gem Runs
	;				global Champ3 	:= -1		;cele
	;					the Champ in Slot 3 would not be added to leveled up early
	;----------------------------
	global Champ1	:= "9|-1|9"			
	global Champ2	:= -1
	global Champ3	:= -1
	global Champ4	:= 16
	global Champ5	:= -1
	global Champ6	:= 18				
	global Champ7	:= 4			
	global Champ8	:= -1
	global Champ9	:= -1
	global Champ10	:= "13|13|-1"
	global Champ11	:= -1
	global Champ12	:= -1
	
	;----------------------------
	;Champ Specialization Selection
	;		NOTE: if Value is not Valid; script will default to 1 
	;		NOTE: if Value is Out of Range (ie had Minsc and was set to 5 and switched to Black Viper) script will default to Option 1
	;
	;		Set Value to -1 if Champ is not to be Used (wont be leveled and should never get added to formation)
	;		Set Value 1-7 (depends on Champ's Options) to the Specialization Option you'd like for the Champ
	;
	;	Additional Functionality
	;		If wish to use different options for Patrons
	;		NOTE: the DOUBLE QUOTES are required or only the 1st value will be read
	;		Set Value NoPatron_Option, Mirt_Option, Vajra_Option 
	;			Examples: 
	;				global Champ1_SpecialOptionQ 	:= "2|1|2"	;deekin
	;					would use Option 2 when running NoPatron, Option 1 when running Mirt, Option 2 when running Vajra
	;				global Champ2_SpecialOptionQ 	:= 1		;cele
	;					would use Option 1 for NoPatron, Mirt, and Vajra runs
	;				global Champ3_SpecialOptionQ 	:= -1		;nay
	;					the Champ in Slot 3 would not be added to formation and skip leveling regardless of the save formation being used
	;----------------------------
	;----------------------------
	;Champ Specialization selections will need to be set based on your formation	
	;----------------------------
	global Champ1_SpecialOptionQ 	:= 1		;deekin,bruenor,deekin
	global Champ2_SpecialOptionQ 	:= -1		;cele
	global Champ3_SpecialOptionQ 	:= -1		;nay
	global Champ4_SpecialOptionQ 	:= 2		;jar,jar,paul
	global Champ5_SpecialOptionQ 	:= -1		;cali
	global Champ6_SpecialOptionQ 	:= 1		;shandie
	global Champ7_SpecialOptionQ 	:= 2		;minsc,minsc,bv
	global Champ8_SpecialOptionQ 	:= -1		;hitch,hitch,walnut
	global Champ9_SpecialOptionQ 	:= -1		;makos
	global Champ10_SpecialOptionQ	:= 2		;tyril
	global Champ11_SpecialOptionQ 	:= -1		;strix
	global Champ12_SpecialOptionQ 	:= -1		;zorbu

	;----------------------------
	;Champ Specialization selections will need to be set based on your formation	
	;----------------------------
	global Champ1_SpecialOptionW 	:= 2		;deekin
	global Champ2_SpecialOptionW 	:= -1		;cele
	global Champ3_SpecialOptionW 	:= -1		;nay
	global Champ4_SpecialOptionW	:= 2		;jar,jar,paul
	global Champ5_SpecialOptionW 	:= -1		;cali
	global Champ6_SpecialOptionW 	:= 1		;shandie
	global Champ7_SpecialOptionW 	:= "2|2|2"	;minsc
	global Champ8_SpecialOptionW 	:= -1		;hitch,hitch,walnut
	global Champ9_SpecialOptionW 	:= -1		;makos
	global Champ10_SpecialOptionW	:= -1		;tyril
	global Champ11_SpecialOptionW 	:= -1		;strix
	global Champ12_SpecialOptionW 	:= -1		;zorbu

	;----------------------------
	;Champ Specialization selections will need to be set based on your formation	
	;----------------------------
	global Champ1_SpecialOptionE 	:= "2|1|2"	;deekin,bruenor,deekin
	global Champ2_SpecialOptionE 	:= -1		;cele
	global Champ3_SpecialOptionE 	:= -1		;nay
	global Champ4_SpecialOptionE 	:= 2		;jar,jar,paul
	global Champ5_SpecialOptionE 	:= -1		;cali
	global Champ6_SpecialOptionE 	:= 1		;shandie
	global Champ7_SpecialOptionE 	:= "2|2|2"	;minsc,minsc,bv
	global Champ8_SpecialOptionE 	:= -1		;hitch,hitch,walnut
	global Champ9_SpecialOptionE 	:= -1		;makos
	global Champ10_SpecialOptionE	:= -1		;tyril
	global Champ11_SpecialOptionE 	:= -1		;strix
	global Champ12_SpecialOptionE 	:= -1		;zorbu


;----------------------------
;	Script Settings
;	Ideally these should not need to be modified by the user
;----------------------------	
;design window sizes
	global gWindowWidth_Default 	:= 1296 ;old := 1286
	global gWindowHeight_Default	:= 759	;old := 749

;campaign buttons/locations
	global worldmap_favor_x := 1250			; pixel in favor box (top right of world map screen)
	global worldmap_favor_y := 115					
	global worldmap_favor_c1 := 0x282827	;dark brown/gray
	global worldmap_favor_c2 := 0x282827	;second color added to correct for possible error when last campaign was an Event 

	global swordcoast_x	:= 50				; horizontal location of the tomb button
	global swordcoast_y	:= 115				; vertical location of the tomb button
	global toa_x 		:= 50				; horizontal location of the sword coast button	
	global toa_y		:= 185				; vertical location of the sword coast button
	

;Sword Coast Town with Mad Wizard Adventure
;	there are different positions for the town with the MadWizard adventures based on user progression
;	code will search top to bottom to find all the towns and based on findings determine the correct town for MadWizard runs
	global townsearch_L		:= 400 	
	global townsearch_R		:= 1100
	global townsearch_T		:= 135
	global townsearch_B		:= 700
	global townsearch_C		:= 0xB5AFA9 		;grey/brown-ish

;Patron Detect
	global patron_X 		:= 1105		;old := 1100
	global patron_Y			:= 245		;:= 240
	global patron_NP_C		:= 0x303030
	global patron_M_C		:= 0xBB9E97
	global patron_V_C		:= 0xA37051
	
; red pixel for the Close Button on the Adventure Select window
	global select_win_x 	:= 1043			
	global select_win_y 	:= 56	
	global select_win_c1	:= 0xAF0202 	;red-ish

; pixel to check if list is scrolled to the top (if valid then list needs to scroll up)
	global list_top_x		:= 550			
	global list_top_y		:= 115
	global list_top_c1		:= 0x0A0A0A		;almost solid back (slider background color)				

;searchbox for a pixel in the MadWizard FP Picture displayed in the Adventure Select List
	global MW_Find_L 	:= 255				
	global MW_Find_R 	:= 475
	global MW_Find_T 	:= 65
	global MW_Find_B 	:= 670
	global MW_Find_C 	:= 0x728E57			;pixel in Mad Wizard's Eye
	global MW_Find_C2	:= 0x7C9861			;pixel in Mad Wizard's Eye (when hovered)

;searchbox to find Blue-ish pixel in the Mad Wizard Start Button
	global MW_Start_L	:= 575				
	global MW_Start_R	:= 1025
	global MW_Start_T	:= 550
	global MW_Start_B	:= 700
	global MW_Start_C	:= 0x4175B4			;Blue-ish (in middle of the 'O' in Objective)	
		
;adventure window pixel (redish pixel in the Redish Flag behind the gold coin in the DPS/Gold InfoBox)
	global adventure_dps_x	:= 70
	global adventure_dps_y	:= 35
	global adventure_dps_c1	:= 0x90181C
	global adventure_dps_c2 := 0x731316

;search box for 1st mob
	global mob_area_L	:= 750
	global mob_area_R	:= 1225
	global mob_area_T	:= 225
	global mob_area_B	:= 525
	global mob_area_C 	:= 0xFEFEFE			;almost solid white
	
;autoprogress check
	global autoprogress_x		:= 1247				; horizontal location of a white pixel in the autoprogress arrow
	global autoprogress_y		:= 134 				; vertical location of a white pixel in the autoprogress arrow
	global autoprogress_c1		:= 0xFFFFFF			; white color
	
;variables for checking if a transition is occurring (center of screen and towards top)
	global transition_y 	:= 35 				;toward top of screen
	global transition_c1	:= 0x000000 		;black

;variables pertaining to manipulating the champion roster (and click damage upgrade)
	global roster_x			:= 133			; horizontal location of the a point in the upper left corner of the click damage button
	global roster_y			:= 720			; vertical location of the a point in the upper left corner of the click damage button
	global roster_c1		:= 0x58B831		; Green this used to check if Level Ups are ready
	global roster_c2		:= 0x5CCB2F		; Green Hover color
	global roster_b1		:= 0x589CDE		; Blue Bench Color (benched or not unlocked)
	global roster_b2		:= 0x5CABF7		; Blue Bench Hover Color (benched or not unlocked)
	global roster_g1		:= 0x8F8F8F		; Grey this used to check if Level Ups are ready (via a not check)	
	global roster_g2		:= 0x6B6B6B		; Grey this used to check if Level Ups are ready (if special window is open)		
	global roster_bg1		:= 0x8C8C8C		; Grey this used to check if Level Ups are ready (via a not check - bench champ)		
	global roster_bg2		:= 0x696969		; Grey this used to check if Level Ups are ready (if special window is open - bench champ)		
	global roster_spacing	:= 113			; distance between the roster buttons
	
;whitish pixel on Left Border of Champ1 - used to ensure Roster is Left Justified
	global roster_lcheck_x	:= 131						
	global roster_lcheck_y	:= 645
	global roster_lcheck_c1	:= 0xEFEFEF
	global roster_lcheck_c2	:= 0xB3B3B3

;checks the pixel in bottom left of the Upgrade Button (Square)
;	location is relative to the Found Pixel of the Champ Level Up Button
	global roster_upoff_x 	:= 77
	global roster_upoff_y	:= 16
	global roster_up_c1		:= 0xC94292			;purple without open window		;0x821A61	(katti 7A1761)
	global roster_up_c2		:= 0x97316D			;purple with open window		;0x611349	(katti 5B1149)	
	global roster_up_g1		:= 0x5B5B5B			;grey without open window 					(katti 434343)
	
;red pixel for the close button of the Specialization Window
	global special_window_close_L	:= 0			;this will be screen left
	global special_window_close_R	:= 0			;this will be screen width
	global special_window_close_T	:= 110
	global special_window_close_B	:= 165
	global special_window_close_C	:= 0xCF0000
	
;find left most Green Specialization Select Button
	global special_window_L 		:= 0
	global special_window_T 		:= 550
	global special_window_B 		:= 625
	global special_window_C			:= 0x54B42D 	;color of green button
	global special_window_spacing 	:= 248

;Searchbox to find the Reset Button
	global reset_complete_T		:= 475
	global reset_complete_B		:= 600
	global reset_complete_L		:= 500
	global reset_complete_R		:= 625
	global reset_complete_C		:= 0x54B42D		;green-ish
	global reset_complete_C2	:= 0x5AC030		;hover green

;Pixel location for the Continue Button (During Reset)
	global reset_continue_x		:= 560
	global reset_continue_y		:= 615	
	global reset_continue_c1	:= 0x4A9E2A		;green-ish

;familiar positions
	global fam_roster_top		:= 540
	global fam_roster_bottom	:= 600
	global fam_roster_c1		:= 0x5486C6

	global fam_1_x 	:= 950
	global fam_1_y 	:= 290
	global fam_2_x 	:= 880
	global fam_2_y 	:= 350
	global fam_3_x 	:= 1015
	global fam_3_y 	:= 350
	global fam_4_x 	:= 880
	global fam_4_y 	:= 420
	global fam_5_x 	:= 1015
	global fam_5_y 	:= 420
	global fam_6_x 	:= 950
	global fam_6_y 	:= 485
	global fam_CD_x := 160
	global fam_CD_y := 725
	global fam_U_x 	:= 420		;need work to find this location (changes with number of Ults unlocked)
	global fam_U_y 	:= 600		;need work to find this location (changes with number of Ults unlocked)
	
	
													
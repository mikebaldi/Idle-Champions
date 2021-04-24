;date of script: 4/24/21
;========================================
;User settings not accessible via the GUI
;========================================
;globals for buying and opening chests when offline during restart stacking
global gSCMinGemCount := 0 ;script will only buy chests when you have more than this many gems
;script will only ever buy one type of chest, which ever it can afford first
global gSCBuySilvers := 100 ;script will buy this many silvers when you have enough gems
global gSCSilverCount := 99 ;script will open this many silvers when you have hoarded at least this many
global gSCBuyGolds := 0 ;script will buy this many golds when you have enough gems
global gSCGoldCount := 99 ;script will open this many golds when you have hoarded at least this many
;global gEventSilverID := 0 ;event silver chest ID, set to 0 to disable
;global gEventSilverCount := 99 ;script will open this many event silvers when you have hoarded at least this many
;global gEventGoldID := 0 ;event gold chest ID, set to 0 to disable
;global gEventGoldCount := 99 ;script will open this many event golds when you have hoarded at least this many
;====================
;end of user settings
;====================

;globals used to track chest opening and purchases
global gSCGemsSpent := 0
global gSCSilversPurchased := 0
global gSCGoldsPurchased := 0
global gSCSilversOpened := 0
global gSCGoldsOpened := 0
global gSCFirstRun := 1
global gSCRedRubiesStart :=
global gSCRedRubiesSpentStart :=

;global variables used for server calls
global DummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
global ActiveInstance :=
global InstanceID :=
global UserID :=
global UserHash := ""
global advtoload :=
global gSilversHoarded := ;variable to store amount of chests hoarded
global gGoldsHoarded := ;variable to store amount of chests hoarded
global gEventSilversHoarded := ;variable to store amount of chests hoarded
global gEventGoldsHoarded := ;variable to store amount of chests hoarded
global gRedRubies := ;variable to store amount of gems server thinks you have
global gRedRubiesSpent := ;variable to store amount of gems server thinks you have spent

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
	{
		if (v.game_instance_id == ActiveInstance) 
		{
			CurrentAdventure := v.current_adventure_id
			GuiControl, MyWindow:, CurrentAdventureID, % CurrentAdventure
		}
	}
	gSilversHoarded := UserDetails.details.chests.1
	gGoldsHoarded := UserDetails.details.chests.2
	gRedRubies := UserDetails.details.red_rubies
	gRedRubiesSpent := UserDetails.details.red_rubies_spent
	rawdetails :=
	UserDetails := 
	return CurrentAdventure
}

LoadAdventure() 
{
	advparams := DummyData "&patron_tier=0&user_id=" UserID "&hash=" UserHash "&instance_id=" InstanceID "&game_instance_id=" ActiveInstance "&adventure_id=" advtoload "&patron_id=0"
    ServerCall("setcurrentobjective", advparams)
	return
}

BuyChests(chestID, chests)
{
	if (chests > 100)
	chests := 100
	else if (chests < 1)
	return
	chestparams := DummyData "&user_id=" UserID "&hash=" UserHash "&instance_id=" InstanceID "&chest_type_id=" chestid "&count=" chests
	ServerCall("buysoftcurrencychest", chestparams)
	return
}

OpenChests(chestID, chests)
{
	if (chests > 99)
	chests := 99
	else if (chests < 1)
	return
	chestparams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" UserID "&hash=" UserHash "&instance_id=" InstanceID "&chest_type_id=" chestid "&game_instance_id=" ActiveInstance "&count=" chests
	ServerCall("opengenericchest", chestparams)
	return
}

;functions not actually for server calls
DoChests()
{
	GetUserDetails()
	if gSCFirstRun
	{
		gSCRedRubiesStart := gRedRubies
		GuiControl, MyWindow:, gSCRedRubiesStartID, %gSCRedRubiesStart%
		gSCRedRubiesSpentStart := gRedRubiesSpent
		GuiControl, MyWindow:, gSCRedRubiesSpentStartID, %gSCRedRubiesSpentStart%
		gSCFirstRun := 0
	}
	if (gSCSilverCount < gSilversHoarded)
	{
		OpenChests(1, gSCSilverCount)
		gSCSilversOpened := gSCSilversOpened + gSCSilverCount
		GuiControl, MyWindow:, gSCSilversOpenedID, %gSCSilversOpened%
	}
	else if(gSCGoldCount < gGoldsHoarded)
	{
		OpenChests(2, gSCGoldCount)
		gSCGoldsOpened := gSCGoldsOpened + gSCGoldCount
		GuiControl, MyWindow:, gSCGoldsOpenedID, %gSCGoldsOpened%
	}
	else if (gSCBuySilvers)
	{
		i := gSCBuySilvers * 50
		j := i - gSCMinGemCount
		if (gRedRubies > j)
		{
			BuyChests(1, gSCBuySilvers)
			gSCGemsSpent := gSCGemsSpent + i
			GuiControl, MyWindow:, gSCGemsSpentID, %gSCGemsSpent%
		}
	}
	else if (gSCBuyGolds)
	{
		i := gSCBuyGolds * 500
		j := i - gSCMinGemCount
		if (gRedRubies > j)
		{
			BuyChests(2, gSCBuyGolds)
			gSCGemsSpent := gSCGemsSpent + i
			GuiControl, MyWindow:, gSCGemsSpentID, %gSCGemsSpent%
		}
	}
	var := gRedRubiesSpent - gSCRedRubiesSpentStart
	GuiControl, MyWindow:, GemsSpentID, %var%
	Return
}



BuildChestGUI()
{

	Gui, MyWindow:Show
}
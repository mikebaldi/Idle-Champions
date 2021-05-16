;date of script: 5/14/21

;globals used to track chest opening and purchases
global gSCGemsSpent := 0
global gSCSilversOpened := 0
global gSCSilversOpenedStart :=
global gSCGoldsOpened := 0
global gSCGoldsOpenedStart :=
global gSCFirstRun := 1
global gSCRedRubiesSpentStart :=

;global variables used for server calls
global DummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
global ActiveInstance :=
global InstanceID :=
global UserID :=
global UserHash := ""
global advtoload :=
global gSilversHoarded := ;variable to store amount of chests hoarded
global gSilversOpened := ;variable to store amount of chests opened
global gGoldsHoarded := ;variable to store amount of chests hoarded
global gGoldsOpened := ;variable to store amount of chests opened
;global gEventSilversHoarded := ;variable to store amount of chests hoarded
;global gEventGoldsHoarded := ;variable to store amount of chests hoarded
global gRedRubies := ;variable to store amount of gems server thinks you have
global gRedRubiesSpent := ;variable to store amount of gems server thinks you have spent

ServerCall(callname, parameters) 
{
	URLtoCall := "http://ps6.idlechampions.com/~idledragons/post.php?call=" callname parameters
	;GuiControl, MyWindow:, advparamsID, % URLtoCall
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
	Try
	{
		UserDetails := JSON.parse(rawdetails)
	}
	Catch
	{
		Return
	}
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
	gSilversOpened := UserDetails.details.stats.chests_opened_type_1
	gGoldsHoarded := UserDetails.details.chests.2
	gGoldsOpened := UserDetails.details.stats.chests_opened_type_2
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
	GuiControl, MyWindow:, gloopID, Getting User Details to Do Chests
	GetUserDetails()
	if gSCFirstRun
	{
		gSCRedRubiesSpentStart := gRedRubiesSpent
		GuiControl, MyWindow:, gSCRedRubiesSpentStartID, %gSCRedRubiesSpentStart%
		gSCSilversOpenedStart := gSilversOpened
		GuiControl, MyWindow:, gSCSilversOpenedStartID, %gSCSilversOpenedStart%
		gSCGoldsOpenedStart := gGoldsOpened
		GuiControl, MyWindow:, gSCGoldsOpenedStartID, %gSCGoldsOpenedStart%
		gSCFirstRun := 0
	}
	if (gSCSilverCount < gSilversHoarded AND gSCSilverCount)
	{
		GuiControl, MyWindow:, gloopID, Opening %gSCSilverCount% Silver Chests
		OpenChests(1, gSCSilverCount)
	}
	else if (gSCGoldCount < gGoldsHoarded AND gSCGoldCount)
	{
		GuiControl, MyWindow:, gloopID, Opening %gSCGoldCount% Gold Chests
		OpenChests(2, gSCGoldCount)
	}
	else if (gSCBuySilvers)
	{
		i := gSCBuySilvers * 50
		j := i + gSCMinGemCount
		if (gRedRubies > j)
		{
			GuiControl, MyWindow:, gloopID, Buying %gSCBuySilvers% Silver Chests
			BuyChests(1, gSCBuySilvers)
		}
	}
	else if (gSCBuyGolds)
	{
		i := gSCBuyGolds * 500
		j := i + gSCMinGemCount
		if (gRedRubies > j)
		{
			GuiControl, MyWindow:, gloopID, Buying %gSCBuyGolds% Gold Chests
			BuyChests(2, gSCBuyGolds)
		}
	}
	var := gRedRubiesSpent - gSCRedRubiesSpentStart
	GuiControl, MyWindow:, GemsSpentID, %var%
	var := gSilversOpened - gSCSilversOpenedStart
	GuiControl, MyWindow:, gSCSilversOpenedID, %var%
	var := gGoldsOpened - gSCGoldsOpenedStart
	GuiControl, MyWindow:, gSCGoldsOpenedID, %var%
	Return
}
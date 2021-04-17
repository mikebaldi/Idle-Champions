
;globals for buying and opening chests when offline during restart stacking
global gMinGemCount	:= 0 ;script will only buy chests when you have more than this many gems
;script will only ever buy one type of chest, which ever it can afford first
global gBuySilvers := 100 ;script will buy this many silvers when you have enough gems
global gSilverCount := 99 ;script will open this many silvers when you have hoarded at least this many
global gBuyGolds := 0 ;script will buy this many golds when you have enough gems
global gGoldCount := 99 ;script will open this many golds when you have hoarded at least this many
;global gEventSilverID := 0 ;event silver chest ID, set to 0 to disable
;global gEventSilverCount := 99 ;script will open this many event silvers when you have hoarded at least this many
;global gEventGoldID := 0 ;event gold chest ID, set to 0 to disable
;global gEventGoldCount := 99 ;script will open this many event golds when you have hoarded at least this many

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
global gServerGems := ;variable to store amount of gems server thinks you have

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
	gServerGems := UserDetails.details.red_rubies
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
	if (gSilverCount < gSilversHoarded)
	{
		OpenChests(1, gSilverCount)
	}
	else if(gGoldCount < gGoldsHoarded)
	{
		OpenChests(2, gGoldCount)
	}
	else if (gBuySilvers)
	{
		i := gBuySilvers * 50
		j := i - gMinGemCount
		if (gServerGems > j)
		{
			BuyChests(1, gBuySilvers)
		}
	}
	else if (gBuyGolds)
	{
		i := gBuyGolds * 500
		j := i - gMinGemCount
		if (gServerGems > j)
		{
			BuyChests(2, gBuyGolds)
		}
	}

	Return
}
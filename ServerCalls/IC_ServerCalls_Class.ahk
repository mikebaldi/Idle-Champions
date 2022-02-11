;=================================
;Class for making server calls
;=================================
/*  Usage: 
        variable := new IC_ServerCalls( userID, userHash ) ;create new object
        variable.method() ;see methods below
    Parameters:
        userID - your unique userID
        userHash - your unique userHash

    Changes:
    IC_ServerCalls_Class: v2.0, 12/06/21
    1. Added current time and processing time as data to pull from user details
*/

class IC_ServerCalls_Class
{
    userID := 0
    userHash := ""
    instanceID := 0
    networkID := 11
    clientVersion := 999
    activeModronID := 1
    userDetails := ""
    activePatronID := 0
    dummyData := ""
    webRoot := "https://ps6.idlechampions.com/~idledragons/"

    __New( userID, userHash, instanceID := 0 )
    {
        this.userID := userID
        this.userHash := userHash
        this.instanceID := instanceID
        this.shinies := 0
        return this
    }

    GetVersion()
    {
        return "IC_ServerCalls_Class: v2.2, 01/10/2022"
    }

    UpdateDummyData()
    {
        this.dummyData := "&language_id=1&timestamp=0&request_id=0&network_id=" . this.networkID . "&mobile_client_version=" . this.clientVersion
    }

    SetServer(serverAddress)
    {

    }

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall( callName, parameters ) 
    {
        response := ""
        URLtoCall := this.webRoot . "post.php?call=" . callName . parameters
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( "10000", "10000", "10000", "10000" )
        Try {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
                ; TODO: Add check for outdated Instance ID
                if(!(response.switch_play_server == ""))
                {
                    return this.ServerCall( callName, parameters ) 
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        return response
    }

    CallUserDetails() 
    {
        getUserParams := this.dummyData . "&include_free_play_objectives=true&instance_key=1&user_id=" . this.userID . "&hash=" . this.userHash
        userDetails := this.ServerCall( "getuserdetails", getUserParams )
        return userDetails
    }

    CallLoadAdventure( adventureToLoad ) 
    {
        patronTier := this.activePatronID ? 1 : 0
        advParams := this.dummyData . "&patron_tier=" . patronTier . "&user_id=" . this.userID . "&hash=" . this.userHash . "&instance_id=" . this.instanceID 
            . "&game_instance_id=" . this.activeModronID . "&adventure_id=" . adventureToLoad . "&patron_id=" . this.activePatronID
        return this.ServerCall( "setcurrentobjective", advParams )
    }

    ;calling this loses everything earned during the adventure, should only be used when stuck.
    CallEndAdventure() 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&game_instance_id=" this.activeModronID
        return this.ServerCall( "softreset", advParams )
    }

    ;sample: call=convertresetcurrency&language_id=1&user_id=___&hash=___&converted_currency_id=17&target_currency_id=1&timestamp=0&request_id=0&network_id=0&mobile_client_version=999&localization_aware=true&instance_id=___& 
    ; Valid Target Currencies: 1 (Torm), 3 (Kalemvor), 15 (Helm), 22 (Tiamat), 23 (Auril), 25 (Corellon)
    CallConverCurrency(toCurrency := 1, fromCurrency := 24) 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID
        extraParams := "&converted_currency_id=" . fromCurrency . "&target_currency_id=" . toCurrency
        return this.ServerCall( "convertresetcurrency", (advParams . extraParams))
    }

    CallBuyChests( chestID, chests )
    {
        if ( chests > 100 )
            chests := 100
        else if ( chests < 1 )
            return
        if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311 )
        {
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&chest_type_id=" chestID "&count=" chests
            return this.ServerCall( "buysoftcurrencychest", chestParams )
        }
        else
        {
            switch chestID
            {
                case 152:
                    itemID := 1
                    patronID := 1
                case 153:
                    itemID := 23
                    patronID := 2
                case 219:
                    itemID := 45
                    patronID := 3
                case 311:
                    itemID := 76
                    patronID := 4
                Default:
                    return ""
            }
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&patron_id=" patronID "&shop_item_id=" itemID
            return this.ServerCall( "purchasepatronshopitem", chestParams )
        }
    }

    CallOpenChests( chestID, chests )
    {
        if ( chests > 99 )
            chests := 99
        else if ( chests < 1 )
            return
        chestParams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.instanceID "&chest_type_id=" chestid "&game_instance_id=" this.activeModronID "&count=" chests
        return this.ServerCall( "opengenericchest", chestParams )
    }

    ;A method to check if the party is on the world map. Necessary state to use callLoadAdventure()
    IsOnWorldMap()
    {
        currentAdventure := 0
        userDetails := this.CallUserDetails()
        if ( !IsObject( userDetails ) )
            return "Failed to fetch or build user details."
        for k, v in userDetails.details.game_instances
        {
            if (v.game_instance_id == this.activeInstanceID) 
            {
                currentAdventure := v.current_adventure_id
            }
        }
        if ( currentAdventure == -1 )
            return 1
        else
            return 0
    }

    ParseChestResults( chestResults )
    {
        this.shinies := 0
        string := ""
        for k, v in chestResults.loot_details
        {
            if v.gilded
            {
                this.shinies += 1
                string .= "New shiny! Champ ID: " . v.hero_id . " (Slot " . v.slot_id . ")`n"
            }
        }
        return string
    }

    ServerCallSave( saveBody ) 
    {
        response := ""
        URLtoCall := this.webroot "post.php?call=saveuserdetails&"
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( "10000", "10000", "10000", "10000" )
        Try {
            WR.Open( "POST", URLtoCall, true )
            boundaryHeader = 
            (
                multipart/form-data; boundary="BestHTTP"
            )
            WR.SetRequestHeader( "Content-Type", boundaryHeader )
            WR.SetRequestHeader( "User-Agent", "BestHTTP" )
            ;WR.SetRequestHeader( "Accept-Encoding", "identity" )
            WR.Send(saveBody)
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
                ; TODO: Add check for outdated Instance ID
                if(!(response.switch_play_server == ""))
                {
                    return this.ServerCallSave( saveBody ) 
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        return response
    }

    #include  *i IC_ServerCalls_Class_Extra.ahk
}
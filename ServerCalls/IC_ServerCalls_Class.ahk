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

; json library must be included if this file is used outside of Script Hub
#include %A_LineFile%\..\..\SharedFunctions\json.ahk

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
    webRoot := "http://ps22.idlechampions.com/~idledragons/"
    timeoutVal := 60000
    playServerExcludes := "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16"

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
        return "v2.4.2, 2023-08-22"
    }

    UpdateDummyData()
    {
        this.dummyData := "&language_id=1&timestamp=0&request_id=0&network_id=" . this.networkID . "&mobile_client_version=" . this.clientVersion . "&offline_v2_build=1"
    }

    SetServer(serverAddress)
    {

    }

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall( callName, parameters, timeout := "", retryNum := 0) 
    {
        response := ""
        URLtoCall := this.webRoot . "post.php?call=" . callName . parameters
        timeout := timeout ? timeout : this.timeoutVal
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        ; https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        WR.SetTimeouts( 0, 45000, 30000, timeout )  
        ; WR.SetProxy( 2, "IP:PORT" )  Send web traffic through a proxy server. A local proxy may be helpful for debugging web calls.
        Try {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            ; dataLB := data . "`n"
            ; FileAppend, %dataLB%, % A_LineFile . "\..\ServerLog.txt"
            Try
            {
                response := JSON.parse(data)
                if(!(response.switch_play_server == ""))
                {
                    retryNum += 1
                    this.WebRoot := response.switch_play_server
                    if(retryNum <= 3) 
                        return this.ServerCall( callName, parameters, timeoutVal, retryNum )
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        ; catch except
        ; {
        ;     exceptMessage := except.Message
        ;     exceptMessage .= " Extra: " . except.Extra
        ;     FileAppend, %exceptMessage%, % A_LineFile . "\..\ErrorLog.txt"
        ; }
        return response
    }

    ; Pulls user details from the server and returns it in a json parsed object.
    CallUserDetails() 
    {
        getUserParams := this.dummyData . "&include_free_play_objectives=true&instance_key=1&user_id=" . this.userID . "&hash=" . this.userHash
        userDetails := this.ServerCall( "getuserdetails", getUserParams )
        return userDetails
    }

    ; Starts a new adventure and returns the response.
    CallLoadAdventure( adventureToLoad ) 
    {
        patronTier := this.activePatronID ? 1 : 0
        advParams := this.dummyData . "&patron_tier=" . patronTier . "&user_id=" . this.userID . "&hash=" . this.userHash . "&instance_id=" . this.instanceID 
            . "&game_instance_id=" . this.activeModronID . "&adventure_id=" . adventureToLoad . "&patron_id=" . this.activePatronID
        return this.ServerCall( "setcurrentobjective", advParams )
    }

    ; Calling this loses everything earned during the adventure, should only be used when stuck.
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

    ; Buys <chests> number of <chestID> chests. Automatically uses Patron purchase call for patron chests.
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

    ; Open <chests> number of <chestID> chest.
    CallOpenChests( chestID, chests )
    {
        if ( chests > 1000 )
            chests := 1000
        else if ( chests < 1 )
            return
        chestParams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.instanceID "&chest_type_id=" chestid "&game_instance_id=" this.activeModronID "&count=" chests
        return this.ServerCall( "opengenericchest", chestParams, 60000 )
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
    
    ; Special server call spcifically for use with saves. saveBody must be encoded before using this call.
    ServerCallSave( saveBody, retryNum := 0 ) 
    {
        response := ""
        URLtoCall := this.webroot . "post.php?call=saveuserdetails&"
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        ; https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        WR.SetTimeouts( "0", "15000", "7500", "30000" )
        ; WR.SetProxy( 2, "IP:PORT" )  Send web traffic through a proxy server. A local proxy may be helpful for debugging web calls.
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
                if(!(response.switch_play_server == ""))
                {
                    retryNum += 1
                    this.WebRoot := response.switch_play_server
                    if(retryNum <= 3) 
                        return this.ServerCallSave( saveBody, retryNum ) 
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        return response
    }

    ; Get the loadbalanced Play Server
    CallGetPlayServer() 
    {
        advParams := this.dummyData 
        return this.ServerCall( "getPlayServerForDefinitions", advParams )
    }

    ; Iterate the possible play servers 
    GetFastestPlayServer(numberOfTestsPerServer := 1)
    {
        oldTimeout := this.timeoutVal
        oldWebRoot := this.webRoot
        this.timeoutVal := 1000
        newWebRoot := ""
        highestPlayServerValue := 23
        fastestProcessingTime := 10000
        Loop, %highestPlayServerValue%
        {
            if A_Index in % this.playServerExcludes
                continue
            this.webRoot := "http://ps" . A_Index . ".idlechampions.com/~idledragons/"
            response := this.CallGetPlayServer()
            testCount := 1
            if (response != "" and response.processing_time != "")
            {
                avgProcessingTime := totalProcessingTime := response.processing_time
                loop, % (numberOfTestsPerServer - 1)
                {
                    response := this.CallGetPlayServer()
                    if (response != "" and response.processing_time != "")
                    {
                        totalProcessingTime += response.processing_time
                        ++testCount
                    }
                    avgProcessingTime := totalProcessingTime / testCount
                }
                OutputDebug, % "Average Processing Time for ps" . A_Index . " is: " . avgProcessingTime
                if (avgProcessingTime < fastestProcessingTime)
                {
                    fastestProcessingTime := avgProcessingTime
                    newWebRoot := this.webRoot
                }
            }
            else
                continue
        }
        this.webRoot := oldWebRoot
        this.timeoutVal := oldTimeout
        if (newWebRoot != "" AND fastestProcessingTime < 10000)
            return newWebRoot
        else
            return oldWebRoot
    }

    ; Updates the play server used for server calls. If doPerforamnceTest is true, will test all playservers to find the one that appears to be processing fastest.
    UpdatePlayServer(doPerformanceTest := False, doPerformanceTestOnFail := False, numberOfTestsPerServer := 1)
    {
        OutputDebug, % "Old web root is: " . this.webRoot
        if(doPerformanceTest)
        {
            this.webRoot := this.GetFastestPlayServer(numberOfTestsPerServer)
        }
        else
        {
            oldWebRoot := this.webRoot
            this.webRoot := "http://ps23.idlechampions.com/~idledragons/" ; assume ps23 will always be available (avoiding using master)
            response := this.CallGetPlayServer()
            if (response != "" AND response.play_server != "")
                this.webRoot := response.play_server
            else if (doPerformanceTestOnFail)
                this.webRoot := this.GetFastestPlayServer(numberOfTestsPerServer)
            else
                this.webRoot := oldWebRoot
        }
        OutputDebug, % "New web root is: " . this.webRoot
        response := this.CallGetPlayServer()
        suggestedServer := "unknown"
        if (response != "" AND response.play_server != "")
            suggestedServer := response.play_server
        OutputDebug, % "Server Suggested web root is: " . suggestedServer
    }
    #include *i %A_LineFile%\..\IC_ServerCalls_Class_Extra.ahk
}

class Byteglow_ServerCalls_Class
{
    webRoot := "https://ic.byteglow.com/api/"
    timeoutVal := 60000
    ServerCall( callName, parameters, timeout := "" ) 
    {

        response := ""
        URLtoCall := this.webRoot . callName . "?" . parameters
        timeout := timeout ? timeout : this.timeoutVal
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( 0, 45000, 30000, timeout )
        Try {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        catch exception {
			return exception
		}
        return response
    }

    ; https://ic.byteglow.com/api/briv-stacks?gild=2&enchant=60009&rarity=4&metalborn=1&target=2000
    ; https://ic.byteglow.com/api/briv-stacks?skips=11&metalborn=1&target=2000
    CallBrivStacks(gild, ilvls, rarity, isMetalborn, modronReset) 
    {
        params := "gild=" . gild . "&enchant=" . ilvls . "&rarity=" . rarity . "&metalborn=" . isMetalborn . "&target=" . modronReset
        return this.ServerCall( "briv-stacks", params)
    }    
}
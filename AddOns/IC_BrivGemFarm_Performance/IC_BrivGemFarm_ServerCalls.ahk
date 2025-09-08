#Requires AutoHotkey 1.1.33+ <1.2
#SingleInstance, Off
#NoTrayIcon
#Persistent
#NoEnv ; Avoids checking empty variables to see if they are environment variables.
ListLines Off

#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\ServerCalls\SH_ServerCalls_Includes.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SaveHelper_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk

global g_BrivServerCall := new IC_BrivGemFarm_ServerCalls_Class
global g_SaveHelper := new IC_SaveHelper_Class
global g_SeverSharedData

class IC_BrivGemFarm_ServerCalls_Class extends IC_ServerCalls_Class
{
    ServerSettings := ""
    FncsToCall := {}

    __New()
    {
        this.LoadSettings()
        this.LoadServerCallSettings()
        this.LoadUserSettings()
        
        ; ComObjCreate("Scriptlet.TypeLib").GUID
        if (this["GemFarmGUID"] != "")
            ObjRegisterActive(g_SeverSharedData, this["GemFarmGUID"])
    }

    LoadSettings(settingsLoc := "")
    {
        settingsLoc := settingsLoc ? settingsLoc : A_LineFile . "\..\..\..\ServerCalls\Settings.json"
        this.Settings := this.LoadObjectFromJSON( settingsLoc )
        if(IsObject(this.Settings))
            this.proxy := this.settings["ProxyServer"] . ":" . this.settings["ProxyPort"]
    }

    LoadServerCallSettings()
    {
        this.ServerSettings := this.LoadObjectFromJSON( A_LineFile . "\..\ServerCall_Settings.json" )
        ; test saved parameters on following line.
        ; this.ServerSettings["Calls"] := {"CallLoadAdventure" : [this.CurrentAdventure]}
        for k, v in this.ServerSettings
            if (k != "Calls")
                this[k] := v
    }

    LoadUserSettings()
    {
        this.UserSettings := this.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    }

    LaunchCalls()
    {
        if (A_Args[1] != "") ; Launch a single command from params
        {
            fnc := A_Args[1] 
            args := A_Args.Clone()
            args.RemoveAt(1)
            fnc := ObjBindMethod(this, fnc, args*)
            fnc.Call()
            return
        }
        for fnc, args in this.ServerSettings.Calls
            g_BrivServerCall.FncsToCall[fnc] := ObjBindMethod(this, fnc, args*)
        for name, fnc in this.FncsToCall
            fnc.Call()
    }

    ; ; Sends calls for buying or opening chests and tracks chest metrics.
    ; ; TODO: Modify for logging (to json or csv?)
    ; DoChests(numSilverChests, numGoldChests)
    ; {
    ;     serverRateBuy := 250
    ;     serverRateOpen := 1000
    ;     ; no chests to do - Replaces g_BrivUserSettings[ "DoChests" ] setting.
    ;     if !(g_BrivUserSettings[ "BuySilvers" ] OR g_BrivUserSettings[ "BuyGolds" ] OR g_BrivUserSettings[ "OpenSilvers" ] OR g_BrivUserSettings[ "OpenGolds" ])
    ;         return

    ;     StartTime := A_TickCount
    ;     g_SharedData.LoopString := "Stack Sleep: " . " Buying or Opening Chests"
    ;     loopString := ""
    ;     startingPurchasedSilverChests := g_SharedData.PurchasedSilverChests
    ;     startingPurchasedGoldChests := g_SharedData.PurchasedGoldChests
    ;     startingOpenedGoldChests := g_SharedData.OpenedGoldChests
    ;     startingOpenedSilverChests := g_SharedData.OpenedSilverChests
    ;     currentChestTallies := startingPurchasedSilverChests + startingPurchasedGoldChests + startingOpenedGoldChests + startingOpenedSilverChests
    ;     ElapsedTime := 0

    ;     doHybridStacking := ( g_BrivUserSettings[ "ForceOfflineGemThreshold" ] > 0 ) OR ( g_BrivUserSettings[ "ForceOfflineRunThreshold" ] > 1 )
    ;     while( ( g_BrivUserSettings[ "RestartStackTime" ] > ElapsedTime ) OR doHybridStacking)
    ;     {
    ;         g_SharedData.LoopString := "Stack Sleep: " . g_BrivUserSettings[ "RestartStackTime" ] - ElapsedTime . " " . loopString
    ;         effectiveStartTime := doHybridStacking ? A_TickCount + 30000 : StartTime ; 30000 is an arbitrary time that is long enough to do buy/open (100/99) of both gold and silver chests.

    ;         ;BUYCHESTS
    ;         gems := g_SF.TotalGems - g_BrivUserSettings[ "MinGemCount" ]
    ;         amount := Min(Floor(gems / 50), serverRateBuy )
    ;         if (g_BrivUserSettings[ "BuySilvers" ] AND amount > 0)
    ;             this.BuyChests( chestID := 1, effectiveStartTime, amount )
    ;         gems := g_SF.TotalGems - g_BrivUserSettings[ "MinGemCount" ] ; gems can change from previous buy, reset
    ;         amount := Min(Floor(gems / 500) , serverRateBuy )
    ;         if (g_BrivUserSettings[ "BuyGolds" ] AND amount > 0)
    ;             this.BuyChests( chestID := 2, effectiveStartTime, amount )
    ;         ; OPENCHESTS
    ;         amount := Min(g_SF.TotalSilverChests, serverRateOpen)
    ;         if (g_BrivUserSettings[ "OpenSilvers" ] AND amount > 0)
    ;             this.OpenChests( chestID := 1, effectiveStartTime, amount)
    ;         amount := Min(g_SF.TotalGoldChests, serverRateOpen)
    ;         if (g_BrivUserSettings[ "OpenGolds" ] AND amount > 0)
    ;             this.OpenChests( chestID := 2, effectiveStartTime, amount )

    ;         updatedTallies := g_SharedData.PurchasedSilverChests + g_SharedData.PurchasedGoldChests + g_SharedData.OpenedGoldChests + g_SharedData.OpenedSilverChests
    ;         currentLoopString := this.GetChestDifferenceString(startingPurchasedSilverChests, startingPurchasedGoldChests, startingOpenedGoldChests, startingOpenedSilverChests)
    ;         loopString := currentLoopString == "" ? loopString : currentLoopString

    ;         if (!g_BrivUserSettings[ "DoChestsContinuous" ] ) ; Do one time if not continuous
    ;             return loopString == "" ? "Chests ----" : loopString
    ;         if (updatedTallies == currentChestTallies) ; call failed, likely ran out of time. Don't want to call more if out of time.
    ;             return loopString == "" ? "Chests ----" : loopString
    ;         currentChestTallies := updatedTallies
    ;         ElapsedTime := A_TickCount - StartTime
    ;     }
    ;     return loopString
    ; }

    ; /*  BuyChests - A method to buy chests based on parameters passed.

    ;     Parameters:
    ;     chestID   - The ID of the chest to be bought. Default is 1 (silver).
    ;     startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
    ;         Used to estimate if there is enough time to perform those actions before attempting to do them.
    ;     numChests - expected number of chests to buy. Default is 100.
            
    ;     Return Values:
    ;     None

    ;     Side Effects:
    ;     On success, will update g_SharedData.PurchasedSilverChests and g_SharedData.PurchasedGoldChests.
    ;     On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    ; */
    ; BuyChests( chestID := 1, startTime := 0, numChests := 100)
    ; {
    ;     startTime := startTime ? startTime : A_TickCount
    ;     purchaseTime := 100 ; .1s
    ;     if (g_BrivUserSettings[ "RestartStackTime" ] > ( A_TickCount - startTime + purchaseTime))
    ;     {
    ;         if (numChests > 0)
    ;         {
    ;             response := g_BrivServerCall.CallBuyChests( chestID, numChests )
    ;             if (response.okay AND response.success)
    ;             {
    ;                 g_SharedData.PurchasedSilverChests += chestID == 1 ? numChests : 0
    ;                 g_SharedData.PurchasedGoldChests += chestID == 2 ? numChests : 0
    ;                 g_SF.TotalSilverChests := (chestID == 1) ? response.chest_count : g_SF.TotalSilverChests
    ;                 g_SF.TotalGoldChests := (chestID == 2) ? response.chest_count : g_SF.TotalGoldChests
    ;                 g_SF.TotalGems := response.currency_remaining
    ;             }
    ;         }
    ;     }
    ; }

    ; /*  OpenChests - A method to open chests based on parameters passed.

    ;     Parameters:
    ;     chestID   - The ID of the chest to be bought. Default is 1 (silver).
    ;     startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
    ;         Used to estimate if there is enough time to perform those actions before attempting to do them.
    ;     numChests - expected number of chests to open. Default is 100.


    ;     Return Values:
    ;     None

    ;     Side Effects:
    ;     On success, will update g_SharedData.OpenedSilverChests and g_SharedData.OpenedGoldChests.
    ;     On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    ; */
    ; OpenChests( chestID := 1, startTime := 0, numChests := 99 )
    ; {
    ;     timePerGold := 4.5
    ;     timePerSilver := .75
    ;     timePerChest := chestID == 1 ? timePerSilver : timePerGold
    ;     startTime := startTime ? startTime : A_TickCount
    ;     ; openChestTimeEst := 1000 ; chestID == 1 ? (numChests * 30.3) : numChests * 60.6 ; ~3s for silver, 6s for anything else
    ;     if (g_BrivUserSettings[ "RestartStackTime" ] - ( A_TickCount - startTime) < numChests * timePerChest)
    ;         numChests := Floor(( A_TickCount - startTime) / timePerChest)
    ;     if (numChests < 1)
    ;         return
    ;     chestResults := g_BrivServerCall.CallOpenChests( chestID, numChests )
    ;     if (!chestResults.success)
    ;         return
    ;     g_SharedData.OpenedSilverChests += (chestID == 1) ? numChests : 0
    ;     g_SharedData.OpenedGoldChests += (chestID == 2) ? numChests : 0
    ;     g_SF.TotalSilverChests := (chestID == 1) ? chestResults.chests_remaining : g_SF.TotalSilverChests
    ;     g_SF.TotalGoldChests := (chestID == 2) ? chestResults.chests_remaining : g_SF.TotalGoldChests
    ;     g_SharedData.ShinyCount += g_SF.ParseChestResults( chestResults )
    ; }

    ; forces an attempt for the server to remember stacks
    ; find and replace g_BrivServerCall.CallPreventStackFail with script run servercall.
    CallPreventStackFail(stacks)
    {
        response := ""
        g_SaveHelper.Init()
        stacks := g_SaveHelper.GetEstimatedStackValue(stacks)
        userData := g_SaveHelper.GetCompressedDataFromBrivStacks(stacks)
        checksum := g_SaveHelper.GetSaveCheckSumFromBrivStacks(stacks)
        save :=  g_SaveHelper.GetSave(userData, checksum, this.userID, this.userHash, this.networkID, this.clientVersion, this.instanceID)
        this.ServerCallSave(save)
    }

    ;Gets data from JSON file
    LoadObjectFromJSON( FileName )
    {
        FileRead, oData, %FileName%
        data := "" 
        try
        {
            data := JSON.parse( oData )
        }
        return data
    }

    ;Writes beautified json (object) to a file (FileName)
    WriteObjectToJSON( FileName, ByRef object )
    {
        objectJSON := JSON.stringify( object )
        if (!objectJSON)
            return
        objectJSON := JSON.Beautify( objectJSON )
        FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }
}

g_BrivServerCall.LaunchCalls()

; g_ServerSharedData.CallsAreComplete[GUID] := True
; ObjRegisterActive(g_SeverSharedData, "")
ExitApp
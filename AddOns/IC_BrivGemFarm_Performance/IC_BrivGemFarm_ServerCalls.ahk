#Requires AutoHotkey 1.1.33+ <1.2
#SingleInstance, Off
#NoTrayIcon
#Persistent
#NoEnv ; Avoids checking empty variables to see if they are environment variables.
ListLines Off


#include %A_LineFile%\..\..\IC_Core\IC_SharedData_Class.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SaveHelper_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\ServerCalls\SH_ServerCalls_Includes.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk

global g_BrivServerCall := new IC_BrivGemFarm_ServerCalls_Class
global g_SaveHelper := new IC_SaveHelper_Class

class IC_BrivGemFarm_ServerCalls_Class extends IC_ServerCalls_Class
{
    ServerSettings := ""
    FncsToCall := {}

    __New()
    {
        this.SharedData := new IC_SharedData_Class
        this.LoadSettings()
        this.LoadServerCallSettings()
        this.LoadUserSettings()
        this.LoadGemFarmGUID()
        ; ComObjCreate("Scriptlet.TypeLib").GUID
        if (this["GemFarmGUID"] != "")
            ObjRegisterActive(this.SharedData, this["GemFarmGUID"])
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

    LoadGemFarmGUID()
    {
        this.GemFarmGUID := this.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
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

    ; DoChestsSetup()
    ; {
    ;     g_SharedData.LoopString := "Stack Sleep: " . " Buying or Opening Chests"
    ;     loopString := ""
    ;     while ...
    ;         g_SharedData.LoopString := "Stack Sleep: " . this.UserSettings[ "RestartStackTime" ] - ElapsedTime . " " . loopString
    ; }

    ; ; Sends calls for buying or opening chests and tracks chest metrics.
    ; ; TODO: Modify for logging (to json or csv?)
    ; DoChests(numSilverChests, numGoldChests)
    ; {
    ;     serverRateBuy := 250
    ;     serverRateOpen := 1000
    ;     ; no chests to do - Replaces this.UserSettings[ "DoChests" ] setting.
    ;     if !(this.UserSettings[ "BuySilvers" ] OR this.UserSettings[ "BuyGolds" ] OR this.UserSettings[ "OpenSilvers" ] OR this.UserSettings[ "OpenGolds" ])
    ;         return

    ;     StartTime := A_TickCount
    ;     startingPurchasedSilverChests := g_SharedData.PurchasedSilverChests
    ;     startingPurchasedGoldChests := g_SharedData.PurchasedGoldChests
    ;     startingOpenedGoldChests := g_SharedData.OpenedGoldChests
    ;     startingOpenedSilverChests := g_SharedData.OpenedSilverChests
    ;     currentChestTallies := startingPurchasedSilverChests + startingPurchasedGoldChests + startingOpenedGoldChests + startingOpenedSilverChests
    ;     ElapsedTime := 0

    ;     doHybridStacking := ( this.UserSettings[ "ForceOfflineGemThreshold" ] > 0 ) OR ( this.UserSettings[ "ForceOfflineRunThreshold" ] > 1 )


    ;         effectiveStartTime := doHybridStacking ? A_TickCount + 30000 : StartTime ; 30000 is an arbitrary time that is long enough to do buy/open (100/99) of both gold and silver chests.

    ;         ;BUYCHESTS
    ;         gems := g_SF.TotalGems - this.UserSettings[ "MinGemCount" ]
    ;         amount := Min(Floor(gems / 50), serverRateBuy )
    ;         if (this.UserSettings[ "BuySilvers" ] AND amount > 0)
    ;             this.BuyChests( chestID := 1, effectiveStartTime, amount )
    ;         gems := g_SF.TotalGems - this.UserSettings[ "MinGemCount" ] ; gems can change from previous buy, reset
    ;         amount := Min(Floor(gems / 500) , serverRateBuy )
    ;         if (this.UserSettings[ "BuyGolds" ] AND amount > 0)
    ;             this.BuyChests( chestID := 2, effectiveStartTime, amount )
    ;         ; OPENCHESTS
    ;         amount := Min(g_SF.TotalSilverChests, serverRateOpen)
    ;         if (this.UserSettings[ "OpenSilvers" ] AND amount > 0)
    ;             this.OpenChests( chestID := 1, effectiveStartTime, amount)
    ;         amount := Min(g_SF.TotalGoldChests, serverRateOpen)
    ;         if (this.UserSettings[ "OpenGolds" ] AND amount > 0)
    ;             this.OpenChests( chestID := 2, effectiveStartTime, amount )

    ;         updatedTallies := g_SharedData.PurchasedSilverChests + g_SharedData.PurchasedGoldChests + g_SharedData.OpenedGoldChests + g_SharedData.OpenedSilverChests
    ;         currentLoopString := this.GetChestDifferenceString(startingPurchasedSilverChests, startingPurchasedGoldChests, startingOpenedGoldChests, startingOpenedSilverChests)
    ;         loopString := currentLoopString == "" ? loopString : currentLoopString

    ;         currentChestTallies := updatedTallies
    ;         ElapsedTime := A_TickCount - StartTime
    
    ;     this.WriteObjectToJSON( A_LineFile . "\..\LastCallResponse.json" )
    ;     return loopString
    ; }

    ; BuyChests( chestID := 1, startTime := 0, numChests := 100)
    ; {
    ;     startTime := startTime ? startTime : A_TickCount
    ;     purchaseTime := 100 ; .1s
    ;     if (this.UserSettings[ "RestartStackTime" ] > ( A_TickCount - startTime + purchaseTime))
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

    ; OpenChests( chestID := 1, startTime := 0, numChests := 99 )
    ; {
    ;     timePerGold := 4.5
    ;     timePerSilver := .75
    ;     timePerChest := chestID == 1 ? timePerSilver : timePerGold
    ;     startTime := startTime ? startTime : A_TickCount
    ;     ; openChestTimeEst := 1000 ; chestID == 1 ? (numChests * 30.3) : numChests * 60.6 ; ~3s for silver, 6s for anything else
    ;     if (this.UserSettings[ "RestartStackTime" ] - ( A_TickCount - startTime) < numChests * timePerChest)
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
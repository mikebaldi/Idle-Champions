#Requires AutoHotkey 1.1.33+ <1.2
#SingleInstance, Off
#NoTrayIcon
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

    ; Load global server call Settings into this class.
    LoadSettings(settingsLoc := "")
    {
        settingsLoc := settingsLoc ? settingsLoc : A_LineFile . "\..\..\..\ServerCalls\Settings.json"
        this.Settings := this.LoadObjectFromJSON( settingsLoc )
        if(IsObject(this.Settings))
            this.proxy := this.settings["ProxyServer"] . ":" . this.settings["ProxyPort"]
    }

    ; Load script defined server call Settings into this class.
    LoadServerCallSettings()
    {
        this.ServerSettings := this.LoadObjectFromJSON( A_LineFile . "\..\ServerCall_Settings.json" )
        ; test saved parameters on following line.
        ; this.ServerSettings["Calls"] := {"CallLoadAdventure" : [this.CurrentAdventure]}
        for k, v in this.ServerSettings
            if (k != "Calls")
                this[k] := v
    }

    ; Load gem farm settings into this class.
    LoadUserSettings()
    {
        this.UserSettings := this.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    }

    ; Load gem farm com object GUID into this class.
    LoadGemFarmGUID()
    {
        this.GemFarmGUID := this.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
    }

    ; Execute any function calls passed to this class via arguments or saved in script defined server call settings file.
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

    ; Sends calls for buying or opening chests and tracks chest metrics.
    ; TODO: Modify for logging (to json or csv?)
    DoChests(numSilverChests, numGoldChests, totalGems)
    {
        ; bad memory reads
        if (numSilverChests == "" OR numGoldChests == "") 
            return
        ; no chests to do - Replaces this.UserSettings[ "DoChests" ] setting.
        if !(this.UserSettings[ "OpenChests" ] OR this.UserSettings[ "BuyChests" ])
            return
        ; no chests to do (not buying, nothing available to open)
        if (!this.UserSettings[ "BuyChests" ] AND (numSilverChests <= this.UserSettings["MinSilverChestCount"] AND numGoldChests <= this.UserSettings["MinGoldChestCount"]))
            return
        ; no chests to do (not opening and not enough gems to buy)
        if (!this.UserSettings[ "OpenChests" ] AND (totalGems -  g_BrivUserSettings[ "MinGemCount" ] < 50))
            return

        hybridStackTimeout := Min(this.UserSettings[ "ForceOfflineRunThreshold" ] * 15000, 300000)  ; 5 minute timeout (20 hybrid runs), or 15s per run if < 20

        StartTime := A_TickCount
        ElapsedTime := 0
        doHybridStacking := ( this.UserSettings[ "ForceOfflineGemThreshold" ] > 0 ) OR ( this.UserSettings[ "ForceOfflineRunThreshold" ] > 1 )

        if (doHybridStacking) ; buy/open at until user's min chests + serverRate >= chests left
        {
            ; < runTime * hybridCount (don't want to be double running purchase scripts) ; alternatively shared com flag?
            while(ElapsedTime < hybridStackTimeout)
            {
                ElapsedTime := A_TickCount - StartTime
                if !(this.DoChestsAndContinue(numSilverChests, numGoldChests, totalGems)) ; Until Error or no chests opened/closed.
                    break
            }
        }
        else
            this.DoChestsAndContinue(numSilverChests, numGoldChests, totalGems)     
               
        return loopString
    }

    ; Tests for if chests should be bought or opened before doing so.
    DoChestsAndContinue(numSilverChests, numGoldChests, totalGems)
    {
        ; not in defs, needs to be tested to know if the max has changed
        ; maxes accurate as of 9/9/2025
        serverRateBuy := 250
        serverRateOpen := 1000
        goldChestCost := 500
        silverChestCost := 50

        response := ""
        gems := totalGems - this.UserSettings[ "MinGemCount" ] ; gems left to buy with
        gemsSilver := gems * this.UserSettings[ "BuySilverChestRatio" ] ; portion to silver
        gemsGold := gems * this.UserSettings[ "BuyGoldChestRatio" ] ; portion to gold

        ; BUYCHESTS -  wait until can do a max server call of golds or max server call of silvers - then do both - if WaitToBuyChests set
        isMaxReady := ((Floor(gemsSilver / silverChestCost) > serverRateBuy OR Floor(gemsGold / goldChestCost) > serverRateBuy))
        if ((this.UserSettings[ "WaitToBuyChests" ] AND isMaxReady) OR !this.UserSettings[ "WaitToBuyChests" ])
        {
            
            amount := Floor(gemsSilver / silverChestCost)
            response .= this.BuyChests( chestID := 1, amount )
            amount := Floor(gemsGold / goldChestCost) 
            response .= this.BuyChests( chestID := 2, amount )
        }

        ; OPENCHESTS - only open if can do a maxed call if WaitToBuyChests set
        amount := Min(numSilverChests - this.UserSettings[ "MinSilverChestCount" ], serverRateOpen)
        if (this.UserSettings[ "OpenChests" ] AND (amount >= serverRateOpen OR !this.UserSettings[ "WaitToBuyChests" ]))
            response .= this.OpenChests( chestID := 1, amount )
        amount := Min(numGoldChests - this.UserSettings[ "MinGoldChestCount" ], serverRateOpen)
        if (this.UserSettings[ "OpenChests" ] AND (amount >= serverRateOpen OR !this.UserSettings[ "WaitToBuyChests" ]))
            response .= this.OpenChests( chestID := 2, amount )

        if (response / 1 > 0) ; AHK trickery to check if only numeric values were returned (all 1s) vs text/0 (incorrect if test for e.g. 1."".1.1)
            this.WriteObjectToJSON( A_LineFile . "\..\LastBadChestCallResponse.json" )
        else if (response != "") ; "" would also be a failure
            return doContinue := True
        return doContinue := False
    }

    /*  BuyChests - A method to buy chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. (1 is silver, 2 is gold, etc).
        numChests - expected number of chests to buy.
            
        Return Values:
        Failed server response string or 1 if successful.

        Side Effects:
        On success, will update SharedData.PurchasedSilverChests and SharedData.PurchasedGoldChests.
    */
    BuyChests( chestID := "", numChests := "")
    {
        if (numChests <= 0 or chestID <= 0)
            return
        response := g_BrivServerCall.CallBuyChests( chestID, numChests )
        if !(response.okay AND response.success)
            return response
        ; g_SF.TotalSilverChests := (chestID == 1) ? response.chest_count : g_SF.TotalSilverChests
        this.SharedData.PurchasedSilverChests += chestID == 1 ? numChests : 0
        this.SharedData.PurchasedGoldChests += chestID == 2 ? numChests : 0
        this.CurrencyRemaining := response.currency_remaining
        return okToContinue := 1
    }

    /*  OpenChests - A method to open chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. (1 is silver, 2 is gold, etc).
        numChests - expected number of chests to open. 

        Return Values:
        Failed server response string or 1 if successful.

        Side Effects:
        On success, will update SharedData.OpenedSilverChests and SharedData.OpenedGoldChests and SharedData.ShinyCount.
    */
    OpenChests( chestID := "", numChests := "" )
    {
        if (numChests <= 0 or chestID <= 0)
            return
        chestResults := g_BrivServerCall.CallOpenChests( chestID, numChests )
        if (!chestResults.success)
            return chestResults
        this.SharedData.OpenedSilverChests += (chestID == 1) ? numChests : 0
        this.SharedData.OpenedGoldChests += (chestID == 2) ? numChests : 0
        this.SharedData.ShinyCount += g_SF.ParseChestResults( chestResults )
        return okToContinue := 1
    }

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

g_BrivServerCall.SharedData.ServerCallsAreComplete := False
g_BrivServerCall.LaunchCalls()
g_BrivServerCall.SharedData.ServerCallsAreComplete := True
ExitApp
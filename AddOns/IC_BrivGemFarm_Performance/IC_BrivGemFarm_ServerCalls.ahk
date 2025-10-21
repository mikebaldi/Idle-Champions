#Requires AutoHotkey 1.1.37+ <1.2
#SingleInstance, Off
#NoTrayIcon
#NoEnv ; Avoids checking empty variables to see if they are environment variables.
ListLines Off

#include %A_LineFile%\..\..\IC_Core\IC_SharedData_Class.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SaveHelper_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
#include %A_LineFile%\..\..\..\ServerCalls\SH_ServerCalls_Includes.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_Coms.ahk

global g_BrivServerCall := new IC_BrivGemFarm_ServerCalls_Class
global g_SaveHelper := new IC_SaveHelper_Class

class IC_BrivGemFarm_ServerCalls_Class extends IC_ServerCalls_Class
{
    ServerSettings := ""
    FncsToCall := {}
    ServerRateBuy := 250
    ServerRateOpen := 1000
    GoldChestCost := 500
    SilverChestCost := 50
    GemFarmGUID := ""
    SHGUID := ""
    OverridesFile := A_LineFile . "\..\ServerCallLocationOverride_Settings.json"

    __New()
    {
        this.SharedData := new IC_SharedData_Class
        this.LoadSettings()
        this.LoadServerCallSettings()
        this.LoadUserSettings()
        this.LoadGemFarmConnection()
    }

    ; Load global server call Settings into this class.
    LoadSettings(settingsLoc := "")
    {
        settingsLoc := settingsLoc ? settingsLoc : A_LineFile . "\..\..\..\ServerCalls\Settings.json" ; main hub server settings.
        this.Settings := this.LoadObjectFromJSON( settingsLoc )
        if(IsObject(this.Settings))
            this.proxy := this.settings["ProxyServer"] . ":" . this.settings["ProxyPort"]
    }

    ; Load script defined server call Settings into this class.
    LoadServerCallSettings()
    {
        if(FileExist(this.OverridesFile))
            this.SettingsFileLocation := (this.LoadObjectFromJSON(this.OverridesFile)).loc
        else
            this.SettingsFileLocation := A_LineFile . "\..\ServerCall_Settings.json"             
        this.ServerSettings := this.LoadObjectFromJSON(this.SettingsFileLocation)
        ; test saved parameters on following line.
        ; this.ServerSettings["Calls"] := {"DoChests" : [999999,999999,999999999]}
        for k, v in this.ServerSettings
            if (k != "Calls")
                this[k] := v
    }

    ; Load gem farm settings into this class.
    LoadUserSettings()
    {
        this.UserSettings := this.LoadObjectFromJSON( A_LineFile . "\..\BrivGemFarmSettings.json" )
    }

    SaveServerSettings()
    {
        this.WriteObjectToJSON( this.SettingsFileLocation, this.ServerSettings )
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
        size := this.ServerSettings.Calls.Length()
        if(size <= 50) ; Small Sanity check - hard limit of 50 calls. Don't do calls if greater than this many. Just delete them and start over.
        {
            loop, %size%
                for fnc, args in this.ServerSettings["Calls"][A_Index]
                    this.FncsToCall.Push(ObjBindMethod(this, fnc, args*))
            for name, fnc in this.FncsToCall
                fnc.Call()
        }
        this.ServerSettings.Delete("Calls") ; clear calls
        this.SaveServerSettings()
        this.RemoveOverrides()
    }

    ; Load gem farm com object GUID into this class.
    LoadGemFarmConnection()
    {
        this.GemFarmGUID := this.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_BrivGemFarm.json")
        if (this.GemFarmGUID != "")
        {
            try
            {
                this.SharedData := ComObjActive(this.GemFarmGUID)
            }
        }
    }

    RemoveOverrides()
    {
        filename := this.OverridesFile
        if(FileExist(filename))
            FileDelete, %filename%
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
        if (!this.UserSettings[ "OpenChests" ] AND (totalGems -  this.UserSettings[ "MinGemCount" ] < 50))
            return
        this.DoChestsAndContinue(numSilverChests, numGoldChests, totalGems)     
    }

    ; Tests for if chests should be bought or opened before doing so.
    DoChestsAndContinue(numSilverChests, numGoldChests, totalGems)
    {
        ; not in defs, needs to be tested to know if the max has changed
        ; maxes accurate as of 9/9/2025
        serverRateBuy := this.ServerRateBuy
        serverRateOpen := this.ServerRateOpen
        goldChestCost := this.GoldChestCost
        silverChestCost := this.SilverChestCost

        responses := {}
        doContinue :=   True
        gems := totalGems - this.UserSettings[ "MinGemCount" ] ; gems left to buy with
        gemsSilver := silverChestCost * this.UserSettings[ "BuySilverChestRatio" ] * serverRateBuy ; portion to silver
        gemsGold := goldChestCost * this.UserSettings[ "BuyGoldChestRatio" ] * serverRateBuy ; portion to gold

        ; BUYCHESTS -  wait until can do a max server call of golds or max server call of silvers - then do both - if WaitToBuyChests set
        isMaxReady := gems >= gemsSilver + gemsGold ; ((Floor(gemsSilver / silverChestCost) >= serverRateBuy OR Floor(gemsGold / goldChestCost) >= serverRateBuy))
        if (this.UserSettings[ "BuyChests" ] AND ((this.UserSettings[ "WaitToBuyChests" ] AND isMaxReady) OR !this.UserSettings[ "WaitToBuyChests" ]))
        {
            amount := Floor(gemsSilver / silverChestCost)
            responses.Push(this.BuyChests( chestID := 1, amount ))
            amount := Floor(gemsGold / goldChestCost) 
            responses.Push(this.BuyChests( chestID := 2, amount ))
        }
        ; OPENCHESTS - only open if can do a maxed call if WaitToBuyChests set
        amount := Min(numSilverChests - this.UserSettings[ "MinSilverChestCount" ], serverRateOpen)
        if (this.UserSettings[ "OpenChests" ] AND (amount >= serverRateOpen OR !this.UserSettings[ "WaitToBuyChests" ]))
            responses.Push(this.OpenChests( chestID := 1, amount ))
        amount := Min(numGoldChests - this.UserSettings[ "MinGoldChestCount" ], serverRateOpen)
        if (this.UserSettings[ "OpenChests" ] AND (amount >= serverRateOpen OR !this.UserSettings[ "WaitToBuyChests" ]))
            responses.Push(this.OpenChests( chestID := 2, amount ))

        responseCount := responses.Count()
        if(responseCount) <= 0
            return doContinue := False
        lastErrResponse := ""
        loop %responseCount%
        {
            if (responses[A_Index] == 0)
            {
                doContinue := False
                lastErrResponse := "Invalid chestID or chest count."
                continue
            }
            if (responses[A_Index] != 1)
            {
                lastErrResponse := responses[A_Index]
                doContinue := False
            }
        }
        if (!doContinue)
            this.WriteObjectToJSON( A_LineFile . "\..\CurrentLastBadChestCallResponse.json", lastErrResponse )
        return doContinue
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
        gemsSpent := 0
        if (numChests <= 0 or chestID <= 0)
            return 0
        if (numChests > this.ServerRateBuy)
            numChests := this.ServerRateBuy
        response := g_BrivServerCall.CallBuyChests( chestID, numChests )
        if !(response.okay AND response.success)
            return response
        if(response.currency_remaining != "")
        {
            gemsSpent += (chestID == 1) ? numchests * 50 : 0 ; Purchased silver chests
            gemsSpent += (chestID == 2) ? numchests * 500 : 0 ; Purchased gold chests
        }
        try
        {
            this.SharedData.GemsSpent += gemsSpent
            this.SharedData.PurchasedSilverChests += chestID == 1 ? numChests : 0
            this.SharedData.PurchasedGoldChests += chestID == 2 ? numChests : 0
        }
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
            return 0
        if (numChests > this.ServerRateOpen)
            numChests := this.ServerRateOpen
        chestResults := g_BrivServerCall.CallOpenChests( chestID, numChests )
        if (!chestResults.success)
            return chestResults
        try
        {
            this.SharedData.OpenedSilverChests += (chestID == 1) ? numChests : 0
            this.SharedData.OpenedGoldChests += (chestID == 2) ? numChests : 0
            this.SharedData.ShinyCount += g_SF.ParseChestResults( chestResults )
        }
        if (chestResults.chests_remaining < numChests)
            return "Not enough chests remaining to continue opening."
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
        save :=  g_SaveHelper.GetSave(userData, checksum, this.ServerSettings.UserID, this.ServerSettings.UserHash, this.ServerSettings.networkID, this.ServerSettings.clientVersion, this.ServerSettings.InstanceID)
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
        if(FileExist(FileName))
            FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }
}

#include %A_LineFile%\..\IC_BrivGemFarm_Extra_ServerCall_Mods.ahk

g_BrivServerCall.LaunchCalls()
ExitApp
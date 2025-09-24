

    ;=========================================================
    ;DEPRECATED - Chests are now done through ServerCalls.ahk
    ;=========================================================

    /*  BuyChests - A method to buy chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. Default is 1 (silver).
        startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
            Used to estimate if there is enough time to perform those actions before attempting to do them.
        numChests - expected number of chests to buy. Default is 100.
            
        Return Values:
        None

        Side Effects:
        On success, will update g_SharedData.PurchasedSilverChests and g_SharedData.PurchasedGoldChests.
        On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    */
    ; DEPRECATED - user server call script
    BuyChests( chestID := 1, startTime := 0, numChests := 100)
    {
        startTime := startTime ? startTime : A_TickCount
        purchaseTime := 100 ; .1s
        if (g_BrivUserSettings[ "RestartStackTime" ] > ( A_TickCount - startTime + purchaseTime))
        {
            if (numChests > 0)
            {
                response := g_ServerCall.CallBuyChests( chestID, numChests )
                if (response.okay AND response.success)
                {
                    g_SharedData.PurchasedSilverChests += chestID == 1 ? numChests : 0
                    g_SharedData.PurchasedGoldChests += chestID == 2 ? numChests : 0
                    g_SF.TotalSilverChests := (chestID == 1) ? response.chest_count : g_SF.TotalSilverChests
                    g_SF.TotalGoldChests := (chestID == 2) ? response.chest_count : g_SF.TotalGoldChests
                    g_SF.TotalGems := response.currency_remaining
                }
            }
        }
    }

    /*  OpenChests - A method to open chests based on parameters passed.

        Parameters:
        chestID   - The ID of the chest to be bought. Default is 1 (silver).
        startTime - The number of milliseconds that have elapsed since the system was started, up to 49.7 days.
            Used to estimate if there is enough time to perform those actions before attempting to do them.
        numChests - expected number of chests to open. Default is 100.


        Return Values:
        None

        Side Effects:
        On success, will update g_SharedData.OpenedSilverChests and g_SharedData.OpenedGoldChests.
        On success, will update g_SF.TotalSilverChests, g_SF.TotalGoldChests, g_SF.TotalGems
    */
    ; DEPRECATED - user servercall script
    OpenChests( chestID := 1, startTime := 0, numChests := 99 )
    {
        timePerGold := 4.5
        timePerSilver := .75
        timePerChest := chestID == 1 ? timePerSilver : timePerGold
        startTime := startTime ? startTime : A_TickCount
        ; openChestTimeEst := 1000 ; chestID == 1 ? (numChests * 30.3) : numChests * 60.6 ; ~3s for silver, 6s for anything else
        if (g_BrivUserSettings[ "RestartStackTime" ] - ( A_TickCount - startTime) < numChests * timePerChest)
            numChests := Floor(( A_TickCount - startTime) / timePerChest)
        if (numChests < 1)
            return
        chestResults := g_ServerCall.CallOpenChests( chestID, numChests )
        if (!chestResults.success)
            return
        g_SharedData.OpenedSilverChests += (chestID == 1) ? numChests : 0
        g_SharedData.OpenedGoldChests += (chestID == 2) ? numChests : 0
        g_SF.TotalSilverChests := (chestID == 1) ? chestResults.chests_remaining : g_SF.TotalSilverChests
        g_SF.TotalGoldChests := (chestID == 2) ? chestResults.chests_remaining : g_SF.TotalGoldChests
        g_SharedData.ShinyCount += g_SF.ParseChestResults( chestResults )
    }
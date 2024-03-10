GUIFunctions.AddTab("Chests")

Gui, ICScriptHub:Tab, Chests
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x15 y+15 w350, % "Note: Game needs to be open to load user data to refresh chest list."
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "Warning: Only open chests while game is closed."
Gui, ICScriptHub:Add, GroupBox, x15 y+15 w425 h150 vGroupBoxChestPurchase, Buy Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 hwndChestPurchaserChestPurchaseComboBoxID vChestPurchaserChestPurchaseComboBox gChestPurchaserChestPurchaseCB
Gui, ICScriptHub:Add, Picture, x+35 h18 w18 vButtonRefreshChestPurchaser, %g_ReloadButton%
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x30 y+15 w75 vChestPurchaserPurchaseCount, % "99"
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserBuyChests, Buy

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestPurchase
xyValY += 150
Gui, ICScriptHub:Add, GroupBox, x15 y%xyValY% w425 h150 vGroupBoxChestOpen, Open Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 hwndChestPurchaserChestOpenComboBoxID vChestPurchaserChestOpenComboBox gChestPurchaserChestOpenCB
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, y+15 w75 vChestPurchaserChestOpenCount, % "99"
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserOpenChests, Open

buyChestsFunc := Func("IC_ChestPurchaser_Component.BuyChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserBuyChests, % buyChestsFunc
openChestsFunc := Func("IC_ChestPurchaser_Component.OpenChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserOpenChests, % openChestsFunc
chestPurchaserReadChests := Func("IC_ChestPurchaser_Component.Refresh")
GuiControl, ICScriptHub: +g, ButtonRefreshChestPurchaser, % chestPurchaserReadChests

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestOpen
xyValY +=155
Gui, ICScriptHub:Add, Text, x15 y%xyValY% w350 vChestPurchaserCurrentChestCount, % "---"

; g_SF.Memory.InitializeChestsIndices()
; IC_ChestPurchaser_Component.ReadChests()
IC_ChestPurchaser_Component.RefreshUserData()
IC_ChestPurchaser_Component.LoadDefs()
IC_ChestPurchaser_Component.ReadChests()
IC_ChestPurchaser_Component.AddToolTips()

; Same list is used for both open/buy (Even though not all chests are available for purchase.)
ControlGet, g_ChestPurchaserMasterListOpen, List, , , ahk_id %ChestPurchaserChestOpenComboBoxID%
g_ChestPurchaserMasterListOpen := "|" . StrReplace(g_ChestPurchaserMasterListOpen, "`n" , "|") 
ControlGet, g_ChestPurchaserMasterListBuy, List, , , ahk_id %ChestPurchaserChestPurchaseComboBoxID%
g_ChestPurchaserMasterListBuy := "|" . StrReplace(g_ChestPurchaserMasterListBuy, "`n" , "|") 
g_KeyInputTimer := 0
g_KeyInputTimerDelay := 600 ; milliseconds

ChestPurchaserChestPurchaseCB(controlID, mode, key)
{
    global IC_ChestPurchaser_Component
    global g_KeyInputTimerDelay
    global g_KeyInputTimer
    global g_ChestPurchaserMasterListBuy
    g_KeyInputTimer := A_TickCount
    fncToCallOnTimer :=  ObjBindMethod(GUIFunctions, "FilterList", controlID, g_ChestPurchaserMasterListBuy)
    timer := Abs(g_KeyInputTimerDelay) * -1 ; negative time means one time use timer
    SetTimer, %fncToCallOnTimer%, %timer%
}

ChestPurchaserChestOpenCB(controlID, mode, key)
{
    global IC_ChestPurchaser_Component
    global g_KeyInputTimerDelay
    global g_KeyInputTimer
    global g_ChestPurchaserMasterListOpen
    g_KeyInputTimer := A_TickCount
    fncToCallOnTimer :=  ObjBindMethod(GUIFunctions, "FilterList", controlID, g_ChestPurchaserMasterListOpen)
    timer := Abs(g_KeyInputTimerDelay) * -1
    SetTimer, %fncToCallOnTimer%, %timer%
}

class IC_ChestPurchaser_Component
{   

    static chestDefs := [{"id":1,"name":"Silver Chest","name_plural":"Press refresh button to update list", "details":{"cost":"1"}}]

    LoadDefs()
    {
        chestDefs := g_SF.LoadObjectFromJSON( A_LineFile . "\..\CurrentChestDefs.json" )
        if (chestDefs[1].id == 1)
            IC_ChestPurchaser_Component.chestDefs := chestDefs
        else
            OutputDebug, % "Failed to load chests from file, please update chest list"
    }

    Refresh()
    {
        IC_ChestPurchaser_Component.RefreshUserData()
        IC_ChestPurchaser_Component.UpdateDefs()
        IC_ChestPurchaser_Component.ReadChests()
    }

    RefreshUserData()
    {
        if(WinExist("ahk_exe " . g_userSettings[ "ExeName"])) ; only update server when the game is open
        {
            g_SF.Memory.OpenProcessReader()
            g_SF.ResetServerCall()
        }
    }

    UpdateDefs()
    {
        if(WinExist("ahk_exe " . g_userSettings[ "ExeName"])) ; only update server when the game is open
        {
            g_SF.Memory.OpenProcessReader()
            g_SF.ResetServerCall()
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Retrieving chest definitions..."
        chestDefs := (g_ServerCall.ServerCall("getDefinitions", "&mobile_client_version=1234&filter=chest_type_defines")).chest_type_defines
        ; confirm valid defs
        if(chestDefs[1].id == 1 AND chestDefs[1].name == "Silver Chest")
        {
            IC_ChestPurchaser_Component.chestDefs := chestDefs
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Saving chest definitions..."
            IC_SharedFunctions_Class.WriteObjectToJSON( A_LineFile . "\..\CurrentChestDefs.json" , chestDefs )
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Done!"
            return 0
        }
        return "-- Error Reading Chests --"
    }

    GetChestIDBySlot(chestIndex)
    {
        return IC_ChestPurchaser_Component.chestDefs[chestIndex].id
    }

    GetChestNameBySlot(chestIndex)
    {
        return IC_ChestPurchaser_Component.chestDefs[chestIndex].name_plural
    }

    IsChestPurchaseableBySlot(chestIndex)
    {
        return IC_ChestPurchaser_Component.chestDefs[chestIndex].details.cost != ""
    }

    IsChestReleasedBySlot(chestIndex)
    {
        return IC_ChestPurchaser_Component.chestDefs[chestIndex].graphic_id != "0"
    }

    GetChestCostTypeV2ByID(chestID)
    {
        size := IC_ChestPurchaser_Component.chestDefs.Length()
        loop, %size%
        {
            if (IC_ChestPurchaser_Component.GetChestIDBySlot(A_Index) == chestID)
            {
                if (IC_ChestPurchaser_Component.chestDefs[A_Index].details.cost == "")
                    return ""
                else if (IC_ChestPurchaser_Component.chestDefs[A_Index].details.cost.event_v2_id != "")
                    return "eventV2"
                else if (IC_ChestPurchaser_Component.chestDefs[A_Index].details.cost.patron_id != "")
                    return "patron " . IC_ChestPurchaser_Component.chestDefs[A_Index].details.cost.patron_id
                else if (IC_ChestPurchaser_Component.chestDefs[A_Index].details.cost.soft_currency != "")
                    return "gem"
            }
        }
        return ""
    }

    ReadChests()
    {
        size := IC_ChestPurchaser_Component.chestDefs.Length()
        comboBoxOptionsBuy := comboBoxOptions := "|"
        loop, %size%
        {
            chestID := IC_ChestPurchaser_Component.GetChestIDBySlot(A_Index)
            chestName := IC_ChestPurchaser_Component.GetChestNameBySlot(A_Index)
            if(IC_ChestPurchaser_Component.IsChestReleasedBySlot(A_Index))
            {
                comboBoxOptions .= chestID . " " . chestName . "|"
                if (IC_ChestPurchaser_Component.IsChestPurchaseableBySlot(A_Index))
                    comboBoxOptionsBuy .= chestID . " " . chestName . "|"
            }
        }
        GuiControl,ICScriptHub:, ChestPurchaserChestOpenComboBox, %comboBoxOptions%
        GuiControl,ICScriptHub:, ChestPurchaserChestPurchaseComboBox, %comboBoxOptionsBuy%
    }

    ; ReadChests()
    ; {
    ;     if(!WinExist("ahk_exe " . g_userSettings[ "ExeName"])) ; only update when the game is open
    ;         return
    ;     g_SF.Memory.OpenProcessReader()
    ;     g_SF.ResetServerCall()
    ;     size := g_SF.Memory.ReadChestDefinesSize()
    ;     comboBoxOptions := "|"
    ;     if(!size OR size > 3000 OR size < 0)
    ;     {
    ;         comboBoxOptions .= "-- Error Reading Chests --"
    ;         GuiControl,ICScriptHub:, ChestPurchaserChestOpenComboBox, %comboBoxOptions%
    ;         GuiControl,ICScriptHub:, ChestPurchaserChestPurchaseComboBox, %comboBoxOptions%
    ;         return
    ;     }
    ;     loop, %size%
    ;     {
    ;         chestID := g_SF.Memory.GetChestIDBySlot(A_Index)
    ;         chestName := g_SF.Memory.GetChestNameBySlot(A_Index)
    ;         comboBoxOptions .= chestID . " " . chestName . "|"
    ;         this.comboBoxOptions := comboBoxOptions.Clone()
    ;     }
    ;     GuiControl,ICScriptHub:, ChestPurchaserChestOpenComboBox, %comboBoxOptions%
    ;     GuiControl,ICScriptHub:, ChestPurchaserChestPurchaseComboBox, %comboBoxOptions%
    ; }

    BuyChests()
    {
        global g_ServerCall
        global ChestPurchaserPurchaseCount
        global ChestPurchaserCurrentChestCount
        global ChestPurchaserChestPurchaseComboBox
        Gui,ICScriptHub:Submit, NoHide
        IC_ChestPurchaser_Component.RefreshUserData()
        if(g_ServerCall == "")
        {
            MsgBox % "No user data available. Open the game and refresh chest list before continuing."
            return
        }
        splitArray := StrSplit(ChestPurchaserChestPurchaseComboBox, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Buying " . ChestPurchaserPurchaseCount . " of " . chestName . " (ID: " . chestID . ")"
        buyCount := ChestPurchaserPurchaseCount
        while(buyCount > 0)
        {
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Buying " buyCount " chests..."
            if ( IC_ChestPurchaser_Component.GetChestCostTypeV2ByID(chestID) == "eventV2")
                response := g_ServerCall.CallBuyChests( chestID, buyCount, "eventV2" )
            else
                response := g_ServerCall.CallBuyChests( chestID, buyCount )
            if(!IsObject(response))
            {
                MsgBox % "Error purchasing chest or parsing response."
                return
            }
            if (!response.okay)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311 )
                buyCount -= 250
            else
                buyCount -= 1
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Done buying!"
        MsgBox % "Done"
    }

    OpenChests()
    {
        global g_ServerCall
        global ChestPurchaserChestOpenCount
        global ChestPurchaserCurrentChestCount
        global ChestPurchaserChestOpenComboBox
        Gui,ICScriptHub:Submit, NoHide
        IC_ChestPurchaser_Component.RefreshUserData()
        if(g_ServerCall == "")
        {
            MsgBox % "No user data available. Open the game and refresh chest list before continuing."
            return
        }
        splitArray := StrSplit(ChestPurchaserChestOpenComboBox, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Opening " . ChestPurchaserChestOpenCount . " of " . chestName . " (ID: " . chestID . ") Make sure the game is closed before continuing."
        openCount := ChestPurchaserChestOpenCount
        shinyCount := 0
        while(openCount > 0)
        {
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Opening " openCount " chests..."
            response := g_ServerCall.CallOpenChests( chestID, openCount )
            if(!IsObject(response))
            {
                MsgBox % "Error opening chest(s) or parsing response."
                return
            }
            if (!response.success)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            shinyCount += g_SF.ParseChestResults(response)
            openCount -= 1000
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Done opening!"
        shinyString := "No shiny gear found."
        if(shinyCount > 0)
        {
            shinyString := "Shinies found: " . shinyCount . "`n"
            shinyString .= IC_ChestPurchaser_Component.GetShinyCountString()
        }
        MsgBox % "Done`n" . shinyString
    }

    ; Returns a string listing shinies found by champion.
    GetShinyCountString()
    {
        shnieisByChampString := ""
        shiniesByChamp := g_SharedData.ShiniesByChamp
        for champID, slots in shiniesByChamp
        {
            champName := g_SF.Memory.ReadChampNameByID(champID)
            champName := champName ? champName : champID
            shnieisByChampString .= champName . ": Slots ["
            for k,v in slots
            {
                shnieisByChampString .= k . ","
            }
            if(slots != "")
            {
                shnieisByChampString := SubStr(shnieisByChampString,1,StrLen(shnieisByChampString)-1)
            }                
            shnieisByChampString .= "]`n"
        }
        shnieisByChampString := SubStr(shnieisByChampString, 1, StrLen(shnieisByChampString)-1)
        return shnieisByChampString
    }

    AddToolTips()
    {
        GUIFunctions.AddToolTip( "ButtonRefreshChestPurchaser", "Refresh")
    }  
}
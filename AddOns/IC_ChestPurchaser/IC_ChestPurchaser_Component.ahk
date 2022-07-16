GUIFunctions.AddTab("Chests")

Gui, ICScriptHub:Tab, Chests
Gui, ICScriptHub:Add, Text, x15 y+15 w350, % "Note: Game needs to be open to read chests into lists."
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "Only buy or open chests while game is closed. (Yes, this is a hassle.)"
Gui, ICScriptHub:Add, GroupBox, x15 y+15 w425 h150 vGroupBoxChestPurchaseID, Buy Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 vChestPurchaseComboBoxID
Gui, ICScriptHub:Add, Picture, x+35 h18 w18 vButtonRefreshChestPurchaser, %g_ReloadButton%
Gui, ICScriptHub:Add, Edit, x30 y+15 w75 vChestPurchaseCountID, % "99"
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserBuyChests, Buy

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestPurchaseID
xyValY += 150
Gui, ICScriptHub:Add, GroupBox, x15 y%xyValY% w425 h150 vGroupBoxChestOpenID, Open Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 vChestOpenComboBoxID
Gui, ICScriptHub:Add, Edit, y+15 w75 vChestOpenCountID, % "99"
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserOpenChests, Open

buyChestsFunc := Func("IC_ChestPurchaser_Component.BuyChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserBuyChests, % buyChestsFunc
openChestsFunc := Func("IC_ChestPurchaser_Component.OpenChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserOpenChests, % openChestsFunc
chestPurchaserReadChests := Func("IC_ChestPurchaser_Component.ReadChests")
GuiControl, ICScriptHub: +g, ButtonRefreshChestPurchaser, % chestPurchaserReadChests

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestOpenID
xyValY +=150
Gui, ICScriptHub:Add, Text, x15 y%xyValY% w350 vChestPurchaserCurrentChestCount, % "---"

IC_ChestPurchaser_Component.ReadChests()


class IC_ChestPurchaser_Component
{
    ReadChests()
    {
        if(WinExist("ahk_exe IdleDragons.exe")) ; only update when the game is open
            g_SF.Memory.OpenProcessReader()
        else
            return
        size := g_SF.Memory.ReadChestDefinesSize()
        if(!size)
            return
        loop, %size%
        {
            chestID := g_SF.Memory.GetChestIDBySlot(A_Index)
            chestName := g_SF.Memory.GetChestNameBySlot(A_Index)
            comboBoxOptions .= chestID . " " . chestName . "|"
        }
        g_SF.ResetServerCall()
        GuiControl,ICScriptHub:, ChestOpenComboBoxID, %comboBoxOptions%
        GuiControl,ICScriptHub:, ChestPurchaseComboBoxID, %comboBoxOptions%
    }

    BuyChests()
    {
        global
        Gui,ICScriptHub:Submit, NoHide
        splitArray := StrSplit(ChestPurchaseComboBoxID, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Buying " . ChestPurchaseCountID . " of " . chestName . " (ID: " . chestID . ")"
        buyCount := ChestPurchaseCountID
        while(buyCount > 0)
        {
            GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Buying " buyCount " chests..."
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
                buyCount -= 100
            else
                buyCount -= 1
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Buying " Max(buyCount,0) " chests..."
        MsgBox % "Done"
    }

    OpenChests()
    {
        global
        Gui,ICScriptHub:Submit, NoHide
        splitArray := StrSplit(ChestOpenComboBoxID, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Opening " . ChestOpenCountID . " of " . chestName . " (ID: " . chestID . ") Make sure the game is closed before continuing."
        openCount := ChestOpenCountID
        shinyMessage := ""
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
            shinyMessage .= g_ServerCall.ParseChestResults(response)
            openCount -= 99
        }
        GuiControl, ICScriptHub:, ChestPurchaserCurrentChestCount, % "Opening " Max(openCount,0) " chests..."
        MsgBox % "Done`n" . (shinyMessage != "" ? shinyMessage : "No shiny gear found.")
    }
}
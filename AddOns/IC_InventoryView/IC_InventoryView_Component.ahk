GUIFunctions.AddTab("Inventory View")

global g_InventoryView := new IC_InventoryView_Component()

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Inventory View
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, Inventory:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Button, x+15 yp+0 w60 vButtonReadInventory, Load
InventoryViewRead := ObjBindMethod(g_InventoryView, "ReadInventory")
GuiControl,ICScriptHub: +g, ButtonReadInventory, % InventoryViewRead


Gui, ICScriptHub:Add, Button, x+15 yp+0 w75 vButtonReadChests, View Chests
InventoryViewChests := ObjBindMethod(g_InventoryView, "ReadChests")
GuiControl,ICScriptHub: +g, ButtonReadChests, % InventoryViewChests

Gui, ICScriptHub:Add, Text, vInventoryViewTimeStampID x15 y+5 w225, % "Last Updated: "

if(g_isDarkMode)
    Gui, ICScriptHub:Font, g_CustomColor
Gui, ICScriptHub:Add, ListView, x15 y+5 w450 h450 vInventoryViewID, `ID|Name|Amount|Change|Per `Run
if(g_isDarkMode)
{
    GuiControl,ICScriptHub: +Background888888, InventoryViewID
    Gui, ICScriptHub:Font, cSilver
}

; Highly recommended to use classes to reduce chance of interference with other addons/code.
; Below is the functionality included with the component. For readability in more complex addons, these will often be separated 
; into a new ahk file that is read from an #include line here.

; IC_InventoryVIew_Component uses the MemoryReads to keep track of non-chest Inventory changes.
class IC_InventoryView_Component
{
    FirstReadValues := ""
    ; ReadInventory reads the inventory from in game and displays it in a list. Remembers first run values to compare for changes and per run calculations.
    ReadInventory(runCount := 1)
    {
        restore_gui_on_return := LV_Scope("ICScriptHub", "InventoryViewID")
        doAddToFirstRead := false
        GuiControl, ICScriptHub:, InventoryViewTimeStampID, % "Last Updated: " . A_YYYY . "/" A_MM "/" A_DD " at " A_Hour . ":" A_Min 
        if(WinExist("ahk_exe IdleDragons.exe")) ; only update when the game is open
            g_SF.Memory.OpenProcessReader()
        else
            return
        LV_Delete()
        if(!IsObject(this.FirstReadValues))
        {
            this.FirstReadValues := {}
            doAddToFirstRead := true
        }
        size := g_SF.Memory.ReadInventoryItemsCount()
        loop, %size%
        {
            change := ""
            buffID := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID.GetGameObjectFromListValues(A_index - 1))
            itemName := g_SF.Memory.GetInventoryBuffNameByID(buffID)
            itemAmount := g_SF.Memory.GetInventoryBuffAmountByID(buffID)
            if(doAddToFirstRead AND size) ; only create first object if there is an inventory
                this.FirstReadValues.Push({"ID":buffID, "Name":itemName, "Amount":itemAmount})
            else if(size)
                change := this.GetChange(buffID, itemAmount)
            else
                return
            perRunVal := Round(change / runCount, 2)
            if(!perRunVal)
                perRunVal := ""
            if(!change)
                change := ""
            LV_Add(,buffID,itemName, itemAmount, change, perRunVal)
        }
        LV_ModifyCol()
        LV_ModifyCol(1, "Integer")  
        LV_ModifyCol(3, "Integer")
        LV_ModifyCol(4, "50 Integer")
        LV_ModifyCol(5, "50 Integer")
    }
    
    ; Reads the game memory for all chests in the inventory and their counts and shows it in the inventory view.
    ReadChests()
    {
        restore_gui_on_return := LV_Scope("ICScriptHub", "InventoryViewID")
        GuiControl, ICScriptHub:, InventoryViewTimeStampID, % "Last Updated: " . A_YYYY . "/" A_MM "/" A_DD " at " A_Hour . ":" A_Min 
        if(WinExist("ahk_exe IdleDragons.exe")) ; only update when the game is open
            g_SF.Memory.OpenProcessReader()
        else
            return
        LV_Delete()
        size := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionarySize)    
        if(!size)
            return "" 
        loop, %size%
        {
            ; See GetChestCountByID() memory function to see why these extra caluculations are made.
            listIndex := g_SF.Memory.Is64Bit ? ((A_index - 1) * 4 + 4)  : (A_index - 1) * 4
            chestID := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(listIndex))
            itemName := g_SF.Memory.GetChestNameByID(chestID)
            itemAmount := g_SF.Memory.GetChestCountByID(chestID) ;g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(A_index - 1 + 3))
            LV_Add(, chestID, itemName, itemAmount, "", "")
        }
        LV_ModifyCol()
        LV_ModifyCol(1, "Integer")  
        LV_ModifyCol(3, "Integer")
        LV_ModifyCol(4, "50 Integer")
        LV_ModifyCol(5, "50 Integer")
    }

    ; ClearFirstRead clears the first run values to start new tracking.
    ClearFirstRead()
    {
        this.FirstReadValues := ""
    }

    ; GetChange compares the current inventory item's (buffID) value (itemAmount) with the start value and returns the difference.
    GetChange(buffID, itemAmount)
    {
        firstCount := this.GetFirstCountFromID(buffID)
        diff := itemAmount - firstCount
        return diff
    }

    ; GetFirstCountFromID returns the inventory start amount for the item (buffID) passed in.
    GetFirstCountFromID(buffID)
    {
        for k, v in this.FirstReadValues
        {
            if(v["ID"] == buffID)
                return v["Amount"]
        }
        return ""
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
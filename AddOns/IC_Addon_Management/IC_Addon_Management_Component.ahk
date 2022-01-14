; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement
AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()
AddonManagement.FirstRunCheck()
AddonManagement.CheckDependencies()

; ############################################################
;                    Add tab to the GUI
; ############################################################
GUIFunctions.AddTab("Addons")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
Gui, ICScriptHub:Tab, Addons

AddonTabWidth := 450

; Build Listview of available Addons
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Available Addons
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, ListView ,w%AddonTabWidth% vAddonsAvailableID hWndhLV,  Active|Name|Version|Folder
AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
GUIFunctions.LVM_CalculateSize(hLV,-1,AddonLVWidth,AddonLVHeight)
AddonLVWidth+=4
AddonLVHeight+=4
ControlMove,,,,,AddonLVHeight,ahk_id %hLV%


AddonNumberOfButtons := 4
AddonButtonWidth := (AddonTabWidth - (5 * (AddonNumberOfButtons - 1))) / AddonNumberOfButtons
AddonButtonYIncrease := AddonLVHeight + 5
Gui, ICScriptHub:Add, Button , yp+%AddonButtonYIncrease% w%AddonButtonWidth% gAddonsEnableClicked, Enable
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsDisableClicked, Disable
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsInfoClicked, Info
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsSaveClicked, Save

AddonsEnableClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		AddonManagement.EnableAddon(SelectedRow)
	}
}

AddonsDisableClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		AddonManagement.DisableAddon(SelectedRow)
	}
}

AddonsInfoClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		AddonManagement.ShowAddonInfo(SelectedRow)
	}
}

AddonsSaveClicked(){
	AddonManagement.WriteAddonManagementSettings()
}


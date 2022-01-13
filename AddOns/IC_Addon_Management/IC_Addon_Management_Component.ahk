; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement
AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()
AddonManagement.CheckDependencies()


; ############################################################
;                    Add tab to the GUI
; ############################################################
AddTab("Addons|")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
Gui, ICScriptHub:Tab, Addons

TabWidth := 450

; Build Listview of available Addons
Gui, ICScriptHub:Font, w700
Gui Add, Text, , Available Addons
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, ListView ,w%TabWidth% vAddonsAvailableID hWndhLV,  Active|Name|Version|Folder
AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
LVM_CalculateSize(hLV,-1,AddonLVWidth,AddonLVHeight)
AddonLVWidth+=4
AddonLVHeight+=4
ControlMove,,,,,AddonLVHeight,ahk_id %hLV%


NumberOfButtons := 4
ButtonWidth := (TabWidth - (5 * (NumberOfButtons - 1))) / NumberOfButtons
AddonButtonYIncrease := AddonLVHeight + 5
Gui, ICScriptHub:Add, Button , yp+%AddonButtonYIncrease% w%ButtonWidth% gAddonsEnableClicked, Enable
Gui, ICScriptHub:Add, Button , x+5 w%ButtonWidth% gAddonsDisableClicked, Disable
Gui, ICScriptHub:Add, Button , x+5 w%ButtonWidth% gAddonsInfoClicked, Info
Gui, ICScriptHub:Add, Button , x+5 w%ButtonWidth% gAddonsSaveClicked, Save

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


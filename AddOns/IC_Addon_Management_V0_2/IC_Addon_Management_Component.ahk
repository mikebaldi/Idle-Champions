; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement		; Creation of the AddonManagement
global g_AddonFolder := "Addons\" 					; Relative to A_ScriptDir

AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()
AddonManagement.FirstRunCheck()

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

Gui, ICScriptHub:Add, ListView ,w%AddonTabWidth% vAddonsAvailableID hWndhLV ,  Active|Name|Version|Folder
AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
GUIFunctions.LVM_CalculateSize(hLV,-1,AddonLVWidth,AddonLVHeight)
AddonLVWidth+=4
AddonLVHeight+=4
ControlMove,,,,,AddonLVHeight,ahk_id %hLV%


AddonNumberOfButtons := 6
AddonButtonWidth := (AddonTabWidth - (5 * (AddonNumberOfButtons - 1))) / AddonNumberOfButtons
AddonButtonYIncrease := AddonLVHeight + 5
Gui, ICScriptHub:Add, Button , yp+%AddonButtonYIncrease% w%AddonButtonWidth% gAddonsEnableClicked, Enable
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsDisableClicked, Disable
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsMoveUpClicked, Move Up
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsMoveDownClicked, Move Down
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsInfoClicked, Info
Gui, ICScriptHub:Add, Button , x+5 w%AddonButtonWidth% gAddonsSaveClicked, Save

AddonsEnableClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	while(SelectedRow := LV_GetNext(SelectedRow)){
		LV_GetText(AddonName, SelectedRow , 2)
		LV_GetText(AddonVersion, SelectedRow , 3)
		AddonManagement.EnableAddon(AddonName,AddonVersion)
	}
	AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
}

AddonsDisableClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	while(SelectedRow := LV_GetNext(SelectedRow)){
		LV_GetText(AddonName, SelectedRow , 2)
		LV_GetText(AddonVersion, SelectedRow , 3)
		AddonManagement.DisableAddon(AddonName,AddonVersion)		
	}
	AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
}

AddonsMoveUpClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		if(SelectedRow > 1){
			WantedRow := SelectedRow -1
			if(AddonManagement.SwitchOrderAddons(SelectedRow,WantedRow)){
				AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
				LV_Modify(WantedRow, "Select")
			}
			else{
				msgbox Can't move above a dependancy
			}			
		}
	}
}

AddonsMoveDownClicked(){
	Gui, ICScriptHub:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		if(SelectedRow < LV_GetCount()){
			WantedRow := SelectedRow + 1
			if(AddonManagement.SwitchOrderAddons(SelectedRow,WantedRow)){
				AddonManagement.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
				LV_Modify(WantedRow, "Select")
			}
			else{
				msgbox Can't move below a addon who depends on this addon
			}	
		}
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



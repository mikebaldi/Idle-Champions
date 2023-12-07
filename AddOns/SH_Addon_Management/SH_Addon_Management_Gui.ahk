Gui, AddonManagement:New , ,Addon Management
GUIFunctions.LoadTheme("AddonManagement")
Gui, AddonManagement:+Resize -MaximizeBox
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()

AddonManagementWindowWidth := 450

Gui, AddonManagement:Add, ListView ,w%AddonManagementWindowWidth% vAddonsAvailableID hWndhLV ,  Active|Name|Version|Folder
GUIFunctions.UseThemeListViewBackgroundColor("AddonsAvailableID")
AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
GUIFunctions.LVM_CalculateSize(hLV,-1,AddonLVWidth,AddonLVHeight)
AddonLVWidth+=4
AddonLVHeight+=30
ControlMove,,,,,AddonLVHeight,ahk_id %hLV%


AddonNumberOfButtons := 6
AddonButtonWidth := (AddonManagementWindowWidth - (5 * (AddonNumberOfButtons - 1))) / AddonNumberOfButtons
AddonButtonYIncrease := AddonLVHeight + 5
Gui, AddonManagement:Add, Button , yp+%AddonButtonYIncrease% w%AddonButtonWidth% gAddonManagementEnableClicked, Enable
Gui, AddonManagement:Add, Button , x+5 w%AddonButtonWidth% gAddonManagementDisableClicked, Disable
Gui, AddonManagement:Add, Button , x+5 w%AddonButtonWidth% gAddonManagementMoveUpClicked, Move Up
Gui, AddonManagement:Add, Button , x+5 w%AddonButtonWidth% gAddonManagementMoveDownClicked, Move Down
Gui, AddonManagement:Add, Button , x+5 w%AddonButtonWidth% gAddonManagementInfoClicked, Info
Gui, AddonManagement:Add, Button , x+5 w%AddonButtonWidth% gAddonManagementSaveClicked, Save

AddonManagementGuiClose(){
	if(AddonManagement.NeedSave){
		MsgBox, 36, Save, Looks like you didn't save your changes, would you like to do this now?
        IfMsgBox, Yes
            AddonManagementSaveClicked()
		IfMsgBox,No
		{
			AddonManagement.Addons:=[]
			AddonManagement.GetAvailableAddons()
			AddonManagement.GetAddonManagementSettings()
			AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
		}
	}
}

AddonManagementEnableClicked(){
	Gui, AddonManagement:ListView, AddonsAvailableID
	while(SelectedRow := LV_GetNext(SelectedRow)){
		LV_GetText(AddonName, SelectedRow , 2)
		LV_GetText(AddonVersion, SelectedRow , 3)
		AddonManagement.EnableAddon(AddonName,AddonVersion)
	}
	AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
}

AddonManagementDisableClicked(){
	Gui, AddonManagement:ListView, AddonsAvailableID
	while(SelectedRow := LV_GetNext(SelectedRow)){
		LV_GetText(AddonName, SelectedRow , 2)
		LV_GetText(AddonVersion, SelectedRow , 3)
		AddonManagement.DisableAddon(AddonName,AddonVersion)		
	}
	AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
}

AddonManagementMoveUpClicked(){
	Gui, AddonManagement:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		if(SelectedRow > 1){
			WantedRow := SelectedRow -1
			if(AddonManagement.SwitchOrderAddons(SelectedRow,WantedRow)){
				AddonManagement.NeedSave:=1
				AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
				LV_Modify(WantedRow, "Select")
			}
			else{
				msgbox Can't move above a dependency.
			}			
		}
	}
}

AddonManagementMoveDownClicked(){
	Gui, AddonManagement:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		if(SelectedRow < LV_GetCount()){
			WantedRow := SelectedRow + 1
			if(AddonManagement.SwitchOrderAddons(SelectedRow,WantedRow)){
				AddonManagement.NeedSave:=1
				AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
				LV_Modify(WantedRow, "Select")
			}
			else{
				msgbox Can't move below an addon who depends on this addon.
			}	
		}
	}
}

AddonManagementInfoClicked(){
	Gui, AddonManagement:ListView, AddonsAvailableID
	if(SelectedRow := LV_GetNext()){
		AddonManagement.ShowAddonInfo(SelectedRow)
	}
}

AddonManagementSaveClicked(){
	AddonManagement.WriteAddonManagementSettings()
	AddonManagement.NeedSave := 0
	MsgBox, 36, Restart, To activate changes to enabled/disabled addons you need to restart the script.`nDo you want to do this now?
	IfMsgBox, Yes
		Reload
}
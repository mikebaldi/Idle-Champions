; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement		; Creation of the AddonManagement
global g_AddonFolder := "Addons\" 					; Relative to A_ScriptDir

AddonManagement.NeedSave := 0
AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()
AddonManagement.FirstRunCheck()


; ############################################################
;                    Add Button to the GUI
; ############################################################

AddonLinkToPicture := ""
if(GUIFunctions.isDarkMode)
	AddonLinkToPicture := A_LineFile . "\..\Images\MenuBarDark.png"
else
	AddonLinkToPicture := A_LineFile . "\..\Images\MenuBar.png"
GUIFunctions.AddButton(AddonLinkToPicture,"AddonOpenGuiClicked","AddonOpenGUIClickedButton")

AddonOpenGuiClicked(){
	;AddonManagement.OpenDefaultGui()
	AddonManagement.NeedSave := 0
	Gui, AddonManagement:Show
}


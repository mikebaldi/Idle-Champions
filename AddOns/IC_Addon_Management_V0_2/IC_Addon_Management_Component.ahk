; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement		; Creation of the AddonManagement
global g_AddonFolder := "Addons\" 					; Relative to A_ScriptDir

AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()
AddonManagement.FirstRunCheck()

; ############################################################
;                    Add Button to the GUI
; ############################################################

AddonLinkToPicture := A_LineFile . "\..\Images\MenuBar.png"
GUIFunctions.AddButton(AddonLinkToPicture,"AddonOpenGuiClicked")

AddonOpenGuiClicked(){
	;AddonManagement.OpenDefaultGui()
	Gui, AddonManagement:Show
}


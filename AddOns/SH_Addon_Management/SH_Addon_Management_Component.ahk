; ############################################################
;                    Defining & init
; ############################################################

global AddonManagement := new AddonManagement			; Creation of the AddonManagement
global g_AddonFolder := A_LineFile . "\..\..\"			; Up from addon file and folder

AddonManagement.NeedSave := 0
AddonManagement.GetAvailableAddons()
AddonManagement.GetAddonManagementSettings()


; ############################################################
;                    Add Button to the GUI
; ############################################################

AddonLinkToPicture := ""
AddonManagementSetButtonImage()
GUIFunctions.AddButton(AddonLinkToPicture,"AddonOpenGuiClicked","AddonOpenGUIClickedButton")
GUIFunctions.UseThemeBackgroundColor()

AddonOpenGuiClicked(){
	AddonManagement.NeedSave := 0
	if(!g_UserSettings[ "TutorialsSeen" ])
	{
		g_UserSettings[ "TutorialsSeen" ] := True
		; save settings
    	IC_SharedFunctions_Class.WriteObjectToJSON( A_ScriptDir . "\Settings.json" , g_UserSettings )
		SetTimer, AddonManagementBlinkButton, Off
		SetTimer, AddonManagementBlinkButton, Delete
		AddonManagementSetButtonImage()
	}
	Gui, AddonManagement:Show
    AddonManagement.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
	GUIFunctions.UseThemeTitleBar("AddonManagement")
}

AddonManagementSetButtonImage(){
	global AddonLinkToPicture
	if(GUIFunctions.isDarkMode)
		AddonLinkToPicture := A_LineFile . "\..\Images\MenuBarDark.png"
	else
		AddonLinkToPicture := A_LineFile . "\..\Images\MenuBar.png"
	GuiControl,ICScriptHub:, AddonOpenGUIClickedButton, %AddonLinkToPicture%
}

If(!g_UserSettings[ "TutorialsSeen"] )
{
	; Run timer function to start blinking the addon button
	SetTimer, AddonManagementBlinkButton, 650, 0
}

AddonManagementBlinkButton()
{
	global AddonLinkToPicture
	global AddonOpenGUIClickedButton
	static isSetDark
	if(isSetDark)
		AddonLinkToPicture := A_LineFile . "\..\Images\MenuBarDark.png"
	else
		AddonLinkToPicture := A_LineFile . "\..\Images\MenuBar.png"
	GuiControl,ICScriptHub:, AddonOpenGUIClickedButton, %AddonLinkToPicture%
	isSetDark := !isSetDark
}
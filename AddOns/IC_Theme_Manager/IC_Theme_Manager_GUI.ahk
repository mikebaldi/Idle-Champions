; ############################################################
;                    Add tab to the GUI
; ############################################################
GUIFunctions.AddTab("Theme Manager")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
; Create a Tab and GUI elements. Some addons do not need a GUI.
; 
; Select the tab created above

Gui, ICScriptHub:Tab, Theme Manager

;Add GUI fields to this addon's tab.
; Gui, ICScriptHub:Tab, Briv Gem Farm
; GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmPlayButton
; if(IsObject(IC_GameLocationSettings_Component))
; {
;     posY += 65
;     posX += 175
; }
Gui, ICScriptHub:Add, Button, w160 vButtonOpenThemeManagerGUI, Theme Manager
g_ShowThemeManagerButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerGuiClicked")
g_ThemeManagerTestButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerTestThemesClicked")
g_ThemeManagerSaveButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerSaveThemeClicked")
GuiControl,ICScriptHub: +g, ButtonOpenThemeManagerGUI, % g_ShowThemeManagerButton
g_ThemeManager.WindowHeight := IC_Theme_Manager_GUI_Class.BuildThemeManagerGUI()

; ############################################################
;               Add a new GUI Window that uses themes
; ############################################################
; The following GUI elements are not necessary in an Addon. They are just here for examples.
; The following GUI Is not required to be in a function but it is easier to rebuild when destroyed.

class IC_Theme_Manager_GUI_Class
{
        ; Shows the Example Addon's extra GUI Window
    ThemeManagerGuiClicked()
    {
        Gui, ThemeManager:Show, % " h" . g_ThemeManager.WindowHeight
        GUIFunctions.UseThemeTitleBar("ThemeManager")
    }

    ; Swaps between the default theme and Example Addon's custom theme
    ThemeManagerTestThemesClicked()
    {
        g_ThemeManager.ResetThemeManagerGui()
    }

    
    ; Swaps between the default theme and Example Addon's custom theme
    ThemeManagerSaveThemeClicked()
    {
        g_ThemeManager.SaveCurrentTheme()
    }

    ; Builds the GUI for the new window. 
    BuildThemeManagerGUI(themeName := "CurrentTheme")
    {   
        ; ListView's variable name must be global.
        global ThemeSelectorSettingsListID
        global ThemeSelectorComboBoxID
        global ButtonThemeManagerSaveThemes
        global ButtonThemeManagerTestThemes
        global g_ThemeManagerSaveButton
        global g_ThemeManagerTestButton
        global g_ThemeManager
        themeFile := A_LineFile . "\..\..\..\Themes\" . themeName . ".json"
        Gui, ThemeManager:New , , Theme Manager
        GUIFunctions.LoadTheme("ThemeManager", themeFile)
        Gui, ThemeManager:+Resize -MaximizeBox
        GUIFunctions.UseThemeBackgroundColor()
        GUIFunctions.UseThemeTextColor("InputBox")
        Gui, ThemeManager:Add, ComboBox, xp+15 yp+15 w150 vThemeSelectorComboBoxID
        comboBoxOptions := "|"
        for k,fileName in g_ThemeManager.GetThemesList()
        {
            comboBoxOptions .= StrSplit(fileName,".json")[1] . "|"
        }
        GuiControl,ThemeManager:, ThemeSelectorComboBoxID, %comboBoxOptions%
        GUIFunctions.UseThemeTextColor()
        Gui, ThemeManager:Add, Button , x+10 vButtonThemeManagerTestThemes, Test Theme
        Gui, ThemeManager:Add, Button , x+10 vButtonThemeManagerSaveThemes, Save Theme
        GuiControl,ThemeManager: +g, ButtonThemeManagerTestThemes, % g_ThemeManagerTestButton
        GuiControl,ThemeManager: +g, ButtonThemeManagerSaveThemes, % g_ThemeManagerSaveButton
        GUIFunctions.UseThemeTextColor("TableTextColor")
        Gui, ThemeManager:Add, ListView , x10 w500 vThemeSelectorSettingsListID hWndThemeManagerListViewHwnd,  Name|Value
        g_ThemeManager.ShowThemeAttributesInList(themeFile)
        GUIFunctions.LVM_CalculateSize(ThemeManagerListViewHwnd,GUIFunctions.CurrentTheme.Count(),ThemeManagerListViewWidth,ThemeManagerListViewHeight)
        ThemeManagerListViewHeight+=4
        ControlMove,,,,,ThemeManagerListViewHeight,ahk_id %ThemeManagerListViewHwnd%
        GUIFunctions.UseThemeListViewBackgroundColor("ThemeSelectorSettingsListID")
        GUIFunctions.UseThemeTitleBar("ThemeManager", false)
        ; restore original theme when done
        Gui,ThemeManager:Submit, NoHide
        GUIFunctions.LoadTheme()
        return ThemeManagerListViewHeight
    }
}
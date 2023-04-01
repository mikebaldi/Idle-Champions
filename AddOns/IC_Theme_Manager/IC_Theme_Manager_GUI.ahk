; ############################################################
;                Add tab or button to the GUI
; ############################################################

if(IsObject(IC_BrivGemFarm_Class)) ; Add to Briv Gem Farm if exists
{
    Gui, ICScriptHub:Tab, Briv Gem Farm
    GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmPlayButton
    posX += (IsObject(IC_GameLocationSettings_Component) ? 175 : 0)
    posY += 65
    Gui, ICScriptHub:Add, Button, x%posx% y%posY% w160 vButtonOpenThemeManagerGUI, Theme Manager
}
else ; Otherwise create new tab.
{
    GUIFunctions.AddTab("Theme Manager")
    Gui, ICScriptHub:Tab, Theme Manager
    ;Add GUI fields to this addon's tab.
    Gui, ICScriptHub:Add, Button, w160 vButtonOpenThemeManagerGUI, Theme Manager
}

; Update buttons
g_ShowThemeManagerButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerGuiClicked")
g_ThemeManagerTestButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerTestThemesClicked")
g_ThemeManagerSaveButton := ObjBindMethod(IC_Theme_Manager_GUI_Class, "ThemeManagerSaveThemeClicked")
GuiControl,ICScriptHub: +g, ButtonOpenThemeManagerGUI, % g_ShowThemeManagerButton
g_ThemeManager.WindowHeight := IC_Theme_Manager_GUI_Class.BuildThemeManagerGUI()

; ############################################################
;               Add a new GUI Window for themes
; ############################################################

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

    ; Builds the GUI for the new window. Returns suggested window height after filling list box.
    BuildThemeManagerGUI(themeName := "CurrentTheme")
    {   
        ; GUI control variables must be global. 
        global ThemeSelectorSettingsListID
        global ThemeSelectorComboBoxID
        global ButtonThemeManagerSaveThemes
        global ButtonThemeManagerTestThemes
        ; GUI control functions must be global.
        global g_ThemeManagerSaveButton
        global g_ThemeManagerTestButton
        global g_ThemeManager

        themeFile := A_LineFile . "\..\..\..\Themes\" . themeName . ".json"

        Gui, ThemeManager:New , , Theme Manager
        Gui, ThemeManager:+Resize -MaximizeBox

        GUIFunctions.LoadTheme("ThemeManager", themeFile)
        GUIFunctions.UseThemeBackgroundColor()
        GUIFunctions.UseThemeTextColor("InputBox")

        ; Themes Dropdown
        Gui, ThemeManager:Add, ComboBox, x10 yp+15 w150 vThemeSelectorComboBoxID
        comboBoxOptions := this.GetThemesComboBoxString()
        GuiControl,ThemeManager:, ThemeSelectorComboBoxID, %comboBoxOptions%

        ; Save/Test buttons
        GUIFunctions.UseThemeTextColor()
        Gui, ThemeManager:Add, Button , x+10 vButtonThemeManagerTestThemes, Test Theme
        Gui, ThemeManager:Add, Button , x+10 vButtonThemeManagerSaveThemes, Save Theme
        GuiControl,ThemeManager: +g, ButtonThemeManagerTestThemes, % g_ThemeManagerTestButton
        GuiControl,ThemeManager: +g, ButtonThemeManagerSaveThemes, % g_ThemeManagerSaveButton

        ; Add sample GUI items
        expectedSampleControlsHeight := 125
        GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
        Gui, ThemeManager:Add, GroupBox, x5 y+10 w450 h115, Fonts
        GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
        Gui, ThemeManager:Add, Text, x15 yp+20, Header Text
        GUIFunctions.UseThemeTextColor("DefaultTextColor")
        Gui, ThemeManager:Add, Text, xp+100, Default Text
        GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
        Gui, ThemeManager:Add, Text, x15 y+10, Warning Text
        GUIFunctions.UseThemeTextColor("ErrorTextColor", 700)
        Gui, ThemeManager:Add, Text, xp+100, Error Text
        GUIFunctions.UseThemeTextColor("SpecialTextColor1", 700)
        Gui, ThemeManager:Add, Text, x15 y+10, Special Text 1
        GUIFunctions.UseThemeTextColor("SpecialTextColor2", 700)
        Gui, ThemeManager:Add, Text, xp+100, Special Text 2
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ThemeManager:Add, Edit, x15 y+10, InputBox Text
        GUIFunctions.UseThemeTextColor()

        ; ListView showing theme settings
        GUIFunctions.UseThemeTextColor("TableTextColor")
        Gui, ThemeManager:Add, ListView , x10 w500 vThemeSelectorSettingsListID hWndThemeManagerListViewHwnd,  Name|Value
        g_ThemeManager.ShowThemeAttributesInList(themeFile)
        GUIFunctions.LVM_CalculateSize(ThemeManagerListViewHwnd,GUIFunctions.CurrentTheme.Count(),ThemeManagerListViewWidth,ThemeManagerListViewHeight)
        ThemeManagerListViewHeight+=4
        ControlMove,,,,,ThemeManagerListViewHeight,ahk_id %ThemeManagerListViewHwnd%
        GUIFunctions.UseThemeListViewBackgroundColor("ThemeSelectorSettingsListID")

        ; Set Title Bar color
        GUIFunctions.UseThemeTitleBar("ThemeManager", false)
        
        ; restore original theme when done
        Gui,ThemeManager:Submit, NoHide
        GUIFunctions.LoadTheme()
        return ThemeManagerListViewHeight + expectedSampleControlsHeight
    }

    ; Builds combo box items from themes list.
    GetThemesComboBoxString()
    {
        comboBoxOptions := "|"
        for k,fileName in g_ThemeManager.GetThemesList()
        {
            comboBoxOptions .= StrSplit(fileName,".json")[1] . "|"
        }
        return comboBoxOptions
    }
}
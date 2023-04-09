Class IC_Theme_Manager_Class
{
    ; Opens the example theme and displays its values.
    ShowThemeAttributesInList(themeLocation)
    {
        ; Using Script Hub's built in functions to read a JSON file:
        themeSettingsObj := g_SF.LoadObjectFromJSON( themeLocation )
        ;  Make sure the correct list is being updated.
        restore_gui_on_return := GUIFunctions.LV_Scope("ThemeManager", "ThemeSelectorSettingsListID")
        ; Clear the list
        LV_Delete()
        ; Add values to list
        for name, value in themeSettingsObj
        {
            LV_Add(, name, value)
        }
        ; Tell UI to update GUI
        Gui, Submit, NoHide
        ; Adjust columns
        LV_ModifyCol()
    }

    ; Reset the Theme Manager GUI
    ResetThemeManagerGui()
    {
        global ThemeSelectorComboBoxID
        Gui, ThemeManager:Submit, NoHide
        selectedTheme := ThemeSelectorComboBoxID
        titleText := "Theme Manager" . " - Current Theme: " . ThemeSelectorComboBoxID
        this.ThemeFile := themeFile := A_LineFile . "\..\..\..\Themes\" . ThemeSelectorComboBoxID . ".json"
        WinGetPos, xPos, yPos,,, 
        Gui, ThemeManager:Destroy
        ThemeManagerListViewHeight := IC_Theme_Manager_GUI_Class.BuildThemeManagerGUI(ThemeSelectorComboBoxID) + 5
        ; Don't lose position or hide window
     
        ;GuiControl, Move, ICScriptHub:ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
        ;Gui, ICScriptHub:Show, %  "x" . g_UserSettings[ "WindowXPosition" ] " y" . g_UserSettings[ "WindowYPosition" ] . " w" . g_TabControlWidth+5 . " h" . g_TabControlHeight, % "IC Script Hub" . (g_UserSettings[ "WindowTitle" ] ? (" - " .  g_UserSettings[ "WindowTitle" ]) : "")
        Gui, ThemeManager:Show, % "x" . xPos . " y" . yPos . " h" . ThemeManagerListViewHeight, %titleText%
        GuiControl, ChooseString, ThemeSelectorComboBoxID, %selectedTheme%
    }

    GetThemesList()
    {
        themesList := {}
        Loop, Files, % A_LineFile . "\..\..\..\Themes\*.json"
        {
            if(A_LoopFileName != "CurrentTheme.json")
                themesList.Push(A_LoopFileName)
        }
        return themesList
    }

    SaveCurrentTheme()
    {
        global g_SF
        global ThemeSelectorComboBoxID
        Gui,ThemeManager:Submit, NoHide
        currentThemeFile := A_LineFile . "\..\..\..\Themes\CurrentTheme.json"
        if(this.ThemeFile == "" AND ThemeSelectorComboBoxID == "")
            return
        chosenThemeFile := ThemeSelectorComboBoxID ? (A_LineFile . "\..\..\..\Themes\" . ThemeSelectorComboBoxID . ".json") : this.ThemeFile
        GUIFunctions.LoadTheme("ThemeManager", chosenThemeFile)               ;set currentTheme to the last theme tested.
        g_SF.WriteObjectToJSON(currentThemeFile, GUIFunctions.CurrentTheme)
        GUIFunctions.LoadTheme()  
        MsgBox, 36, Reload?, Theme Saved. Do you wish to reload Script Hub now?
        IfMsgBox, Yes
            Reload
    }
}


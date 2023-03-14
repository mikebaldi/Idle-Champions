; ############################################################
;                          Code
; ############################################################
; ############################################################
;                          Button Clicks
; ############################################################
; Note: AHK requires the functions a button calls must be global and not part of a class.
; Be careful not to name button functions with names that are already in use in the script.
;

; Does two hello world promps using different methods of accessing clases.
ExampleButtonPromptClicked()
{
    ; Static class
    IC__AddonExample_Class.Prompt("Hello World")
    ; Dynamic class
    g_ExampleVariable.Prompt("Alternative Hello World")

    ; Note that members of a class are accessible differently depending on if you are
    ; using the static class or using a dynamic one using New.
    ; For example, properties are only available to dynamic classes.
}

; Populates Exmaple Addon ListView
ExampleButtonFilListClicked()
{
    g_ExampleVariable.ShowThemeAttributesInList()
}

; Swaps between the default theme and Example Addon's custom theme
ExampleButtonSwapThemesClicked()
{
    g_ExampleVariable.ResetExampleGui()
}

; Shows the Example Addon's extra GUI Window
ExampleAddonGuiClicked()
{
	Gui, ExampleAddon:Show
	GUIFunctions.UseThemeTitleBar("ExampleAddon")
}

Class IC__AddonExample_Class
{

    ; Opens the example theme and displays its values.
    ShowThemeAttributesInList()
    {
        ; Using Script Hub's built in functions to read a JSON file:
        themeSettingsObj := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Themes\ExampleTheme.json")
        ;  Make sure the correct list is being updated.
        restore_gui_on_return := GUIFunctions.LV_Scope("ExampleAddon", "ExampleListViewID")
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

    ; Reset the Example Addon Window
    ResetExampleGui()
    {
        static UseCustomTheme := false
        UseCustomTheme := NOT UseCustomTheme
        titleText := "Example Addon Window" . (UseCustomTheme ? " - Custom Theme" : "")
        WinGetPos, xPos, yPos,,, 
        Gui, ExampleAddon:Destroy
        BuildExampleAddonGUI(UseCustomTheme)
        ; Don't lose position or hide window
        Gui, ExampleAddon:Show, x%xPos% y%yPos%, %titleText%
    }

    Prompt(text){
        msgbox % text
    }
}


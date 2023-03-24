; ############################################################
;                    Add tab to the GUI
; ############################################################
GUIFunctions.AddTab("Example")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
; Create a Tab and GUI elements. Some addons do not need a GUI.
; 
; Select the tab created above
Gui, ICScriptHub:Tab, Example
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Example template
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x10 y+10 , This is a demo text
Gui, ICScriptHub:Add, Button , x10 y+10 vExampleVariableForMouseover gExampleAddonGuiClicked, Test Button

; Example of adding a tooltip to Script Hub.
GUIFunctions.AddToolTip( "ExampleVariableForMouseover", "Click to load example GUI.") 

; ############################################################
;               Add a new GUI Window that uses themes
; ############################################################
; The following GUI elements are not necessary in an Addon. They are just here for examples.
; The following GUI Is not required to be in a function but it is easier to rebuild when destroyed.

; Builds the GUI for the new window. 
BuildExampleAddonGUI(UseCustomTheme := false)
{   
    ; ListView's variable name must be global.
    global ExampleListViewID

    themeFile := UseCustomTheme ? (A_LineFile . "\..\Themes\ExampleTheme.json") : ""
    Gui, ExampleAddon:New , , Example Addon Window
    GUIFunctions.LoadTheme("ExampleAddon", themeFile)
    Gui, ExampleAddon:+Resize -MaximizeBox
    GUIFunctions.UseThemeBackgroundColor()
    GUIFunctions.UseThemeTextColor()

    Gui, ExampleAddon:Add, Button , x10 y+10 gExampleButtonPromptClicked, Popup
    Gui, ExampleAddon:Add, Button , x+10 gExampleButtonFilListClicked, Fill List
    Gui, ExampleAddon:Add, Button , x+10 gExampleButtonSwapThemesClicked, Swap Themes

    GUIFunctions.UseThemeTextColor("TableTextColor")
    Gui, ExampleAddon:Add, ListView , x10 w500 vExampleListViewID hWndhLV ,  Name|Value
    GUIFunctions.UseThemeListViewBackgroundColor("ExampleListViewID")
    GUIFunctions.UseThemeTitleBar("ExampleAddon", false)
    ; restore original theme when done
    GUIFunctions.LoadTheme()
}
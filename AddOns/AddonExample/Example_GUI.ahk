; ############################################################
;                    Add tab to the GUI
; ############################################################
GUIFunctions.AddTab("Example")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
; Select the tab you created above
Gui, ICScriptHub:Tab, Example

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Example template
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Text, x10 y+10 , This is a demo text

Gui, ICScriptHub:Add, Button , x10 y+10 gExampleButtonClicked, Testbutton

; ############################################################
;                          Buttons
; ############################################################

ExampleButtonClicked(){
    ExampleVariable.Prompt("Hello World")
}
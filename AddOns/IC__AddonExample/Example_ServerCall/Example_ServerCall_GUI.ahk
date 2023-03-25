; First few lines of code will add a button to the pre-existing Example addon's tab.
; Set guicontrol to act on the Example tab
Gui, ICScriptHub:Tab, Example
; Get the features of the gui control with the variable "ExampleVariableForMouseover" and store them in pos-prefixed varibles: posY posX posW and posH
GuiControlGet, pos, ICScriptHub:Pos, ExampleVariableForMouseover
; Add 45 pixels to the posY position of the control
posY += 45
; Add a new text 45 pixels down from the top corner of the previous button.
Gui, ICScriptHub:Add, Text, x10 y%posY% w420, % "Example ServerCall (Chest Codes). Can not use special characters like '#'"
; Add a new button 10 pixesl below the text control with associated global variable ExampleButtonInputChestCode.
Gui, ICScriptHub:Add, Button, x10 y+10 w160 vExampleButtonInputChestCode, Input Chest Code
; Bind the GetChestCode class function call to the global variable ExampleInputChestCodeButton
ExampleInputChestCodeButton := ObjBindMethod(IC_Example_ServerCall_Class, "GetChestCode")
; Bind the global function call to the button created above
GuiControl,ICScriptHub: +g, ExampleButtonInputChestCode, % ExampleInputChestCodeButton

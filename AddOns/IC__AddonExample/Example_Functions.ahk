; ############################################################
;                          Buttons
; ############################################################

ExampleButtonClicked(){
    ; Static class
    IC__AddonExample_Class.Prompt("Hello World")
    ; Dynamic class
    g_ExampleVariable.Prompt("Alternative Hello World")
}

Class IC__AddonExample_Class{
    Prompt(text){
        msgbox % text
    }
}
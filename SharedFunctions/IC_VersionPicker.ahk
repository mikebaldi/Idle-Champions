
#include %A_LineFile%\..\json.ahk
Gui, ICScriptHub:New
Gui, ICScriptHub:+Resize -MaximizeBox
Gui, ICScriptHub:Add, Text, w100, Platform:
Gui, ICScriptHub:Add, DropDownList, yp+15 w100 vVersionPickerPlatformDropdown gVersionPickerUpdateVersions,
Gui, ICScriptHub:Add, Text, y6 x+10 w50, Version:
Gui, ICScriptHub:Add, DropDownList, yp+15 w50 vVersionPickerVersionDropdown,
Gui, ICScriptHub:Add, Button, x+5 w50 vVersionPickerSaveButton gVersionPickerSaveChoice, Save
Gui, ICScriptHub:Show,, Memory Version Picker

global scriptLocation := A_LineFile . "/../"
global g_VersionPickerPlatformChoice
global g_VersionPickerVersionChoice
;Gets data from JSON file
LoadObjectFromJSON( FileName )
{
    FileRead, oData, %FileName%
    return JSON.parse( oData )
}

;Writes beautified json (object) to a file (FileName)
WriteObjectToJSON( FileName, ByRef object )
{
    objectJSON := JSON.stringify( object )
    objectJSON := JSON.Beautify( objectJSON )
    FileDelete, %FileName%
    FileAppend, %objectJSON%, %FileName%
    return
}

VersionPickerUpdateVersions()
{
    global VersionPickerPlatformDropdown
    Gui, ICScriptHub:Submit, NoHide
    versionComboBoxOptions := "|"
    for k,v in GameObj[VersionPickerPlatformDropdown]
    {
        versionComboBoxOptions .= k . "|"
    }
    GuiControl,ICScriptHub:, VersionPickerVersionDropdown, %versionComboBoxOptions%
}

VersionPickerSaveChoice()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    if(VersionPickerVersionDropdown == "" OR VersionPickerPlatformDropdown == "" )
    {
        MsgBox, Please select both the platform and version.
        return
    }
    WriteObjectToJSON(scriptLocation . "MemoryRead/CurrentPointers.json", GameObj[VersionPickerPlatformDropdown][VersionPickerVersionDropdown] )
    MsgBox, Settings saved! ; Close/Restart all running Script Hub scripts before continuing.
    OutputDebug, % "Pointer Version Saved!"
    scriptHubLoc := A_LineFile . "\..\..\ICScriptHub.ahk"
    Run, %scriptHubLoc%
    ICScriptHubGuiClose()
}

ICScriptHubGuiClose()
{
    ExitApp
}

global GameObj := LoadObjectFromJSON( scriptLocation . "PointerData.json")


platformComboBoxOptions := "|"
for k,v in GameObj
{
    platformComboBoxOptions .= k . "|"
}
GuiControl,ICScriptHub:, VersionPickerPlatformDropdown, %platformComboBoxOptions%



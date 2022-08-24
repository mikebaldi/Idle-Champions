
#include %A_LineFile%\..\json.ahk
#include %A_LineFile%\..\MemoryRead\IC_MemoryFunctions_Class.ahk
Gui, ICSHVersionPicker:New
Gui, ICSHVersionPicker:+Resize -MaximizeBox
Gui, ICSHVersionPicker:Add, Text, w100, Platform:
Gui, ICSHVersionPicker:Add, DropDownList, yp+15 w100 vVersionPickerPlatformDropdown gVersionPickerUpdateVersions,
Gui, ICSHVersionPicker:Add, Text, y6 x+10 w50, Version:
Gui, ICSHVersionPicker:Add, DropDownList, yp+15 w50 vVersionPickerVersionDropdown,
Gui, ICSHVersionPicker:Add, Button, x+5 w50 vVersionPickerSaveButton gVersionPickerSaveChoice, Save
Gui, ICSHVersionPicker:Show,, Memory Version Picker

; GetExeBaseAddress()
; {
;     main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
;     loc := main.getModuleBaseAddress("IdleDragons.exe")
;     ;steamDLL := Main.getModuleBaseAddress("apphelp.dll")
;     ;steamDLL := Main.getModuleBaseAddress("steam_api64.dll")
;     ;return (steamDLL != -1)
;     return loc
; }
global scriptLocation := A_LineFile . "/../"
global g_VersionPickerPlatformChoice
global g_VersionPickerVersionChoice
global GameObj := LoadObjectFromJSON( scriptLocation . "PointerData.json")

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

; Reads version numbers into version dropdown box.
VersionPickerUpdateVersions()
{
    global VersionPickerPlatformDropdown
    Gui, ICSHVersionPicker:Submit, NoHide
    versionComboBoxOptions := "|"
    for k,v in GameObj[VersionPickerPlatformDropdown]
    {
        versionComboBoxOptions .= k . "|"
    }
    GuiControl,ICSHVersionPicker:, VersionPickerVersionDropdown, %versionComboBoxOptions%
}

; Saves pointers from platform/version selected to IC Script Hub and starts IC Script Hub.
VersionPickerSaveChoice()
{
    global
    Gui, ICSHVersionPicker:Submit, NoHide
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
    ICSHVersionPickerGuiClose()
}

; Closes the current Script
ICSHVersionPickerGuiClose()
{
    ExitApp
}

;  user needs to have the right Offsets before trying the pointer otherwise they probably won't get good info 
;  if while checking pointers one tries to access unavailable memory and crashes IC.. that'd be a problem
ChooseRecommendation()
{
    
    hWnd := WinExist("ahk_exe IdleDragons.exe")
    CheckPlatformByExePath(hWnd)
    ; check based on saved path
    ; check based on exe path
    ; check WRL for platform/version
    ; some check to say okay, yeah you picked the v463 pointer, but you don't have the v463 offsets.
}

; Attempts to retrieve platform information using Script Hub's saved launch path.
CheckPlatformBySettingsPath()
{
    IdleDragonsLauncher.exe
    WinGet, vPName, ProcessName, % "ahk_id " hWnd
    WinGet, vPPath, ProcessPath, % "ahk_id " hWnd
}

; Attempts to retrieve platform information using currently running IdleDragons.exe path location.
CheckPlatformByExePath(hWnd)
{
    WinGet, vProcPath, ProcessPath, % "ahk_id " hWnd
    if ProcPath == ""
        return ""
    CNELauncherPath := ProcPath . "../../IdleDragonsLauncher.exe"
    if(FileExist(CNELauncherPath))
        return "CNE"
    else if (StrSplitProcessPath)
        return "Steam"
    else if (StrSplitProcessPath)
        return "EGS"
    else if (StrSplitProcessPath)
        return "Kartridge"
}

; Attempts to retrieve version information using Script Hub's saved launch path.
CheckVersionBySettingsPath()
{
    ; check WRL for game version
}

; Attempts to retrieve version information using currently running IdleDragons.exe path location.
CheckVersionByExePath()
{
    ;
}

; Attempts to verify working pointers by checking if a valid game version can be read.
TestPointersByGameVersion()
{
    ; test gameVersion > 400 and < 2000
}

; Attempts to verify working pointers by checking if a valid timescale can be read.
TestPointersByTimeScale()
{
    ; test timescale is between 1 and 10
}

platformComboBoxOptions := "|"
for k,v in GameObj
{
    platformComboBoxOptions .= k . "|"
}
GuiControl,ICSHVersionPicker:, VersionPickerPlatformDropdown, %platformComboBoxOptions%



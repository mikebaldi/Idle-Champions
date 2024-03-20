

#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\MemoryRead\classMemory.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\CLR.ahk
#include *i %A_LineFile%\..\MemoryRead\Imports\IC_GameVersion64_Import.ahk
#include *i %A_LineFile%\..\MemoryRead\Imports\IC_GameVersion32_Import.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_GUIFunctions.ahk

Gui, ICSHVersionPicker:New
GUIFunctions.LoadTheme("ICSHVersionPicker")
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()
Gui, ICSHVersionPicker:+Resize -MaximizeBox
Gui, ICSHVersionPicker:Add, GroupBox, w300 h75, Pointer Select: 
Gui, ICSHVersionPicker:Add, Text, xp+10 yp+15 w100, Platform:
Gui, ICSHVersionPicker:Add, DropDownList, yp+15 w100 vVersionPickerPlatformDropdown gVersionPickerUpdateVersions,
Gui, ICSHVersionPicker:Add, Text, y22 x+10 w50, Version:
Gui, ICSHVersionPicker:Add, DropDownList, yp+15 w50 vVersionPickerVersionDropdown gVersionPickerResetText,
Gui, ICSHVersionPicker:Add, Button, x+5 w50 vVersionPickerSaveButton gVersionPickerSaveChoice, Save
Gui, ICSHVersionPicker:Add, Text, x20 y+5 w275 vVersionPickerSuggestionText, Checking...
;Gui, ICSHVersionPicker:Font, w700
Gui, ICSHVersionPicker:Add, Text, x20 y+8 w300 h26 vVersionPickerSuggestionText2, 
Gui, ICSHVersionPicker:Font, w400
Gui, ICSHVersionPicker:Add, Text, x13 y+2 w300 vVersionPickerDetectionText, Script Hub Recommends: Checking...
Gui, ICSHVersionPicker:Show, , Memory Version Picker
GUIFunctions.UseThemeTitleBar("ICSHVersionPicker")

global scriptLocation := A_LineFile . "\..\"
global g_VersionPickerPlatformChoice
global g_VersionPickerVersionChoice
global GameObj := LoadObjectFromJSON( scriptLocation . "PointerData.json")
global WRLPath := ""

; Searches the WebRequestLog for the Nth (param 3) string found between a start value (param 1) and end value (param 2)
GetDataFromWRL(string, string2, occurance := 1)
{
    global WRLPath
    if(!FileExist(WRLPath))
        return ""
    FileRead, wrl, %WRLPath%
    foundPos := InStr(wrl, string,,, occurance) + StrLen(string)
    endPos := InStr(wrl, string2,, foundPos + 1)
    length := endPos - foundPos
    data := SubStr(wrl, foundPos, length)
    wrl := ""
    return data
}

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
    if(FileExist(FileName))
        FileDelete, %FileName%
    FileAppend, %objectJSON%, %FileName%
    return ErrorLevel
}

; Sets suggestion text back to empty
VersionPickerResetText()
{
    GuiControl,ICSHVersionPicker:, VersionPickerSuggestionText, % ""
}

; Reads version numbers into version dropdown box.
VersionPickerUpdateVersions()
{
    global VersionPickerPlatformDropdown
    global VersionPickerVersionText
    GuiControl,ICSHVersionPicker:, VersionPickerSuggestionText, % ""
    Gui, ICSHVersionPicker:Submit, NoHide
    versionComboBoxOptions := "|"
    for k,v in GameObj[VersionPickerPlatformDropdown]
    {
        versionComboBoxOptions .= k . "|"
    }
    Sort, versionComboBoxOptions, N D|
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
    pointersToWrite := GameObj[VersionPickerPlatformDropdown][VersionPickerVersionDropdown]
    pointersToWrite["Platform"] := VersionPickerPlatformDropdown
    pointersToWrite["Version"] := VersionPickerVersionDropdown
    failedWrite := WriteObjectToJSON(scriptLocation . "MemoryRead\CurrentPointers.json", pointersToWrite )
    if !failedWrite
    {
        MsgBox, Settings saved! ; Close/Restart all running Script Hub scripts before continuing.
    }
    else
    {
        errMsg := "There was a problem saving the settings."
        errMsg .= "`nMake sure you have write permissions to the Script Hub directory."
        errMsg .= "`n  1) Make sure you have write permissions to Script Hub's Folder. (e.g. The script is not in Program Files)"
        errMsg .= "`n  2) Try running the script as Admin."
        errMsg .= "`nClosing script."
        MsgBox,0,, %errMsg%
        IfMsgBox, OK
            ExitApp
        IfMsgBox, Cancel
            return
    }
    OutputDebug, % "Pointer Version Saved!"
    ICSHVersionPickerGuiClose()
}

; Closes the current Script
ICSHVersionPickerGuiClose()
{
    scriptHubLoc := A_LineFile . "\..\..\..\ICScriptHub.ahk"
    Run, %scriptHubLoc%
    ExitApp
}

; Attempts to find the best recommendation for platform and version.
ChooseRecommendation()
{
    global VersionPickerPlatformDropdown
    defaultPaths := []
    defaultPaths[1] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\" ; Steam
    defaultPaths[2] := "C:\Program Files\Epic Games\IdleChampions" ; Epic
    defaultPaths[3] := "%AppData%\..\Local\Kartridge.kongregate.com\games\309647" ; Kartridge
    defaultPaths[4] := "" ; CNE
    settingsJSONPath := A_LineFile . "\..\..\Settings.json"
    settings := LoadObjectFromJSON( settingsJSONPath )
    settingsGamePath := settings.InstallPath

    hWnd := WinExist("ahk_exe IdleDragons.exe")
    if(!hWnd)
        hWnd := WinExist("ahk_exe " . settings.ExeName )
    WinGet, pPath, ProcessPath, % "ahk_id " hWnd
    exePath := pPath . "\..\"

    if(exePath != "\..\")
        platform := CheckPlatformByPath(exePath)
    if(!platform)
        platform := CheckPlatformByPath(settingsGamePath)
    if(!platform AND hWnd)
        platform := CheckPlatformByLoadedModules()
    for k,gamePath in defaultPaths
    {
        if(platform)
            break
        platform := CheckPlatformByPath(gamePath, false)
    }

    if(exePath != "\..\")
        version := CheckVersionByPath(exePath)
    checkVersion := platform ? true : false
    if(!version)
        version := CheckVersionByPath(settingsGamePath, checkVersion)
    for k,gamePath in defaultPaths
    {
        if(version)
            break
        version := CheckVersionByPath(gamePath)
    }

    recommended := "Script Hub Detected: Platform (" . (platform ? platform : "Unknown") . "), Version (" . (version ? version : "Uknown") . ")" ; CheckVersionByExePath()
    GuiControl,ICSHVersionPicker:, VersionPickerDetectionText, % recommended

    if(platform)
        GuiControl, choosestring, VersionPickerPlatformDropdown, %platform%
    VersionPickerUpdateVersions()
    closest := 0
    for k,v in GameObj[VersionPickerPlatformDropdown]
    {
        if (version == k)
        {
            closest := version
            break
        }
        else if (version > k AND closest < k)
        {
            closest := k
        }
        else if (version < k)
        {
            closest := k
            break
        }
    }

    successMessage := (version == closest) ? "A match has been selected." :  "The closest match has been selected."
     versionTextColor := (version == closest AND version != "") ?  "cGREEN" : "cF18500"
    importsVersionMessage := ""
    if(platform == "" AND version == "")
        importsVersionMessage := ""
    else if(platform AND version == "")
        importsVersionMessage .= "Unknown version. Selected [" . closest . "], Script [" . GetImportsVersion(platform, version, closest) . "]"
    else if(GetImportsVersion(platform, version, closest) == version)
        importsVersionMessage .= "Imports match version [" . GetImportsVersion(platform, version, closest) . "]." 
    else
        importsVersionMessage .= "Imports version mismatch. Game [" . version . "], Script [" . GetImportsVersion(platform, version, closest)  . "]`nCheck Discord and Github for updated Imports"
    textColor := IsVersionMatchToImports(platform, version, closest) ? "cGREEN" : "cF18500"
    GuiControl, choosestring, VersionPickerVersionDropdown, %closest%
    if(version AND platform)
        GuiControl, ICSHVersionPicker:, VersionPickerSuggestionText, % successMessage
    else
        GuiControl, ICSHVersionPicker:, VersionPickerSuggestionText, % "Unsuccessful detection. Please manually select."
    Gui,Font, bold +%versionTextColor%
    GuiControl, ICSHVersionPicker:Font, VersionPickerSuggestionText, 
	Gui,Font, bold +%textColor%
    GuiControl, ICSHVersionPicker:Font, VersionPickerSuggestionText2, 
    Gui,Font,
    GuiControl, ICSHVersionPicker:, VersionPickerSuggestionText2, % importsVersionMessage
}

; Will check paths to get a guess at platform.. both what's saved in Script Hub and what's used by the currently running IdleDragons.exe
; Use WRL to also check platform.
; Attempts to retrieve platform information using currently running IdleDragons.exe path location.
CheckPlatformByPath(gamePath, checkPath := True)
{
    platform := ""
    if(!gamePath)
        return ""
    if(checkPath)
        platform := CheckPlatformByPathContents(gamePath)
    if(!platform)
        platform := CheckPlatformBySettingsOverride(gamePath)
    if(!platform)
        platform := CheckPlatformByWRL(gamePath)
    return platform
}

; check platform based on game path 
CheckPlatformByPathContents(gamePath)
{
    if(InStr(gamePath, "steam", False))
        return "Steam"
    if(InStr(gamePath, "Epic", False))
        return "EGS"
    CNELauncherPath := gamePath . "..\IdleDragonsLauncher.exe"
    if(FileExist(CNELauncherPath))
        return "CNE"
    if(InStr(gamePath, "Kartridge", False))
        return "Kartridge"
    return ""
}

; check platform by settings-override.txt
CheckPlatformBySettingsOverride(gamePath)
{
    settingsOverridePath := gamePath . "IdleDragons_Data\StreamingAssets\settings-override.txt"
    settingsOverride := LoadObjectFromJSON( settingsOverridePath )
    settingPlatform := ""
    if(settingsOverride != "" AND settingsOverride.platform != "")
        settingPlatform := settingsOverride.platform
    return GetPlatformNameByID(settingPlatform)
}

; check platform by WRL
CheckPlatformByWRL(gamePath)
{
    global WRLPath
    WRLPath := gamePath . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
    return GetPlatformNameByID(GetDataFromWRL("network_id=", "&"))
}

; tries to find a platform based on dlls loaded in IdleDragons.exe
CheckPlatformByLoadedModules()
{
    main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
    loc := main.getModuleBaseAddress("IdleDragons.exe")
    steamDLL := Main.getModuleBaseAddress("steam_api64.dll")
    if (steamDLL != -1)
        return "Steam"
    kartridgeDLL := Main.getModuleBaseAddress("kartridge-sdk.dll")
    if(!kartridgeDLL) ; steam and EGS include kartridge dll while CNE does not. Kartridge not tested but assumed use it because Kartridge.
         return "CNE" 
    ;kartridgeDLL := Main.getModuleBaseAddress("kartridge.dll")
        ;return "Kartridge"         
    ;CNEDLL := Main.getModuleBaseAddress("cne.dll")
        ;return "CNE"
    ;EGSDLL := Main.getModuleBaseAddress("EGS.dll")
        ;return "EGS"
    return ""
}

; returns platform name based on an ID
GetPlatformNameByID(platformID)
{
    Switch platformID
    {
        Case 11:
            return "Steam"
        Case 18:
            return "CNE"
        Case 20:
            return "Kartridge"
        Case 21:
            return "EGS"
        Default:
            return ""
    }
    return ""
}

; Attempts to retrieve version based on game's path.
CheckVersionByPath(gamePath, checkPath := True)
{
    if(!gamePath)
        return ""
    dllPath := gamePath . "IdleDragons_Data\Managed\Assembly-CSharp.dll"
    version := ""
    ; Check version by DLL .NET Reflection
    try
    {
        version := CheckDLLVersion(dllPath)
    }
    ; Use WRL to also check version.
    if(!version)
        version := CheckVersionByWRL(gamePath)
    return version
}

; check platform by WRL
CheckVersionByWRL(gamePath)
{
    global WRLPath
    WRLPath := gamePath . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
    return GetDataFromWRL("mobile_client_version=", "&")
}

; Check DLL for version info
CheckDLLVersion(dllPath)
{
    
    cSharp =
    (
        using System;
        using System.Reflection;

        class ICVersionGrabber
        {
            public string GetVersion(string location = @".\IdleDragons_Data\Managed\Assembly-CSharp.dll")
            {
                    Assembly asmCSharp = Assembly.LoadFrom(location);
                    Type gameSettingsType = asmCSharp.GetType("CrusadersGame.GameSettings");
                    FieldInfo mcv = gameSettingsType.GetField("MobileClientVersion");
                    FieldInfo vpf = gameSettingsType.GetField("VersionPostFix");
                    var version = mcv.GetValue(null);
                    var postfix = vpf.GetValue(null);
                    return version.ToString() + postfix.ToString();
            }
        }
    )

    GSObj := CLR_CreateObject( CLR_CompileC#( cSharp, "System.dll" ), "ICVersionGrabber")
    try
    {
        version := GSObj.GetVersion(dllPath)
    }
    catch except
    {
        throw except
    }
    return version
}

IsVersionMatchToImports(platform, version, closest)
{
    importsVersion := GetImportsVersion(platform, version, closest)
    if(version == importsVersion)
        return true
    else
        return false
}

GetImportsVersion(platform, version, closest := 0)
{
    is64bit := GetArchitectureByPlatformAndVersion(platform, version)
    if (is64bit == "")
        is64bit := GetArchitectureByPlatformAndVersion(platform, closest)
    if(is64bit)
        importsVersion := g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64
    else
        importsVersion := g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32
    return importsVersion
}

GetArchitectureByPlatformAndVersion(platform, version)
{
    if(GameObj AND GameObj[platform] AND GameObj[platform][version])
        is64Bit := GameObj[platform][version]["is64"]
    return is64Bit
}

; Attempts to verify working pointers by checking if a valid game version can be read.
; Probably even iterate through all pointers if everything else fails just to see if something comes back with seemingly relevant info.
; user needs to have the right Offsets before trying the pointer otherwise they probably won't get good info 
; if while checking pointers one tries to access unavailable memory and crashes IC.. that'd be a problem
; Will attempt with most recent pointers to see if version is readable/within limits and pull info from that if possible.
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
ChooseRecommendation()

#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
; Reset Addon Includes
AddonIncludes := ".\AddOns\GeneratedAddonInclude.ahk"
FileDelete, %AddonIncludes%
; copy AddonManagement.json to SH_Addon_Management from IC_Addon_Management
 if FileExist(".\Addons\IC_Addon_Management\AddonManagement.json")
 {
    if !FileExist(".\Addons\SH_Addon_Management\AddonManagement.json")
    {
        FileCopy, .\Addons\IC_Addon_Management\AddonManagement.json, .\Addons\SH_Addon_Management\AddonManagement.json 
    }
 }
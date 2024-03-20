#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
; Reset Addon Includes
AddonIncludes := ".\AddOns\GeneratedAddonInclude.ahk"
FileDelete, %AddonIncludes%
/*
    To include an add-on, place the add-on folder in the AddOns directory and add an #include line in this file to its primary .AHK location.
    To temporarily remove an AddOn's functionality, remove (or comment) its #include line from this file.
*/

; Inclusion of an Addon Manager this will control the includes of other addons.
; If you don't want to use the Addon Manager, you can include other addons manually here
#include *i %A_LineFile%\..\SH_Addon_Management\SH_Addon_Management_Includes.ahk



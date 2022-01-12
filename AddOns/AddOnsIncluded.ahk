/*
    To include an add-on, place the add-on folder in the AddOns directory and add an #include line in this file to its primary .AHK location.
    To temporarily remove an AddOn's functionality, remove (or comment) its #include line from this file.

    Future TODO: Add each folder's primary AHK by adding [foldername]_Component.ahk 
*/

#include *i %A_LineFile%\..\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Component.ahk
#include *i %A_LineFile%\..\IC_GameLocationSettings\IC_GameLocationSettings_Component.ahk
#include *i %A_LineFile%\..\IC_MemoryFunctions\IC_MemoryFunctions_Component.ahk
#include *i %A_LineFile%\..\IC_InventoryView\IC_InventoryView_Component.ahk
#include *i %A_LineFile%\..\IC_MemoryFunctionsFullRead\IC_MemoryFunctionsFullRead_Component.ahk
#include *i %A_LineFile%\..\IC_Jimothy\IC_Jimothy_Component.ahk
#include *i %A_LineFile%\..\IC_ChestPurchaser\IC_ChestPurchaser_Component.ahk
#include *i %A_LineFile%\..\IC_About\IC_About_Component.ahk
#include *i %A_LineFile%\..\IC_DashCheck\IC_DashCheck_Component.ahk
# Shared Functions
## Description

These functions are intended to be shared among many scripts. They are built with a class based structure so object oriented programming methods can be practiced.

## Important Included Files

> CLR.ahk  

CLR contains various functions that allow for use with managed libraries (written C#/VB). Required for IC_SaveHelper_Class.ahk. No longer in use.

> SH_ArrayFunctions.ahk

Contains functions for copying arrays and for viewing decimal and hex number arrays as strings. If this file is included, a script may access these functions through **ArrFnc.[FunctionName]\(\)**

> SH_GUIFunctions.ahk

Contains expanded functions for handling or updating GUI elements. If this file is included, a script may access these functions through **GUIFunctions.[FunctionName]\(\)**

`LV_Scope` is used whenever a listview is updated in order to ensure the correct listview gets updated. 

> SH_KeyHelper.ahk  

SH_KeyHelper helps convert keystrokes to a virtual key code and scancode key code which are used in SendMessage and PostMessage commands. It allows for expanded compatibility for international keyboards and more control than standard Send and SendInput ahk commands.

> SH_SharedFunctions.ahk

Has includes to collections of commonly used and basic functions that could be expected to be used in a script interacting with the associated game.

> SH_UpdateClass.ahk

SH_UpdateClass is used to overwrite AHK classes. Since AHK does not protect class fields and functions, this class can be used for simple updates to instances of the classes when they require modified functionality for addons.

> SH_VersionHelper.ahk

SH_VersionHelper contains a function which can be used to compare version numbers that are in a specific format. It is used for managing Addons properly.

> json.ahk  

json is a library that allows for common json functionality such as loading and saving json to files. It has been expanded from the original to include json formatting functions.

> ObjRegisterActive.ahk  

ObjRegisterActive contains various functions written primarily by ahk's lexikos that expand functionality of AHK.

`ObjRegisterActive` creates a comobject that can be used to interact directly with the script from another script.  

> MemoryRead\classMemory.ahk

classMemory is a library required for any game memory interaction. All scripts rely heavily on this to read game states.
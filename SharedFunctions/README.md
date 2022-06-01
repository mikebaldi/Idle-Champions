# Shared Functions
## Description

These functions are intended to be shared among many scripts. They are built with a class based structure so object oriented programming methods can be practiced.

## Important Included Files

> CLR.ahk  

CLR contains various functions that allow for use with managed libraries (written C#/VB). Required for IC_SaveHelper_Class.ahk.

> IC_ArrayFunctions_Class.ahk

Contains functions for copying arrays and for viewing decimal and hex number arrays as strings. If this file is included, a script may access these functions through **ArrFnc.[FunctionName]\(\)**

> IC_GUIFunctions_Class.ahk

Contains expanded functions for handling or updating GUI elements. If this file is included, a script may access these functions through **GUIFunctions.[FunctionName]\(\)**

`LV_Scope` is used whenever a listview is updated in order to ensure the correct listview gets updated. 

> IC_KeyHelper_Class.ahk  

IC_KeyHelper_Class helps convert keystrokes to a virtual key code which is used in SendMessage and PostMessage commands. It allows for expanded  compatability for international keyboards and more control than standard Send and SendInput ahk commands.

> IC_SaveHelper_Class.ahk

IC_SaveHelper_Class is used for building save server call strings. Currently mainly used to force stack conversion on resets.

> IC_SharedFunctionsClass.ahk

IC_SharedFunctionsClass has a collection of commonly used and basic functions that could be expected to be used in a script interacting with Idle Champions. This is the place to look before writing your own custom functions.

Some examples include:  
`ToggleAutoProgress` - Toggles the game's autoprogress feature.  
`DirectedInput` - Sends keyboard input to the game.  
`OpenIC` - Opens the game and determines when it is fully loaded.  
`CloseIC` - Closes the game. Forces it closed after 10 seconds.  
`SetUserCredentials` - Stores UserID, Hash, InstanceID and some commonly used user data for use in server calls.

> json.ahk  

json is a library that allows for common json functionality such as loading and saving json to files. It has been expanded from the original to include json formatting functions.

> ObjRegisterActive.ahk  

ObjRegisterActive contains various functions written primarily by ahk's lexikos that expand functionality of AHK.

`ObjRegisterActive` creates a comobject that can be used to interact directly with the script from another script.  

> MemoryRead\classMemory.ahk

classMemory is a library required for any game memory interaction. All scripts rely heavily on this to read game states.

> MemoryRead\IC_EngineSettings_Class.ahk

IC_EngineSettings_Class reads data from the game's static EngineSettings object. It is used to retrieve the current server the game is connecting to. 

> MemoryRead\IC_GameManager_Class.ahk

IC_GameManager_Class is the **first** place to look to update offsets to data read from the game. It contains many offsets for things ranging from game speed to loot/chest/buffs to autoprogress to current area and just about anything in between. The offsets are based on the 32-bit (Steam) version of the game.

> MemoryRead\IC_GameObjectStructure_Class.ahk

IC_GameObjectStructure_Class is used by other memory scripts to control how offsets are created, interpreted and read. It should not need to modified, but is fundamental to how the game objects are structured.

> MemoryRead\IC_GameSettings_Class.ahk

IC_GameSettings_Class contains the offsets for the games static GameSettings object. It includes important information such as *UserID*, *User Hash*, *Version*, *Instance ID*. These memory reads are required reading data used in IC_ServerCalls_Class.ahk.

> MemoryRead\IC_MemoryFunctions_Class.ahk

**Important**: IC_MemoryFunctions_Class contains functions that simplify memory reading. Use this class's functions to read important information from the game. It utilizes the other classes in the diretory and simplifies their read calls. Although most things *can* be done without these functions, using them will greatly simplify code. 




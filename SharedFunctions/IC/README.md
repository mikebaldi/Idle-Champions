# Shared Functions
## Description

These functions are intended to be shared among many scripts. They are built with a class based structure so object oriented programming methods can be practiced.

## Important Included Files

> IC_SaveHelper_Class.ahk

IC_SaveHelper_Class is used for building save server call strings. Currently mainly used to force stack conversion on resets.

> IC_SharedFunctions_Class.ahk

IC_SharedFunctionsClass has a collection of commonly used and basic functions that could be expected to be used in a script interacting with Idle Champions. This is the place to look before writing your own custom functions.

Some examples include:  
`ToggleAutoProgress` - Toggles the game's autoprogress feature.  
`DirectedInput` - Sends keyboard input to the game.  
`OpenIC` - Opens the game and determines when it is fully loaded.  
`CloseIC` - Closes the game. Forces it closed after 10 seconds.  
`SetUserCredentials` - Stores UserID, Hash, InstanceID and some commonly used user data for use in server calls.

> MemoryRead\IC_ActiveEffectKeyHandler_Class.ahk

IC_ActiveEffectKeyHandler_Class is used for handling ``Champion Abilities``. **IMPORTANT:** This file also contains ``ActiveEffectKeySharedFunctions`` which is the ``interface`` for getting memory reads about Champion abilities.  The offsets used can be found/updated in the ``MemoryRead\Imports\ActiveEffectHandlers\`` folder.

> MemoryRead\IC_EngineSettings_Class.ahk

IC_EngineSettings_Class reads data from the game's static EngineSettings object. It is used to retrieve the current server the game is connecting to. 

> MemoryRead\IC_GameObjectStructure_Class.ahk

IC_GameObjectStructure_Class is used by other memory scripts to control how offsets are created, interpreted and read. It should not need to modified, but is fundamental to how the game objects are structured.

> MemoryRead\IC_GameSettings_Class.ahk

IC_GameSettings_Class contains the offsets for the games static GameSettings object. It includes important information such as *UserID*, *User Hash*, *Version*, *Instance ID*. These memory reads are required reading data used in IC_ServerCalls_Class.ahk.

> MemoryRead\IC_IdleGameManager_Class.ahk

IC_IdleGameManager_Class is the **first** place to look to update offsets to data read from the game. It contains many offsets for things ranging from game speed to loot/chest/buffs to autoprogress to current area and just about anything in between. The offsets are based on the 32-bit (Steam) version of the game.

> MemoryRead\IC_MemoryFunctions_Class.ahk

**Important**: IC_MemoryFunctions_Class is the interface that contains functions that simplify memory reading. Use this class's functions to read important information from the game. It utilizes the other classes in the directory and simplifies their read calls. Using the functions in this file (except ``GenericGetValue``) is the best way to make sure addons remain compatible with Script Hub.  


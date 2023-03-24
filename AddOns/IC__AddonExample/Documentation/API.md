# API

There is a vast amount of functionality available through the code included with Script Hub that can simplify creating an addon.

## Common functions
For an overview see [Shared Functions Suite](./../../../SharedFunctions/README.md).

``SharedFunctions\IC_SharedFunctions_Class.ahk`` in particular contains manly commonly used functions for interacting with the game.
## Reading Memory
``SharedFunctions\Memory\IC_MemoryFunctions_Class.ahk`` contains functions for simple reads on the game's memory. 

## Expanding Memory Reading 
If there is a value in memory that you wish to add and you know its location (e.g. you found it in Cheat Engine), you can use the [AutomaticOffsets tool](https://github.com/antilectual/ScriptHub-AutomaticOffsets) to generate imports that will link to the memory location. See the [documentation](https://github.com/antilectual/ScriptHub-AutomaticOffsets/blob/main/README_MODIFYING.md) for how to easily add it to the list of values that are generated with imports.

To use those pointers it is best to create functions using the techniques that are used in ``SharedFunctions\Memory\IC_MemoryFunctions_Class.ahk`` since Script Hub's method of reading values is subject to change but a function can be modified to use the new methods.

## Server Interaction
``ServerCalls\IC_ServerCalls_Class.ahk`` contains functions used to interact directly with the game server API.
See [Server Calls](./ServerCalls.md) (Coming Soon...)

## Themes
See [Themes](./Themes.md).


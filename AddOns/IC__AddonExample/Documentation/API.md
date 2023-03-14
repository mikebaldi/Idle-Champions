# API

There are vast amount of functionality available through the code indluded with Script Hub that can simplify creating an addon.

## Common functions
``SharedFunctions\IC_SharedFunctions_Class.ahk`` contains commonly used functions for interacting with the game.

## Reading Memory
``SharedFunctions\Memory\IC_MemoryFunctions_Class.ahk`` contains functions for simple reads on the game's memory. 

## Expanding Memory Reading 
If there is a value in memory that you wish to add and you know its location (e.g. you found it in Cheat Engine), you can use the AutomaticOffsets tool to generate imports that will link to the memory location. See the documentation for how to easily add it to the list of values that are generated with imports.

To use those pointers it is best to create functions using the techniques that are used in ``SharedFunctions\Memory\IC_MemoryFunctions_Class.ahk``.

## Server Interaction
``ServerCalls\IC_ServerCalls_Class.ahk`` contains functions used to interact directly with the game server API.

## Themes
See [Themes](./Themes.md).
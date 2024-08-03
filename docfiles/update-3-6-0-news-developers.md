## **Simplified ActiveEffectHandlers** 
Simplified the process of creating new champion ability handlers.  
See the [README](../SharedFunctions/MemoryRead/HeroHandlers/README.md).  

## **Streamlined collection access**  
``GenericGetValue`` is no longer needed. It has been merged into game objects. Use ``<Game Object>.Read()`` instead.
``GetGameObjectFromListValues`` is no longer needed. Game Objects that contain collections can now use more intuitive indexing. It should now be much easier to see from code where lists/dictionaries are being used.

Example:  

Previously:  
```ahk
g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.gameInstances.Controller.UserData.HeroHandler.heroes.allUpgradesOrdered.size.GetGameObjectFromListValues(0, v - 1))
```

Now:  
```ahk
g_SF.Memory.GameManager.Game.gameInstances[0].Controller.UserData.HeroHandler.heroes[v - 1].allUpgradesOrdered.size.Read()
```

Dictionaries are treated as lists in Script Hub. The index will accept three different styles.  
**Dictionary[``"key", index``]** - Will return a game object for the key at the collection index.  
**Dictionary[``"value", index``]** - Will return a game object for the value at the collection index.  
**Dictionary[``"string"``]** or **Dictionary[``<integer>``]** - Will return a game object for the value of the dictionary entry that contains the key matching the string or number.  


## **Example Addon**  
Added an addon with tons of documentation and sample code to demonstrate a number of tools available to addon developers.
Start with the [Documentation](../AddOns/IC__AddonExample/Documentation/index.md).  

## **Pointer Builder**  
Created a new repository that has a simple AHK script that can simplify building the pointer file used in the script.  
See the repo [Here](https://github.com/antilectual/IC_PointerBuilder).  
The repo also contains a [CT file](https://github.com/antilectual/IC_PointerBuilder/blob/main/IC_Script_Hub_Ptrs_Helper.ct) to simplify finding pointers, especially the static ones.  

To understand how to use CE to find pointers, read the instructional information in the following files:  
[Standard Pointers (IdleGameManager)](how-to-find-idle-champions-pointers-with-cheat-engine.md)  
[Static Pointers (Most others)](../GameSettingsStaticInstructions.pdf)  
[Offsets (No longer needed, but here for informational purposes)](how-to-update-memory-read-offsets-using-cheat-engine.md)  
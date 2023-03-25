# **Injection**
> **``WARNING:``** Overwriting functions of another class will affect ALL uses of it and can potentially break Addons or even Script Hub functionality. Use with caution!

Injection is a method of overwriting existing functionality with your own and/or adding new functions to an already existing class. 
The basic steps to accomplish this are:
1. Create a class that contains functions with the same name as a function you wish to replace in another class object in script hub (replace) or with newly created functions (add).
2. Update the functions in the target class with your own by:  
   1. Use ``IC_UpdateClass_Class.UpdateClassFunctions(<target class object>,<your custom class>)`` to update the functions in the target class object with your custom built functions in your own custom class.  ... **_Or_** ...
   2.  Set the global variable that contains an the instance of the class you wish to update as a new instance of your custom class.  
    > Examples found in [Example_BrivGemFarm_Extends_Addon.ahk](./../Example_Extends/Example_BrivGemFarm_Extends_Addon.ahk)
3. ``[BrivGemFarm]`` Add your updates to the Briv Gem Farm mods. This is done by appending the #include to the file set in ``g_BrivFarmModLoc``. See [Inject() example.](./../Example_Extends/Example_BrivGemFarm_Extends_Component.ahk)

> Note: It is important that the injecting addon is loaded **after** any code that it is injecting into. Be sure to include those addons as dependencies in the Addon.json file.



See [full example](./../Example_Extends/) of how this is done with line by line explanations.
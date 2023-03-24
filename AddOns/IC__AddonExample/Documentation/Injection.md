# **Injection**
> **``WARNING:``** Overwriting functions of another class will affect ALL uses of it and can potentially break Addons or even Script Hub functionality. Use with caution!

Injection is a method of overwriting existing functionality with your own. 
The basic steps to accomplish this are:
1. Create a class that contains functions with the same name as a function you wish to replace in another class object in script hub.
2. Use ``IC_UpdateClass_Class.UpdateClassFunctions(<target class object>,<your custom class>)`` to replace the function in the target class object with your custom built function in your own class.

See [example](./../Example_Injection/) example of how this is done with line by line explanations.
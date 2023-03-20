# ADDON FILE STRUCTURE <!-- omit from toc -->

* [Naming](#naming)  
* [Standard Addon Files](#standard-addon-files)

## Naming  
There are no required naming requirements for addons folders, however the recommended standard is to use the format of IC_AddonName. 

While developing an addon you can start the name with ``IC_Test`` or start the name with ``IC_`` and end the name with  ``_Extra`` to have the addon be ignored by the Script Hub repository. This will make it simpler to continue to update Script Hub during addon development.

## Standard Addon Files
* [Addon.json](#addonjson)  
* [\<AddonName\>_Includes.ahk](#includes)  
* [\<AddonName\>_Component.ahk](#component)  
* [\<AddonName\>_GUI.ahk](#gui)  
* [\<AddonName\>_Functions.ahk](#functions)  
* [README.md](#readmemd)
  
### **Addon.json (required)**

Required fields:  
-	**Name**: <string> The name of your addon.  
-	**Version**: The version of your addon. Must be in the format of the letter v followed by 3 revision numbers separated by periods. (e.g. v0.0.0).  
-    **Includes**: The location of the primary AHK file for your add. It is recommended that this is an includes file that only includes #include directives to your other AHK files used in the addon.  
-    **Author**: The name you want to be recognized by.  
-    **Url**: A link to the location your addon will be hosted at online. Often a github repository.  
-    **Info**: Any additional information you want to include about the addon, such as a description.  
-    **Dependencies**: A list of addons that are required for this addon to function. Each item includes the name and required version of the required addon.  

### **Includes**
The includes file is a list of #include directives that allow the addon code to be added to Script Hub. Typically this would be the the ``GUI`` file, the``Component`` file, and sometimes the ``Functions`` file.

### **Component**
The component file should be the the main code that executes when the addon is loaded. This is the core of the addon.

For simple addons, instead of using an ``Includes`` file, it is possible for the ``GUI``, ``Functions``, and executed code (``Component``) could all be combined into a single ``Component`` file which would be the AHK file set as the link under ``Includes`` in the addon.json. This is generally not recommended though.

### **GUI**
Build any addon GUI in the ``GUI`` file. 

There are functions available to your addon via the global object ``GUIFunctions`` that can simplify some common addon GUI functions, such as adding a new Tab for the addon. These functions can be found in the ``\SharedFunctions\IC_GUIFunctions_Class.ahk`` file.

### **Functions**
The main functions and algorithms used by your addon should be in the Functions folder. It is highly recommended to nest functions in a class object in order to reduce the risk of conflicting with previously defined functions. Class names should follow the format of ``AddonFolder_Class`` (e.g. an addon named ``Example`` in ``IC_Example_Addon`` folder would have a class named ``IC_Example_Addon_Class``). If there will be functions used to override functions from another addon they should be in their own class that includes the name of the class they want to override. (e.g.  if overriding ``IC_SharedFunctions_Class`` you would create a class like ``IC_Example_Addon_SharedFunctions_Class``. Use ``extends IC_SharedFunctions_Class`` to add new functions rather than overriding them). 

### **README.md**

It is recommended to include a README.md file for every addon to help people understand it at a deeper level than what is given by the Addons description.



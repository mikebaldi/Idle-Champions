## **Updates**

### **Architectual Changes**  
Script Hub has been refactored to be more generic. IC specific functionality has been contained entirely within addons. The shared functions are now part of the ``IC_Core`` addon. 

### **Macro Recorder**
An open source macro recorder has been added to the base script to allow for recording your own scripts! (``Exit`` button is under ``[F9]Options``).

>Hint: Try recording clicking for using bounty contracts.

### **Key Send**
Update Key sending to work with newer versions of unity where the update caused keys like left/right/` to fail.
  
&nbsp;  
## **For Addon Developers**

### **Updating Addons**  
Due to the new changes, ``IC_Core`` will nearly always be a dependency for addons (``IC_SharedFunctions_Class`` is located in the ``IC_Core`` addon).

Addons will also need to the ``#include``s be updated to point to the new file locations (e.g. ``IC_UpdateClass_Class.ahk`` is now ``SH_UpdateClass.ahk``).

### **Stack and Queue support.**  
Script should now be able to properly read Stacks and Queues in memory.

### **RNG**  
Based on [ImpEGamer](https://github.com/imp444/)'s work, the C# RNG code has been added to SharedFunctions.
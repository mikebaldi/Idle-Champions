## INSTRUCTIONS FOR ADDING NEW HERO ABILITIES TO READ:
First, using the AutomaticOffsets/Import tool, add the champion's ability information using the instructions here:  
https://github.com/antilectual/ScriptHub-AutomaticOffsets/blob/main/README_MODIFYING.md  
Copy the generated imports to the SharedFunctions\MemoryRead\Imports directory.  
Create a file in the SharedFunctions\MemoryRead\HeroHandlers\ directory using the format IC_<CHAMPION NAME>.ahk  
Follow the template outlined in __Template.ahk in this folder to create a custom class for the champion.  
Add the include to the new file at the bottom of the list of #includes in ``IC_ActiveEffectKeySharedFunctions_Class.ahk`` using the same format as used.  
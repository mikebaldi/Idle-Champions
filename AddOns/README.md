# AddOns
## Including Addons
To include an add-on, place the add-on folder in the AddOns directory and add an #include line in this file to its primary .AHK location.
To temporarily remove an AddOn's functionality, remove (or comment) its #include line from this AddOnsIncluded.ahk file.
Using *i in the include will make the script not report an error if the Addon is missing. If your addon is not showing up and you want to track down why, it is recommended you do not include *i until you know it is working.  

## Building Addons   
  
Addons are extra functionality that can be added to the main script. The benefit of using the Addon structure is that any Addon automatically has access to SharedFunctions through the g_SF global variable and MemoryRead functions through g_SF.Memory. There is no need to include them separately in a new script. They also have access to other addons. 

> **Note:** AddOns\IC_InventoryView\ is recommended as an example.


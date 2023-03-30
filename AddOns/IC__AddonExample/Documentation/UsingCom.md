# Using ComObjects to Talk Between Scripts

# Libraries
- ``\SharedFunctions\ObjRegisterActive.ahk``  
Required for ComObject usage in AHK

- ``\SharedFunctions\IC_SharedFunctions_Class.ahk``  
For writing JSON to files with ``WriteObjectToJSON``

## ``Creating a ComObject``

A script that wants to allow another script to talk to it needs to create a ComObject for itself with a unique ID. 

Create a GUID for the unique iD:  
``g_guid := ComObjCreate("Scriptlet.TypeLib").Guid``

There are several ways to keep track of the GUID between scripts but Script Hub tends to use one of two methods.  
1. Script Hub generates a GUID and passes it to the second script via a parameter when running the script. (See [Miniscripts](#miniscripts))  
   
3. The script generates a GUID for itself and saves it in a json file (e.g. ``LastGUID_BrivGemFarm.json``). This method is typically used when the script is run independently of Script Hub so Script Hub can later find the GUID and use it to talk to the script.

Once a unique identifier is generated, active the ComObject using: 
```ahk
ObjRegisterActive(<SharedDataClass>, <guid>)
```
Where ``<SharedDataClass>`` is the class in the script that has fields or functions that need to be shared and ``<guid>`` is the unique identifier that is to be tied to this script/class.

In order to keep a persistent guid or to leave a method of other scripts knowing the guid a file should be created which contains the guid being used.
```ahk
g_SF.WriteObjectToJSON(A_LineFile . "\..\LastGUID_OpenProcessReader.json", guid)
```
> Note: g_SF is variable that contains an instance of the ``SharedFunctions`` class.

## ``Talking to a ComObject``

To talk to a script who has an activated ComObject, set a variable with ``<guid>`` being the unique identifier assigned to the ComObjet when ``ObjRegisterActive`` was used:
```ahk
SharedData := ComObjActive(<guid>)
```

Due to AHK throwing errors whenever it tries to read from a ComObject it is recommended to use try catch blocks when using them. 

Simple try:
```ahk
    try ; avoid thrown errors when comobject is not available.
    {
        local SharedRunData := ComObjActive(<guid>)
        fieldData := SharedRunData.FieldData
    }
```

For common reuse of the ComObject, a class property may be a useful way of getting the ComObject without errors.
```ahk      
    class MyClass
    {
        SharedData[]
        {
            get 
            {
                try
                {
                    return ComObjActive(<guid>)
                }
                catch, Err
                {
                    return ""
                }
            }
        }
    }
```
  
## ``Closing a ComObject``

Before a script using ComObjects closes it should remove its register with windows.  Using the ``ObjRegisterActive`` function with a null (i.e. ``""``) second parameter will accomplish this. 

It is recommended that this is done using the OnExit function which is automatically run when a script is closed.

```ahk
OnExit(ComObjectRevoke())

ComObjectRevoke()
{
    ObjRegisterActive(g_MoveGameWindow_Mini, "")
    ExitApp
}
```

# ``Useful Directives For Scripts``

``#SingleInstance force`` - Only allow one copy of the script to run at once.  
``#NoTrayIcon`` - Hides AHK icon from the tray.  
``#Persistent`` - Keeps the script running even if there is no GUI or hotkeys.  

# ``BrivGemFarm Specifics``

BrivGemFarm's guid is stored in the variable ``g_BrivFarm.GemFarmGUID``.
Example:
```ahk
sharedData := ComObjActive(g_BrivFarm.GemFarmGUID) ; Connect to gem farm.
shinyCount := sharedData.ShinyCount                ; retrieve a count of shinies found.
sharedData.Close()                                 ; Close the BrivGemFarm script.
```
## **Expanding BrivGemFarm capabilities**
An addon that modifies the behavior of BrivGemFarm can take advantage of BrivGemFarm's ComObject by adding additional fields or functions to the ``IC_SharedData_Class`` class. Once modified, Script Hub addons can utilize BrivGemFarm's ComObject to interact with those fields/functions.

## **Miniscripts**
A miniscript is a small addon script that is run when BrivGemFarm is run. They typically only perform one simple task, often on a timer.
BrivGemFarm keeps tracks of miniscripts using the ``g_Miniscripts`` variable. An addon can add its script to this variable with:  

```ahk
    g_guid := ComObjCreate("Scriptlet.TypeLib").Guid   
    g_Miniscripts[g_guid] := A_LineFile . "\..\IC_<AddOn>_Mini_Run.ahk"  
```

The ``IC_<AddOn>_Mini_Run.ahk`` script will also need to be able to accept the guid parameter when run and open its ComObject with it:  

    ObjRegisterActive(g_<AddOn>_Mini, A_Args[1])





    

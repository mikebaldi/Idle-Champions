# Timers and Briv Gem Farm
There are two styles of timer scripts that can be used with the BrivGemFarm addon in Script Hub. Both styles will be started/stopped when using the start/stop buttons of the BrivGemFarm addon.  

1. Independent scripts that have their own timers, but the execution and stopping of the scripts are controlled by Script Hub.
Sample code can be found in [Example_Timer](./../Example_Timer/)  

2. Functions that are run on a timer directly by Script Hub. This style is what is used for updating the GUI in tabs like Stats and MemoryRead.
Sample code can be found in [Example_Timer2](./../Example_Timer2/)  

>Note: The examples above have sample code that is part of the AddonExample addon. As such they are not split into the usual Includes/GUI/Functions/Component structure that is standard for addons.  

>Note: These addons are disabled by default. To see the code in action, enable the corresponding include in the [Example_Includes](./../Example_Includes.ahk) file and reload Script Hub. Press the play button in Briv Gem Farm to start the activated timer(s), and the stop button to turn them off. After pressing play, manually closing the BrivGemFarm script will stop the gem farm but the timers will continue to run until the stop button is pressed.  

## 1. Independent Scripts

This style of addon will run a script that include timed functions. These scripts do not require timers and can be customized to do any behaviors, but for the purpose of these instructions timed functions will be what's focused on.  

At minimum, two script files are required. One for code that will be loaded into Script Hub as an addon, and the other as a Script that runs independently. For convention it is recommended to add "_Run" to the end of the independent script's name to denote that it will run on its own.  

In the example provided the Example Addon's ``Example_Includes.ahk`` includes the ``Example_BrivGemFarm_TimerScript.ahk`` script. This included script simply does two things:  
1. Creates a GUID to give the independent script being run its own unique identifier for script to script communications.  
2. Adds the independent script's file location to Script Hub's list of scripts (``g_Miniscripts``) that will be automatically run when a Gem Farm is started.  

The independent script contains a function that will be called on a timer, methods to start that timed function, and a ``Close()`` function that is executed when the Briv Gem Farm stop button is pressed. Executing the script will start any timed functions and the script will continue to run until it is terminated from the Windows Task Manager or a call to the ``Close()`` function. See the [example](./../Example_Timer/Example_BrivGemFarm_TimerScript_Run.ahk) for line by line explanations.  

## 2. Timer functions

To utilize timer functions, several functions are required:
1. A function (or two, as in the example) that will bind the functions to variables and then activate those functions on a timer.  
2. A function that will stop and disable the timer functions.
3. The function that will run on a timer.

Once these functions have been created they can be added to the ``g_BrivFarmAddonStopFunctions`` list variable which contains the list of functions that Script Hub will run on a timer when BrivGemFarm is started.

 See the [example](./../Example_Timer2/Example_BrivGemFarm_TimerScript2.ahk) for line by line explanations.  
# BrivGemFarm_Performance Settings File
## Description:
These are the currently available advanced settings for this AddOn. These are are for advanced users and must be set from within the ``BrivGemFarmSettings.json`` file.

## Settings: 

* **BrivJumpBuffer** - 0-2000 (zones/areas)  
This value tells the script how many areas before a modron reset zone that switching to e formation over q formation is desired. The value should be greater than the stack zone value, but less than the modron reset value. This helps resolve issues of Briv Stacks not being converted properly on modron resets.
  
* **DashWaitBuffer** - 0-? (time in ms)  
**Updated:** DashWaitBuffer has been repurposed to be a distance from your modron's reset zone where dashwait will stop being activated. Default is 30.
e.g. WIth the default value DashWait will not trigger if the script is started at 280 and then reset area is 305.
~~Sometimes DashWait timer ends before Shandie gains dash. This setting adds a value in ms to the already set DashWait time. (Largely unnecessary as you can just increase your DashWait time.)~~

* **DoChestsContinuous**: 0 / 1  
If you are not satisfied with only 100/99 Buy/Open chests per run you can set this to 1. The script will buy and open as many as it can within the stack sleep time set. 

> **Note:** The script will only open silver chests if there are at least 3 seconds left on Stack Reset Time, and will only open Gold Chests if there are at least 7 seconds left on Stack Reset time. These are estimations of how long the server takes to process the calls for opening 99 at a time. If you know these values are incorrect, or you don't mind losing BPH by waiting longer during Stack Resets, these values can be changed in the ``IC_BrivGemFarm_Functions.ahk`` script. They are set at the top of the ``BuyOrOpenChests()`` function.  

> **WARNING:** Chest purchases happen very quickly. If the maintain gems setting is set incorrectly and this option is turned on, all gems could easily be spent, especially when buying gold chests.

> Particularly interesting when using hybrid stacking strategy and restarting e.g. every 100k gems. If hybrid stacking is activated together with continuous chest, script will continue buying even after Stack Reset Time has elapsed - only way for it to stop automatically is when all non-reserved gems are spent and all chests are open.

* **ForceOfflineGemThreshold**
Activates "hybrid stacking" (a.k.a. Hamerstein method a.k.a. Tatyana stacking). Makes the script prefer stacking online regardless of what `RestartStackTime` says, but do offline stacking once in a while to clear memory leaks and buy/open chests. Specified as available gems above the normal reserved amount.

* **ForceOfflineRunThreshold**
Same as `ForceOfflineGemThreshold`, but specified as max amount of runs based on "Resets Done", as reported by current core. Reset is forced on the last run (so setting to 1 also disables this setting, every run will be offline). If both thresholds are enabled, any of them matching will trigger offline restart.

* **HiddenFarmWindow**: 0 / 1  
You can enable or disable the visibility of the second script window (the one that does the farming) by setting this value. 0 will have it show when it is run. 1 will hide it so only an icon in the tray appears.

* **ResetZoneBuffer**: 0-2000 (41 is default)
By default, the script assumes you do not want to do early stacking with Briv and that if you go 41 levels beyond your stack zone, you have your modron reset area incorrectly set. If this is not the case, you can change this value to increase the number of zones the script will go waiting for modron reset after stacking before manually resetting. Since there is an area cap of 2000, setting this to 2000 effectively disables it.

* **RestoreLastWindowOnGameOpen**: 0 / 1  
You can enable or disable whether the script will try to switch focus back to the last active window immediately when the game opens.  

* **WindowXPosition**:0
This option allows you to set where the gem farm script will appear horizontally across your screen. 0 is default and is the far left of the screen. If you have HiddenFarmWindow set to 1 there is no reason to change this.

* **WindowYPosition**:0
This option allows you to set where the gem farm script will appear vertically on your screen. 0 is default and is the very top of the screen. If you have HiddenFarmWindow set to 1 there is no reason to change this.

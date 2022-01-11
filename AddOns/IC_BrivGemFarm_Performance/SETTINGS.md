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

* **ForceDashWait**: 0 / 1  
When enabled (set to 1), this will always wait the DashWait time when calling DoDashWait.

* **HiddenFarmWindow**: 0 / 1  
You can enable or disable the visibility of the second script window (the one that does the farming) by setting this value. 0 will have it show when it is run. 1 will hide it so only an icon in the tray appears.

* **ResetZoneBuffer**: 0-2000 (41 is default)
By default, the script assumes you do not want to do early stacking with Briv and that if you go 41 levels beyond your stack zone, you have your modron reset area incorrectly set. If this is not the case, you can change this value to increase the number of zones the script will go waiting for modron reset after stacking before manually resetting. Since there is an area cap of 2000, setting this to 2000 effectively disables it.

* **WindowXPositon**:0
This option allows you to set where the gem farm script will appear horizontally across your screen. 0 is default and is the far left of the screen. If you have HiddenFarmWindow set to 1 there is no reason to change this.

* **WindowYPositon**:0
This option allows you to set where the gem farm script will appear vertically on your screen. 0 is default and is the verey top of the screen. If you have HiddenFarmWindow set to 1 there is no reason to change this.

# BrivGemFarm_Performance
## Description:
This Addon automates and optimizes gem farming by utilizing Briv swapping during transitions, offline steelbones stacking, waiting for Shandie's dash, leveling with Fkeys, opening chests while the game is closed, and numerous other speed farming features. This is the current rewrite/replacement for ModronGUI.

> **Note:** Script requires Briv and Modron Automation.

## Addon's GUI Modifications:
Adds a Briv Gem Farm tab for updating settings the addon's settings and starting the `IC_BrivGemFarm_Run.ahk`.  
  
Adds BrivGemFarm Stats box to Stats page that shows a count of swaps made during the current run, how many boss levels were reached in the current run, and how many boss levels have been hit since it started recording.

Once the settings have been saved, `IC_BrivGemFarm_Run.ahk` can be run by itself to gem farm without any GUI updates. You can run the GUI open the main script and go to the *Briv Gem Farm* tab and click connect at any point after `IC_BrivGemFarm_Run.ahk` has started in order to start reading data and getting GUI updates.

#
## Instructions:
Instructions:
1. Save your speed formation in formation save slot 1, in game hotkey "Q". This formation must include Briv and at least one familiar on the field.
2. Save your stack farming formation in formation save slot 2, in game hotkey "W". Don't include any familiars on the field.
3. Save your speed formation without Briv in formation save slot 3, in game hotkey "E".
4. Adjust the settings on the settings tab.
5. Click the save button to save your settings.
6. Load into zone 1 of an adventure to farm gems.
7. Press the run button to start farming gems.

Notes:

1. You can can settings at any point during the run by clicking Save Settings again.
2. First run is ignored for stats, in case it is a partial run.
3. Settings save to and load from `BrivGemFarmSettings.json` file.
4. Recommended SB stack level is [Modron Reset Zone] - X, with X = 4 for single skip, X = 6 for double skip, X = 8 for triple skip, and X = 10 for quadruple skip.
5. Script will activate and focus the game window for manual resets as part of failed stacking.
6. Script communicates directly with Idle Champions play servers to recover from a failed stacking and for when Modron resets to the World Map.
7. Script reads system memory.
8. Disable manual resets to recover from failed Briv stack conversions when running event free plays.
9. Recommended Briv swap sleep time is betweeb 1500 - 3000. If you are seeing Briv's landing animation then increase the the swap sleep time. If Briv is not back in the formation before monsters can be killed then decrease the swap sleep time.
10. Be sure the launcher's settings script `Settings.json` is updated to include the correct game location, otherwise offline stacking will be unable to start the game.
11. To **stop** BrivGemFarm, press the **stop button**. This will stop the continuous loading of memory reads as well. 
> **Known Issue:** The updates (Memory read, inventory) will continue to run even after BrivGemFarm has been stopped. Current workaround is to reload the script if you want the updates to stop.

Known Issues:
1. Cannot always interact with GUI while script is running.
#
## Settings: 
**Level Champions with Fkeys:**  
Uses Fkeys to level the champions that are included in *Favorite 1* formation. It is a very fast way of leveling champions and requires no familiars. There is very little reason to turn this off. (**Note:** Only the key for leveling click damage will be pressed once champions have reached their upgrade limit).  

**Swap 'e' formation when on boss zones:**  
Recommended for 4/9 jump Briv (or very close). This will use the formation without Briv in it on bosses so that it will move on to the boss+1 level and start skipping from there to avoid future bosses. If you are at a jump level that consistently runs into bosses, this is a speed loss.  

**Enable manual resets to recover from failed Briv stacking:**  
When this box is checked, Briv has less than 50 Haste stacks, and the script reads a zone higher than 'Minimum zone Briv can farm SB stacks on' then the script will attempt to farm Steelbones stacks, manually reset the adventure by closing the game and using server calls, open the game client, and start a new run with enough Haste stacks for a standard run.

**Farm SB stacks AFTER this zone:**  
The script will attempt to farm Steelbones stacks once it reads that it has passed the zone number entered here. At a minimum, this zone should be high enough that the "W" formation does not kill anything. At a maximum, this zone should be 5 zones below the Modron reset zone for single skip, 7 zones below for double skip, 9 zones below for triple skip, and 11 zones below for quadruple skip.

**Minimum zone Briv can farm SB Stacks on:**  
This is the minimum zone number that your "W" formation can farm Steelbones stacks. This is only used when 'Enable manual resets to recover from failed Briv Stacking' is checked.  

**Target Haste stacks for next run:**  
When farming Steelbones stacks, the script will attempt to farm enough to have this amount of Haste stacks for the next run. You will have to calculate how many Haste stacks you need to complete your gem farm runs. This site provides an excellent stack calculator: https://ic.byteglow.com/speed  

**Disable Dash Wait:**  
The script will attempt to wait for Shandie's dash to activate if she is in the formation before progressing the run. Enabling this setting will disable the attempt to wait entirely.

**Briv Jump Timer (ms) client remains closed for Briv Restart Stack (0 disables):**  
After passing the zone set as part of 'Farm SB stacks AFTER this zone', the script will close the Idle Champions client for this amount of time, in milliseconds. With this value properly set, upon restarting the client an offline progress catch up mechanic will trigger and 5 minutes of time will be simulated, generally providing more stacks in less time when compared to stacking in game manually (by setting this value to 0). Recommended value range is 9000 to 15000. Longer durations do not provide more stacks, but too low of a duration may prevent the catch up mechanic from triggering resulting in few or no stacks.
> **Note:** Offline Progress appears to trigger when 15 seconds have passed between the last save and the next getuserdetails request.  

**Briv swap sleep time (ms):**  
If you see Briv's landing animation then this value should be made larger. If Briv is not being put back in the formation until after monsters spawn then this value should be made smaller. 2000 to 3000 is the typical range. This value may need to be tweaked again if you use different combinations of potions. 

---

When the game closes for offline stacking, the script will make server calls to buy (100) and/or open (99) chests according to the following settings.  

**Buy silver chests?:**  
Purchases 100 silver chests if you have at least 5000 gems above maintain gem number.

**Buy Gold Chests?:**  
Purchases 100 gold chests if you have at least 50000 gems above maintain gem number.

**Open Silver Chests?:**  
Opens 99 silver chests if you have at least 99 silver chests.

**Open Silver Chests?:**  
Opens 99 gold chests if you have at least 99 gold chests.

> **Note:** See SETTINGS.md for advanced configuration settings.

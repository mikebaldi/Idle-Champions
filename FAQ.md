# FAQ

* **BrivGemFarm is missing settings. I'd like it to do _X_.**   
Many advanced settings are hidden from the UI to make the new user experience more simple and less overwhelming. To review the hidden advanced settings, see the readme located [here](./Addons/IC_BrivGemFarm_Performance/SETTINGS.md).

* **What are the benefits of IC Script Hub over ModronGUI?** 
  * Its responsiveness has been increased.
  * Its reliability has been improved and is constantly being worked on.
  * It never takes control of the mouse away from the user.
  * It uses virtual keys so you can use your computer without issue while the script is running.
  * The settings are simpler and easier to get started with for new scripters.  
  * Many people see a speed increase using IC Script Hub over ModronGUI.
  * IC Script Hub has loads of auto-detection that ModronGUI never had. One example is automatically detecting "Quick Transitions" (QT) for adventures such as The Everlasting Rime and Tall Tales. 
  * IC Script hub is being actively developed while ModronGUI has been retired. If there's an issue with ModronGUI it is not getting fixed, however IC Script Hub is likely to see any issues resolved.
  * ### AddOns! 
    * Users can easily add and remove what functionality they want in the script through the easy to use Addon Manager. 
    * Easily add new addons by dropping them into the Addons folder.
    * Addons are great for developers. If there is a feature missing, it is relatively easy to create (or ask for someone to create) an Addon that does what you want using generic shared functions.

* **How does BrivGemFarm handle buying and opening chests?**  
The logic works like this:
  * If there is at least .1 seconds left during stack restart and your gems are higher than the maintenance level, it will **buy** between 0 and 100 **silver chests** depending on what you can afford.
  * THEN if there is still at least .1 seconds left during stack restart and your gems are higher than the maintenance level, it will **buy** between 0 and 100 **gold chests** depending on what you can afford.
  * THEN if there is still at least 3 seconds left during stack restart and you have unopened silvers, it will **open** between 0-99 **silver chests** depending on how many you have.
  * THEN if there is still at least 3 seconds left during stack restart and you have unopened golds, it will **open** between 0-99 **gold chests** depending on how many you have.

  If the advanced setting ``DoChestsContinuous`` is set to 1, it will repeat this process as long as there is time during the Stack Reset.  
  > **WARNING:** Be careful setting this value to 1. MANY purchases can happen during a reset and gems will seemingly evaporate.  

* **NEW! Can I run the Gem Farm script on multiple platforms at the same time?**  
Yes! To run the script on multiple platforms first requires a copy of the entire IC Script Hub for each platform that will be used. Game detection is based on exe name so one platform will need the `IdleDragons.exe` to be renamed (e.g. IdleDragonsSteam.exe) and the `IdleDragons_Data` folder to be renamed in the same way (e.g. IdleDragonsSteam_Data). Set up each script with their own settings. The important thing is to remember to set the Install exe to the new renamed exe in the game location.
Warning: This script reads system memory. I do not know CNE's stance on reading system memory used by the game, so use at your own risk. Pointers may break on any given update and I may no longer decide to update them.

Features:
1.	Fkey leveling of champions beginning on level 1. Shandie must be leveled first and Briv Second.
2.	Continued Fkey leveling of champions beyond level 1.
3.	Click damage leveling. Must include `` as part of initial Fkey leveling.
4.	Summon Dembo as part of the initial leveling.
5.	Wait for Dash timer on level 1.
6.	Briv stack farming at end of run, traditional or restart method.
7.	May close and restart game if stuck on a level for 60 seconds or longer (not sure why this isn’t an issue with Dash timer, potential future bug here)
8.	Restarts game after crashing.
9.	Script will swap out Briv to avoid his long transition animation.
How to use:
1.	Download Modron.AHK, classMemor.AHK, and IC_Pointers.AHK to the same folder.
2.	Adjust User Settings in Modron.AHK
3.	Run script Modron.AHK
4.	Set your Modron core and 'q' formation to your speed team.
5.	Set your 'w' formation to your Briv stack farming team.
6.	Set your ‘e’ formation to your speed team minus Briv, Melf, and Hew.
7.	Set your Modron core to reset on the boss after the zones you farm Briv stacks. E.g. if you want to farm stacks on z26-29 reset on z30. For quad skip, consider z31 reset. For added reliability, consider setting AreaLow to z21.
8.	Load adventure.
9.	Press F2 to start. If F2 is pressed after level 1 you may need to manually level champions for the first run.
10.	If you are having issues after the script restarts the game consider increasing the Open Process and Get Address variables under the restart section of user settings. If problems persist, consider disabling restarting by setting the restarting variables to 0.
If you find anything working not as intended, please look for me in #scripting channel of the official Idlen Champions discord. Thanks.


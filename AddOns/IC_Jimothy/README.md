# Jimothy
## Description:
This Addon was initially meant to assist in Jimothy push runs, but has been modified to additionally assist in push or variant runs where swapping briv in or out on a given zone may be beneficial. The script no longer requires you to use particular champions to operate.

## Addon's GUI Modifications:
Adds a Jimothy tab.

#
## Instructions:
Instructions:
1. Adjust settings as necessary, see documentation on settings below for informatino on specific settings.
2. Press the 'Save Settings' button.
3. Save the appropriate formations to save slots 'Q' and 'E'.
4. Press the 'Run' button to start the script.

Notes:
1. When using Briv, the script will attempt to cancel his jump animation. The script will also prioritize leveling him first if he is found in the 'Q' formation.
2. The script will attempt to level Shandie second if she is found in the 'Q' formation.
3. The script will attempt to level Havilar third and summon Dembo if she is found in the 'Q' formation.
4. No testing has been performed on the EGS client.
5. To uncheck a Mod 5 or Mod 10 check box, you must first uncheck the appropriate Mod 50 check box.

Known Issues:
1. When attempting to summon Dembo the script will send Havilar's ultimate input once if it does not detect Dembo already summoned. In some cases, this will sacrifice the current imp and leave you with no imps summoned. A solution to cycle the current Imp to Dembo is on the to do list.

#
## Settings: 
1. Max Zone - The script will fall back and stop when this zone has been reached.
2. Max Monsters - The script will reset the current zone by falling back and then autoprogressing forward when this many monsters have spawned.
3. Use Fkeys to level 'Q' formation - The script will use Fkeys to level the formation saved in slot 1, 'Q'.
4. Level click damage - The script will level click damage.
5. Check if Hew is alive - The script will check if Hew is alive. When Hew is not alive, the script will reset the current zone by falling back and then autoprogressing forward.
6. Select the formation to be used on the checked zones below - Choose either the 'Q' or 'E' formation to be used on the checked zones below. On the zones not checked, the unselected formation will be used.
7. Mod 5, Mod 10, and Mod 50 check boxes - See setting 6 above.

#
## Change Log:
v1.0.1, February 5, 2022
    Fixed a case that would result in Havilar attempting to summon Dembo would throw an error.
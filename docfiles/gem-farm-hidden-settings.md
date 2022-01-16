[< Return to Setting Up a Gem Farm](setting-up-a-gem-farm.md)

# Gem Farm: Hidden settings

This iteration of the Gem Farm script attempts to automate a lot of the settings away where possible.

Previously you had to set the specific F keys you wanted the script to hit. It now detects that automatically from the Modron core formation.

The settings file that is saved when you edit the entries using the GUI can be found at [\AddOns\IC_BrivGemFarm_Performance\BrivGemFarmSettings.json](../AddOns/IC_BrivGemFarm_Performance/BrivGemFarmSettings.json)

I will only cover the settings that aren't in the GUI:

## "HiddenFarmWindow"

This can be 0 or 1. 1 will hide the window that appears when you click the Start Gem Farm button on the GUI.

## "ResetZoneBuffer"

This is how far past your Modron Core reset point the game will allow you to travel before the game resets for you

This is useful for running a Gem Farm in a variant where the Modron core will not reset for you. This is a very niche situation though.

## "WindowXPosition" and "WindowYPosition"

These set the X and Y coordinates for the Gem Farm window.
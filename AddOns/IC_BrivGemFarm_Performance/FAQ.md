# Troubleshooting

* **After the game restarts to stack with briv, the script closes again before reaching the modron reset and when it opens it is on zone 1.**  
There are two cases for this to happen.
  1. Briv ran out of haste stacks before reaching the modron area but has steelbones stacks.
  * This means adjustments need to be made. Either the modron reset area needs to be lowered, Briv's stacking conditions need to be adjusted, or both. For Briv's stacking conditions, this could mean:
    * Lowering the area he stacks at. (He should not be able to kill mobs).
    * Increasing Briv's health.
  2. By default, the script will reset the map at 41 areas past the stack zone if a modron reset has not been triggered. This is a safety measure in case the modron core has been disabled or the modron's reset area was set too high and clicking would not reach it.
  *  This setting can be adjusted. See ``ResetZoneBuffer`` in the [advanced settings.](SETTINGS.md)
* **The script is using a lot of CPU. Is there some way I can reduce its load on my computer?**  
See the readme for the ``IC_GemFarm_Potato`` addon at ``Addons\IC_BrivGemFarm_Potato\README.md``

  *Still a work in progress.*

* **Epic's overlay is causing problems with the game running well.**   
For scripting with the EGS client we recommend you:
1. Disable the overlay by moving all ``EOS*.*`` in the folder ``\Epic Games\Launcher\Portal\Extras\Overlay`` to a subfolder (such as \_disabled). Move the files back if needed for other EGS games.
2. In ``IdleChampions\IdleDragons_Data\Plugins\x86_64`` move or delete ``EOSSDK-Win64-Shipping.dll`` and ``GfxPluginEOSLoader_x64.dll``

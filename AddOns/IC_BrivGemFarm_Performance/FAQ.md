# Troubleshooting

* **After the game restarts to stack with briv, the script closes again before reaching the modron reset and when it opens it is on zone 1.**  
  - Briv ran out of haste stacks before reaching the modron area but has steelbones stacks.
  * This means adjustments need to be made. Either the modron reset area needs to be lowered, Briv's stacking conditions need to be adjusted, or both. For Briv's stacking conditions, this could mean:
    * Lowering the area he stacks at. (He should not be able to kill mobs).
    * Increasing Briv's health.

* **Epic's overlay is causing problems with the game running well.**   
For scripting with the EGS client we recommend you:
1. Disable the overlay by moving all ``EOS*.*`` in the folder ``\Epic Games\Launcher\Portal\Extras\Overlay`` to a subfolder (such as \_disabled). Move the files back if needed for other EGS games.
2. In ``IdleChampions\IdleDragons_Data\Plugins\x86_64`` move or delete ``EOSSDK-Win64-Shipping.dll`` and ``GfxPluginEOSLoader_x64.dll``

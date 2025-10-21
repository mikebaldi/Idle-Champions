#include %A_LineFile%\..\IC_BrivGemFarm_StackAndStop_Addon.ahk
; Override start_click to not switch to stats tab and to say it is going to stop at stacking (colored text "running to stack")
SH_UpdateClass.UpdateClassFunctions(IC_BrivGemFarm_Component, IC_BrivGemFarm_Component_StackAndStop_Class)
SH_UpdateClass.AddClassFunctions(IC_BrivGemFarm_Component, IC_BrivGemFarm_Component_StackAndStop_Added_Class)
IC_StackAndStop_Class.InjectAddon()
MsgBox, You have enabled the BrivGemFarm Stack and Stop addon. This addon will make the gem farm stop after one run. If this is not what you want, please disable this addon using addon management from the puzzle piece icon.
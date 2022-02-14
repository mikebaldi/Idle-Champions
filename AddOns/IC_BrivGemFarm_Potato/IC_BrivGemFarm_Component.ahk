#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
class IC_BrivGemFarm_Potato_Component
{
    InjectAddon()
    {
        addonLoc := "#include *i %A_LineFile%\..\..\IC_BrivGemFarm_Potato\IC_BrivGemFarm_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}
IC_BrivGemFarm_Potato_Component.InjectAddon()
#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
class IC_BrivGemFarm_Potato_Component
{
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}
IC_BrivGemFarm_Potato_Component.InjectAddon()
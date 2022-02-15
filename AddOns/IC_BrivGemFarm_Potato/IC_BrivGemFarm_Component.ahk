#include %A_LineFile%\..\IC_BrivGemFarm_Functions.ahk
class IC_BrivGemFarm_Potato_Component
{
    InjectAddon()
    {
        SplitPath, A_LineFile ,, addonDirFullLoc
        splitStr := StrSplit(addonDirFullLoc, "\")
        size := splitStr.Count()
        addonDirLoc := splitStr[size]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}
IC_BrivGemFarm_Potato_Component.InjectAddon()
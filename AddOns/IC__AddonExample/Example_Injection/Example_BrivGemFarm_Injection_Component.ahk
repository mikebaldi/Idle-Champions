#include %A_LineFile%\..\IC_Example_BrivGemFarm_Injection_Functions.ahk
class Example_BrivGemFarm_Injection_Component
{
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonExampleDirLoc := splitStr[(splitStr.Count()-1)]
        addonDirLoc := splitStr[(splitStr.Count()-2)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\" . addonExampleDirLoc . "\IC_BrivGemFarm_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}
Example_BrivGemFarm_Injection_Component.InjectAddon()
; Override start_click to not switch to stats tab and to say it is going to stop at stacking (colored text "running to stack")

class IC_StackAndStop_Class
{
    ; Adds IC_BrivGemFarm_BrivFeatSwap_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_StackAndStop_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}
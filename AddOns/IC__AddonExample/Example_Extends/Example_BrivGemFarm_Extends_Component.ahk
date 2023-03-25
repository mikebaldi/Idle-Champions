class Example_BrivGemFarm_Extension_Component
{
    ; Function that adds Example_BrivGemFarm_Extends_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        ; Split this file's location between \'s
        splitStr := StrSplit(A_LineFile, "\")
        ; The directory above the file                       
        addonExampleDirLoc := splitStr[(splitStr.Count()-1)]        
        ; The addon directory
        addonDirLoc := splitStr[(splitStr.Count()-2)]               
        ; Location of the code to be added to BrivGemFarm
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\" . addonExampleDirLoc . "\Example_BrivGemFarm_Extends_Addon.ahk`n" 
        ; g_BrivFarmModLoc is an include file for BrivGemFarm's script. Append the #include directive to it.
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%                  
    }
}

; Call the function that adds Example_BrivGemFarm_Extends_Addon.ahk to the startup of the Briv Gem Farm script.
Example_BrivGemFarm_Extension_Component.InjectAddon()



/* INSTRUCTIONS: First, using the auto offsets/import tool, add the champion's ability information using the instructions here: 
   https://github.com/antilectual/ScriptHub-AutomaticOffsets/blob/main/README_MODIFYING.md
   Copy the generated imports to the SharedFunctions\MemoryRead\Imports directory.
   Create a file in the SharedFunctions\IC\MemoryRead\HeroHandlers\ directory using the format IC_<CHAMPION NAME>.ahk
   Follow the template outlined in __Template.ahk in this folder to create a custom class for the champion.
   Add the include to the new file at the bottom of the list of #includes below using the same format.
*/
class ActiveEffectKeySharedFunctions
{
    ; After building your hero class, include the file here.
    #include *i %A_LineFile%\..\IC_Briv.ahk
    #include *i %A_LineFile%\..\IC_Havilar.ahk
    #include *i %A_LineFile%\..\IC_HewMaan.ahk
    #include *i %A_LineFile%\..\IC_Nerds.ahk
    #include *i %A_LineFile%\..\IC_Omin.ahk
    #include *i %A_LineFile%\..\IC_Shandie.ahk
    #include *i %A_LineFile%\..\IC_Spurt.ahk
    #include *i %A_LineFile%\..\IC_Nordom.ahk
    #include *i %A_LineFile%\..\IC_Jim.ahk
    #include *i %A_LineFile%\..\IC_Thellora.ahk
    #include *i %A_LineFile%\..\IC_Nrakk.ahk
    #include *i %A_LineFile%\..\IC_Ellywick.ahk
}





; Extra information about specific hero handlers.
; Omin Contractual Obligations
    ; ChampID := 65
    ; EffectKeyString := "contractual_obligations"
    ; RequiredLevel := 210
    ; EffectKeyID := 4110

; NerdWagon
    ; ChampID := 87
    ; EffectKeyString := "nerd_wagon"
    ; RequiredLevel := 80
    ; EffectKeyID := 921
    ; NerdType := {0:"None", 1:"Fighter_Orange", 2:"Ranger_Red", 3:"Bard_Green", 4:"Cleric_Yellow", 5:"Rogue_Pink", 6:"Wizard_Purple"}

; Havilar Imp Handler (HavilarImpHandler)
    ; ChampID := 56
    ; EffectKeyString := "havilar_imps"
    ; RequiredLevel := 15
    ; EffectKeyID := 3431

; Briv Unnatural haste (BrivUnnaturalHasteHandler)
    ; ChampID := 58
    ; EffectKeyString := "briv_unnatural_haste"
    ; RequiredLevel := 80
    ; EffectKeyID := 3452

; Shandie Dash (TimeScaleWhenNotAttackedHandler)
    ; ChampID := 47
    ; EffectKeyString := "time_scale_when_not_attacked"
    ; RequiredLevel := 120
    ; EffectKeyID := 2774
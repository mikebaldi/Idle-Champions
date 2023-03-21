; ActiveEffectKeyHandler finds base addresses for ActiveEffectKeyHandler classes such as BrivUnnaturalHasteHandler and imports the offsets used for them.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_ActiveEffectKeyHandler_Class
{
    ; chance_multiply_monster_quest_rewards (Hew Maan effect)
    HeroHandlerIDs := {"HavilarImpHandler":56, "BrivUnnaturalHasteHandler":58,"TimeScaleWhenNotAttackedHandler":47, "OminContractualObligationsHandler":65, "NerdWagonHandler":87, "HewMaanTeamworkHandler":75, "SpurtWaspirationHandlerV2":43}
    HeroEffectNames := {"HavilarImpHandler":"havilar_imps", "BrivUnnaturalHasteHandler":"briv_unnatural_haste", "TimeScaleWhenNotAttackedHandler":"time_scale_when_not_attacked", "OminContractualObligationsHandler": "contractual_obligations", "NerdWagonHandler":"nerd_wagon", "HewMaanTeamworkHandler":"hewmaan_teamwork", "SpurtWaspirationHandlerV2":"spurt_waspiration_v2"}
    
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.4.0, 2023-03-19"
    }

    Refresh()
    {
        this.GameInstance := 0
        _MemoryManager.Refresh()
        this.BrivUnnaturalHasteHandler := this.GetEffectHandler("BrivUnnaturalHasteHandler")
        this.HavilarImpHandler := this.GetEffectHandler("HavilarImpHandler")
        this.NerdWagonHandler := this.GetEffectHandler("NerdWagonHandler")
        this.OminContractualObligationsHandler := this.GetEffectHandler("OminContractualObligationsHandler")
        this.TimeScaleWhenNotAttackedHandler := this.GetEffectHandler("TimeScaleWhenNotAttackedHandler")
        this.HewMaanTeamworkHandler := this.GetEffectHandler("HewMaanTeamworkHandler")
        this.SpurtWaspirationHandlerV2 := this.GetEffectHandler("SpurtWaspirationHandlerV2")
        if _MemoryManager.is64Bit
            this.Refresh64()
        else
            this.Refresh32()
    }

    Refresh32()
    {
        #include *i %A_LineFile%\..\Imports\ActiveEffectHandlers\IC_HeroHandlerIncludes32_Import.ahk
    }

    Refresh64()
    {
        #include *i %A_LineFile%\..\Imports\ActiveEffectHandlers\IC_HeroHandlerIncludes64_Import.ahk
    }

    GetEffectHandler(handlerName)
    {
        baseAddress := this.GetBaseAddress(handlerName)
        gameObject := New GameObjectStructure([])
        gameObject.Is64Bit := _MemoryManager.is64Bit
        gameObject.BaseAddress := baseAddress
        return gameObject
    }

    GetBaseAddress(handlerName)
    {
        champID := this.HeroHandlerIDs[handlerName]
        effectName := this.HeroEffectNames[handlerName]
        ; assuming first item in effectKeysByKeyName[key]'s list. Note: DM has two for "force_allow_hero"
        ; need _items value to use offsets later      
        handlerAddressObj := g_SF.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByKeyName[effectName].List[0].parentEffectKeyHandler.activeEffectHandlers._items
        ; use first item in the _items list as base address so offsets work later
        address := handlerAddressObj.Read() + handlerAddressObj.CalculateOffset(0) 
        return address
    }
}


class ActiveEffectKeySharedFunctions
{
    class Havilar
    {
        class ImpHandler
        {
            GetCurrentOtherImpIndex()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.activeImps.Read()
            }
            
            GetActiveImpsSize()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.currentOtherImpIndex.Read()
            }

            GetSummonImpCoolDownTimer()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.summonImpUltimate.CoolDownTimer.Read()
            }

            GetSacrificeImpCoolDownTimer()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.sacrificeImpUltimate.CoolDownTimer.Read()
            }
        } 
    }

    class Briv
    {
        class BrivUnnaturalHasteHandler
        {
            ReadSkipChance()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areaSkipChance.Read()
            }

            ReadHasteStacks()
            {
                 return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.sprintStacks.stackCount.Read()
            }

            ReadSkipAmount()
            {
                 return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areaSkipAmount.Read()
            }

            ReadAreasSkipped()
            {
                 return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areasSkipped.Read()
            }

        }
    }

    class Shandie
    {
        class TimeScaleWhenNotAttackedHandler
        {
            ReadDashActive()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.TimeScaleWhenNotAttackedHandler.scaleActive.Read()
            }
        }
    }

    class Omin
    {
        class OminContractualObligationsHandler
        {
            ReadNumContractsFulfilled()
            {
                contractsFulfilled := g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.numContractsFufilled.Read()
                if(contractsFulfilled != "" AND contractsFulfilled <= 100)
                    return contractsFulfilled
                return g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.obligationsFufilled.Read()
            }

            ; ReadSecondsOnGoldFind()
            ; {
            ;     return g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.secondsOnGoldFind)
            ; }
        }
    }

    class HewMaan
    {
        class HewMaanTeamworkHandler
        {
            ReadUltimateCooldownTimeLeft()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HewMaanTeamworkHandler.hewmaan.ultimateAttack.CooldownTimer.Read()
            }

            ReadUltimateID()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.HewMaanTeamworkHandler.hewmaan.ultimateAttack.ID.Read()
            }
        }
    }

    class Nerds
    {
        class NerdWagonHandler
        {
            static NerdType := {0:"None", 1:"Fighter_Orange", 2:"Ranger_Red", 3:"Bard_Green", 4:"Cleric_Yellow", 5:"Rogue_Pink", 6:"Wizard_Purple"}

            ReadNerd0()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd0.type.Read()
            }

            ReadNerd1()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd1.type.Read()
            }


            ReadNerd2()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd2.type.Read()
            }

            ReadNerd0Type()
            {
                return this.NerdType[this.ReadNerd0()]
            }

            ReadNerd1Type()
            {
                return this.NerdType[this.ReadNerd1()]
            }

            ReadNerd2Type()
            {
                return this.NerdType[this.ReadNerd2()]
            }
        }
    }

    class Spurt
    {
        class WaspirationHandler
        {

            ; ReadSpurtStacksLeft()
            ; {
            ;     return g_SF.Memory.ActiveEffectKeyHandler.SpurtWaspirationHandlerV2.remainingStacksNeededForNextEffect.Read()
            ; }

            ReadSpurtWasps()
            {
                return g_SF.Memory.ActiveEffectKeyHandler.SpurtWaspirationHandlerV2.activeWasps.size.Read()
            }
        }
    }
}

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

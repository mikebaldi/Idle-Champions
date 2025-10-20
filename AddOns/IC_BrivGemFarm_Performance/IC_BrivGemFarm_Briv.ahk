;=========================================================
; Briv Steelbones and Haste related functions
;=========================================================

; Original Credit ImpEGamer - https://github.com/imp444/IC_Addons/
class BrivFunctions
{
    static BrivId := 58
    static BrivJumpSlot := 4
    static UnnaturalHasteBaseEffect := 25
    static WastingHastePercentOverride := 800
    static StrategicStridePercentOverride := 25600
    static WastingHasteId := 791
    static StrategicStrideId := 2004
    static AccurateAcrobaticsFeatId := 2062
    static BrivSkipConfigByFavorite := []

    class BrivSkipConfig ; IC_BrivGemFarm_Class.BrivFunctions.BrivSkipConfig
    {
        ; Cached properties
        SkipAmount := 0
        SkipChance := 0
        Feats := ""
        4JFeat := false
        9JFeat := false
        AAFeat := false
        AvailableJumps := ""

        __New(skipAmount, skipChance, feats)
        {
            this.SkipAmount := skipAmount
            this.SkipChance := skipChance
            this.Feats := feats
            for k, v in feats
            {
                if (v == IC_BrivGemFarm_BrivFeatSwap_Functions.BrivFunctions.WastingHasteId)
                    this.4JFeat := true
                else if (v == IC_BrivGemFarm_BrivFeatSwap_Functions.BrivFunctions.StrategicStrideId)
                    this.9JFeat := true
                else if (v == IC_BrivGemFarm_BrivFeatSwap_Functions.BrivFunctions.AccurateAcrobaticsFeatId)
                    this.AAFeat := true
            }
            if (skipChance == 1 || skipAmount == 0) ; Perfect jump or no Briv in formation
                this.AvailableJumps := [skipAmount]
            else if (skipChance == 0) ; Round down to previous jump. - nJ,0% := n(J - 1),100%
                this.AvailableJumps := [skipAmount - 1]
            else ; Partial jump
                this.AvailableJumps := [skipAmount - 1, skipAmount]
        }

        IsPartialJump()
        {
            return this.AvailableJumps.Length() == 2
        }
    }

    GetBrivLoot()
    {
        gild := g_SF.Memory.ReadHeroLootGild(this.BrivId, this.BrivJumpSlot)
        enchant := Floor(g_SF.Memory.ReadHeroLootEnchant(this.BrivId, this.BrivJumpSlot))
        rarity := g_SF.Memory.ReadHeroLootRarityValue(this.BrivId, this.BrivJumpSlot)
        if (gild == "" || enchant == "" || rarity == "")
            return ""
        return {"gild":gild, "enchant":enchant, "rarity":rarity}
    }

    GetHeroFeatsInFormationFavorite(formationFavorite, heroID)
    {
        if (heroID < 1)
            return ""
        slot := g_SF.Memory.GetSavedFormationSlotByFavorite(formationFavorite)
        size := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].FormationSaveHandler.formationSavesV2[slot].Feats[heroID].List.size.Read()
        ; Sanity check, should be < 4 but set to 6 in case of future feat num increase.
        if (size < 0 || size > 6)
            return ""
        featList := []
        Loop, %size%
            featList.Push(g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].FormationSaveHandler.formationSavesV2[slot].Feats[heroID].List[A_Index - 1].Read())
        return featList
    }

    GetBrivSkipConfig(favorite := "", refresh := false)
    {
        if (favorite < 1)
            return
        if ((refresh || this.BrivSkipConfigByFavorite[favorite] == "") && g_SF.Memory.ReadCurrentZone() != "")
        {
            skipValues := this.GetBrivSkipValues(favorite)
            feats := this.GetHeroFeatsInFormationFavorite(favorite, this.BrivId)
            config := new IC_BrivGemFarm_Class.BrivFunctions.BrivSkipConfig(skipValues[1], skipValues[2], feats)
            this.BrivSkipConfigByFavorite[favorite] := config
        }
        return this.BrivSkipConfigByFavorite[favorite]
    }

    CurrentFormationMatchesBrivConfig(favoriteFormationSlot, refresh := false)
    {
        if (g_SF.Memory.ReadResetting())
            return true
        config := this.GetBrivSkipConfig(favoriteFormationSlot, refresh)
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        equalAmount := skipAmount == config.skipAmount
        equalChance := config.IsPartialJump() ? (0 < skipChance && skipChance < 1) : (skipChance == config.skipChance)
        return equalAmount && equalChance
    }   

    ;=========================================================
    ; Continue Updates
    ;=========================================================

    GetBrivSkipValues(favoriteFormationSlot := "")
    {
        feats := ""
        hasAccurateFeat := false
        if (favoriteFormationSlot > 0)
        {
            formation := g_SF.Memory.GetFormationByFavorite(favoriteFormationSlot)
            heroID := this.BrivId
            if (g_SF.IsChampInFormation(heroID, formation))
            {
                feats := this.GetHeroFeatsInFormationFavorite(favoriteFormationSlot, heroID)
                for k, v in feats
                    if (v == this.AccurateAcrobaticsFeatId)
                        hasAccurateFeat := true
            }
            else
                return [0, 0]
        }
        defaultSkipChance := this.GetDefaultBrivSkipChance(feats)
        return this.CalculateAreaSkipValues(defaultSkipChance, hasAccurateFeat)
    }

    GetDefaultBrivSkipChance(feats := "")
    {
        ; Check for 4J or 9J feat
        if (IsObject(feats))
        {
            hasFeatOverride := false
            featOverridePercent := 1234567890
            for k, v in feats
            {
                if (v == this.WastingHasteId) ; 4J feat takes precedence over 9J feat
                    hasFeatOverride := true,    featOverridePercent := Min(this.WastingHastePercentOverride, featOverridePercent)
                else if (v == this.StrategicStrideId)
                    hasFeatOverride := true,    featOverridePercent := Min(this.StrategicStridePercentOverride, featOverridePercent)
            }
            if (hasFeatOverride)
                return featOverridePercent
        }
        ; Compute effect from loot
        loot := this.GetBrivLoot()
        if (loot == "")
            return ""
        gild := loot.gild
        enchant := loot.enchant
        rarity := loot.rarity
        baseEffect := this.UnnaturalHasteBaseEffect
        ilvlMult := 1 + Max(enchant, 0) * 0.004
        rarityMult := (rarity == 0) ? 0 : (rarity == 1) ? 0.1 : (rarity == 2) ? 0.3 : (rarity == 3) ? 0.5 : (rarity == 4) ? 1 : 0
        gildMult := (gild == 0) ? 1 : (gild == 1) ? 1.5 : (gild == 2) ? 2 : 1
        skipChance := baseEffect * (1 + ilvlMult * rarityMult * gildMult)
        return skipChance
    }

    GetHighestBrivSkipAmount()
    {
        BrivID := IC_BrivGemFarm_HybridTurboStacking_Functions.BRIV_ID
        BrivJumpSlot := IC_BrivGemFarm_HybridTurboStacking_Functions.BrivJumpSlot
        gild := g_SF.Memory.ReadHeroLootGild(BrivID, BrivJumpSlot)
        ilvls := Floor(g_SF.Memory.ReadHeroLootEnchant(BrivID, BrivJumpSlot))
        rarity := g_SF.Memory.ReadHeroLootRarityValue(BrivID, BrivJumpSlot)
        if (ilvls == "" || rarity == "" || gild == "")
            return 50
        return this.CalculateAreaSkipValues(gild, ilvls, rarity)[1]
    }

    GetLastSafeStackZone(modronReset := "")
    {
        if (modronReset == "")
            modronReset := g_SF.Memory.GetModronResetArea()
        lastZone := modronReset - 1
        ; Move back one zone if the last zone before reset is a boss.
        if (Mod(lastZone, 5 ) == 0)
            lastZone -= 1
        skipAmount := IC_BrivGemFarm_HybridTurboStacking_Functions.GetHighestBrivSkipAmount()
        return lastZone - skipAmount - 1
    }

    ; BrivFeatSwap - nov 23, 2023
    CalculateAreaSkipValues(defaultPercent, hasAccurateFeat := false)
    {
        if (defaultPercent < this.UnnaturalHasteBaseEffect)
            return ""
        skipChance := 0.01 * defaultPercent
        skipAmount := 1
        if (skipChance > 1)
        {
            while (skipChance > 1)
                skipAmount := skipAmount + 1, skipChance *= 0.5
            if (hasAccurateFeat && skipChance < 1)
                skipChance := 0
            else
                skipChance := (skipChance - 0.5) / (1 - 0.5) * (1 - 0.01) + 0.01
        }
        return [skipAmount, skipChance]
    }

    ; Predicts the number of Briv haste stacks after the next reset.
    ; After resetting, Briv's Steelborne stacks are added to the remaining Haste stacks.
    PredictStacks(addSBStacks := true, refreshCache := false, forcedReset := False )
    {
        static skipQ
        static skipE

        preferred := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
        if (IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class)) ; levelup addon controls briv leveling.
            brivMinlevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ] ; min zone for metalborn
        else
            brivMinlevelArea := 1
        if (refreshCache || skipQ == "" || skipE == "" || skipQ == 0 && skipE == 0)
            skipQ := (this.GetBrivSkipValues(1))[1], skipE := (this.GetBrivSkipValues(3))[1]
        modronReset := g_SF.Memory.GetModronResetArea()
        sbStacks := g_SF.Memory.ReadSBStacks()
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        sprintStacks := g_SF.Memory.ReadHasteStacks()
        ; Party has not progressed to the next zone yet but Briv stacks were consumed.
        if (highestZone - currentZone > 1)
            currentZone := highestZone
        ; This assumes Briv has gained more than 48 stacks ever.
        stacksAtReset := Max(48, this.CalcStacksLeftAtReset(preferred, currentZone, modronReset, sprintStacks, skipQ, skipE, brivMinlevelArea, brivMetalbornArea))
        if (addSBStacks)
            stacksAtReset += sbStacks
        return stacksAtReset
    }

    ; Calculates the path from z1 to the reset area.
    ; Parameters: - mod50values:Array - Preferred Briv jump zones for the Q/E favorite formations.
    ;             - currentZone:int - Starting zone.
    ;             - resetZone:int - Actual zone where the run is reset.
    ;             - startStacks:int - Briv Haste stacks.
    ;             - skipQ:int - Number of Briv jumps in the Q formation.
    ;             - skipE:int - Number of Briv jumps in the E formation.
    ;             - brivMinLevelArea:int - Minimum level where Briv can jump (LevelUp addon setting).
    ;             - brivMetalbornArea:int - Minimum level where Briv gets Metalborn (LevelUp addon setting).
    ; Returns:    - int - Number of Briv Haste stacks left at the reset zone.
    CalcStacksLeftAtReset(mod50values, currentZone, resetZone, startStacks, skipQ, skipE, brivMinLevelArea := 1, brivMetalbornArea := 1)
    {
        qVal := skipQ != "" ? Max(skipQ + 1, 1) : 1
        eVal := skipE != "" ? Max(skipE + 1, 1) : 1
        if (!Isobject(mod50values))
        {
            mod50Int := mod50values
            mod50values := []
            Loop, 50
                mod50values[A_Index] := (mod50Int & (2 ** (A_Index - 1))) != 0
        }
        ; Walk
        currentZone := Max(currentZone, brivMinLevelArea)
        ; Jump
        while (currentZone < resetZone)
        {
            ; Area progress
            mod50Index := Mod(currentZone, 50) == 0 ? 50 : Mod(currentZone, 50)
            mod50Value := mod50values[mod50Index]
            move := mod50Value ? qVal : eVal
            if (move > 1)
                startStacks := Round(startStacks * (currentZone < brivMetalbornArea ? 0.96 : 0.968))
            currentZone += move
        }
        return startStacks
    }

    PredictStacksActive()
    {
        return !g_BrivUserSettings[ "IgnoreBrivHaste" ]
    }
}
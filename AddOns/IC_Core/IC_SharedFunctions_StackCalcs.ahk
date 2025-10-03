
    ; SharedFunctions Extension
    
    ; Left here for reference calculations.
    CalculateBrivStacksLeftAtTargetZone_Depricated(startZone := 1, targetZone := 1, worstCase := true)
    {
        jumps := 0
        reductionFactor := this.IsBrivMetalborn() ? 1 -.032 : 1 -.04 ;Default := 4%, MetalBorn := 3.2%
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks() ; doesn't work without briv on field
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() ; doesn't work without briv on field
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance() ; doesn't work without briv on field
        distance := targetZone - startZone
        ; skipAmount == 1 is a special case where Briv won't use stacks when he skips 0 areas.
        if(skipAmount == 1)
            jumps := worstCase ? Max(Ceil(distance / 2),0) : Max(Ceil((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1)),0)
        else
            jumps :=  Max(Floor(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance))), 0)
        isEffectively100 := 1 - skipChance < .004
        if (worstCase AND skipChance < 1 AND !isEffectively100 AND skipAmount != 1)
            jumps := Floor(jumps * 1.05)
        return Max(Floor(stacks*reductionFactor**jumps), 48)
    }

    ; Calculates the number of Haste stacks will be used to progress from the current zone to the modron reset area.
    CalculateBrivStacksConsumedToReachModronResetZone(worstCase := true)
    {
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        return stacks - this.CalculateBrivStacksLeftAtTargetZone(this.Memory.ReadCurrentZone(), this.Memory.GetModronResetArea() + 1, worstCase)
    }

    ; Calculates the farthest zone Briv expects to jump to with his current stacks on his current zone.  avgMinOrMax: avg = 0, min = 1, max = 2.
    CalculateMaxZone(avgMinOrMax := 0)
    {
        ; 1 jump results will change based on the current zone depending on whether the previous zones had jumps and used stacks or not.
        consume := this.IsBrivMetalborn() ? -.032 : -.04 ;Default := 4%, MetalBorn := 3.2%
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        currentZone := this.Memory.ReadCurrentZone()
        if g_BrivUserSettings[ "ManualBrivJumpValue" ] is integer
            skipAmount := g_BrivUserSettings[ "ManualBrivJumpValue" ] ? g_BrivUserSettings[ "ManualBrivJumpValue" ] : ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        else
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        jumps := Floor(Log(49 / Max(stacks,49)) / Log(1+consume))
        avgJumpDistance := skipAmount * (1-skipChance) + (skipAmount+1) * skipChance
        maxJumpDistance := skipAmount+1
        minJumpDistance := skipAmount
        ;zones := jumps * avgJumpDistance
        zones := avgMinOrMax == 0 ? jumps * avgJumpDistance : (avgMinOrMax == 1 ? jumps * minJumpDistance : jumps * maxJumpDistance)
        return currentZone + zones
    }

    CalculateBrivStacksToReachNextModronResetZone()
    {
        static skipQ := ""
        static skipE := ""

        ; if (refreshCache || skipQ == "" || skipE == "" || skipQ == 0 && skipE == 0)
        skipE := (IC_BrivGemFarm_Class.BrivFunctions.GetBrivSkipValues(3))[1], skipQ := (IC_BrivGemFarm_Class.BrivFunctions.GetBrivSkipValues(1))[1]
        qVal := skipQ != "" ? Max(skipQ + 1, 1) : 1
        eVal := skipE != "" ? Max(skipE + 1, 1) : 1
        reductionFactor := this.IsBrivMetalborn() ? 1-.032 : 1-.04 ;Default := 4%, MetalBorn := 3.2%
        preferred := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
        currentArea := startArea := 296 ; Min((this.Memory.ReadCurrentZone() / 5), g_SF.Memory.GetFavorExponentFor("Corellon")) + 1 ; total Thellora jump accumulated thus far.
        modronResetZone := g_SF.Memory.GetModronResetArea()
        jumps := 0
        thunderStepMod := g_SF.BrivHasThunderStep() ? 1.2 : 1
        brivMinMetalbornArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ] ? g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ] : 1
        while (currentArea < modronResetZone) ; skip using preferred jump zones.
        {
            mod50Index := Mod(currentArea, 50) == 0 ? 50 : Mod(currentArea, 50)
            mod50Value := preferred[mod50Index]
            move := mod50Value ? qVal : eVal
            if (move > 1)
                jumps += 1
            currentArea += move
        }
        stacks := Ceil(49 / reductionFactor**(jumps+1))
        return stacks
    }
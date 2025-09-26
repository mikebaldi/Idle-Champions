
    ; SharedFunctions Extension
    
    ; Calculates the number of Haste stacks are required to jump from area 1 to the modron's reset area. worstCase default is true.
    CalculateBrivStacksToReachNextModronResetZone(worstCase := true)
    {
        g_SharedData.RedoStackCalc := False
        jumps := 0
        consume := this.IsBrivMetalborn() ? -.032 : -.04  ;Default := 4%, SteelBorn := 3.2%
        if g_BrivUserSettings[ "ManualBrivJumpValue" ] is integer
            skipAmount := g_BrivUserSettings[ "ManualBrivJumpValue" ] ? g_BrivUserSettings[ "ManualBrivJumpValue" ] : ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        else
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance() 
        if (!skipChance)
        {
            skipChance := 1
            g_SharedData.RedoStackCalc := True
        }
        skipChance := skipChance ? skipChance : 1
        distance := this.Memory.GetModronResetArea() - this.ThelloraRushTest()
        ; skipAmount == 1 is a special case where Briv won't use stacks when he skips 0 areas.
        ; average
        if(skipAmount == 1) ; true worst case =  worstCase ? Ceil(distance / 2) : normalcalc
            jumps := worstCase ? Ceil(((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1)) * 1.15) : Ceil((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1))
        else
            jumps := Ceil(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance)))
        isEffectively100 := 1 - skipChance < .004
        stacks := Ceil(49 / (1+consume)**jumps)
        if (worstCase AND skipChance < 1 AND !isEffectively100 AND skipAmount != 1) 
            stacks := Floor(stacks * 1.15) ; 15% more - guesstimate
        return stacks
    }

    ; Calculates the number of Haste stacks that will be left over once when the target zone has been reached. Defaults: startZone=1, targetZone=1, worstCase=true.
    CalculateBrivStacksLeftAtTargetZone(startZone := 1, targetZone := 1, worstCase := true)
    {
        jumps := 0
        consume := this.IsBrivMetalborn() ? -.032 : -.04 ;Default := 4%, MetalBorn := 3.2%
        stacks := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks()
        if g_BrivUserSettings[ "ManualBrivJumpValue" ] is integer
            skipAmount := g_BrivUserSettings[ "ManualBrivJumpValue" ] ? g_BrivUserSettings[ "ManualBrivJumpValue" ] : ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        else
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        distance := targetZone - startZone
        ; skipAmount == 1 is a special case where Briv won't use stacks when he skips 0 areas.
        if(skipAmount == 1)
            jumps := worstCase ? Max(Ceil(distance / 2),0) : Max(Ceil((distance - (distance/((skipAmount*(1-skipChance))+(skipAmount+1)*skipChance))*(1-skipChance)) / (skipAmount + 1)),0)
        else
            jumps :=  Max(Floor(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance))), 0)
        isEffectively100 := 1 - skipChance < .004
        if (worstCase AND skipChance < 1 AND !isEffectively100 AND skipAmount != 1)
            jumps := Floor(jumps * 1.05)
        return Floor(stacks*(1+consume)**jumps)
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
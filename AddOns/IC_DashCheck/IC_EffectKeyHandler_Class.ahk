class EffectKeyHandler
{
    DictIndex := ""
    BaseAddress := ""
    Initialized := false

    ;returns -1 if champ not leveled, -2 if can't find effect key name, 0 if likely success
    Initialize()
    {
        this.Initialized := this.CheckChampLevel()
        if !this.Initialized
            return -1
        this.DictIndex := this.GetDictIndex()
        if (this.DictIndex == -1)
        {
            this.Initialized := false
            return -2
        }
        this.BaseAddress := this.GetBaseAddress()
        return 0
    }

    CheckChampLevel()
    {
        if (g_SF.Memory.ReadChampLvlByID(this.ChampID) < this.RequiredLevel)
            return false
        else
            return true
    }
    
    GetDictIndex()
    {
        dictCount := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyNameCount.GetGameObjectFromListValues(this.ChampID - 1))
        i := 0
        loop, % dictCount
        {
            keyName := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.Name.GetGameObjectFromDictValues( [ this.ChampID - 1, [ "key", i ] ]* ) )
            if (keyName == this.EffectKeyString)
                return i
            ++i
        }
        return -1
    }

    GetBaseAddress()
    {
        return g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey.parentEffectKeyHandler.activeEffectHandlers.GetGameObjectFromDictValues( [ this.ChampID - 1, [ "value", this.DictIndex ] ]* ) )
    }

    IsBaseAddressCorrect()
    {
        readEffectKeyID := g_SF.Memory.GameManager.Main.read(this.baseAddress + EffectKeyHandler.effectKeyOffset, "int", EffectKeyHandler.effectKeyIDoffset*)
        if (readEffectKeyID != this.EffectKeyID)
        {
            this.Initialized := false
            return false
        }
        return true
    }

    effectKeyOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x14
            Else
                return 0x14
        }
    }

    effectKeyIDoffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return [0x8, 0x8, 0xC, 0x8]
            Else
                return [0x8, 0x8, 0xC, 0x8]
        }
    }
}

;EGS offsets need to be updated
class TimeScaleWhenNotAttackedHandler extends EffectKeyHandler
{
    ChampID := 47
    EffectKeyString := "time_scale_when_not_attacked"
    RequiredLevel := 120
    EffectKeyID := 2774

    activeOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x10
            Else
                return 0x10
        }
    }

    GetActiveValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + TimeScaleWhenNotAttackedHandler.activeOffset, "int")
    }

    scaleActiveOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xD0
            Else
                return 0xD0
        }
    }

    GetScaleActiveValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + TimeScaleWhenNotAttackedHandler.scaleActiveOffset, "int")
    }

    effectTimeOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xD8
            Else
                return 0xD8
        }
    }

    GetEffectTimeValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + TimeScaleWhenNotAttackedHandler.effectTimeOffset, "double")
    }    
}

;EGS offsets need to be updated
class OminContractualObligationsHandler extends EffectKeyHandler
{
    ChampID := 65
    EffectKeyString := "contractual_obligations"
    RequiredLevel := 210
    EffectKeyID := 4110

    numContractsFufilled[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x38
            Else
                return 0x38
        }
    }

    GetNumContractsFufilledValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + OminContractualObligationsHandler.numContractsFufilled, "int")
    }

    secondsOnGoldFind[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x5C
            Else
                return 0x5C
        }
    }

    GetSecondsOnGoldFindValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + OminContractualObligationsHandler.secondsOnGoldFind, "float")
    }

    effectKeyOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x18
            Else
                return 0x18
        }
    } 
}

;EGS offsets need to be updated
class BrivUnnaturalHasteHandler extends EffectKeyHandler
{
    ChampID := 58
    EffectKeyString := "briv_unnatural_haste"
    RequiredLevel := 80
    EffectKeyID := 3452

    ;this is a pointer
    sprintStacks[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x18
            Else
                return 0x18
        }
    }

    stackCount[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x58
            Else
                return 0x58
        }
    }

    GetStackCountValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.sprintStacks, "double", BrivUnnaturalHasteHandler.stackCount)
    }

    areasSkipped[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x2C
            Else
                return 0x2C
        }
    }

    GetAreasSkippedValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areasSkipped, "int")
    }

    areaSkipChance[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x34
            Else
                return 0x34
        }
    }

    GetAreaSkipChanceValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areaSkipChance, "float")
    }

    areaSkipAmount[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x38
            Else
                return 0x38
        }
    }

    GetAreaSkipAmountValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areaSkipAmount, "int")
    }

    alwaysSkipOneLess[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x3C
            Else
                return 0x3C
        }
    }

    GetAlwaysSkipOneLessValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.alwaysSkipOneLess, "char")
    }

    stacksToConsume[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x40
            Else
                return 0x40
        }
    }

    GetStacksToConsumeValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.stacksToConsume, "int")
    }
}

/*  A series of classes for reading memory from specific Effect Key Handlers

    Usage:
    global g_HandlerInstance := new HandlerClass ; Create an instance of the handler class. It doesn't have to be global.
    init := g_HandlerInstance.Initialize() ; Initialize the instance of the class, this has to be done every time the game restarts, 
        possibly after modron resets, and possibly through runs. Returns -1 if champ not leveled, -2 if can't find effect key name, 0 if likely success.
    isCorrect := g_HandlerInstance.IsBaseAddressCorrect() ; Check if the base address to the handler is correct, returns true or false. If false 
        call Initialize() method.
    field := g_HandlerInstance.GetFieldValue() ; Returns memory value associated with 'Field', see below for fields.

    Handlers and Fields:

    TimeScaleWhenNotAttackedHandler ;Shandie's Dash ability.
        active ; The handler, not Dash.
        scaleActive ; True or false for Dash ability is active.
        effectTimeValue ; Starts at 0 and counts up. At 60 Dash scaleActive should be truen and Dash on.
    
    OminContractualObligationsHandler
        numContractsFufilled ; Number of contracts fullfilled.
        secondsOnGoldFind ; Seconds remaining for Contractual Obligations gold find boost. Value is set to -1 when no boost is active.
    
    BrivUnnaturalHasteHandler
        stackCount ; Unnatural Haste stack count.
        areasSkipped ; Areas skipped this run. There are bugs where this doesn't always reset between runs.
        areaSkipChance ; Chance for Briv to skip his maximum amount of areas in one jump.
        areaSkipAmount ; Maximum amount of areas Briv will skip in one jump.
        alwaysSkipOneLess ; True or false if Briv will at least skip one less than his maximum amount of areas in one jump.
        stacksToConsume ; This one doesn't appear to do anything.
*/

class EffectKeyHandler
{
    DictIndex := ""
    BaseAddress := ""
    Initialized := false

    ; Returns -1 if champ not leveled, -2 if can't find effect key name, 0 if likely success.
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
                return 0x28
            Else
                return 0x14
        }
    }

    effectKeyIDoffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return [0x10, 0x10, 0x18, 0x10]
            Else
                return [0x8, 0x8, 0xC, 0x8]
        }
    }
}

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
                return 0x20
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
                return 0x108
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
                return 0x110
            Else
                return 0xD8
        }
    }

    GetEffectTimeValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + TimeScaleWhenNotAttackedHandler.effectTimeOffset, "double")
    }    
}

class OminContractualObligationsHandler extends EffectKeyHandler
{
    ChampID := 65
    EffectKeyString := "contractual_obligations"
    RequiredLevel := 210
    EffectKeyID := 4110

    numContractsFufilledOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x70
            Else
                return 0x38
        }
    }

    GetNumContractsFufilledValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + OminContractualObligationsHandler.numContractsFufilledOffset, "int")
    }

    secondsOnGoldFindOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x94
            Else
                return 0x5C
        }
    }

    GetSecondsOnGoldFindValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + OminContractualObligationsHandler.secondsOnGoldFindOffset, "float")
    }

    effectKeyOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x30
            Else
                return 0x18
        }
    } 
}

class BrivUnnaturalHasteHandler extends EffectKeyHandler
{
    ChampID := 58
    EffectKeyString := "briv_unnatural_haste"
    RequiredLevel := 80
    EffectKeyID := 3452

    ;this is a pointer
    sprintStacksOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x30
            Else
                return 0x18
        }
    }

    stackCountOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x98
            Else
                return 0x58
        }
    }

    GetStackCountValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.sprintStacksOffset, "double", BrivUnnaturalHasteHandler.stackCountOffset)
    }

    areasSkippedOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x58
            Else
                return 0x2C
        }
    }

    GetAreasSkippedValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areasSkippedOffset, "int")
    }

    areaSkipChanceOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x60
            Else
                return 0x34
        }
    }

    GetAreaSkipChanceValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areaSkipChanceOffset, "float")
    }

    areaSkipAmountOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x64
            Else
                return 0x38
        }
    }

    GetAreaSkipAmountValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.areaSkipAmountOffset, "int")
    }

    alwaysSkipOneLessOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x68
            Else
                return 0x3C
        }
    }

    GetAlwaysSkipOneLessValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.alwaysSkipOneLessOffset, "char")
    }

    stacksToConsumeOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x6C
            Else
                return 0x40
        }
    }

    GetStacksToConsumeValue()
    {
        return g_SF.Memory.GameManager.Main.read(this.baseAddress + BrivUnnaturalHasteHandler.stacksToConsumeOffset, "int")
    }
}
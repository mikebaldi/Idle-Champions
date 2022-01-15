/*  A handler for Briv's Unnatural Haste ability

    Properties:
        stackCount ; Unnatural Haste stack count.
        areasSkipped ; Areas skipped this run. There are bugs where this doesn't always reset between runs.
        areaSkipChance ; Chance for Briv to skip his maximum amount of areas in one jump.
        areaSkipAmount ; Maximum amount of areas Briv will skip in one jump.
        alwaysSkipOneLess ; True or false if Briv will at least skip one less than his maximum amount of areas in one jump.
        stacksToConsume ; This one doesn't appear to do anything.
*/

#include %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

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
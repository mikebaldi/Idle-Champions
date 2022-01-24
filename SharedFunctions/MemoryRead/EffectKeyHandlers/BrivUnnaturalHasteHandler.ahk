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

    GetStackCount()
    {
        return this.sprintStacks.stackCount.GetValue()
    }

    GetAreasSkipped()
    {
        return this.areasSkipped.GetValue()
    }

    GetAreaSkipChance()
    {
        return this.areaSkipChance.GetValue()
    }

    GetAreaSkipAmount()
    {
        return this.areaSkipAmount.GetValue()
    }

    GetAlwaysSkipOneLess()
    {
        return this.alwaysSkipOneLess.GetValue()
    }

    GetStacksToConsume()
    {
        return this.stacksToConsume.GetValue()
    }

    BuildMemoryObjects()
    {
        this.BuildEffectKey()
        this.sprintStacks := new MemoryObject(0x18, 0x30, "Ptr", "", this.BaseAddress)
        this.sprintStacks.stackCount := new MemoryObject(0x58, 0x98, "Double", this.sprintStacks, this.BaseAddress)
        this.areasSkipped := new MemoryObject(0x2C, 0x58, "Int", "", this.BaseAddress)
        this.areaSkipChance := new MemoryObject(0x34, 0x60, "Float", "", this.BaseAddress)
        this.areaSkipAmount := new MemoryObject(0x38, 0x64, "Int", "", this.BaseAddress)
        this.alwaysSkipOneLess := new MemoryObject(0x3C, 0x68, "Char", "", this.BaseAddress)
        this.stacksToConsume := new MemoryObject(0x40, 0x6C, "Int", "", this.BaseAddress)
    }
}
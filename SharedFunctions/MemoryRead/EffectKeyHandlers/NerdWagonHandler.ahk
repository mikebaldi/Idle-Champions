/*  A handler for the NERDs wagon

    Properties:
        GetNerd#Int() - where # is 0, 1, or 2, representing the three NERDs in the wagon. returns an integer representation of the NERD
        GetNerd#Type() - same as above but returns a string representation of the NERD
*/

#include %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

class NerdWagonHandler extends EffectKeyHandler
{
    ChampID := 87
    EffectKeyString := "nerd_wagon"
    RequiredLevel := 80
    EffectKeyID := 921
    NerdType := {0:"None", 1:"Fighter_Orange", 2:"Ranger_Red", 3:"Bard_Green", 4:"Cleric_Yellow", 5:"Rogue_Pink", 6:"Wizard_Purple"}

    IsBaseAddressCorrect()
    {
        readEffectKeyID := this.effectKey.parentEffectKeyHandler.parent.def.ID.GetValue()
        if (readEffectKeyID != this.EffectKeyID)
        {
            this.Initialized := false
            return false
        }
        return true
    }

    GetNeard0Int()
    {
        return this.nerd0.type.GetValue()
    }

    GetNeard0Type()
    {
        return this.NerdType[ this.nerd0.type.GetValue() ]
    }

    GetNeard1Int()
    {
        return this.nerd1.type.GetValue()
    }

    GetNeard1Type()
    {
        return this.NerdType[ this.nerd1.type.GetValue() ]
    }

    GetNeard2Int()
    {
        return this.nerd2.type.GetValue()
    }

    GetNeard2Type()
    {
        return this.NerdType[ this.nerd2.type.GetValue() ]
    }    

    BuildMemoryObjects()
    {
        this.BuildEffectKey()

        this.nerd0 := new MemoryObject(0x20, 0x40, "Ptr", "", this.BaseAddress)
        this.nerd0.type := new MemoryObject(0x10, 0x20, "Int", this.nerd0, this.BaseAddress)
        this.nerd1 := new MemoryObject(0x24, 0x48, "Ptr", "", this.BaseAddress)
        this.nerd1.type := new MemoryObject(0x10, 0x20, "Int", this.nerd1, this.BaseAddress)
        this.nerd2 := new MemoryObject(0x28, 0x50, "Ptr", "", this.BaseAddress)
        this.nerd2.type := new MemoryObject(0x10, 0x20, "Int", this.nerd2, this.BaseAddress)
    }
}
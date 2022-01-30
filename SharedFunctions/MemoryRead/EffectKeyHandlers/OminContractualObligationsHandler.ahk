/*  A handler for Omin's Contractual Obligations ability

    Properties:
        numContractsFufilled ; Number of contracts fullfilled.
        secondsOnGoldFind ; Seconds remaining for Contractual Obligations gold find boost. Value is set to -1 when no boost is active.
*/

#include %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

class OminContractualObligationsHandler extends EffectKeyHandler
{
    ChampID := 65
    EffectKeyString := "contractual_obligations"
    RequiredLevel := 210
    EffectKeyID := 4110

    GetNumContractsFufilled()
    {
        return this.numContractsFufilled.GetValue()
    }

    GetSecondsOnGoldFind()
    {
        return this.secondsOnGoldFind.GetValue()
    }

    BuildMemoryObjects()
    {
        this.BuildEffectKey()
        ;effectKey has a different offset than standard.
        this.effectKey.Offset32 := 0x18
        this.effectKey.Offset64 := 0x30
        this.numContractsFufilled := new MemoryObject(0x38, 0x70, "Int", "", this.BaseAddress)
        this.secondsOnGoldFind := new MemoryObject(0x5C, 0x94, "Float", "", this.BaseAddress)
    }
}
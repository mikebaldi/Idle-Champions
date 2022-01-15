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
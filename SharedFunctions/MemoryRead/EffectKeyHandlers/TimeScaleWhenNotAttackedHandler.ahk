/*  A handler for Shandie's Dash ability

    Properties:
        active ; The handler, not Dash.
        scaleActive ; True or false for Dash ability is active.
        effectTimeValue ; Starts at 0 and counts up. At 60 Dash scaleActive should be truen and Dash on.
*/

#include %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

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
/*  A handler for Shandie's Dash ability

    Properties:
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

    GetScaleActive()
    {
        return this.scaleActive.GetValue()
    }

    GetEffectTime()
    {
        return this.effectTimeValue.GetValue()
    }

    BuildMemoryObjects()
    {
        this.BuildEffectKey()
        this.scaleActive := new MemoryObject(0xD0, 0x108, "Int", "", this.BaseAddress)
        this.effectTimeValue := new MemoryObject(0xD8, 0x110, "Double", "", this.BaseAddress)
    } 
}
/*  A handler for Havilar's Imps

    Properties:
        CurrentOtherImpIndex - 0 == no summoned 2nd imp, 1 == Dembo, 2 == forget but the next guy, 3 == also forget his name but the next one.
            Exception, when initiated, this field's value is set as 1, even though no imps have yet been summoned.
        ActiveImpsSize - Number of imps active. This should read 2 when Dembo or one of the others is summoned. Upon sacrificing it will read 1 for
            a short while before reading 0.
        SummonImpCooldownTimer - Timer that counts down from _CooldownTime when Summon Imp Ultimate is used. Negative value means off cool down.
        SacrificeImpCoolDownTimer - Same as SummonImpCooldownTimer, but for Sacrifice Imp Ultimate.
            When both of the above are less than 0, ultimate button should be ready to click.
*/

#include %A_LineFile%\..\IC_EffectKeyHandler_Class.ahk

class HavilarImpHandler extends EffectKeyHandler
{
    ChampID := 56
    EffectKeyString := "havilar_imps"
    RequiredLevel := 15
    EffectKeyID := 3431

    GetActiveImpsSize()
    {
        return this.activeImps._size.GetValue()
    }

    GetCurrentOtherImpIndex()
    {
        return this.currentOtherImpIndex.GetValue()
    }

    GetSummonImpCoolDownTimer()
    {
        return this.summonImpUltimate.CoolDownTimer.GetValue()
    }

    GetSacrificeImpCoolDownTimer()
    {
        return this.sacrificeImpUltimate.CoolDownTimer.GetValue()
    }

    BuildMemoryObjects()
    {
        this.BuildEffectKey()
        
        this.activeImps := new MemoryObject(0x34, 0x68, "Ptr", "", this.BaseAddress)
        this.activeImps._size := new MemoryObject(0xC, 0x18, "Int", this.activeImps, this.BaseAddress)
        this.currentOtherImpIndex := new MemoryObject(0x120, 0x1A8, "Int", "", this.BaseAddress)
        this.summonImpUltimate := new MemoryObject(0x58, 0xB0, "Ptr", "", this.BaseAddress)
        this.summonImpUltimate.CoolDownTimer := new MemoryObject(0x74, 0xAC, "Float", this.summonImpUltimate, this.BaseAddress)
        this.sacrificeImpUltimate := new MemoryObject(0x5C, 0xB8, "Ptr", "", this.BaseAddress)
        this.sacrificeImpUltimate.CoolDownTimer := new MemoryObject(0x74, 0xAC, "Float", this.sacrificeImpUltimate, this.BaseAddress)
    }
}
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

    ;pointer
    activeImpsOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x68
            Else
                return 0x34
        }
    }

    activeImpsSizeOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x18
            Else
                return 0xC
        }
    }

    ActiveImpsSize[]
    {
        get
        {
            return g_SF.Memory.GameManager.Main.read(this.baseAddress + HavilarImpHandler.activeImpsOffset, "int", HavilarImpHandler.activeImpsSizeOffset)
        }
    }

    currentOtherImpIndexOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x1A8
            Else
                return 0x120
        }
    }

    CurrentOtherImpIndex[]
    {
        get
        {
            return g_SF.Memory.GameManager.Main.read(this.baseAddress + HavilarImpHandler.currentOtherImpIndexOffset, "int")
        }
    }

    summonImpUltimateOffset[]
    {
        get
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xB0
            Else
                return 0x58
        }
    }

    summonImpCooldownTimerOffset[]
    {
        get
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xAC
            Else
                return 0x74
        }
    }

    SummonImpCooldownTimer[]
    {
        get
        {
            return g_SF.Memory.GameManager.Main.read(this.baseAddress + HavilarImpHandler.summonImpUltimateOffset, "float", HavilarImpHandler.summonImpCooldownTimerOffset)
        }
    }

    sacrificeImpUltimateOffset[]
    {
        get
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xB8
            Else
                return 0x5C
        }
    }


    sacrificeImpCooldownTimerOffset[]
    {
        get
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0xAC
            Else
                return 0x74
        }
    }

    SacrificeImpCooldownTimer[]
    {
        get
        {
            return g_SF.Memory.GameManager.Main.read(this.baseAddress + HavilarImpHandler.sacrificeImpUltimateOffset, "float", HavilarImpHandler.sacrificeImpCooldownTimerOffset)
        }
    }
}
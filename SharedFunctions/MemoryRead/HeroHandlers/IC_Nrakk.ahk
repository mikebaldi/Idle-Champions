class Nrakk
{
    static HeroID := 24
    class NrakkUltimateAttackHandler
    {
        static EffectKeyString := "nrakk_ultimate_handler"
        ReadInTargetArc()
        {
            lastSetFilledPercent := this.ReadLastSetFilledPercent()
            lastSetTargetArcPercent := this.ReadLastSetTargetArcPercent()
            if (lastSetFilledPercent == "") {
                return False
            }
            if (lastSetTargetArcPercent == "") {
                return False
            }
            return 1 - lastSetFilledPercent <= lastSetTargetArcPercent
        }

        ReadLastSetFilledPercent()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NrakkUltimateAttackHandler.overlay.lastSetFilledPercent.Read()
        }

        ReadLastSetTargetArcPercent()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NrakkUltimateAttackHandler.overlay.lastSetTargetArcPercent.Read()
        }

        ReadMaxAttacks()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NrakkUltimateAttackHandler.maxAttacks.Read()
        }

        ReadAttacksCounter()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NrakkUltimateAttackHandler.attacksCounter.Read()
        }
    }
}
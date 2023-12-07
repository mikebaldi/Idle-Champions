class Havilar
{
    static HeroID := 56
    class HavilarImpHandler
    {
        static EffectKeyString := "havilar_imps"
        GetCurrentOtherImpIndex()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.currentOtherImpIndex.Read()
        }
        
        GetActiveImpsSize()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.activeImps.size.Read()
        }

        GetSummonImpCoolDownTimer()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.summonImpUltimate.internalCooldownTimer.Read()
        }

        GetSacrificeImpCoolDownTimer()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.sacrificeImpUltimate.internalCooldownTimer.Read()
        }

        ; GetActiveImps1()
        ; {
        ;     fist := g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.activeImps[0].Read()
        ;     sec := g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.activeImps[1].Read()
        ;     return "[" . fist . ", " . sec . "]"
        ; }
    } 
}
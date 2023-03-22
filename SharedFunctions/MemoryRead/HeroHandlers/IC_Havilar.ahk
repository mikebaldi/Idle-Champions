class Havilar
{
    static HeroID := 56
    class HavilarImpHandler
    {
        static EffectKeyString := "havilar_imps"
        GetCurrentOtherImpIndex()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.activeImps.Read()
        }
        
        GetActiveImpsSize()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.currentOtherImpIndex.Read()
        }

        GetSummonImpCoolDownTimer()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.summonImpUltimate.CoolDownTimer.Read()
        }

        GetSacrificeImpCoolDownTimer()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HavilarImpHandler.sacrificeImpUltimate.CoolDownTimer.Read()
        }
    } 
}
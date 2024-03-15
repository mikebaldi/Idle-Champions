class Spurt
{
    static HeroID := 43
    class SpurtWaspirationHandlerV2
    {
        static EffectKeyString := "spurt_waspiration_v2"
        ; ReadSpurtStacksLeft()
        ; {
        ;     return g_SF.Memory.ActiveEffectKeyHandler.SpurtWaspirationHandlerV2.remainingStacksNeededForNextEffect.Read()
        ; }

        ReadSpurtWasps()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.SpurtWaspirationHandlerV2.activeWasps.size.Read()
        }
    }
}
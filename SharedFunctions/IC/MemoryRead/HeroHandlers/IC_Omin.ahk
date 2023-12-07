class Omin
{
    static HeroID := 65
    class OminContractualObligationsHandler
    {
        static EffectKeyString := "contractual_obligations"
        ReadNumContractsFulfilled()
        {
            contractsFulfilled := g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.numContractsFufilled.Read()
            if(contractsFulfilled != "" AND contractsFulfilled <= 100)
                return contractsFulfilled
            return g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.obligationsFufilled.Read()
        }

        ; ReadSecondsOnGoldFind()
        ; {
        ;     return g_SF.Memory.ActiveEffectKeyHandler.OminContractualObligationsHandler.secondsOnGoldFind)
        ; }
    }
}
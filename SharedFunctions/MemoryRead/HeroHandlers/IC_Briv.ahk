
class Briv
{
    static HeroID := 58
    class BrivUnnaturalHasteHandler
    {
        static EffectKeyString := "briv_unnatural_haste"
        ReadSkipChance()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areaSkipChance.Read()
        }

        ReadHasteStacks()
        {
                return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.sprintStacks.stackCount.Read()
        }

        ReadSkipAmount()
        {
                return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areaSkipAmount.Read()
        }

        ReadAreasSkipped()
        {
                return g_SF.Memory.ActiveEffectKeyHandler.BrivUnnaturalHasteHandler.areasSkipped.Read()
        }

    }
}
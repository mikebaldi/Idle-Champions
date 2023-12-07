
class Jim
{
    static HeroID := 48
    class JimMagicalMysteryTourHandler
    {
        static EffectKeyString := "jim_magical_mystery_tour"
        ReadMysteryStacks()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.JimMagicalMysteryTourHandler.effect_k__BackingField.effectKeyHandlers[0].stacks.stackCount.Read()
        }
    }
}
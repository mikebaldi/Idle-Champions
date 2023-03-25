class Nordom
{
    static HeroID := 100
    class NordomModronCoreToolboxHandler
    {
        static EffectKeyString := "nordom_modron_xp_buff"

        ReadAwardedXP()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NordomModronCoreToolboxHandler.controller.GameInstance_k__BackingField.StatHandler.NordomAwardedEXP.Read()
        }

        ReadPendingXP()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NordomModronCoreToolboxHandler.controller.GameInstance_k__BackingField.StatHandler.NordomPendingEXP.Read()
        }
    }
}
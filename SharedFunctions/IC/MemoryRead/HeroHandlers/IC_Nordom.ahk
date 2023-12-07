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

        ReadAwardedXPStat()
        {
            return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].StatHandler.NordomAwardedEXP.Read()
        }

        ReadPendingXP()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NordomModronCoreToolboxHandler.controller.GameInstance_k__BackingField.StatHandler.NordomPendingEXP.Read()
        }
    }
}
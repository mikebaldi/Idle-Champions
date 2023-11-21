class HewMaan
{
    static HeroID := 75
    class HewMaanTeamworkHandler
    {
        static EffectKeyString := "hewmaan_teamwork"
        ReadUltimateCooldownTimeLeft()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HewMaanTeamworkHandler.hewmaan.ultimateAttack.internalCooldownTimer.Read()
        }

        ReadUltimateID()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.HewMaanTeamworkHandler.hewmaan.ultimateAttack.ID.Read()
        }
    }
}
class Shandie
{
    static HeroID := 47
    class TimeScaleWhenNotAttackedHandler
    {
        static EffectKeyString := "time_scale_when_not_attacked"
        ReadDashActive()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.TimeScaleWhenNotAttackedHandler.scaleActive.Read()
        }
    }
}
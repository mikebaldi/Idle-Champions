
class Thellora
{
    static HeroID := 139
    class ThelloraPlateausOfUnicornRunHandler
    {
        static EffectKeyString := "thellora_plateaus_of_unicorn_run"
        ReadMaxRushArea()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.ThelloraPlateausOfUnicornRunHandler.baseFavorExponent.Read()
        }

        ReadRushStacks()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.ThelloraPlateausOfUnicornRunHandler.controller.userData.StatHandler.ServerStats["thellora_plateaus_of_unicorn_run_areas"].Read()
            ; return g_SF.Memory.UserData._instance.StatHandler.ServerStats["thellora_plateaus_of_unicorn_run_areas"].Read() ; Requires alternate pointer
        }

        ; ReadRushArea()
        ; {
        ;         return g_SF.Memory.ActiveEffectKeyHandler.ThelloraPlateausOfUnicornRunHandler.areaSkipAmount.Read()
        ; }
    }
}
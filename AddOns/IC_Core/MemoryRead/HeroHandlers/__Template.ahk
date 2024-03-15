/* TEMPLATE - REPLACE ALL <INSERT HANDLER NAME HERE> WITH HANDLER NAME, NO QUOTES

IC_ActiveEffectKeyHandler_Class.Add(<INSERT HANDLER NAME HERE>)
class <INSERT HERO NAME HERE>
{
    static HeroID := <INSERT HERO ID HERE, NO QUOTES BUT MAYBE OKAY>
    class <INSERT HANDLER NAME HERE>
    {
        static EffectKeyString := <INSERT EFFECT KEY STRING HERE, WITH QUOTES>
        <INSERT FUNCTION NAME HERE (e.g ReadAbilityValue1)>()
        {
            return g_SF.ActiveEffectKeyHandler.<INSERT HANDLER NAME HERE>.<INSERT NAME OF VALUE TO BE READ HERE>.Read()
        }
    }

    ; Each handler in game needs its own class here. There should only be one file/class per hero.
}


SAMPLE:
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
*/
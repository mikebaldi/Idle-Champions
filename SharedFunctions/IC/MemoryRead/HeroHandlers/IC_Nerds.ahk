class Nerds
{
    static HeroID := 87
    class NerdWagonHandler
    {
        static NerdType := {0:"None", 1:"Fighter_Orange", 2:"Ranger_Red", 3:"Bard_Green", 4:"Cleric_Yellow", 5:"Rogue_Pink", 6:"Wizard_Purple"}
        static EffectKeyString := "nerd_wagon"
        ReadNerd0()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd0.type.Read()
        }

        ReadNerd1()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd1.type.Read()
        }


        ReadNerd2()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.NerdWagonHandler.nerd2.type.Read()
        }

        ReadNerd0Type()
        {
            return this.NerdType[this.ReadNerd0()]
        }

        ReadNerd1Type()
        {
            return this.NerdType[this.ReadNerd1()]
        }

        ReadNerd2Type()
        {
            return this.NerdType[this.ReadNerd2()]
        }
    }
}
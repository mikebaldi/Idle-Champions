
class Ellywick
{
    static HeroID := 83
    class EllywickCallOfTheFeywildHandler
    {
        
        static CardType := {1:"Knight", 2:"Moon", 3:"Gem", 4:"Fates", 5:"Flames"}
        static EffectKeyString := "ellywick_call_of_the_feywild"

        ReadGemMult()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.controller.GameInstance_k__BackingField.StatHandler.EllywickGemMult.Read()
        }

        ReadCurrentMonsterKills()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.currentMonsterKills.Read()
        }

        ReadCardsInHand()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
            ; sanity check, 5 is the max number of cards in hands possible.
            if (size < 1 OR size > 5)
                return ""
            cards := []
            loop, %size%
            {
                currCard := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand[A_index - 1].CardType.Read()
                cards.Push(currCard)
            }
            return cards
        }

        ReadCardsInHandNames()
        {
            cards := this.ReadCardsInHand()
            size := cards.Length()
            namedCards := []
            loop, %size%
            {
                namedCards.push(this.CardType[cards[A_Index]])
            }
            return namedCards
        }

        ReadTempProbabilityMap()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.tempProbabilityMap.size.Read()
            ; sanity check, 5 should be the number of card types
            if (size != 5)
                return ""
            pmap := {}
            loop, 5
            {
                cardType := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.tempProbabilityMap["key", A_index - 1].Read()
                probability := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.tempProbabilityMap["value", A_index - 1].Read()
                pmap[cardType] := probability
            }
            return pmap
        }
        
        ReadUltimateActive()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.IsUltimateActive.Read()
        }

    }
}
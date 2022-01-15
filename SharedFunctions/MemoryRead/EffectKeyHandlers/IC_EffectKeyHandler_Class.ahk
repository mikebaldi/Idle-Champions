/*  A series of classes for reading memory from specific Effect Key Handlers

    Usage:
    global g_HandlerInstance := new HandlerClass ; Create an instance of the handler class. It doesn't have to be global.
    init := g_HandlerInstance.Initialize() ; Initialize the instance of the class, this has to be done every time the game restarts, 
        possibly after modron resets, and possibly through runs. Returns -1 if champ not leveled, -2 if can't find effect key name, 0 if likely success.
    isCorrect := g_HandlerInstance.IsBaseAddressCorrect() ; Check if the base address to the handler is correct, returns true or false. If false 
        call Initialize() method.
    field := g_HandlerInstance.GetFieldValue() ; Returns memory value associated with the property 'field', see specific handlers for properties.

    Each of the handler classes should include this file by default.
*/

class EffectKeyHandler
{
    DictIndex := ""
    BaseAddress := ""
    Initialized := false

    ; Returns -1 if champ not leveled, -2 if can't find effect key name, 0 if likely success.
    Initialize()
    {
        this.Initialized := this.CheckChampLevel()
        if !this.Initialized
            return -1
        this.DictIndex := this.GetDictIndex()
        if (this.DictIndex == -1)
        {
            this.Initialized := false
            return -2
        }
        this.BaseAddress := this.GetBaseAddress()
        return 0
    }

    CheckChampLevel()
    {
        if (g_SF.Memory.ReadChampLvlByID(this.ChampID) < this.RequiredLevel)
            return false
        else
            return true
    }
    
    GetDictIndex()
    {
        dictCount := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyNameCount.GetGameObjectFromListValues(this.ChampID - 1))
        i := 0
        loop, % dictCount
        {
            keyName := g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.Name.GetGameObjectFromDictValues( [ this.ChampID - 1, [ "key", i ] ]* ) )
            if (keyName == this.EffectKeyString)
                return i
            ++i
        }
        return -1
    }

    GetBaseAddress()
    {
        return g_SF.Memory.GenericGetValue(g_SF.Memory.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.effects.effectKeysByKeyName.effectKey.parentEffectKeyHandler.activeEffectHandlers.GetGameObjectFromDictValues( [ this.ChampID - 1, [ "value", this.DictIndex ] ]* ) )
    }

    IsBaseAddressCorrect()
    {
        readEffectKeyID := g_SF.Memory.GameManager.Main.read(this.baseAddress + EffectKeyHandler.effectKeyOffset, "int", EffectKeyHandler.effectKeyIDoffset*)
        if (readEffectKeyID != this.EffectKeyID)
        {
            this.Initialized := false
            return false
        }
        return true
    }

    effectKeyOffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return 0x28
            Else
                return 0x14
        }
    }

    effectKeyIDoffset[]
    {
        get 
        {
            if (g_SF.Memory.GameManager.Is64Bit())
                return [0x10, 0x10, 0x18, 0x10]
            Else
                return [0x8, 0x8, 0xC, 0x8]
        }
    }
}
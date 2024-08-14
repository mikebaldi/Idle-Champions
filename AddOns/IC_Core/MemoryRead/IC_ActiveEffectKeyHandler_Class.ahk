; ActiveEffectKeyHandler finds base addresses for ActiveEffectKeyHandler classes such as BrivUnnaturalHasteHandler and imports the offsets used for them.
; See the HeroHandlers folder for information on how to add more champions.
; ActiveAffectKeyHandler structures for Individual champions are not created until the champion's handler exists! (Must purchase/level champion)

class IC_ActiveEffectKeyHandler_Class
{
    HeroHandlerIDs := {} 
    HeroEffectNames := {}
    GameInstance := 0
    
    __new(memory := "")
    {
        for hero, heroObj in ActiveEffectKeySharedFunctions
        {
            for handler, handlerObj in heroObj
            {
                if(IsObject(heroObj) and IsObject(handlerObj))
                {
                    this.HeroHandlerIDs[handler] := heroObj.HeroID
                    this.HeroEffectNames[handler] := handlerObj.EffectKeyString
                }
            }
        }
        this.Memory := memory
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.5.0, 2024-08-14"
    }

    Refresh()
    {
        build := 0
        for k,v in this.HeroEffectNames
        {
            build := build OR this[this.HerroEffectNames[k]] == ""
            baseAddress := this.GetBaseAddress(k)
            if(baseAddress != this[k].BaseAddress)
            {
                this[k] := New GameObjectStructure([])
                this[k].Is64Bit := _MemoryManager.is64Bit
                this[k].BaseAddress := baseAddress
                this[k].BasePtr := this[k]
            }
        }
        if (!build)
            return
        if (_MemoryManager.is64Bit)
            this.Refresh64()
        else
            this.Refresh32()
    }

    Refresh32()
    {
        #include *i %A_LineFile%\..\Imports\ActiveEffectHandlers\IC_HeroHandlerIncludes32_Import.ahk
    }

    Refresh64()
    {
        #include *i %A_LineFile%\..\Imports\ActiveEffectHandlers\IC_HeroHandlerIncludes64_Import.ahk
    }

    GetBaseAddress(handlerName)
    {
        champID := this.HeroHandlerIDs[handlerName]
        effectName := this.HeroEffectNames[handlerName]
        ; assuming first item in effectKeysByKeyName[key]'s list. Note: DM has two for "force_allow_hero"
        ; need _items value to use offsets later      
        handlerAddressObj := this.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByKeyName[effectName].List[0].parentEffectKeyHandler.activeEffectHandlers._items
        ; Check for update that uses effectKeysByHashedKeyName instead of effectKeysByKeyName
        if (handlerAddressObj == "")
        {
            keyHash := this.GetKeyHash(champID, effectName)
            if(keyHash != "") 
            {
                handlerAddressObj := this.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByHashedKeyName[keyHash].List[0].parentEffectKeyHandler.activeEffectHandlers._items
            }
        }
        
        ; use first item in the _items list as base address so offsets work later
        address := handlerAddressObj.Read() + handlerAddressObj.CalculateOffset(0) 
        return address
    }

    ; Finds the KeyHash value when effectKeysByHashedKeyName is used instead of effectKeysByKeyName.
    GetKeyHash(champID, effectName)
    {
        size := this.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByHashedKeyName.size.Read()
        loop, %size%
        {
            effectNameLocal := this.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByHashedKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.Key.Read()
            if (effectName == effectNameLocal)
            {
                keyHash := this.Memory.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler.heroes[this.Memory.GetHeroHandlerIndexByChampID(ChampID)].effects.effectKeysByHashedKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.KeyHash.Read()
                return keyHash
            }
        }
        return ""           
    }

    ResetCollections()
    {
        for k,v in this.HeroEffectNames
        {
            this[k].ResetCollections()
        }
    }
}

#include *i %A_LineFile%\..\HeroHandlers\IC_ActiveEffectKeySharedFunctions_Class.ahk
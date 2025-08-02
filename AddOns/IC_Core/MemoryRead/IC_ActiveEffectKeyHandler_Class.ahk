; ActiveEffectKeyHandler finds base addresses for ActiveEffectKeyHandler classes such as BrivUnnaturalHasteHandler and imports the offsets used for them.
; See the HeroHandlers folder for information on how to add more champions.
; ActiveAffectKeyHandler structures for Individual champions are not created until the champion's handler exists! (Must purchase/level champion)

class IC_ActiveEffectKeyHandler_Class
{
    HeroHandlerIDs := {} 
    HeroEffectNames := {}
    GameManager := ""
    HeroHandler := ""
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
        this.GameManager := memory.GameManager
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.6.0, 2025-08-01"
    }

    ; Used to update the create new game objects or refresh base addresses when they change.
    Refresh(HandlerName := "")
    {
        ; reset HeroHandler in case the game was not open and GameManager objects were not built at startup.
        this.HeroHandler := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler
        if(HandlerName != "")
            this.RefreshHandler(HandlerName)
        else
            for k,v in this.HeroEffectNames
                this.RefreshHandler(k)
    }

    ;  
    RefreshHandler(HandlerName := "")
    {
        baseAddress := this.GetBaseAddress(HandlerName)
        if(this[HandlerName] == "")
            this.NewHandlerObject(HandlerName, baseAddress)
        else if(baseAddress != this[HandlerName].BaseAddress)
            this.UpdateBaseAddress(HandlerName, baseAddress)
    }

    NewHandlerObject(HandlerName, baseAddress)
    {
        this[HandlerName] := New GameObjectStructure([])
        this.UpdateBaseAddress(HandlerName, baseAddress)
        functionName := "Build" . HandlerName
        this.handlerFnc := ObjBindMethod(this, functionName)
        if (this.handlerFnc == "") ; import does not exist
            return
        this.handlerFnc()
    }

    UpdateBaseAddress(handlerName, baseAddress)
    {
        this[handlerName].Is64Bit := _MemoryManager.is64Bit
        this[handlerName].BaseAddress := baseAddress
        this[handlerName].BasePtr := this[handlerName]
        this.ResetBaseAddress(currentObj)
    }

    ResetBaseAddress(currentObj)
    {
        for k,v in currentObj
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure" AND v.FullOffsets != "" AND k != "BasePtr")
            {
                v.BaseAddress := currentObj.BaseAddress
                this.RebuildBaseAndOffsets(v)
            }
        }
    }

    GetBaseAddress(handlerName)
    {
        champID := this.HeroHandlerIDs[handlerName]    
        keyHash := this.GetKeyHash(champID, this.HeroEffectNames[handlerName])
        if(keyHash != "") 
            handlerAddressObj := this.HeroHandler.heroes[IC_MemoryFunctions_Class.GetHeroHandlerIndexByChampID(champID)].effects.effectKeysByHashedKeyName[keyHash].List[0].parentEffectKeyHandler.activeEffectHandlers._items
            ; assuming first item in effectKeysByHashedKeyName/effectKeysByKeyName[key]'s list. Note: DM has two for "force_allow_hero"
         ; use first item in the _items list as base address so offsets work later
        address := handlerAddressObj.Read() + handlerAddressObj.CalculateOffset(0) 
        return address
    }

    ; Finds the KeyHash value when effectKeysByHashedKeyName is used instead of effectKeysByKeyName.
    GetKeyHash(champID, effectName)
    {
        effectsByKeyName := this.HeroHandler.heroes[IC_MemoryFunctions_Class.GetHeroHandlerIndexByChampID(champID)].effects.effectKeysByHashedKeyName
        size := effectsByKeyName.size.Read()
        loop, %size%
            if (effectName == effectsByKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.Key.Read())
                return keyHash := effectsByKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.KeyHash.Read()
        return ""           
    }

    ResetCollections()
    {
        for k,v in this.HeroEffectNames
            this[k].ResetCollections()
    }
    #include *i %A_LineFile%\..\Imports\ActiveEffectHandlers\IC_HeroHandlerIncludes64_Import.ahk
}

#include *i %A_LineFile%\..\HeroHandlers\IC_ActiveEffectKeySharedFunctions_Class.ahk
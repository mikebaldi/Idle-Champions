; ActiveEffectKeyHandler finds base addresses for ActiveEffectKeyHandler classes such as BrivUnnaturalHasteHandler and imports the offsets used for them.
; See the HeroHandlers folder for information on how to add more champions.
; ActiveAffectKeyHandler structures for Individual champions are not created until the champion's handler exists! (Must purchase/level champion)

class IC_ActiveEffectKeyHandler_Class
{
    HeroHandlerIDs := {} 
    HeroEffectNames := {}
    HeroEffectKeys := {}
    GameManager := ""
    HeroHandler := ""
    GameInstance := 0
    HeroIDMap := {}
    HeroMapFunction := ""
    
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
                    this.HeroEffectKeys[handlerObj.EffectKeyString] := handler
                }
            }
        }
        this.GameManager := memory.GameManager
        this.HeroMapFunction := ObjBindMethod(memory, "GetChampIDToIndexMap")
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.6.4, 2025-08-11"
    }

    ; Used to update the create new game objects or refresh base addresses when they change.
    Refresh(HandlerEffectKey := "")
    {
        ; reset HeroHandler in case the game was not open and GameManager objects were not built at startup.
        this.HeroHandler := this.GameManager.game.gameInstances[this.GameInstance].Controller.userData.HeroHandler
        if (this.HeroIDMap.Count() <= 0) ; get list once - same every time
            this.HeroIDMap := this.HeroMapFunction() ; maps champion ID to its index in the hero handler
        if(HandlerEffectKey != "")
            this.RefreshHandler(HandlerEffectKey)
        else
            for k,v in this.HeroEffectKeys
                this.RefreshHandler(k)
    }

    ;  
    RefreshHandler(HandlerEffectKey := "")
    {
        HandlerName := this.HeroEffectKeys[HandlerEffectKey] 
        baseAddress := this.GetBaseAddress(HandlerName)
        if(this[HandlerName] == "")
            this.NewHandlerObject(HandlerName, baseAddress)
        else if(baseAddress != this[HandlerName].BasePtr.BaseAddress)
        { 
            this[handlerName].BasePtr.BaseAddress := baseAddress
            this[handlerName].ResetBasePtr(this[handlerName])
        }
    }

    NewHandlerObject(HandlerName, baseAddress)
    {
        this[handlerName] := New GameObjectStructure([])
        this[handlerName].BasePtr := new SH_BasePtr(baseAddress, 0, 0, "ActiveEffectKeyHandler")
        functionName := "Build" . HandlerName
        this.handlerFnc := ObjBindMethod(this, functionName)
        if (this.handlerFnc == "") ; import does not exist
            return
        this.handlerFnc() ; Build child objects from imports.
    }

    GetBaseAddress(handlerName)
    {
        champID := this.HeroHandlerIDs[handlerName]    
        keyHash := this.GetKeyHash(champID, this.HeroEffectNames[handlerName])
        if(keyHash != "") ; assuming first item in effectKeysByHashedKeyName/effectKeysByKeyName[key]'s list. Note: DM has two for "force_allow_hero"
            handlerAddressObj := this.HeroHandler.heroes[this.HeroIDMap[champID]].effects.effectKeysByHashedKeyName[keyHash].List[0].parentEffectKeyHandler.activeEffectHandlers._items
        address := handlerAddressObj.Read() + handlerAddressObj.CalculateOffset(0) ; use first item in the _items list as base address so offsets work later
        return address
    }

    ; Finds the KeyHash value when effectKeysByHashedKeyName is used instead of effectKeysByKeyName.
    GetKeyHash(champID, effectName)
    {
        effectsByKeyName := this.HeroHandler.heroes[this.HeroIDMap[champID]].effects.effectKeysByHashedKeyName
        size := effectsByKeyName.size.Read()
        loop, %size%
        {
            if (effectName == effectsByKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.Key.Read())
                return keyHash := effectsByKeyName["value", A_Index - 1].List[0].parentEffectKeyHandler.def.KeyHash.Read()
        }
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
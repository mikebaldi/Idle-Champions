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
        this.BuildMemoryObjects()
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
        tempObject := g_SF.Memory.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.effects.effectKeysByKeyName.size.GetGameObjectFromListValues(0, this.ChampID - 1)
        dictCount := g_SF.Memory.GenericGetValue(tempObject)
        i := 0
        loop, % dictCount
        {
            tempObject := g_SF.Memory.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.effects.effectKeysByKeyName.GetGameObjectFromListValues(0, this.ChampID - 1)
            currOffset := tempObject.CalculateDictOffset(["key", i])
            tempObject.FullOffsets.Push(currOffset)
            tempObject.ValueType := "UTF-16"
            testString := ArrFnc.GetHexFormattedArrayString(tempObject.FullOffsets)
            keyName := g_SF.Memory.GenericGetValue(tempObject)
            if (keyName == this.EffectKeyString)
                return i
            ++i
        }
        return -1
    }

    GetBaseAddress()
    {
        ;tempObject := g_SF.Memory.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.effects.effectKeysByKeyName.parentEffectKeyHandler.activeEffectHandlers.GetGameObjectFromListValues( 0, this.ChampID - 1)
        tempObject := g_SF.Memory.GameManager.game.gameInstances.Controller.userData.HeroHandler.heroes.effects.effectKeysByKeyName.parentEffectKeyHandler.activeEffectHandlers.size.GetGameObjectFromListValues( 0, this.ChampID - 1)
        ; add dictionary value from effectkeysbyname
        currOffset := tempobject.CalculateDictOffset(["value", this.DictIndex]) + 0 
        tempObject.FullOffsets.InsertAt(15, currOffset)
        ; insert list items offset
        tempObject.FullOffsets.InsertAt(16, g_SF.Memory.GameManager.Is64Bit() ? 0x20 : 0x8)
        ; insert first list item offset (Assuming only 1 item in effectkeyslist of effectkeysbyname (the dictionary value is a List<EffectKey>) list?)
        tempObject.FullOffsets.InsertAt(17, g_SF.Memory.GameManager.Is64Bit() ? 0x20 : 0x10)
        testHexString := ArrFnc.GetHexFormattedArrayString(tempObject.FullOffsets)
        OutputDebug, %testHexString%
        _size := g_SF.Memory.GenericGetValue(tempObject)
        ; Remove the "size" from the offsets list
        tempObject.FullOffsets.Pop()
        ; insert first list item offset (Assuming only 1 item in activeEffectKeys list)
        tempObject.FullOffsets.Push(g_SF.Memory.GameManager.Is64Bit() ? 0x20 : 0x8)
        testHexString := ArrFnc.GetHexFormattedArrayString(tempObject.FullOffsets)
        OutputDebug, %testHexString%
        address := g_SF.Memory.GenericGetValue(tempObject) + tempObject.CalculateOffset(0)
        return address
    }

    IsBaseAddressCorrect()
    {
        readEffectKeyID := this.effectKey.parentEffectKeyHandler.parent.source.ID.GetValue()

        valueActive := g_SF.Memory.GameManager.Main.read(0x3194A6C0, "Int", 0x14, 0x8, 0x8, 0xC, 0x8)        
        valueActive := g_SF.Memory.GameManager.Main.read(0x3194A6C0, "Char", 0x10)        
        areasSkipped := g_SF.Memory.GameManager.Main.read(0x3194A6C0, "Int", 0x34)     
        resolutionSmall := g_SF.Memory.GameManager.Main.read(0x1165AF00, "Int", 0x44)     
           
        areasSkipped := this.areasSkipped.GetValue()
        debugString := ArrFnc.GetHexFormattedArrayString(this.effectKey.parentEffectKeyHandler.parent.source.ID.FullOffsets)
        OutputDebug, %debugString%
        if (readEffectKeyID != this.EffectKeyID)
        {
            this.Initialized := false
            return false
        }
        return true
    }

    BuildEffectKey()
    {
        this.effectKey := new MemoryObject(0x14, 0x28, "Ptr", "", this.BaseAddress)
        this.effectKey.parentEffectKeyHandler := new MemoryObject(0x8, 0x10, "Ptr", this.effectKey, this.BaseAddress)
        this.effectKey.parentEffectKeyHandler.parent := new MemoryObject(0x8, 0x10, "Ptr", this.effectKey.parentEffectKeyHandler, this.BaseAddress)
        this.effectKey.parentEffectKeyHandler.parent.def := new MemoryObject(0x8, 0x10, "Ptr", this.effectKey.parentEffectKeyHandler.parent, this.BaseAddress)
        this.effectKey.parentEffectKeyHandler.parent.def.ID := new MemoryObject(0x8, 0x10, "Int", this.effectKey.parentEffectKeyHandler.parent.def, this.BaseAddress)
        this.effectKey.parentEffectKeyHandler.parent.source := new MemoryObject(0xC, 0x18, "Ptr", this.effectKey.parentEffectKeyHandler.parent, this.BaseAddress)
        this.effectKey.parentEffectKeyHandler.parent.source.ID := new MemoryObject(0x8, 0x10, "Int", this.effectKey.parentEffectKeyHandler.parent.source, this.BaseAddress)
    }

    BuildMemoryObjects()
    {
        this.BuildEffectKey()
    }
}

class MemoryObject
{
    __new(32BitOffset, 64BitOffset, valueType, parentObj, baseAddress)
    {
        this.ValueType := valueType
        this.Offset32 := 32BitOffset
        this.Offset64 := 64BitOffset
        this.ParentObj := parentObj
        this.Is64Bit := g_SF.Memory.GameManager.Is64Bit()
        this.BaseAddress := baseAddress
    }

    FullOffsets[]
    {
        get 
        {
            offsets := {}
            If IsObject(this.ParentObj)
                offsets := this.ParentObj.FullOffsets
            offsets.Push(this.Offset)
            return offsets
        }
    }

    Offset[]
    {
        get 
        {
            if (this.Is64Bit)
                return this.Offset64
            Else
                return this.Offset32
        }
    }

    GetValue()
    {
        if (this.ValueType == "Ptr")
            return g_SF.Memory.GameManager.Main.getAddressFromOffsets(this.BaseAddress, this.FullOffsets*)
        else
        {
            fullOffsets := this.FullOffsets
            fullOffsets := ArrFnc.GetHexFormattedArrayString(fullOffsets)
            value := g_SF.Memory.GameManager.Main.read(this.BaseAddress, this.ValueType, this.FullOffsets*)
            return g_SF.Memory.GameManager.Main.read(this.BaseAddress, this.ValueType, this.FullOffsets*)
        }
    }
}
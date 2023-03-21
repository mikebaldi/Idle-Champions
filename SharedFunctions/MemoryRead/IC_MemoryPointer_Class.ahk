; GameManager class contains the in game data structure layout

#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_MemoryPointer_Class
{
    moduleOffset := 0
    structureOffsets := 0

    __new(moduleOffset := 0, structureOffsets := 0)
    {
        this.moduleOffset := moduleOffset
        this.structureOffsets := structureOffsets
        this.Refresh()
    }

    __Get(key)
    {
        if(this.HasKey(key))
        {
            if(IsObject(this[key])) ; This will only get triggered if __Get is called explicitly since __Get does not get called if the key already exists (not as a property/function)
            {
                this[key].FullOffsets.Push(this.structureOffsets*)
                this[key].FullOffsets.Push(this[key].Offset*)
            }
            ;return ; Not returning a value allows AHK to use standard behavior for gets.
            return this[key] 
        }
    }

    GetVersion()
    {
        return "v0.0.1, 2023-03-18"
    }

    is64Bit()
    {
        return _MemoryManager.is64bit
    }

    Refresh()
    {
        _MemoryManager.Refresh()
        this.BaseAddress := _MemoryManager.baseAddress+this.moduleOffset
    }
}
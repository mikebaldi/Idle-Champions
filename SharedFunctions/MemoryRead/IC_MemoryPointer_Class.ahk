; GameManager class contains the in game data structure layout

#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_MemoryPointer_Class
{
    ModuleOffset := 0
    StructureOffsets := 0
    BaseAddress := ""

    __new(moduleOffset := 0, structureOffsets := 0)
    {
        this.ModuleOffset := moduleOffset
        this.StructureOffsets := structureOffsets
        this.Refresh()
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
        this.BaseAddress := _MemoryManager.baseAddress+this.ModuleOffset
    }
}
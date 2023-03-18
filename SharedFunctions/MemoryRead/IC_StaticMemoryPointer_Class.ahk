; GameManager class contains the in game data structure layout

#include %A_LineFile%\..\IC_MemoryPointer_Class.ahk

class IC_StaticMemoryPointer_Class extends IC_MemoryPointer_Class
{
    staticOffset := 0

    __new(moduleOffset := 0, staticOffset := 0, structureOffsets := 0)
    {
        this.moduleOffset := moduleOffset
        this.structureOffsets := structureOffsets
        this.StaticOffset := staticOffset
        this.Refresh()
    }

    GetVersion()
    {
        return "v0.0.1, 2023-03-18"
    }
}
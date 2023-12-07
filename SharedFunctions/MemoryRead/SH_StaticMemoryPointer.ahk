; GameManager class contains the in game data structure layout

#include %A_LineFile%\..\SH_MemoryPointer.ahk

class SH_StaticMemoryPointer extends SH_MemoryPointer
{
    staticOffset := 0

    __new(moduleOffset := 0, staticOffset := 0, structureOffsets := 0)
    {
        this.ModuleOffset := moduleOffset + 0
        this.StaticOffset := staticOffset + 0
        ; Do math on strings created by json to make sure they are values, otherwise memory leaks can occur in memory reads.
        if(structureOffsets.Count() > 0)
        {
            size := structureOffsets.Count()
            loop, %size%
            {
                structureOffsets[A_Index] := structureOffsets[A_Index] + 0
            }
        }
        else
        {
            structureOffsets := structureOffsets + 0
        }
        this.structureOffsets := structureOffsets
        this.Refresh()
    }

    GetVersion()
    {
        return "v0.0.2, 2023-09-03"
    }
}
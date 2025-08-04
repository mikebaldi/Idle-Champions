; GameManager class contains the in game data structure layout

; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; Is64Bit identifies if the object is using 32-bit or 64-bit addresses.

#include %A_LineFile%\..\SH__MemoryManager.ahk
#include %A_LineFile%\..\SH_GameObjectStructure.ahk

class SH_BasePtr
{
    ModuleOffset := 0
    StructureOffsets := 0
    BaseAddress := ""
    Is64bit := True

    __new(baseAddress := 0, moduleOffset := 0, structureOffsets := 0, is64Bit := True)
    {
        this.BaseAddress := baseAddress
        this.ModuleOffset := moduleOffset
        this.StructureOffsets := structureOffsets
        this.Is64Bit := is64Bit
    }
}

class SH_MemoryPointer
{
    ModuleOffset := 0
    StructureOffsets := 0
    BaseAddress := ""
    Is64Bit := ""

    __new(moduleOffset := 0, structureOffsets := 0)
    {
        this.ModuleOffset := moduleOffset == "" ? "" : moduleOffset + 0
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
        this.StructureOffsets := structureOffsets
        this.Refresh()
    }

    GetVersion()
    {
        return "v0.0.3, 2025-08-03"
    }
}
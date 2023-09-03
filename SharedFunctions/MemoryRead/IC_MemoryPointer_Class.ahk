; GameManager class contains the in game data structure layout

; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; Is64Bit identifies if the object is using 32-bit or 64-bit addresses.

#include %A_LineFile%\..\IC_MemoryManager_Class.ahk
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_MemoryPointer_Class
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
        return "v0.0.2, 2023-09-03"
    }

    Refresh()
    {
        ; _MemoryManager should only be refreshed outside of MemoryPointer, but must be refreshed before refreshing a memory pointer.
        _MemoryManager.Refresh()       
        this.BaseAddress := _MemoryManager.baseAddress+this.ModuleOffset
        this.Is64Bit := _MemoryManager.is64Bit
    }

    ResetCollections()
    {
        for k,v in this
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure")
                this[k].ResetCollections()
        }
    }
}
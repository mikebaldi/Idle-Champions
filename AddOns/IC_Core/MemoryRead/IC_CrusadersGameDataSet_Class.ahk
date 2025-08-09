; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
; Note static loc is == its instance loc

class IC_CrusadersGameDataSet_Class extends SH_MemoryPointer
{
    GetVersion()
    {
        return "v2.1.2, 2025-08-06"
    }
    
    Refresh()
    {        
        if (_MemoryManager.is64bit == "") ; Don't build offsets if no client is available to check variable types.
            return
        baseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.BasePtr.BaseAddress != baseAddress)
        {
            this.BasePtr.BaseAddress := baseAddress
            this.Is64Bit := _MemoryManager.is64bit
            if (this.CrusadersGame == "")
            {
                this.CrusadersGame := {}
                this.CrusadersGame.Defs := {}
                this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( this.StructureOffsets)
                this.CrusadersGame.Defs.CrusadersGameDataSet.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := _MemoryManager.is64bit
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
                return
            }
            this.CrusadersGame.Defs.CrusadersGameDataSet.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets, "CrusadersGameDataSet")
            this.ResetBasePtr(this.CrusadersGame.Defs.CrusadersGameDataSet)
        }
    }
}

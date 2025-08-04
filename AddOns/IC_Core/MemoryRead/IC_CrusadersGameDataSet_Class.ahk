; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
; Note static loc is == its instance loc

class IC_CrusadersGameDataSet_Class extends SH_MemoryPointer
{
    GetVersion()
    {
        return "v2.1.1, 2025-08-03"
    }
    
    Refresh()
    {
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            if (this.CrusadersGame == "")
            {
                this.CrusadersGame := {}
                this.CrusadersGame.Defs := {}
                this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( this.StructureOffsets)
                this.CrusadersGame.Defs.CrusadersGameDataSet.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := _MemoryManager.is64bit
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
            }
            else
            {
                this.CrusadersGame.Defs.CrusadersGameDataSet.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.Defs.CrusadersGameDataSet.ResetBasePtr(this.CrusadersGame.Defs.CrusadersGameDataSet)
            }
        }
    }
}

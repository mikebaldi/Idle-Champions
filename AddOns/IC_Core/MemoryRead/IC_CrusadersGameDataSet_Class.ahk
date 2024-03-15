; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
; Note static loc is == its instance loc

class IC_CrusadersGameDataSet_Class extends SH_MemoryPointer
{
    GetVersion()
    {
        return "v2.1.0, 2023-03-18"
    }
    
    Refresh()
    {
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            this.CrusadersGame := {}
            this.CrusadersGame.Defs := {}
            this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( this.StructureOffsets )
            this.CrusadersGame.Defs.CrusadersGameDataSet.BasePtr := this
            this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := _MemoryManager.is64bit
            if(!_MemoryManager.is64bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
            }
        }
    }
}

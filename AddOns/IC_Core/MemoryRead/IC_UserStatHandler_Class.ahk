class IC_UserStatHandler_Class extends SH_StaticMemoryPointer
{
    GetVersion()
    {
        return "v0.0.2, 2025-08-03"
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
                this.CrusadersGame.User := {}
                this.CrusadersGame.User.UserStatHandler := new GameObjectStructure(this.StructureOffsets)
                this.CrusadersGame.User.UserStatHandler.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.User.UserStatHandler.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_UserStatHandler64_Import.ahk
            }
            else
            {
                this.CrusadersGame.User.UserStatHandler.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.User.UserStatHandler.ResetBasePtr(this.CrusadersGame.User.UserStatHandler)
            }
        }
    }
}
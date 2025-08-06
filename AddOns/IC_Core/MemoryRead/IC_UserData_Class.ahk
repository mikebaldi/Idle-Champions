class IC_UserData_Class extends SH_StaticMemoryPointer
{
    GetVersion()
    {
        return "v0.0.2, 2025-08-03"
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
                this.CrusadersGame.User := {}
                this.CrusadersGame.User.UserData := new GameObjectStructure(this.StructureOffsets)
                this.CrusadersGame.User.UserData.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.User.UserData.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_UserData64_Import.ahk
                return
            }
            this.CrusadersGame.User.UserData.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
            this.ResetBasePtr(this.CrusadersGame.User.UserData)
        }
    }
}
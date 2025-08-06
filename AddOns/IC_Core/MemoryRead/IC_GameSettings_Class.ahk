; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
class IC_GameSettings_Class extends SH_StaticMemoryPointer
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
                this.CrusadersGame.GameSettings := new GameObjectStructure(this.StructureOffsets)
                this.CrusadersGame.GameSettings.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.GameSettings.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
                return
            }
            this.CrusadersGame.GameSettings.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
            this.ResetBasePtr(this.CrusadersGame.GameSettings)
        }
    }
}
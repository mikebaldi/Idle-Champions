; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
class IC_GameSettings_Class extends SH_StaticMemoryPointer
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
                this.CrusadersGame.GameSettings := new GameObjectStructure(this.StructureOffsets)
                this.CrusadersGame.GameSettings.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.GameSettings.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
            }
            else
            {
                this.CrusadersGame.GameSettings.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.CrusadersGame.GameSettings.ResetBasePtr(this.CrusadersGame.GameSettings)
            }
        }
    }
}
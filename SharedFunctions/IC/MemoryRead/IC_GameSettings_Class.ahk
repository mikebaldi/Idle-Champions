; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
class IC_GameSettings_Class extends SH_StaticMemoryPointer
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
            this.CrusadersGame.GameSettings := new GameObjectStructure(this.StructureOffsets)
            this.CrusadersGame.GameSettings.BasePtr := this
            this.CrusadersGame.GameSettings.Is64Bit := _MemoryManager.is64Bit
            if(!_MemoryManager.is64Bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_GameSettings32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
            }
        }
    }
}
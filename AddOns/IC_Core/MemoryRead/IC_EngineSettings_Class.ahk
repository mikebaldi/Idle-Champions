; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
class IC_EngineSettings_Class extends SH_StaticMemoryPointer
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
            if (this.UnityGameEngine == "")
            {
                this.UnityGameEngine := {}
                this.UnityGameEngine.Core := {}
                this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure(this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk
            }
            else
            {
                this.UnityGameEngine.Core.EngineSettings.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.ResetBasePtr(this.UnityGameEngine.Core.EngineSettings)
            }
        }
    }
}
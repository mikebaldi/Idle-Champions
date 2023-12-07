; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
class IC_EngineSettings_Class extends SH_StaticMemoryPointer
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
            this.UnityGameEngine := {}
            this.UnityGameEngine.Core := {}
            this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure(this.StructureOffsets)
            this.UnityGameEngine.Core.EngineSettings.BasePtr := this
            this.UnityGameEngine.Core.EngineSettings.Is64Bit := _MemoryManager.is64Bit
            if(!_MemoryManager.is64Bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_EngineSettings32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk    
            }
        }
    }
}
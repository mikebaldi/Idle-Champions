; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
class IC_EngineSettings_Class extends SH_StaticMemoryPointer
{
    GetVersion()
    {
        return "v2.1.3, 2025-08-11"
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
            if (this.UnityGameEngine == "")
            {
                this.UnityGameEngine := {}
                this.UnityGameEngine.Core := {}
                this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure(this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk
                return
            }
            this.UnityGameEngine.Core.EngineSettings.BasePtr := new SH_BasePtr(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets, "EngineSettings")
            this.ResetBasePtr(this.UnityGameEngine.Core.EngineSettings)
        }
    }
}
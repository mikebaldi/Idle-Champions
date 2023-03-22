; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
#include %A_LineFile%\..\IC_StaticMemoryPointer_Class.ahk
class IC_EngineSettings_Class extends IC_StaticMemoryPointer_Class
{
    GetVersion()
    {
        return "v2.1.0, 2023-03-18"
    }

    Refresh()
    {
        baseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if(baseAddress != this.BaseAddress)
        {
            this.BaseAddress := baseAddress
            this.UnityGameEngine := {}
            this.UnityGameEngine.Core := {}
            this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure(this.StructureOffsets)
            this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
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
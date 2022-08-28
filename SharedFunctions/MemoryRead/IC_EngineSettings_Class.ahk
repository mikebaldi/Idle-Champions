; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_EngineSettings_Class
{
    moduleOffset := 0
    structureOffsets := 0
    staticOffset := 0

    __new(moduleOffset := 0, staticOffset := 0, structureOffsets := 0)
    {
        this.moduleOffset := moduleOffset
        this.structureOffsets := structureOffsets
        this.StaticOffset := staticOffset
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.0.2, 2022-08-28, IC v0.463+"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe " . g_userSettings[ "ExeName"], "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+this.moduleOffset
        this.UnityGameEngine := {}
        this.UnityGameEngine.Core := {}
        this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure(this.structureOffsets)
        this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
        this.UnityGameEngine.Core.EngineSettings.Is64Bit := this.Main.isTarget64bit
        if(!this.Main.isTarget64bit)
        {
            #include %A_LineFile%\..\Imports\IC_EngineSettings32_Import.ahk
        }
        else
        {
            #include %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk    
        }
    }
}
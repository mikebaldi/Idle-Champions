; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_EngineSettings_Class
{
    StaticOffset := 0x0
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.0.0, 2022-08-18, IC v0.463+"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        if(!this.Main.isTarget64bit)
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
            this.UnityGameEngine := {}
            this.UnityGameEngine.Core := {}
            this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x20])
            this.StaticOffset := 0xFC0
            this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_EngineSettings32_Import.ahk
        }
        else
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x004A7678 ; v463+
            this.UnityGameEngine := {}
            this.UnityGameEngine.Core := {}
            this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x2A0]) ; v452
            this.StaticOffset := 0xF60
            this.UnityGameEngine.Core.EngineSettings.Is64Bit := true
            this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk    
        }
    }
}
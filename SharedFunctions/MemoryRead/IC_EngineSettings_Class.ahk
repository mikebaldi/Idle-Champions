; EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_EngineSettings32_Class
{
    StaticOffset := 0xF88
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 12/03/21, IC v0.414+, 32-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
        this.UnityGameEngine := {}
        this.UnityGameEngine.Core := {}
        this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x1C])
        this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_EngineSettings32_Import.ahk
    }
}

class IC_EngineSettings64_Class
{
    StaticOffset := 0xF60
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 2022-01-31, IC v0.414+, 64-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493DC8 ; v414-435
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x004A3658 ; v435
        this.UnityGameEngine := {}
        this.UnityGameEngine.Core := {}
        ; this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x1C]) ; v414-433
        ; this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x30]) ; v435
        this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x2A0])
        ; this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x30, 0x60, 0xC0, 0xC0]) ; v435 static - 0xEA0
        ; this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x30, 0x60, 0x0]) ; v435
        this.UnityGameEngine.Core.EngineSettings.Is64Bit := true
        this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_EngineSettings64_Import.ahk       
    }
}
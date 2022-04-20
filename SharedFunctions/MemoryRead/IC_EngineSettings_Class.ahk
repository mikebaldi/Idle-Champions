; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
; pointer scan for depth of 2 has been fine.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_EngineSettings_Class
{
    
    StaticOffset := 0xF88
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 12/03/21, IC v0.414+, Steam"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
        this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x1C])
        this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\IC_EngineSettings32_Export.ahk
    }
}

class IC_EngineSettingsEGS_Class
{
    
    StaticOffset := 0xF60
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 2022-01-31, IC v0.414+, EGS"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493DC8
        this.UnityGameEngine.Core.EngineSettings := new GameObjectStructure([0x1C])
        this.UnityGameEngine.Core.EngineSettings.Is64Bit := true
        this.UnityGameEngine.Core.EngineSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\IC_EngineSettings64_Export.ahk       
    }
}
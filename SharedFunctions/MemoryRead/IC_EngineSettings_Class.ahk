#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
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
        this.EngineSettings := new GameObjectStructure([0x1C])
        this.EngineSettings.BaseAddress := this.BaseAddress
        this.EngineSettings.WebRoot := new GameObjectStructure(this.EngineSettings,"UTF-16",[this.StaticOffset + 0x8, 0xC])
    }
}

; EGS variation of GameSettings (Thanks to Fenume for updating offsets for 412)
class IC_EngineSettingsEGS_Class
{
    
    StaticOffset := 0xF60
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 12/03/21, IC v0.414+, EGS"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493DC8
        this.EngineSettings := new GameObjectStructure([0x30])
        this.EngineSettings.BaseAddress := this.BaseAddress
        this.EngineSettings.WebRoot := new GameObjectStructure(this.EngineSettings,"UTF-16",[this.StaticOffset + 0x10, 0x14])
    }
}
; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_GameSettings_Class
{
    StaticOffset := 0xE00
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.5, 2022-04-16, IC v0.430+, Steam"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
        this.GameSettings := new GameObjectStructure([0xE0])
        #include %A_LineFile%\..\IC_GameSettings64_Export.ahk
    }
}

class IC_GameSettingsEGS_Class
{
    StaticOffset := 0xA80
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0.4, 2022-04-14, IC v0.428+, EGS"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493e40
        this.GameSettings := new GameObjectStructure([0x820])
        this.GameSettings.Is64Bit := true
        this.GameSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\IC_GameSettings64_Export.ahk
    }
}
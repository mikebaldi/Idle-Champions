; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_GameSettings32_Class
{
    StaticOffset := 0xE00
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.5, 2022-04-16, IC v0.430+, 32-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
        this.CrusadersGame := {}
        this.CrusadersGame.GameSettings := new GameObjectStructure([0xE0])
        this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_GameSettings32_Import.ahk
    }
}

class IC_GameSettings64_Class
{
    StaticOffset := 0xA80
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0.4, 2022-04-14, IC v0.428+, 64-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493e40
        this.CrusadersGame := {}
        this.CrusadersGame.GameSettings := new GameObjectStructure([0x820])
        this.CrusadersGame.GameSettings.Is64Bit := true
        this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
    }
}
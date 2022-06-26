; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_GameSettings32_Class
{
    StaticOffset := 0x130
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.6, 2022-06-24, IC v0.452+, 32-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A4F74
        this.CrusadersGame := {}
        this.CrusadersGame.GameSettings := new GameObjectStructure([0x8, 0xC, 0x60])
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
        return "v1.0.5, 2022-06-24, IC v0.452+, 64-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00497E40 ; v452
        this.CrusadersGame := {}
        this.CrusadersGame.GameSettings := new GameObjectStructure([0x820])
        this.CrusadersGame.GameSettings.Is64Bit := true
        this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
    }
}
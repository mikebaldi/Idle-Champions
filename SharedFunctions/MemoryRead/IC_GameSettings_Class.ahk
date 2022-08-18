; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_GameSettings_Class
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
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A4F74
            this.CrusadersGame := {}
            this.CrusadersGame.GameSettings := new GameObjectStructure([0x8, 0xC, 0x60])
            this.StaticOffset := 0x130
            this.CrusadersGame.GameSettings.Is64Bit := false
            this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_GameSettings32_Import.ahk
        }
        else
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00497E40 ; v463
            this.CrusadersGame := {}
            this.CrusadersGame.GameSettings := new GameObjectStructure([0x820])
            this.StaticOffset := 0xA80
            this.CrusadersGame.GameSettings.Is64Bit := true
            this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
        }
    }
}
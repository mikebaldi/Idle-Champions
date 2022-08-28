; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
class IC_GameSettings_Class
{
    moduleOffset := 0
    structureOffsets := 0
    StaticOffset := 0

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
        this.CrusadersGame := {}
        this.CrusadersGame.GameSettings := new GameObjectStructure(this.structureOffsets)
        this.CrusadersGame.GameSettings.Is64Bit := this.Main.isTarget64bit
        this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
        if(!this.Main.isTarget64bit)
        {
            #include %A_LineFile%\..\Imports\IC_GameSettings32_Import.ahk
        }
        else
        {
            #include %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
        }
    }
}
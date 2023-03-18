; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
#include %A_LineFile%\..\IC_StaticMemoryPointer_Class.ahk
class IC_GameSettings_Class extends IC_StaticMemoryPointer_Class
{
    GetVersion()
    {
        return "v2.1.0, 2023-03-18"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe " . g_userSettings[ "ExeName"], "", hProcessCopy)
        baseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+this.moduleOffset
        if(baseAddress != this.BaseAddress)
        {
            this.BaseAddress := baseAddress
            this.CrusadersGame := {}
            this.CrusadersGame.GameSettings := new GameObjectStructure(this.structureOffsets)
            this.CrusadersGame.GameSettings.Is64Bit := this.Main.isTarget64bit
            this.CrusadersGame.GameSettings.BaseAddress := this.BaseAddress
            if(!this.Main.isTarget64bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_GameSettings32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_GameSettings64_Import.ahk
            }
        }
    }
}
; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
; Note static loc is == its instance loc
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_CrusadersGameDataSet_Class
{
    moduleOffset := 0
    structureOffsets := 0

    __new(moduleOffset := 0, structureOffsets := 0)
    {
        this.moduleOffset := moduleOffset
        this.structureOffsets := structureOffsets
        this.Refresh()
    }

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
            this.CrusadersGame.Defs := {}
            this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( this.structureOffsets )
            this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
            this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := this.Main.isTarget64bit
            if(!this.Main.isTarget64bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
            }
        }
    }
}

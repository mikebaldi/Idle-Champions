; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.

#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_CrusadersGameDataSet32_Class ; static loc is ==  its instance loc
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.1.6, 2022-04-09, IC v0.425.1+, 32-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A0574
        this.CrusadersGame := {}
        this.CrusadersGame.Defs := {}
        this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( [0x648, 0x9C, 0x50, 0xE80] )
        this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\IC_CrusadersGameDataSet32_Export.ahk
    }
}

class IC_CrusadersGameDataSet64_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.1.6, 2022-04-09, IC v0.425.1+, 64-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493DC8
        this.CrusadersGame := {}
        this.CrusadersGame.Defs := {}
        this.CrusadersGameDataSet := new GameObjectStructure( [0x10, 0xBE0] )
        this.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        this.CrusadersGameDataSet.Is64Bit := true
        #include %A_LineFile%\..\IC_CrusadersGameDataSet64_Export.ahk
    }
}
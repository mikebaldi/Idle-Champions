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
        return "v1.1.7, 2022-06-24, IC v0.452+, 32-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A4A64 ; v452
        this.CrusadersGame := {}
        this.CrusadersGame.Defs := {}
        this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( [0x84, 0x94, 0x4, 0x80, 0x40] ) ; v452
        this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_CrusadersGameDataSet32_Import.ahk
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
        return "v1.1.8, 2022-06-24, IC v0.452+, 64-bit"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x0049CC50 ; v452
        this.CrusadersGame := {}
        this.CrusadersGame.Defs := {}
        this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( [0x0, 0xD0, 0x8, 0X1D0, 0x80] ) ; v435
        this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := true
        #include %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
    }
}
; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
; Note static loc is == its instance loc
#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_CrusadersGameDataSet_Class 
{
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
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A4DE0 ; v461.1
            this.CrusadersGame := {}
            this.CrusadersGame.Defs := {}
            this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( [0xEC, 0x38, 0x24, 0x50, 0xE80] ) ; v461.1
            this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
            this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := false
            #include %A_LineFile%\..\Imports\IC_CrusadersGameDataSet32_Import.ahk
        }
        else
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x0049C7C8 ; v463
            this.CrusadersGame := {}
            this.CrusadersGame.Defs := {}
            this.CrusadersGame.Defs.CrusadersGameDataSet := new GameObjectStructure( [0x40, 0xC50] ) ; v463
            this.CrusadersGame.Defs.CrusadersGameDataSet.BaseAddress := this.BaseAddress
            this.CrusadersGame.Defs.CrusadersGameDataSet.Is64Bit := true
            #include %A_LineFile%\..\Imports\IC_CrusadersGameDataSet64_Import.ahk
        }
    }
}
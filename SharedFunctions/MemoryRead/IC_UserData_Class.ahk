#include %A_LineFile%\..\IC_StaticMemoryPointer_Class.ahk
class IC_UserData_Class extends IC_StaticMemoryPointer_Class
{
    GetVersion()
    {
        return "v0.0.1, 2023-10-28"
    }

    Refresh()
    {
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            this.CrusadersGame := {}
            this.CrusadersGame.User := {}
            this.CrusadersGame.User.UserData := new GameObjectStructure(this.StructureOffsets)
            this.CrusadersGame.User.UserData.BasePtr := this
            this.CrusadersGame.User.UserData.Is64Bit := _MemoryManager.is64Bit
            if(!_MemoryManager.is64Bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_UserData32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_UserData64_Import.ahk    
            }
        }
    }
}
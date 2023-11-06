#include %A_LineFile%\..\IC_StaticMemoryPointer_Class.ahk
class IC_UserStatHandler_Class extends IC_StaticMemoryPointer_Class
{
    GetVersion()
    {
        return "v0.0.1, 2023-10-27"
    }

    Refresh()
    {
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            this.CrusadersGame := {}
            this.CrusadersGame.User := {}
            this.CrusadersGame.User.UserStatHandler := new GameObjectStructure(this.StructureOffsets)
            this.CrusadersGame.User.UserStatHandler.BasePtr := this
            this.CrusadersGame.User.UserStatHandler.Is64Bit := _MemoryManager.is64Bit
            if(!_MemoryManager.is64Bit)
            {
                #include *i %A_LineFile%\..\Imports\IC_UserStatHandler32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_UserStatHandler64_Import.ahk    
            }
        }
    }
}
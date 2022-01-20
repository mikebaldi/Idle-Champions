#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; DialogManager class contains IC's DialogManager class structure. Useful for finding information in dialogues such as what Favor needs to be converted.
class IC_DialogManager_Class
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0, 01/20/22, IC v0.416+, Steam"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00001314
        this.DialogManager := new GameObjectStructure([0x0, 0x8, 0xD90])
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x3C, 0x8]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x3C, 0xC]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x288])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x8])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0xA4, 0x3C, 0xC]) ; push sprit.gameobjectname.0xC
    }
}

; EGS variation of DialogManager
class IC_DialogManagerEGS_Class
{
    
    StaticOffset := 0xE00
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0, 01/20/22, IC v0.416+, EGS"
    }

    Refresh()
    {
    }
}
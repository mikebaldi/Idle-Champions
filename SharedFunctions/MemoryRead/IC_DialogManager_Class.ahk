#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; DialogManager class contains IC's DialogManager class structure. Useful for finding information in dialogues such as what Favor needs to be converted.
; DialogList needs to open a BlessingsStoreDialog object instead of a Dialog object.
; Searching for ptr depth of 1 is fine.
class IC_DialogManager_Class
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.3, 2022-02-25, IC v0.420+, Steam"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00001314
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A31B8
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x001B4F40
        this.DialogManager := new GameObjectStructure([0xD68])
        ;this.DialogManager := new GameObjectStructure([0x1D8, 0xA60])
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x3C, 0x8]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x3C, 0xC]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x294])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x8])
        this.DialogManager.DialogsList.ForceConvertFavor := new GameObjectStructure(this.DialogManager.DialogsList,"Char",[0x2A4])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0xAC, 0x40, 0xC]) ; push sprite.gameobjectname.value
        this.DialogManager.DialogsList.ConvertWindow := new GameObjectStructure(this.DialogManager.DialogsList,,[0x290])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow,,[0x1FC])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x234])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x238])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom,,[0x8])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo,,[0x8])
    }
}

; EGS variation of DialogManager
class IC_DialogManagerEGS_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0.4, 2022-03-08, IC v0.420.2+, EGS"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00495C70
        this.DialogManager := new GameObjectStructure([0xA60])
        this.DialogManager.Is64Bit := true
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x78, 0x10]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x78, 0x18]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x408])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x10])
        this.DialogManager.DialogsList.ForceConvertFavor := new GameObjectStructure(this.DialogManager.DialogsList,"Char",[0x428])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0x160, 0x080, 0x14]) ; push sprite.gameobjectname.value
        this.DialogManager.DialogsList.ConvertWindow := new GameObjectStructure(this.DialogManager.DialogsList,,[0x400])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow,,[0x300])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x370])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x378])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom,,[0x10])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo,,[0x10])
    }
}
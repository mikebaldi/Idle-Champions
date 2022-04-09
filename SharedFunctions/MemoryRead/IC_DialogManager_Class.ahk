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
        return "v1.0.7, 2022-04-08, IC v0.425.1+, Steam"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00001314
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A31B8
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x001B4F40
        this.DialogManager := new GameObjectStructure([0xD30])
        ;this.DialogManager := new GameObjectStructure([0x1D8, 0xA60])
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x3C, 0x8]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x3C, 0xC]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x2C4])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x8])
        this.DialogManager.DialogsList.ForceConvertFavor := new GameObjectStructure(this.DialogManager.DialogsList,"Char",[0x2D8])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0xB0, 0x40, 0xC]) ; push sprite.gameobjectname.value
        this.DialogManager.DialogsList.ConvertWindow := new GameObjectStructure(this.DialogManager.DialogsList,,[0x2C0])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow,,[0x200])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x234])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x23C])
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
        return "v1.0.8, 2022-04-08, IC v0.425.1+, EGS"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00495C70
        this.DialogManager := new GameObjectStructure([0xA10])
        this.DialogManager.Is64Bit := true
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x78, 0x10]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x78, 0x18]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x438])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x10])
        this.DialogManager.DialogsList.ForceConvertFavor := new GameObjectStructure(this.DialogManager.DialogsList,"Char",[0x458])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0x160, 0x080, 0x14]) ; push sprite.gameobjectname.value
        this.DialogManager.DialogsList.ConvertWindow := new GameObjectStructure(this.DialogManager.DialogsList,,[0x430])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow,,[0x330])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x3A0])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x3A8])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom,,[0x10])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo,,[0x10])
    }
}
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
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00001314
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A3188
        ; +0x003A31B8 + D90
        ; +0x003A3188 + D90
        ; +0x003A4754 + 8 + D90
        ; +0x003A3164 + 0 + D90
        ; +0x003A1C54 + 410 + C00
        this.DialogManager := new GameObjectStructure([0xD90])
        this.DialogManager.BaseAddress := this.BaseAddress
        this.DialogManager.DialogsList := new GameObjectStructure(this.DialogManager,"List",[0x3C, 0x8]) ; push dialogs._items
        this.DialogManager.DialogsListSize := new GameObjectStructure(this.DialogManager,,[0x3C, 0xC]) ; push dialogs._size
        this.DialogManager.DialogsList.CurrentCurrency := new GameObjectStructure(this.DialogManager.DialogsList,,[0x288])
        this.DialogManager.DialogsList.CurrentCurrency.ID := new GameObjectStructure(this.DialogManager.DialogsList.CurrentCurrency,,[0x8])
        this.DialogManager.DialogsList.ForceConvertFavor := new GameObjectStructure(this.DialogManager.DialogsList,"Char",[0x298])
        this.DialogManager.DialogsList.ObjectName := new GameObjectStructure(this.DialogManager.DialogsList,"UTF-16",[0xA4, 0x3C, 0xC]) ; push sprite.gameobjectname.value
        this.DialogManager.DialogsList.ConvertWindow := new GameObjectStructure(this.DialogManager.DialogsList,,[0x284])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow,,[0x1F4])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x22C])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel,,[0x230])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingFrom,,[0x22C])
        this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo.ID := new GameObjectStructure(this.DialogManager.DialogsList.ConvertWindow.ConvertPanel.ConvertingTo,,[0x230])
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
        return "v1.0, 01/20/22, IC v0.416+, EGS"
    }

    Refresh()
    {
    }
}
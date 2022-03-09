#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; CrusadersGameDataSet class contains IC's CrusadersGameDataSet class structure. Useful for finding information in defines.
class IC_CrusadersGameDataSet_Class ; static loc is ==  its instance loc
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.1.3, 2022-03-08, IC v0.420.2+, Steam"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A3188
        ; Possible other locations:
        ;mono-2.0-bdwgc.dll+0x003A3188 [0x20, 0xF10]
        ;mono-2.0-bdwgc.dll+0x003A31B8 [0x20, 0xF10]
        ;mono-2.0-bdwgc.dll+0x003AAFFC [0x470, 0xE70]
        this.CrusadersGameDataSet := new GameObjectStructure( [0x20, 0xF28] )
        this.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        this.CrusadersGameDataSet.AreaDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0xC, 0x8]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.AreaDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0xC, 0xC]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.BuffdefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x10, 0x8]) ; Push BuffDefines._items
        this.CrusadersGameDataSet.BuffdefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x10, 0xC]) ; Push BuffDefines._size
        this.CrusadersGameDataSet.ChestDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x20, 0x8]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.ChestDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x20, 0xC]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.UpgradeDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x6C, 0x8]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.UpgradeDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x6C, 0xC]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.AdventureDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0xA0, 0x8]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.AdventureDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0xA0, 0xC]) ; Push ChestTypeDefines._size
        ;=========================================================
        ;ChestDefinesList - 
        ;=========================================================
        this.CrusadersGameDataSet.ChestDefinesList.ID := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,,[0x8])
        this.CrusadersGameDataSet.ChestDefinesList.NamePlural := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,"UTF-16",[0xC, 0xC]) ; Push NamePlura.Value
        this.CrusadersGameDataSet.ChestDefinesList.NameSingular := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,"UTF-16",[0xC, 0xC]) ; Push Name.Value
    }
}

; EGS variation of GameSettings (Thanks to Fenume for updating offsets for 412)
class IC_CrusadersGameDataSetEGS_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.1.3, 2022-03-08, IC v0.420.2+, EGS"  
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00495CE0
        ; Possible other locations:
        ;mono-2.0-bdwgc.dll+0x00493DC8 [0x18, 0xD80]
        ;mono-2.0-bdwgc.dll+0x00495C70 [0x38, 0xE80]
        ;mono-2.0-bdwgc.dll+0x00495CE0 [0x38, 0xE80]
        ;mono-2.0-bdwgc.dll+0x004A33D8 [0x280, 0xD80]
        ;mono-2.0-bdwgc.dll+0x004A3658 [0x285, 0xD80]
        this.CrusadersGameDataSet := new GameObjectStructure( [0x38, 0xEB0] )
        this.CrusadersGameDataSet.BaseAddress := this.BaseAddress
        this.CrusadersGameDataSet.Is64Bit := true
        this.CrusadersGameDataSet.BuffdefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x20, 0x10]) ; Push BuffDefines._items
        this.CrusadersGameDataSet.BuffdefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x20, 0x18]) ; Push BuffDefines._size
        this.CrusadersGameDataSet.AreaDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x18, 0x10]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.AreaDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x18, 0x18]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.ChestDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x40, 0x10]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.ChestDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,"Short",[0x40, 0x18]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.UpgradeDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0xD8, 0x10]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.UpgradeDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0xD8, 0x18]) ; Push ChestTypeDefines._size
        this.CrusadersGameDataSet.AdventureDefinesList := new GameObjectStructure(this.CrusadersGameDataSet,"List",[0x140, 0x10]) ; Push ChestTypeDefines._items
        this.CrusadersGameDataSet.AdventureDefinesListSize := new GameObjectStructure(this.CrusadersGameDataSet,,[0x140, 0x18]) ; Push ChestTypeDefines._size
        ;=========================================================
        ;ChestDefinesList - 
        ;=========================================================
        this.CrusadersGameDataSet.ChestDefinesList.ID := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,,[0x10]) 
        this.CrusadersGameDataSet.ChestDefinesList.NamePlural := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,"UTF-16",[0x20, 0x14]) ; Push NamePlura.Value
        this.CrusadersGameDataSet.ChestDefinesList.NameSingular := new GameObjectStructure(this.CrusadersGameDataSet.ChestDefinesList,"UTF-16",[0x18, 0x14]) ; Push Name.Value
    }
}
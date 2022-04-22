#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
class IC_GameSettings_Class
{
    StaticOffset := 0xE00
    ;StaticOffset := 0x130
    ;back ups: 0x190 and 0x1C0
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.5, 2022-04-16, IC v0.430+, Steam"  
    }

    Refresh()
    {
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;hProcessCopy is an optional variable in which the opened handled is stored.
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A1C54
        ;this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A4F74
        this.GameSettings := new GameObjectStructure([0xE0])
        ;this.GameSettings := new GameObjectStructure([0x8, 0xC, 0x60])
        ;back ups
        ;[0x8, 0xC, 0x300]
        ;[0x8, 0xC, 0xE44]
        this.GameSettings.BaseAddress := this.BaseAddress
        this.GameSettings.UserID := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x20])
        this.GameSettings.Hash := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x28, 0xC])
        this.GameSettings.Platform := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x48])
        this.GameSettings.Version := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x50]) ; Push MobileClientVersion
        this.GameSettings.PostFix := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x54, 0xC])
        this.GameSettings._Instance := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x0])
        this.GameSettings._Instance.InstanceID := new GameObjectStructure(this.GameSettings._Instance,,[0x10])
    }
}

; EGS variation of GameSettings (Thanks to Fenume for updating offsets for 412)
class IC_GameSettingsEGS_Class
{
    
    StaticOffset := 0xA80
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0.4, 2022-04-14, IC v0.428+, EGS"  
    }

    Refresh()
    {
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;hProcessCopy is an optional variable in which the opened handled is stored.
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00493e40
        this.GameSettings := new GameObjectStructure([0x820])
        this.GameSettings.Is64Bit := true
        this.GameSettings.BaseAddress := this.BaseAddress
        this.GameSettings.UserID := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x40])
        this.GameSettings.Hash := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x48, 0x14])
        this.GameSettings.Platform := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x78])
        this.GameSettings.Version := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x88]) ; Push MobileClientVersion
        this.GameSettings.PostFix := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x90, 0x14])
        this.GameSettings._Instance := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x0])
        this.GameSettings._Instance.InstanceID := new GameObjectStructure(this.GameSettings._Instance,,[0x18])
    }
}
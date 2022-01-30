#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls.
class IC_GameSettings_Class
{
    
    StaticOffset := 0xD20
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.01, 2022-01-29, IC v0.418.1+, Steam"  
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
        this.GameSettings := new GameObjectStructure([0xA8])
        this.GameSettings.BaseAddress := this.BaseAddress
        this.GameSettings.UserID := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x20])
        this.GameSettings.Hash := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x28, 0xC])
        this.GameSettings.Platform := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x3C])
        this.GameSettings.Version := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x44]) ; Push MobileClientVersion
        this.GameSettings.PostFix := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x48, 0xC])
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
        return "v1.01, 2022-01-29, IC v0.418.1+, EGS"  
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
        this.GameSettings.BaseAddress := this.BaseAddress
        this.GameSettings.UserID := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x40])
        this.GameSettings.Hash := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x48, 0x14])
        this.GameSettings.Platform := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x70])
        this.GameSettings.Version := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x80]) ; Push MobileClientVersion
        this.GameSettings.PostFix := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x88, 0x14])
        this.GameSettings._Instance := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x0])
        this.GameSettings._Instance.InstanceID := new GameObjectStructure(this.GameSettings._Instance,,[0x18])
    }
}
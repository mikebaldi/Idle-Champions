#include IC_GameObjectStructureClass.ahk
; GameManager class contains the in game data structure layout
;Script Date := "11/11/21"
;Script Ver := "v0.412"

class GameSettings
{
    
    StaticOffset := 0xD20
    __new()
    {
        this.Refresh()
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
        this.GameSettings.Platform := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x30])
        this.GameSettings.Version := new GameObjectStructure(this.GameSettings,,[this.StaticOffset + 0x38]) ; Push MobileClientVersion
        this.GameSettings.PostFix := new GameObjectStructure(this.GameSettings,"UTF-16",[this.StaticOffset + 0x3C, 0xC])
        this.GameSettings.GameSettingsInstanceLocation := new GameObjectStructure(this.GameSettings,,[this.StaticOffset, 0x0])
        this.GameSettings.GameSettingsInstanceLocation.InstanceID := new GameObjectStructure(this.GameSettings.GameSettingsInstanceLocation,,[0x10])
    }
}
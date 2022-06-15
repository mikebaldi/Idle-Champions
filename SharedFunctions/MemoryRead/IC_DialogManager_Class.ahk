#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; DialogManager class contains IC's DialogManager class structure. Useful for finding information in dialogues such as what Favor needs to be converted.
; DialogList needs to open a BlessingsStoreDialog object instead of a Dialog object.
; Searching for ptr depth of 1 has been fine.
class IC_DialogManager32_Class
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v1.0.8, 2022-04-16, IC v0.431+, 32-bit"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A31B8
        this.UnityGameEngine := {}
        this.UnityGameEngine.Dialogs := {}
        this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure([0xD10])
        this.UnityGameEngine.Dialogs.DialogManager.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_DialogManager32_Import.ahk
    }
}

; EGS variation of DialogManager
class IC_DialogManager64_Class
{
    __new()
    {
        this.Refresh()
    }

    GetVersion()
    {
        return "v1.0.10, 2022-04-16, IC v0.430+, 64-bit"
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00495C70
        this.UnityGameEngine := {}
        this.UnityGameEngine.Dialogs := {}
        if(this.HasOverlay())
            this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure([0x9E0])
        else
            this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure([0x9D0])
        this.UnityGameEngine.Dialogs.DialogManager.Is64Bit := true
        this.UnityGameEngine.Dialogs.DialogManager.BaseAddress := this.BaseAddress
        #include %A_LineFile%\..\Imports\IC_DialogManager64_Import.ahk
    }

    ; GfxPluginEOSLoader_x64 and EOSSDK-Win64-Shipping.dll are EGS specific DLLs for its overlay.
    ; Since they are either removed by some people or a 64 bit version may not include them, the pointer could change depending on if they exist.
    HasOverlay()
    {
        overlayDLL1 := this.Main.getModuleBaseAddress("GfxPluginEOSLoader_x64.dll")
        overlayDLL2 := this.Main.getModuleBaseAddress("EOSSDK-Win64-Shipping.dll")
        return (overlayDLL1 != -1 AND overlayDLL2 != -1)
    }
}
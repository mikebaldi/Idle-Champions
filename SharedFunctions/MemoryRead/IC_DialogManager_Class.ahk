#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk
; DialogManager class contains IC's DialogManager class structure. Useful for finding information in dialogues such as what Favor needs to be converted.
; DialogList needs to open a BlessingsStoreDialog object instead of a Dialog object.
; Searching for ptr depth of 1 has been fine.
class IC_DialogManager_Class
{
    __new()
    {
        this.Refresh()
    }
 
    GetVersion()
    {
        return "v2.0.0, 2022-08-18, IC v0.463+" 
    }

    Refresh()
    {
        this.Main := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        if(!this.Main.isTarget64bit)
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x003A31B8
            this.UnityGameEngine := {}
            this.UnityGameEngine.Dialogs := {}
            this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure([0xD10])
            this.UnityGameEngine.Dialogs.DialogManager.Is64Bit := false
            this.UnityGameEngine.Dialogs.DialogManager.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_DialogManager32_Import.ahk
        }
        else
        {
            this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00499C70
            this.UnityGameEngine := {}
            this.UnityGameEngine.Dialogs := {}
            offset := 0x9C0
            if(this.HasOverlay())
                offset += 0x010
            this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure([offset])
            this.UnityGameEngine.Dialogs.DialogManager.Is64Bit := true
            this.UnityGameEngine.Dialogs.DialogManager.BaseAddress := this.BaseAddress
            #include %A_LineFile%\..\Imports\IC_DialogManager64_Import.ahk
        }
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
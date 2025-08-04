; DialogManager class contains IC's DialogManager class structure. Useful for finding information in dialogues such as what Favor needs to be converted.
; DialogList needs to open a BlessingsStoreDialog object instead of a Dialog object.
; Searching for ptr depth of 1 has been fine.
class IC_DialogManager_Class extends SH_MemoryPointer
{
    GetVersion()
    {
        return "v2.1.1, 2025-08-03"
    }

    Refresh()
    {
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            if (this.UnityGameEngine == "")
            {
                this.UnityGameEngine := {}
                this.UnityGameEngine.Dialogs := {}
                structureOffsetsOverlay := this.StructureOffsets.Clone()
                ; structureOffsetsOverlay[1] += 0x10 ; for myself (Steam only)
                offsets := (this.HasOverlay() AND _MemoryManager.is64Bit) ? structureOffsetsOverlay : this.StructureOffsets
                this.UnityGameEngine.Dialogs.DialogManager := new GameObjectStructure(offsets)
                this.UnityGameEngine.Dialogs.DialogManager.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.UnityGameEngine.Dialogs.DialogManager.Is64Bit := _MemoryManager.is64Bit
                #include *i %A_LineFile%\..\Imports\IC_DialogManager64_Import.ahk
            }
            else
            {
                this.UnityGameEngine.Dialogs.DialogManager.BasePtr := new SH_BasePtr(this.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                this.UnityGameEngine.Dialogs.DialogManager.ResetBasePtr(this.UnityGameEngine.Dialogs.DialogManager)
            }
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

    ResetCollections()
    {
        this.UnityGameEngine.ResetCollections()
    }
}
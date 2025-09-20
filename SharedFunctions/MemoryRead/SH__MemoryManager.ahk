
#include %A_LineFile%\..\classMemory.ahk
; A class to manage and make available instances of class Memory
class _MemoryManager
{
    _exeName := ""
    baseAddress := {}
    handle := ""

    classMemory[]
    {
        get
        {
            if !(this.isInstantiated)
            {
                this.Refresh()
            }
            return this.instance
        }
    }

    exeName[]
    {
        get
        {
            return this._exeName
        }
        set
        {
            return this._exeName := value
        }
    } 

    is64Bit
    {
        get
        {
            return this.instance.isTarget64bit
        }
    }

    Refresh(moduleName := "mono-2.0-bdwgc.dll")
    {
        moduleName1 := "mono-2.0-bdwgc.dll"
        moduleName2 := "UnityPlayer.dll"
        this.isInstantiated := false
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;handle is an optional variable in which the opened handle is stored.
        this.instance := new _ClassMemory("ahk_exe " . this._exeName, "", handle)
        this.handle := handle
        if IsObject(this.instance)
        {
            this.isInstantiated := true
        }
        else
        {
            this.baseAddress[moduleName1] := -1
            this.baseAddress[moduleName2] := -1
            return False
        }
        this.baseAddress[moduleName1] := this.instance.getModuleBaseAddress(moduleName1)
        this.baseAddress[moduleName2] := this.instance.getModuleBaseAddress(moduleName2)
        return true
    }
}
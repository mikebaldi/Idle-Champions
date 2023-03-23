
#include %A_LineFile%\..\classMemory.ahk
; A class to manage and make available instances of class Memory
; TODO add error handling

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

    Refresh(baseAddress := "mono-2.0-bdwgc.dll")
    {
        this.isInstantiated := false
        this.instance := new _ClassMemory("ahk_exe " . this._exeName, "", handle)
        this.handle := handle
        if IsObject(this.instance)
        {
            this.isInstantiated := true
        }
        else
        {
            return false
        }
        this.baseAddress[baseAddress] := this.instance.getModuleBaseAddress(baseAddress)
        return true
    }
}
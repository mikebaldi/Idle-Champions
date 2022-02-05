GUIFunctions.AddTab("EffectKey Handlers Full Read")

Gui, ICScriptHub:Tab, EffectKey Handlers Full Read
Gui, ICScriptHub:Add, Button, x+220 w160 gIC_TestEffectKeys_Component.EffectKeyReadAllFunctions, Load Handlers
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 yp+5, `All EffectKey Handlers:
Gui, ICScriptHub:Font, w400

if(g_isDarkMode)
    Gui, Font, g_CustomColor
Gui, ICScriptHub:Add, TreeView, x15 y+8 w450 h450 vEffectKeysViewID ReadOnly
if(g_isDarkMode)
{
    GuiControl,ICScriptHub: +Background888888, EffectKeysViewID
    Gui, ICScriptHub:Font, cSilver
}

class IC_TestEffectKeys_Component
{
    static exclusionList := [ "__Init", "__new", "__Class", "Initialize", "CheckChampLevel", "GetDictIndex", "GetBaseAddress", "IsBaseAddressCorrect", "BuildEffectKey", "BuildMemoryObjects" ]
    static handlerList := [ "BrivUnnaturalHasteHandler", "HavilarImpHandler", "OminContractualObligationsHandler", "TimeScaleWhenNotAttackedHandler" ]

    InExclusionsList(value)
    {
        static
        _size := this.exclusionList.Count()
        loop, %_size%
        {
            if(this.exclusionList[A_Index] == value)
                return true
        }
        return false
    }

    EffectKeyReadAllFunctions()
    {
        restore_gui_on_return := GUIFunctions.TV_Scope("ICScriptHub", "EffectKeysViewID")
        g_SF.Memory.OpenProcessReader()
        TV_Delete()
        ;disable redraw while adding items to increase performance
        GuiControl, -Redraw, EffectKeysViewID
        _size := IC_TestEffectKeys_Component.handlerList.Count()
        loop, %_size%
        {
            handlerName := IC_TestEffectKeys_Component.handlerList[A_Index]
            handlerID := TV_Add(handlerName,0,Bold)
            handlerInstance := new %handlerName%
            handlerInstance.Initialize()
            handlerInstance.IsBaseAddressCorrect()
            for k, v in  handlerInstance
            {
                if( !IC_TestEffectKeys_Component.InExclusionsList(k))
                {
                    value := handlerInstance[k]
                    if (IsObject(value))
                    {
                        IC_TestEffectKeys_Component.TVADD(handlerID, handlerInstance, k)
                    }
                    else
                    {
                        value := value == "" ? "-- ERROR --" : value
                        if (k == "BaseAddress")
                            value := Format("0x{:X}", value)
                        entry := k . ": " . value
                        TV_Add(entry, handlerID)
                    }
                }
            }
            for k,v in %handlerName%
            {
                if( isFunc(v) AND !IC_TestEffectKeys_Component.InExclusionsList(k) )
                {
                    fncToCall := ObjBindMethod(handlerInstance, k)
                    entry := k . ": " . fncToCall.Call()
                    TV_ADD(entry, handlerID)
                }
            }
            TV_Modify(handlerID, "Sort") 
        }
        TV_Modify(0, "Sort") 
        GuiControl, +Redraw, EffectKeysViewID
    }

    TVADD(objID, objInstance, key)
    {
        nestedObj := objInstance[key]
        if (nestedObj.ValueType == "Ptr")
        {
            item := Format("0x{:X}", nestedObj.offset) . " - " . key
            itemID := TV_Add(item, objID)
            for k, v in nestedObj
            {
                if (k != "ParentObj")
                    IC_TestEffectKeys_Component.TVADD(itemID, nestedObj, k)
            }
        }
        else if (nestedObj.ValueType != "")
        {
            item := Format("0x{:X}", nestedObj.offset) . " - " . key . ": " . nestedObj.GetValue()
            TV_Add(item, objID)
        }
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\MemoryRead\EffectKeyHandlers\BrivUnnaturalHasteHandler.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\MemoryRead\EffectKeyHandlers\HavilarImpHandler.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\MemoryRead\EffectKeyHandlers\OminContractualObligationsHandler.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\MemoryRead\EffectKeyHandlers\TimeScaleWhenNotAttackedHandler.ahk
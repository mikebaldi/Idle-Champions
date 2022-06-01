g_TabControlHeight := Max(g_TabControlHeight, (650+100))
g_TabControlWidth := Max(g_TabControlHeight, (525+10))
GUIFunctions.AddTab("FullMemoryFunctions")

Gui, ICScriptHub:Tab, FullMemoryFunctions
Gui, ICScriptHub:Add, Button, x+220 w160 gIC_MemoryFunctionsFullRead_Component.ReadAllFunctions, Load Memory Functions
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 yp+5, `All Memory Functions:
Gui, ICScriptHub:Font, w400

if(g_isDarkMode)
    Gui, Font, g_CustomColor
Gui, ICScriptHub:Add, ListView, x15 y+8 w525 h650 vMemoryFunctionsViewID, Function|x|Value
if(g_isDarkMode)
{
    GuiControl,ICScriptHub: +Background888888, MemoryFunctionsViewID
    Gui, ICScriptHub:Font, cSilver
}

class IC_MemoryFunctionsFullRead_Component
{
    static exclusionList := [ "__Init", "__new",  "BinarySearchList", "ConvQuadToString", "ConvQuadToString2", "ConvQuadToString3", "GenericGetValue", "OpenProcessReader", "ReadConversionCurrencyBySlot", "ReadUserHash", "ReadUserID", "ReadTimeScaleMultipliersKeyByIndex", "AdjustObjectListIndexes" ]

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

    ; Current valid ERRORs to reads using value 1:
    ;   ReadTimeScaleMultipliersKeyByIndex - May be modron core speed which won't read effect data
    ;   ReadChampIDBySlot - make sure a champion is in slot 1 on the game field or this will have an error. (game field slots start at 0 at the far right and count: right to left, top to bottom)
    ;   ReadUltimateButtonChampIDByItem - Must have at least 2 ultimate abilities unlocked or this will error.
    ReadAllFunctions()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "MemoryFunctionsViewID")
        valueToPass := 1
        g_SF.Memory.OpenProcessReader()
        LV_Delete()
        for k,v in IC_MemoryFunctions_Class
        {
            if( isFunc(v) AND !IC_MemoryFunctionsFullRead_Component.InExclusionsList(k) )
            {
                parameterString := k . (v.MaxParams > 4 ? "(...)" : (v.MaxParams > 3 ? "(x,y,z)" : (v.MaxParams > 2 ? "(x,y)" : (v.MaxParams > 1 ? "(x)" : ""))))
                fncToCall := ObjBindMethod(g_SF.Memory, k)
                value := v.Maxparams >= 2 ? fncToCall.Call(valueToPass) : fncToCall.Call()
                value := IsObject(value) ? ArrFnc.GetDecFormattedArrayString(value) : value
                value := value == "" ? "-- ERROR --" : value
                valuePassedString := (v.Maxparams >= 2 ? "(" . valueToPass . ")" : "")
                LV_Add(, parameterString, valuePassedString, value)
            }
        }
        LV_ModifyCol()
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
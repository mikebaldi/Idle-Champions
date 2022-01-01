addedTabs := "FullMemoryFunctions|"
GuiControl,,ModronTabControl, % addedTabs
g_TabList .= addedTabs
StrReplace(g_TabList,"|",,tabCount)
g_TabControlWidth := Max(Max(g_TabControlWidth,475), tabCount * 75)
GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+40


Gui, Tab, FullMemoryFunctions
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, `All Memory Functions:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Button, x155 y60 w160 gIC_MemoryFunctionsFullRead_Component.ReadAllFunctions, Load Memory Functions

if(g_isDarkMode)
    Gui, Font, g_CustomColor
Gui Add, ListView, x15 y+15 w450 h450 vMemoryFunctionsViewID, Function|x|Value
if(g_isDarkMode)
{
    GuiControl, +Background888888, MemoryFunctionsViewID
    Gui, Font, cSilver
}

class IC_MemoryFunctionsFullRead_Component
{
    static exclusionList := [ "__Init", "__new", "GenericGetValue", "OpenProcessReader", "ConvQuadToString", "ConvQuadToString2", "ConvQuadToString3", "ReadUserID", "ReadUserHash" ]

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

    ReadAllFunctions()
    {
        restore_gui_on_return := LV_Scope("ICScriptHub", "MemoryFunctionsViewID")
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
                valuePassedString := (v.Maxparams >= 2 ? "(1)" : "")
                LV_Add(, parameterString, valuePassedString, value)
            }
        }
        LV_ModifyCol()
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
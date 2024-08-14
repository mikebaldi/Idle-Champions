g_TabControlHeight := Max(g_TabControlHeight, (650+100))
g_TabControlWidth := Max(g_TabControlHeight, (525+10))
GUIFunctions.AddTab("FullMemoryFunctions")

Gui, ICScriptHub:Tab, FullMemoryFunctions
Gui, ICScriptHub:Add, Button, x+215 w160 gIC_MemoryFunctionsFullRead_Component.ReadAllFunctions, Load Memory Functions
Gui, ICScriptHub:Add, Button, x+10 w135 gIC_MemoryFunctionsFullRead_Component.SwapPointers, Change Pointers
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 yp+5, `All Memory Functions:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Checkbox,x145 yp+0 vMemoryFunctionsFullRead_LoadHandlers, Champions

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, x15 y+8 w525 h650 vMemoryFunctionsViewID, Function|x|Value

GUIFunctions.UseThemeListViewBackgroundColor("MemoryFunctionsViewID")
GUIFunctions.UseThemeTextColor("DefaultTextColor")
class IC_MemoryFunctionsFullRead_Component
{
    static exclusionList := [ "__Init", "__new",  "BinarySearchList", "GenericGetValue", "OpenProcessReader", "ReadConversionCurrencyBySlot", "BuildChestIndexList", "InitializeChestsIndices", "ReadUserHash", "ReadUserID" ]
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

    ; Resize window to trigger automatic resize code in ICScriptHubGuiSize()
    RefreshSize()
    {
        GuiControlGet, Size, ICScriptHub:Pos, ModronTabControl
        ICScriptHubGuiSize(WinExist(),0,SizeW+20,SizeH+40)
    }

    ; Current valid ERRORs to reads using value 1:
    ;   ReadChampIDBySlot - make sure a champion is in slot 1 on the game field or this will have an error. (game field slots start at 0 at the far right and count: right to left, top to bottom)
    ;   ReadUltimateButtonChampIDByItem - Must have at least 2 ultimate abilities unlocked or this will error.
    ReadAllFunctions()
    {
        Gui, ICScriptHub:Submit, NoHide
        global MemoryFunctionsFullRead_LoadHandlers
        IC_MemoryFunctionsFullRead_Component.RefreshSize()
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
        if(!MemoryFunctionsFullRead_LoadHandlers)
        {
            LV_ModifyCol()
            return
        }
        for k,v in ActiveEffectKeySharedFunctions ; Class
        {
            for k1, v1 in v ; Champions
            {
                for k2, v2 in v1 ; Handlers
                {
                    if( isFunc(v2) ) ; Handler Fields/Functions
                    {
                        parameterString := k . "..." . k2 . (v2.MaxParams > 4 ? "(...)" : (v2.MaxParams > 3 ? "(x,y,z)" : (v2.MaxParams > 2 ? "(x,y)" : (v2.MaxParams > 1 ? "(x)" : ""))))
                        currentObject := ActiveEffectKeySharedFunctions[k][k1]
                        fncToCall := ObjBindMethod(currentObject, k2)
                        value := v2.Maxparams >= 2 ? fncToCall.Call(valueToPass) : fncToCall.Call()
                        value := IsObject(value) ? ArrFnc.GetAlphaNumericArrayString(value) : value
                        value := value == "" ? "-- ERROR --" : value
                        valuePassedString := (v2.Maxparams >= 2 ? "(" . valueToPass . ")" : "")
                        LV_Add(, parameterString, valuePassedString, value)
                    }
                }
            }
        }
        LV_ModifyCol()
    }

    SwapPointers()
    {
        MsgBox, Closing Script Hub and running the pointer version picker.
        versionPickerLoc := A_LineFile . "\..\..\IC_Core\IC_VersionPicker.ahk"
        Run, %versionPickerLoc%
        ExitApp
    }
}

#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
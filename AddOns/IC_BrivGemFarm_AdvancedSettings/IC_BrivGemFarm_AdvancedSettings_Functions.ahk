; When a check box is checked...
BrivPreferredJumpSettings_Click()
{
    Gui, ICScriptHub:Submit, NoHide
    currentControl := A_GuiControl
    isChecked := %A_GuiControl%
    splitString := StrSplit(currentControl, "_")
    modVal := splitString[2]
    currentIndex := splitString[3]
    IC_BrivGemFarm_AdvancedSettings_Functions.ToggleSelectedChecksForMod(modVal, currentIndex, isChecked)
}

class IC_BrivGemFarm_AdvancedSettings_Functions
{

    ; Property that returns a specific mod value if passed a valid parameter, or the full list of mod values if invalid/no param passed.
    ModList[index := 0]
    {
        get
        {
            minValue := 1
            maxVal := 3
            mods := [5,10,50] ; value of 50 is required for script to function

            if(index != "" AND index <= maxVal AND index >= minValue)
                return mods[index]
            else
                return mods
        }
    }
    
    ; Saves the settings for briv preferred jumps based on the boxes checked
    UpdateJumpSettings()
    {
        g_BrivUserSettings[ "PreferredBrivJumpZones" ] := []
        Loop, 50
        {
            isChecked := PreferredBrivJumpSettingMod_50_%A_Index%
            g_BrivUserSettings[ "PreferredBrivJumpZones" ][A_Index] := isChecked
        }
    }

    ; Sets the checkboxes for Briv preferred jumps based on the user settings.
    LoadPreferredBrivJumpSettings()
    {
        modListLength := IC_BrivGemFarm_AdvancedSettings_Functions.ModList.Length()
        Loop, %modListLength% ; different check box sections [5,10,50]
        {
            modVal := IC_BrivGemFarm_AdvancedSettings_Functions.ModList[A_Index]
            modChecked := True
            currentModCheckedArray := []
            Loop, 50
            {
                isChecked := g_BrivUserSettings[ "PreferredBrivJumpZones" ][A_Index]
                PreferredBrivJumpSettingMod_50_%A_Index% := isChecked
                modIndex := Mod(A_Index, modVal) ? Mod(A_Index, modVal) : modVal
                currentModCheckedArray[modIndex] :=  currentModCheckedArray[modIndex] == "" ? isChecked : currentModCheckedArray[modIndex] AND isChecked
                GUiControl, ICScriptHub:, PreferredBrivJumpSettingMod_50_%A_Index%, %isChecked%
            }
            modValCount := currentModCheckedArray.Length()
            loop, %modValCount%
            {
                PreferredBrivJumpSettingMod_%modVal%_%A_Index% := currentModCheckedArray[A_Index]
                GUiControl, ICScriptHub:, PreferredBrivJumpSettingMod_%modVal%_%A_Index%, % currentModCheckedArray[A_Index]
            }
        }
        Gui, ICScriptHub:Submit, NoHide
    }

    ; Toggles all checkboxes that are not part of the original
    ToggleSelectedChecksForMod(modVal, currentModResult, isChecked)
    {
        global
        local numMods := IC_BrivGemFarm_AdvancedSettings_Functions.ModList.Length()
        Loop, %numMods%
        {
            local currModVal := IC_BrivGemFarm_AdvancedSettings_Functions.ModList[A_Index]
            if (currModVal > modVal)
            {
                Loop, %currModVal%
                {
                    ;local currIndex := (A_Index -1) * currModVal + currentModResult
                    ;local modIndex := Mod(A_Index, modVal) == "" ? Mod(A_Index, modVal) : currModVal
                    ;if(modIndex == currentModResult)
                    modTest := Mod(A_Index, modVal) ? Mod(A_Index, modVal) : modVal
                    if(modTest == currentModResult)
                    {
                        PreferredBrivJumpSettingMod_%currModVal%_%A_Index% := isChecked
                        GUiControl, ICScriptHub:, PreferredBrivJumpSettingMod_%currModVal%_%A_Index%, %isChecked%
                    }
                }
            }
            else if (currModVal < modVal)
            {
                local currentModCheckedArray := []
                Loop, 50
                {
                    modTest := Mod(A_Index, modVal) ? Mod(A_Index, modVal) : modVal
                    if(modTest == currentModResult)
                    {
                        PreferredBrivJumpSettingMod_%currModVal%_%A_Index% := isChecked
                        GUiControl, ICScriptHub:, PreferredBrivJumpSettingMod_50_%A_Index%, %isChecked%
                        Gui, ICScriptHub:Submit, NoHide
                    }
                    local modIndex := Mod(A_Index, currModVal) ? Mod(A_Index, currModVal) : currModVal
                    currentModCheckedArray[modIndex] := currentModCheckedArray[modIndex] == "" ? PreferredBrivJumpSettingMod_50_%A_Index% : currentModCheckedArray[modIndex] AND PreferredBrivJumpSettingMod_50_%A_Index% 
                }
                loop, %currModVal%
                {
                    GUiControl, ICScriptHub:, PreferredBrivJumpSettingMod_%currModVal%_%A_Index%, % currentModCheckedArray[A_Index]
                }
            }
        }
        Gui, ICScriptHub:Submit, NoHide
    }

    ; Builds labels and checkboxes for PreferredBrivJumpZones
    BuildModTables(xLoc, yLoc)
    {
        len := this.ModList.Length()
        Loop, % len
        {
            modVal := this.ModList[A_Index]
            yLoc += 20
            Gui, ICScriptHub:Add, Text, x10 y%yLoc%, Mod %modVal%
            ;yLoc += 20
            location := this.BuildModTable(modVal, xLoc, yLoc)
            xLoc := location[1]
            yLoc := location[2]
        }
    }

    ; Builds one set of checkboxes for PreferredBrivJumpZones (e.g. Mod5 and associated checks)
    BuildModTable(modVal, xLoc, yLoc)
    {
        loopCount := Floor(50/modVal)
        modLoopIndex := 0
        loop, %modVal%
        {
            isChecked = True
            modLoopIndex := A_Index
            loop, loopCount
            {
                index := ((A_Index -1) * modVal) + modLoopIndex
                isChecked := g_BrivUserSettings[ "PreferredBrivJumpZones" ][index] AND isChecked
            }
            if(Mod(A_Index, 10) != 1)
                xLoc += 35
            else
            {
                xLoc := 10
                yLoc += 20
            }
            this.AddControlCheckbox(isChecked, xLoc, yLoc, modval, modLoopIndex)    
        }
        location := this.GetControlCoords(modVal)
        return location
    }

    ; Addes the checkbox control
    AddControlCheckbox(isChecked, xLoc, yLoc, modval, loopCount)
    {
        global
        Gui, ICScriptHub:Add, Checkbox, vPreferredBrivJumpSettingMod_%modVal%_%loopCount% Checked%isChecked% x%xLoc% y%yLoc% gBrivPreferredJumpSettings_Click, % loopCount
    }

    ; Gets the coordinates of the checkbox control for the modVal passed.
    GetControlCoords(modVal)
    {
        global
        GuiControlGet, xyVal, ICScriptHub:Pos, PreferredBrivJumpSettingMod_%modVal%_%modVal%
        return [xyValX, xyValY]
    }
}


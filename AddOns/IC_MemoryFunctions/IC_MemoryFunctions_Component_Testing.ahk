/*
    Memory Reads Testing
*/
; Gui, ICScriptHub:Tab, Stats
; Gui, ICScriptHub:Font, w700
; Gui, ICScriptHub:Add, Text, x15 y490, SwapTiming Reads:
; Gui, ICScriptHub:Font, w400

; Gui, ICScriptHub:Add, Text, x15 y+5, QuestRemaining: 
; Gui, ICScriptHub:Add, Text, vSwapTimingQuestReamainingID x+2 w300,
; Gui, ICScriptHub:Add, Text, x15 y+5, Transitioning: 
; Gui, ICScriptHub:Add, Text, vSwapTimingTransitioningID x+2 w300,
; Gui, ICScriptHub:Add, Text, x15 y+5, CurrentZone: 
; Gui, ICScriptHub:Add, Text, vSwapTimingCurrentZoneID x+2 w300,
; Gui, ICScriptHub:Add, Text, x15 y+5, HighestZone: 
; Gui, ICScriptHub:Add, Text, vSwapTimingHighestZoneID x+2 w300,
; Gui, ICScriptHub:Add, Text, x15 y+5, BrivFormationSlot: 
; Gui, ICScriptHub:Add, Text, vSwapTimingBrivInFormationID x+2 w300,

Gui, ICScriptHub:Tab, Memory View
Gui, ICScriptHub:Font, w700
if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
    Gui, ICScriptHub:Add, Text, x15 y550, Current Tests:
else
    Gui, ICScriptHub:Add, Text, x15 y55, Current Tests:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Text, x15 y+5, NumAttackingMonstersReached: 
Gui, ICScriptHub:Add, Text, vNumAttackingMonstersReachedLblID x+2 w70,
Gui, ICScriptHub:Add, Text, x15 y+5, NumRangedAttackingMonster: 
Gui, ICScriptHub:Add, Text, vNumRangedAttackingMonsterLblID x+2 w70,
; Gui, ICScriptHub:Add, Text, x15 y+5, KeyUsage: %y%
; Gui, ICScriptHub:Add, Text, vKeyUsageID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, KeyErrors: 
Gui, ICScriptHub:Add, Text, vKeyErrorStringID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, TimeScales: 
Gui, ICScriptHub:Add, Text, vMultipliersStringID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, FormationCurrent: 
; Gui, ICScriptHub:Add, Text, vFormationCurrentID x+2 w400,
; Gui, ICScriptHub:Add, Text, x15 y+5, FormationFavorite1: 
; Gui, ICScriptHub:Add, Text, vFormationFavorite1ID x+2 w400,
; Gui, ICScriptHub:Add, Text, x15 y+5, FormationFavorite2: 
; Gui, ICScriptHub:Add, Text, vFormationFavorite2ID x+2 w400,
; Gui, ICScriptHub:Add, Text, x15 y+5, FormationFavorite3: 
; Gui, ICScriptHub:Add, Text, vFormationFavorite3ID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTransitionOverrideSize: 
Gui, ICScriptHub:Add, Text, vReadTransitionOverrideSizeID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTransitionDirection: 
Gui, ICScriptHub:Add, Text, vReadTransitionDirectionID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadFormationTransitionDir: 
Gui, ICScriptHub:Add, Text, vReadFormationTransitionDirID x+2 w400,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadFavorID: 
Gui, ICScriptHub:Add, Text, vReadFavorIDID x+2 w400,

class ReadMemoryFunctionsExtended
{
    CheckReads()
    {
        Sleep, -1
        if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
            ReadMemoryFunctions.MainReads()
        this.ReadContinuous()
        ;this.ReadSwapTimings()
        ;this.UpdateKeyUsage()
    }

    ReadContinuous()
    {
      
        GuiControl, ICScriptHub:, KeyErrorStringID, % "KeyDown: " . g_SF.ErrorKeyDown . " - KeyUp: " . g_SF.ErrorKeyUp
        GuiControl, ICScriptHub:, MultipliersStringID, % this.GetMultipliersString()
        ; GuiControl, ICScriptHub:, FormationCurrentID, % ArrFnc.GetDecFormattedArrayString(g_SF.Memory.GetCurrentFormation())
        ; GuiControl, ICScriptHub:, FormationFavorite1ID, % ArrFnc.GetDecFormattedArrayString(g_SF.Memory.GetFormationByFavorite( favorite := 1))
        ; GuiControl, ICScriptHub:, FormationFavorite2ID, % ArrFnc.GetDecFormattedArrayString(g_SF.Memory.GetFormationByFavorite( favorite := 2))
        ; GuiControl, ICScriptHub:, FormationFavorite3ID, % ArrFnc.GetDecFormattedArrayString(g_SF.Memory.GetFormationByFavorite( favorite := 3))
        GuiControl, ICScriptHub:, NumAttackingMonstersReachedLblID, % g_SF.Memory.ReadNumAttackingMonstersReached()
        GuiControl, ICScriptHub:, NumRangedAttackingMonsterLblID, % g_SF.Memory.ReadNumRangedAttackingMonsters()
        ;GuiControl, ICScriptHub:, g_InputsSentID, % g_InputsSent
        GuiControl, ICScriptHub:, ReadTransitionOverrideSizeID, % g_SF.Memory.ReadTransitionOverrideSize()
        GuiControl, ICScriptHub:, ReadTransitionDirectionID, % g_SF.Memory.ReadTransitionDirection()      
        GuiControl, ICScriptHub:, ReadFormationTransitionDirID, % g_SF.Memory.ReadFormationTransitionDir()   
        ;GuiControl, ICScriptHub:, ReadFavorIDID, % g_SF.Memory.GetDialogNameBySlot(0) ;g_SF.Memory.GetConversionCurrencyBySlot()
    }

    ReadSwapTimings()
    {
        GuiControl, ICScriptHub:, SwapTimingQuestReamainingID, % g_SF.Memory.ReadQuestRemaining()
        GuiControl, ICScriptHub:, SwapTimingTransitioningID, % g_SF.Memory.ReadTransitioning()
        GuiControl, ICScriptHub:, SwapTimingCurrentZoneID, % g_SF.Memory.ReadCurrentZone()
        GuiControl, ICScriptHub:, SwapTimingHighestZoneID, % g_SF.Memory.ReadHighestZone()
        GuiControl, ICScriptHub:, SwapTimingBrivInFormationID, % g_SF.Memory.ReadChampSlotByID(ChampID := 58)
    }

    GetMultipliersString()
    {
        multiplierTotal := 1
        size := g_SF.Memory.ReadTimeScaleMultipliersCount()
        if (size > 0 AND size < 150)
            multipliersString := "["
        else
            return ""
        i := 0
        loop, %size%
        {
            value := g_SF.Memory.ReadTimeScaleMultiplierByIndex(i)
            if(i == size - 1)
                multipliersString .= value . "]"
            else
                multipliersString .= value . ", "
            multiplierTotal *= Max(1.0, value)
            i++
        }
        return multipliersString
    }

    UpdateKeyUsage()
    {
        KeysPressed := ""
        for k,v in g_KeyPresses
        {
            KeysPressed .= k . ":" . v . " "
        }
        GuiControl, ICScriptHub:, KeyUsageID, % KeysPressed
    }
}
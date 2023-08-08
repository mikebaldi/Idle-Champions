/*
    Briv Related Memory Reads
*/

Gui, ICScriptHub:Tab, Memory View

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, Briv Functions:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Text, x15 y+5, ReadCurrentZone:
Gui, ICScriptHub:Add, Text, vBrivReadCurrentZoneID x+2 w100,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivSkipChance: 
Gui, ICScriptHub:Add, Text, vBrivSkipChanceID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivHasteStacks: 
Gui, ICScriptHub:Add, Text, vBrivHasteStacksID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivSkipAmount: 
Gui, ICScriptHub:Add, Text, vBrivSkipAmountID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivAreasSkipped: 
Gui, ICScriptHub:Add, Text, vBrivAreasSkippedID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, CalculateBrivStacksToReachNextModronResetZone: 
Gui, ICScriptHub:Add, Text, vCalculateBrivStacksToReachNextModronResetZoneID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, CalculateBrivStacksConsumedToReachModronResetZone: 
Gui, ICScriptHub:Add, Text, vCalculateBrivStacksConsumedToReachModronResetZoneID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, LeftoverStacksAtReset: 
Gui, ICScriptHub:Add, Text, vLeftoverStacksAtResetID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivCalculatedTargetStacks: 
Gui, ICScriptHub:Add, Text, vBrivCalculatedTargetStacksID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, BrivCalculatedTargetStacks (1 time - Com): 
Gui, ICScriptHub:Add, Text, vBrivCalculatedTargetStacks2ID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, CalculateMaxZone: 
Gui, ICScriptHub:Add, Text, vCalculateMaxZoneID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, IsBrivMetalborn: 
Gui, ICScriptHub:Add, Text, vIsBrivMetalbornID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, Stacks from previous stacking: 
Gui, ICScriptHub:Add, Text, vPreviousStackingStacksID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, Briv's Slot 4 Item Level: 
Gui, ICScriptHub:Add, Text, vBrivSlot4IlvlID x+2 w300,

class ReadMemoryFunctionsExtended
{
    CheckReads()
    {
        Sleep, -1
        if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
            ReadMemoryFunctions.MainReads()
        this.ReadContinuous()
    }

    ReadContinuous()
    {
        static lastRead := 0
        if(A_TickCount - lastRead > 1000)
        {
            lastRead := A_TickCount
            GuiControl, ICScriptHub:, BrivReadCurrentZoneID, % g_SF.Memory.ReadCurrentZone()
            GuiControl, ICScriptHub:, BrivSkipChanceID, % Format("{:0.16f}", ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance() * 100)`%
            GuiControl, ICScriptHub:, BrivHasteStacksID, % Format("{:0.1f}", ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks())
            GuiControl, ICScriptHub:, BrivSkipAmountID, % ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
            GuiControl, ICScriptHub:, BrivAreasSkippedID, % ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadAreasSkipped()
            GuiControl, ICScriptHub:, CalculateBrivStacksToReachNextModronResetZoneID, % Format("{:0.2f}", g_SF.CalculateBrivStacksToReachNextModronResetZone())
            GuiControl, ICScriptHub:, CalculateBrivStacksConsumedToReachModronResetZoneID, % Format("{:0.2f}", g_SF.CalculateBrivStacksConsumedToReachModronResetZone())
            GuiControl, ICScriptHub:, LeftoverStacksAtResetID, % Format("{:0.2f}", ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadHasteStacks() - g_SF.CalculateBrivStacksConsumedToReachModronResetZone())
            GuiControl, ICScriptHub:, CalculateMaxZoneID, % Format("{:0.0f}", g_SF.CalculateMaxZone(1)) . " - " . Format("{:0.0f}", g_SF.CalculateMaxZone(2)) . " (" . Format("{:0.0f}", g_SF.CalculateMaxZone(0)) . ")"
            GuiControl, ICScriptHub:, IsBrivMetalbornID, % g_SF.IsBrivMetalborn()
            GuiControl, ICScriptHub:, BrivCalculatedTargetStacksID, % g_SF.CalculateBrivStacksToReachNextModronResetZone() - g_SF.CalculateBrivStacksLeftAtTargetZone(g_SF.Memory.ReadCurrentZone(), g_SF.Memory.GetModronResetArea() + 1)
            GuiControl, ICScriptHub:, BrivSlot4IlvlID, % g_SF.Memory.ReadBrivSlot4ilvl()
            
            Try 
            {
                SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
                GuiControl, ICScriptHub:, PreviousStackingStacksID, % SharedRunData.PreviousStacksFromOffline
                GuiControl, ICScriptHub:, BrivCalculatedTargetStacks2ID, % SharedRunData.TargetStacks
            }
            catch
            {
                GuiControl, ICScriptHub:, BrivCalculatedTargetStacks2ID, % "-- ERROR --"
            }
        }

    }
}
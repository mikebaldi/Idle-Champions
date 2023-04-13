/*
    LoadTiming Testing
*/
Gui, ICScriptHub:Tab, Memory View
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, Testing Memory Reads :
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Text, x15 y+5, ResetsCount: 
Gui, ICScriptHub:Add, Text, vResetsCount2ID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, UserIsInited: 
Gui, ICScriptHub:Add, Text, vReadUserIsInitedID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, GameStarted: 
Gui, ICScriptHub:Add, Text, vReadGS2ID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadFinishedOfflineProgress: 
Gui, ICScriptHub:Add, Text, vReadFinishedOfflineProgressWindow2ID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadInGameNumSecondsToProcess2ID: 
Gui, ICScriptHub:Add, Text, vReadInGameNumSecondsToProcess2ID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadSecondsSinceLastSave: 
Gui, ICScriptHub:Add, Text, vReadSecondsSinceLastSaveID x+2 w300,

class ReadMemoryFunctionsExtended
{
    CheckReads()
    {
        if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
            ReadMemoryFunctions.MainReads()
        this.ReadContinuous()
    }

    ReadContinuous()
    {
        g_SF.Memory.OpenProcessReader()
        this.PreExisting()
        this.Keep()
        this.Depricate()
    }

    PreExisting()
    {
        GuiControl, ICScriptHub:, ReadUserIsInitedID, % g_SF.Memory.ReadUserIsInited()
        GuiControl, ICScriptHub:, ReadFinishedOfflineProgressWindow2ID, % g_SF.Memory.ReadOfflineDone()
        GuiControl, ICScriptHub:, ReadGS2ID, % g_SF.Memory.ReadGameStarted()

        GuiControl, ICScriptHub:, ReadInGameNumSecondsToProcess2ID, % g_SF.Memory.ReadOfflineTime()
        GuiControl, ICScriptHub:, ResetsCount2ID, % g_SF.Memory.ReadResetsCount()
    }

    Keep()
    {
        GuiControl, ICScriptHub:, ReadSecondsSinceLastSaveID, % g_SF.Memory.GameManager.game.gameInstances[0].instanceLoadTimeSinceLastSave.Read()
    }
}
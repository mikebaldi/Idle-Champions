
class IC_SharedData_Class
{
    ; Note stats vs States. Confusing, but intended.


        
    LoopString ; set as a property to be able to overwrite and log loopString in the future.
    {
        get
        {
            return this._loopString
        }
        set
        {
            this._loopString := val
        }
    }

    StackFailStats := new StackFailStates
    TotalBossesHit := 0
    BossesHitThisRun := 0
    SwapsMadeThisRun := 0
    StackFail := 0
    OpenedSilverChests := 0
    OpenedGoldChests := 0
    PurchasedGoldChests := 0
    PurchasedSilverChests := 0
    ShinyCount := 0
    TriggerStart := false
    TotalRollBacks := 0
    BadAutoProgress := 0
    PreviousStacksFromOffline := 0
    TargetStacks := 0
    ShiniesByChamp := {}
    ShiniesByChampJson := ""
    GemsSpent := 0
    LowestHasteStacks := 9999999
    TotalRunsCount := 0
    LastRunTime := 0
    ScriptStartTime := 0
    SharedDataTest := True

    Close()
    {
        ExitApp
    }

    ReloadSettings(ReloadSettingsFunc)
    {
        reloadFunc := Func(ReloadSettingsFunc)
        reloadFunc.Call()
    }

    ShowGUI()
    {
        Gui, show, NA
    }
}
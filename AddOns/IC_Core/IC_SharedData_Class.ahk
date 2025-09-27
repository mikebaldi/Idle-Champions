
class IC_SharedData_Class
{
    ; Note stats vs States. Confusing, but intended.
    StackFailStats := new StackFailStates
    LoopString := ""
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
    ServerCallsAreComplete := True
    GemsSpent := 0

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
        Gui, show
    }
}
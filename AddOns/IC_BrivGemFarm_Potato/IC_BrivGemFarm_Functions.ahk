class IC_BrivPotatoSharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    ; Waits for the game to be in a ready state
    WaitForGameReady( timeout := 90000)
    {
        timeoutTimerStart := A_TickCount
        ElapsedTime := 0
        ; wait for game to start
        g_SharedData.LoopString := "Waiting for game started.."
        while( ElapsedTime < timeout AND !this.Memory.ReadGameStarted())
        {
            ElapsedTime := A_TickCount - timeoutTimerStart
        }
        ; check if game has offline progress to calculate
        offlineTime := this.Memory.ReadOfflineTime()
        if(this.Memory.ReadGameStarted())
        {
            if(offlineTime <= 0 AND offlineTime != "")
                return true ; No offline progress to caclculate, game started
            else
            {
                ; wait for offline progress to finish
                g_SharedData.LoopString := "Waiting for offline progress.."
                while( ElapsedTime < timeout AND !this.Memory.ReadOfflineDone())
                {
                    Sleep, 250
                    ElapsedTime := A_TickCount - timeoutTimerStart
                }
                ; finished before timeout
                if(this.Memory.ReadOfflineDone())
                {
                    this.WaitForFinalStatUpdates()
                    g_PreviousZoneStartTime := A_TickCount
                    return true
                }
            }
        }
        ; timed out
        secondsToTimeout := Floor(timeout/ 1000)
        this.CloseIC( "WaitForGameReady-Failed to finish in " . secondsToTimeout . "s." )
        return false
    }

    ; Waits until stats are finished updating from offline progress calculations. (Currently just Sleep, 1200)
    WaitForFinalStatUpdates()
    {
        g_SharedData.LoopString := "Waiting for offline progress (Area Active)..."
        ; Starts as 1, turns to 0, back to 1 when active again.
        StartTime := ElapsedTime := A_TickCount
        while(this.Memory.ReadAreaActive() AND ElapsedTime < 1700)
        {
            Sleep, 100
            ElapsedTime := A_TickCount - StartTime
        }
        while(!this.Memory.ReadAreaActive() AND ElapsedTime < 3000)
        {
            Sleep, 100
            ElapsedTime := A_TickCount - StartTime
        }
        ; Briv stacks are finished updating shortly after ReadOfflineDone() completes. Give it a second.
        ; Sleep, 1200
    }
}

class IC_BrivPotatoGemFarm_Class extends IC_BrivGemFarm_Class
{
}
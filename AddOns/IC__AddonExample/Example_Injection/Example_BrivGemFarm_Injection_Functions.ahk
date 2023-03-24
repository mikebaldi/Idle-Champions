class IC_Example_SharedFunctions_Class
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

class IC_Example_BrivGemFarm_Class
{
}

class IC_Example_SharedData_Class
{
    ReloadShandieDashWaitSettings() {
        MsgBox, , , Shandie settings saved, 1
        g_ShandieDashWaitUserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\DashWaitSettings.json" )
        If !IsObject( g_ShandieDashWaitUserSettings )
        {
            g_ShandieDashWaitUserSettings := {}        
            g_ShandieDashWaitUserSettings["WriteSettings"] := true
        }
        if ( g_ShandieDashWaitUserSettings["ShandieDashWaitAtStart"] == "" )
            g_ShandieDashWaitUserSettings["ShandieDashWaitAtStart"] := 1

        if ( g_ShandieDashWaitUserSettings["ShandieDashWaitPostStack"] == "" )
            g_ShandieDashWaitUserSettings["ShandieDashWaitPostStack"] := 1
        
        if(g_ShandieDashWaitUserSettings["WriteSettings"] := true)
        {
            g_ShandieDashWaitUserSettings.Delete("WriteSettings")
            g_SF.WriteObjectToJSON( A_LineFile . "\..\DashWaitSettings.json" , g_ShandieDashWaitUserSettings )   
        }
    }
}
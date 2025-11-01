class IC_BrivGemFarm_Stats_Overrides_Class
{
    Briv_Connect_Clicked()
    {   
        
        g_BrivGemFarmStats.StatsRunsCount := 0 ; reset count
        base.Briv_Connect_Clicked()
        g_BrivGemFarmStats.UpdateStartLoopStats()
    }

    StopClickedOnErr()
    {
        try
        {
            base.Briv_Connect_Clicked()
            SharedData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedData.Close()
        }
        catch, err2
        {
            ; When the Close() function is called "0x800706BE - The remote procedure call failed." is thrown even though the function successfully executes.
            if(err2.Message != "0x800706BE - The remote procedure call failed.")
                this.UpdateStatus("Gem Farm not running")
            else
                this.UpdateStatus("Gem Farm Stopped")
        }
    }
}

class IC_BrivGemFarm_Stats_Coms_Added_Class ; g_BrivFarmComsObj 
{
    MonitorIsGameClosed()
    {
        fncToCall := g_BrivFarmComsObj.OneTimeRunAtResetEndFunctions["MonitorIsGameClosed"]
        timer := g_BrivFarmComsObj.OneTimeRunAtResetEndFunctionsTimes["MonitorIsGameClosed"]
        SetTimer, %fncToCall%, %timer%
    }
}

SH_UpdateClass.UpdateClassFunctions(IC_BrivGemFarm_Component, IC_BrivGemFarm_Stats_Overrides_Class)
SH_UpdateClass.AddClassFunctions(IC_BrivGemFarm_Coms, IC_BrivGemFarm_Stats_Coms_Added_Class)
class IC_BrivGemFarm_Stats_Overrides_Class
{
    Briv_Connect_Clicked()
    {   
        
        g_BrivGemFarmStats.StatsRunsCount := 0 ; reset count
        base.Briv_Connect_Clicked()
        g_BrivGemFarmStats.UpdateStartLoopStats(true)
    }
}
SH_UpdateClass.UpdateClassFunctions(IC_BrivGemFarm_Component, IC_BrivGemFarm_Stats_Overrides_Class)
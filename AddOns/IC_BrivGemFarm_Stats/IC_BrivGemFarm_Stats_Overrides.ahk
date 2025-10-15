class IC_BrivGemFarm_Stats_Overrides_Class
{
    Briv_Start_Clicked()
    {   
        g_BrivGemFarmStats.IsFirstRun := True
        base.Briv_Connect_Clicked()
    }
}
SH_UpdateClass.UpdateClassFunctions(IC_BrivGemFarm_Component,IC_BrivGemFarm_Stats_Overrides_Class)
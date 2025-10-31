class IC_BrivGemFarm_Stats_SharedFunctions_Added_Class
{
    CloseIC()
    {
        g_SharedData.MonitorIsGameClosed()
        base.CloseIC()
    }
}

SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivGemFarm_Stats_SharedFunctions_Added_Class)
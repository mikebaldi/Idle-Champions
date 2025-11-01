class IC_BrivGemFarm_Stats_SharedFunctions_Added_Class
{
    CloseIC( string := "")
    {
        base.CloseIC(string)
        g_ScriptHubComs.MonitorIsGameClosed()
    }
}

SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivGemFarm_Stats_SharedFunctions_Added_Class)
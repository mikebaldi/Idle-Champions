; Shared com object
class IC_BrivGemFarm_Coms
{
    OneTimeRunAtResetFunctions := {}
    OneTimeRunAtStartFunctions := {}
    OneTimeRunAtEndFunctions := {}
    OneTimeRunAtResetFunctionsTimes := {}

    RunTimersOnModronReset()
    {
        ; set off timers so gem farm does not have to wait for functions to run before continuing.
		for k,v in this.OneTimeRunAtResetFunctions
        {
            repeatTimeMS := this.OneTimeRunAtResetFunctionsTimes[k]
			SetTimer, %v%, %repeatTimeMS%, 0
        }
    }

    RunTimersOnGemFarmStart()
    {
		for k,v in this.OneTimeRunAtStartFunctions
			SetTimer, %k%, %v%, 3
    }

    RunTimersOnGemFarmEnd()
    {
        for k,v in this.OneTimeRunAtEndFunctions
			SetTimer, %k%, %v%, 0
    }

    StopAll()
    {
        for k,v in this.OneTimeRunAtEndFunctions
        {
			SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        for k,v in this.OneTimeRunAtStartFunctions
        {
			SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        ; for k,v in this.OneTimeRunAtResetFunctions
    }
}
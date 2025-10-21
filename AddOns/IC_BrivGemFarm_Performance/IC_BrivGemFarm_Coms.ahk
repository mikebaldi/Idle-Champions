; Shared com object
class IC_BrivGemFarm_Coms
{
    OneTimeRunAtResetStartFunctions := {}
    OneTimeRunAtResetEndFunctions := {}
    OneTimeRunAtStartFunctions := {}
    OneTimeRunAtEndFunctions := {}
    OneTimeRunAtResetStartFunctionsTimes := {}
    OneTimeRunAtResetEndFunctionsTimes := {}

    Init()
    {
        this.ModronResetStartFnc := ObjBindMethod(this, "RunTimersOnModronResetStartInternal")
        this.ModronResetEndFnc := ObjBindMethod(this, "RunTimersOnModronResetEndInternal")
    }

    RunTimersOnModronResetStart()
    {
        ; set off timers so gem farm does not have to wait for functions to run before continuing.
        timerFnc := this.ModronResetStartFnc
        SetTimer, %timerFnc%, -50, 5
    }

    RunTimersOnModronResetStartInternal()
    {
		for k,v in this.OneTimeRunAtResetStartFunctions
        {
            repeatTimeMS := this.OneTimeRunAtResetStartFunctionsTimes[k]
			SetTimer, %v%, %repeatTimeMS%, 5
        }
    }

    RunTimersOnModronResetEnd()
    {
        ; set off timers so gem farm does not have to wait for functions to run before continuing.
        timerFnc := this.ModronResetEndFnc
        SetTimer, %timerFnc%, -50, 3
    }

    RunTimersOnModronResetEndInternal()
    {
        ; set off timers so gem farm does not have to wait for functions to run before continuing.
		for k,v in this.OneTimeRunAtResetEndFunctions
        {
            repeatTimeMS := this.OneTimeRunAtResetEndFunctionsTimes[k]
			SetTimer, %v%, %repeatTimeMS%, 3
        }
    }

    RunTimersOnGemFarmStart()
    {
		for k,v in this.OneTimeRunAtStartFunctions
			SetTimer, %k%, %v%, 2
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
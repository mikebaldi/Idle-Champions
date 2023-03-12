;========================================
;Class for logging Idle Champions scripts
;========================================
/*  Usage:

    Parameters:

*/

class _classLog
{
    GetVersion()
    {
        return "v1.4, 11/22/21"
    }

    stack := {}
    doLogging := false

    __New( doLogging := false )
    {
        if( doLogging )
        {
            this.StartLogging()
        }
        Return this
    }

    StartLogging()
    {
        this.doLogging := true
        this.CreateLog()
    }

    StopLogging()
    {
        this.doLogging := false
    }

    CreateLog()
    {
        dir := A_ScriptDir . "\LOG"
        if !FileExist( dir )
            FileCreateDir, %dir%
        this.fileName := "LOG\" . A_YYYY . "_" . A_MM . A_DD . "_1.json"
        i := 2
        while ( FileExist( this.fileName ) )
        {
            this.fileName := "LOG\" . A_YYYY . "_" . A_MM . A_DD . "_" . i . ".json"
            ++i
        }
        FileAppend, [, % this.fileName
    }

    LogObject( obj )
    {
        if(this.doLogging)
        {
            FileAppend, % JSON.stringify( obj ) . ",", % this.fileName
        }
        Return
    }

    LogFinalObject( obj )
    {
        if(this.doLogging)
        {
            FileAppend, % JSON.stringify( obj ) . "]", % this.fileName
        }
        Return
    }

    AddToStack( obj )
    {
        if(this.doLogging)
        {
            index := this.stack.Count()
            if index != 0
                this.stack[ index ].eventLog.Push( obj )
            this.stack.Push( obj )
        }
    }

    PopStack()
    {
        if(this.doLogging)
        {
            this.stack.Pop()
        }
    }

    ClearStack()
    {
        if(this.doLogging)
        {
            this.stack := {}
        }
    }
}

class _EventLog
{
    event := {}
    event.description := ""
    event.duration := ""
    eventLog := {}
    __new( description )
    {
        this.event := {}
        this.event.description := description . ""
        this.event.duration := new _ValueStartStop()
        Return this
    }

    Add( value )
    {
        this.eventLog.Push( value )
    }

    Stop()
    {
        this.event.duration.Stop()
    }
}

class _ValueStartStop
{
    startTickCount := ""
    timeStamp := ""
    ms := -1
    __new()
    {
        this.startTickCount := A_TickCount + 0
        this.timeStamp := A_Now
        Return this
    }

    Stop()
    {
        this.ms := A_TickCount - this.startTickCount
    }
}

class _DataPoint
{
    entry := {}
    entry.description := ""
    entry.tickCount := ""
    entry.value := ""

    __new( description, value, paramToBeRemoved := "" )
    {
        this.entry.description := description . ""
        this.entry.tickCount := A_TickCount + 0
        this.entry.value := value . ""
        Return this
    }
}

#include %A_LineFile%\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\SharedFunctions\SH_SharedFunctions.ahk 
class SH_ServerCalls
{
    proxy := ""

    __New()
    {
        this.LoadSettings()
        return this
    }

    BasicServerCall( url, timeout := 60000 ) 
    {

        response := ""
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( 0, 45000, 30000, timeout )
        if (this.proxy != "")
            WR.SetProxy(2, this.proxy)
        Try {
            WR.Open( "GET", Url, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.SetRequestHeader( "Accept","application/json" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        catch exception {
			return exception
		}
        return response
    }

    ; Load global server call Settings into this class.
    LoadSettings(settingsLoc := "")
    {
        settingsLoc := settingsLoc ? settingsLoc :  A_LineFile . "\..\Settings.json"
        this.Settings := SH_SharedFunctions.LoadObjectFromJSON( settingsLoc )
        if(IsObject(this.Settings))
            this.proxy := this.settings["ProxyServer"] . ":" . this.settings["ProxyPort"]
    }
}
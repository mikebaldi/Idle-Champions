/*
    GameSettings Memory Reads (User Info)
*/

g_TabControlHeight += 130
GuiControl, ICScriptHub:Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
;Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+40

Gui, ICScriptHub:Tab, Memory View

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15, GameSettings:
Gui, ICScriptHub:Font, w400

Gui, ICScriptHub:Add, Text, x15 y+5, UserID: 
Gui, ICScriptHub:Add, Text, vUserIDID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, UserHash: 
Gui, ICScriptHub:Add, Text, vUserHashID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, InstanceID: 
Gui, ICScriptHub:Add, Text, vInstanceIDID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, Platform: 
Gui, ICScriptHub:Add, Text, vPlatformID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, GameVersion: 
Gui, ICScriptHub:Add, Text, vGameVersionID x+2 w300,
Gui, ICScriptHub:Add, Text, x15 y+5, WebRoot: 
Gui, ICScriptHub:Add, Text, vWebRootID x+2 w300,

class ReadMemoryFunctionsExtended
{
    CheckReads()
    {
        Sleep, -1
        if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
            ReadMemoryFunctions.MainReads()
        this.ReadContinuous()
    }

    ReadContinuous()
    {
        GuiControl, ICScriptHub:, UserIDID, % g_SF.Memory.ReadUserID()
        GuiControl, ICScriptHub:, UserHashID, % g_SF.Memory.ReadUserHash()
        GuiControl, ICScriptHub:, InstanceIDID, % g_SF.Memory.ReadInstanceID()
        GuiControl, ICScriptHub:, PlatformID, % g_SF.Memory.ReadPlatform()
        GuiControl, ICScriptHub:, GameVersionID, % g_SF.Memory.ReadGameVersion()
        GuiControl, ICScriptHub:, WebRootID, % g_SF.Memory.ReadWebRoot()
    }
}
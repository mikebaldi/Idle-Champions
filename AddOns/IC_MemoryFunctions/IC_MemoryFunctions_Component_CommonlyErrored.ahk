/*
    Memory Reads Testing
*/
Gui, ICScriptHub:Tab, Memory View
Gui, ICScriptHub:Font, w700
if(IsFunc(Func("ReadMemoryFunctions.MainReads")))
    Gui, ICScriptHub:Add, Text, x15 y550, Commonly Erroring Functions:
else
    Gui, ICScriptHub:Add, Text, x15 y55, Commonly Erroring Functions:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, (Open Blessings Dialog First)

Gui, ICScriptHub:Add, Text, x15 y+10, GetBlessingsCurrency: 
Gui, ICScriptHub:Add, Text, vGetBlessingsCurrencyLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, GetBlessingsDialogSlot: 
Gui, ICScriptHub:Add, Text, vGetBlessingsDialogSlotLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, GetForceConvertFavor: 
Gui, ICScriptHub:Add, Text, vGetForceConvertFavorLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadConversionCurrencyBySlot: 
Gui, ICScriptHub:Add, Text, vReadConversionCurrencyBySlotLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadForceConvertFavorBySlot: 
Gui, ICScriptHub:Add, Text, vReadForceConvertFavorBySlotLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadTimeScaleMultipliersByIndex: 
Gui, ICScriptHub:Add, Text, vReadTimeScaleMultipliersByIndexLblID x+2 w170,
Gui, ICScriptHub:Add, Text, x15 y+5, ReadDialogNameBySlot: 
Gui, ICScriptHub:Add, Text, x20 y+5 vReadDialogNameBySlotLblID w200 h165,

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+0, GameSettings:
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
Gui, ICScriptHub:Add, Text, x15 y+5, Game Location: 
Gui, ICScriptHub:Add, Text, vGameLocID x+2 w600,

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
        GuiControl, ICScriptHub:, GetBlessingsCurrencyLblID, % g_SF.Memory.GetBlessingsCurrency()
        GuiControl, ICScriptHub:, GetBlessingsDialogSlotLblID, % g_SF.Memory.GetBlessingsDialogSlot()
        GuiControl, ICScriptHub:, GetForceConvertFavorLblID, % g_SF.Memory.GetForceConvertFavor()
        GuiControl, ICScriptHub:, ReadConversionCurrencyBySlotLblID, % this.GetConversionCurrencyStrings()
        GuiControl, ICScriptHub:, ReadForceConvertFavorBySlotLblID, % this.GetForceConvertFavorTagInAllSlots()
        GuiControl, ICScriptHub:, ReadTimeScaleMultipliersByIndexLblID, % this.GetMultipliersString()
        GuiControl, ICScriptHub:, ReadDialogNameBySlotLblID, % this.GetDialogNameStrings()
        GuiControl, ICScriptHub:, InstanceIDID, % g_SF.Memory.ReadInstanceID()
        GuiControl, ICScriptHub:, UserIDID, % g_SF.Memory.ReadUserID()
        GuiControl, ICScriptHub:, UserHashID, % g_SF.Memory.ReadUserHash()
        GuiControl, ICScriptHub:, PlatformID, % g_SF.Memory.ReadPlatform()
        GuiControl, ICScriptHub:, GameVersionID, % g_SF.Memory.ReadGameVersion()
        GuiControl, ICScriptHub:, WebRootID, % g_SF.Memory.ReadWebRoot()
        GuiControl, ICScriptHub:, GameLocID, % g_SF.Memory.GetWebRequestLogLocation()
    }

    GetMultipliersString()
    {
        multiplierTotal := 1
        size := g_SF.Memory.ReadTimeScaleMultipliersCount()
        i := 0
        if size
            multipliersString := "["
        loop, %size%
        {
            value := g_SF.Memory.ReadTimeScaleMultiplierByIndex(i)
            if(i == size - 1)
                multipliersString .= value . "]"
            else
                multipliersString .= value . ", "
            multiplierTotal *= Max(1.0, value)
            i++
        }
        return multipliersString
    }

    GetConversionCurrencyStrings()
    {
        size := g_SF.Memory.ReadDialogsListSize()
        i := 0
        if(size > 50 OR size < 0) ; sanity check
            return ""
        currencyString := "["
        loop, %size%
        {
            value := g_SF.Memory.ReadConversionCurrencyBySlot(i)
            if(i == size - 1)
                currencyString .= value . "]"
            else
                currencyString .= value . ", "
            i++
        }
        return currencyString
    }

    GetDialogNameStrings()
    {
        size := g_SF.Memory.ReadDialogsListSize()
        i := 0
        if(size > 50 OR size < 0) ; sanity check
            return ""
        dialogString := "["
        loop, %size%
        {
            value := g_SF.Memory.ReadDialogNameBySlot(i)
            if(i == size - 1)
                dialogString .= value . "]"
            else
                dialogString .= value . "`n"
            i++
        }
        return dialogString
    }

    GetForceConvertFavorTagInAllSlots()
    {
        size := g_SF.Memory.ReadDialogsListSize()
        i := 0
        if(size > 50 OR size < 0) ; sanity check
            return ""
        loop, %size%
        {
            value := g_SF.Memory.ReadForceConvertFavorBySlot(i)
            if(i == size - 1)
                forceConvertString .= value
            else
                forceConvertString .= value . ", "
            i++
        }
        return forceConvertString
    }
}
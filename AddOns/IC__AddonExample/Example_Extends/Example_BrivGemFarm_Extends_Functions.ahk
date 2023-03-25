
; Note that this class is extending IC_BrivSharedFunctions_Class and not IC_SharedFunctions_Class.
; IC_BrivSharedFunctions_Class already extends IC_SharedFunctions_Class and we want this functionality added on top of BrivGemFarm.
; By using extends this class will be a copy of the original class, but will overwrite any existing functions with the new ones or include any added functions.
class IC_Example_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    ; Example of a function being modified.
    ; Modified version of InitZone that will use all champions' ultimate abilities when advancing zones (if possible).

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        if(g_UserSettings[ "NoCtrlKeypress" ])
        {
            this.DirectedInput(,release := 0, "{ClickDmg}") ;keysdown
            this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
        }
        else
        {
            ; ctrl level clickers
            this.DirectedInput(,release := 0, ["{RCtrl}","{ClickDmg}"]*) ;keysdown
            this.DirectedInput(hold := 0,, ["{ClickDmg}","{RCtrl}"]*) ;keysup
        }
        ; turn Fkeys off/on again
        this.DirectedInput(hold := 0,, spam*) ;keysup
        this.DirectedInput(,release := 0, spam*) ;keysdown
        ; try to progress
        this.DirectedInput(,,"{Right}")
        this.ToggleAutoProgress(1)
        ;-----------  Modification being made through Extends -------------
        this.FireFormationUltimates()              ; Call a new function that activates ultimates.
        ;----------------------- MOdification End. ------------------------
        this.ModronResetZone := this.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }

    ; Example of a function being added.

    ; Note that GetUltimateButtonByChampID is a function in the IC_SharedFunctions_Class class. 
    ; By extending IC_BrivSharedFunctions_Class and thus also extending IC_SharedFunctions_Class,
    ; we have access to all funcitons in IC_BrivSharedFunctions_Class.

    ; Attempts to use ultimates for any champions currently on the field.
    FireFormationUltimates()
    {
        formation := this.Memory.GetCurrentFormation()              ; Get the formation on the field
        for k, champID in formation                                 ; Loop through champs in formation
        {
            if(champID <= 0)                                        ; if champID is valid
                continue
            ultButton := this.GetUltimateButtonByChampID(champID)   ; Get ult button for champion.
            this.DirectedInput(,,ultButton)                         ; send ultimate button keystroke
        }
    }
}
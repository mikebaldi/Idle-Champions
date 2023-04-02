g_TabControlHeight := g_TabControlHeight >= 700 ? g_TabControlHeight : 700
GUIFunctions.AddTab("Jimothy")

g_SF := new IC_JimothySharedFunctions_Class
global g_JimothySettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\JimothySettings.json" )

;check if first run
If !IsObject( g_JimothySettings )
{
    g_JimothySettings := {}
    g_SF.WriteObjectToJSON( A_LineFile . "\..\JimothySettings.json" , g_JimothySettings )
}

Gui, ICScriptHub:Tab, Jimothy
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+10 w120, What is happening:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+10 w300 vJimothyStatus, This Addon is not running.
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyHew,
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyMonsters,
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyZone,
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyHaste,
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyFormation,
Gui, ICScriptHub:Add, Text, x15 y+5 w400 vJimothyFkeys,
Gui, ICScriptHub:Add, Text, x15 y+5 w300 vJimothyClick,
    
Gui, ICScriptHub:Add, Button, x15 y+15 gJimothy_Save_Clicked, Save Settings
Gui, ICScriptHub:Add, Button, x+25 w50 gJimothy_Run_Clicked, `Run

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+15 w120, Settings:
Gui, ICScriptHub:Font, w400

if ( g_JimothySettings.MaxZone == "" )
    g_JimothySettings.MaxZone := 2000
Gui, ICScriptHub:Add, Text, x15 y+10, Max Zone:
Gui, ICScriptHub:Add, Edit, vJimothyMaxZone x+5 w50, % g_JimothySettings.MaxZone
b == "Down" ? 0x100 : 0x101
Gui, ICScriptHub:Add, Text, x+5 vJimothyMaxZoneSaved, % "Saved value: " . g_JimothySettings.MaxZone

if ( g_JimothySettings.MaxMonsters == "" )
    g_JimothySettings.MaxMonsters := 75
Gui, ICScriptHub:Add, Text, x15 y+15, Max Monsters:
Gui, ICScriptHub:Add, Edit, vJimothyMaxMonsters x+5 w50, % g_JimothySettings.MaxMonsters
Gui, ICScriptHub:Add, Text, x+5 vJimothyMaxMonstersSaved, % "Saved value: " . g_JimothySettings.MaxMonsters

if ( g_JimothySettings.UseFkeys == "" )
    g_JimothySettings.UseFkeys := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Use Fkeys to level 'Q' formation:
chk := g_JimothySettings.UseFkeys
Gui, ICScriptHub:Add, Checkbox, vCbUseFkeys Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vJimothyUseFkeysSaved w200, % g_JimothySettings.UseFkeys == 1 ? "Saved value: True":"Saved value: False"

if ( g_JimothySettings.UseClick == "" )
    g_JimothySettings.UseClick := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Level click damage:
chk := g_JimothySettings.UseClick
Gui, ICScriptHub:Add, Checkbox, vCbUseClick Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vJimothyUseClickSaved w200, % g_JimothySettings.UseClick == 1 ? "Saved value: True":"Saved value: False"

if ( g_JimothySettings.UseHew == "" )
    g_JimothySettings.UseHew := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Check if Hew is alive:
chk := g_JimothySettings.UseHew
Gui, ICScriptHub:Add, Checkbox, vCbUseHew Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vJimothyUseHewSaved w200, % g_JimothySettings.UseHew  == 1 ? "Saved value: True":"Saved value: False"

if ( g_JimothySettings.FormationRadio == "" )
    g_JimothySettings.FormationRadio := 0
Gui, ICScriptHub:Add, Text, x15 y+15, Select the formation to use on the checked zones below:
if (g_JimothySettings.FormationRadio == 0)
{
    chkQ := 1
    chkE := 0
    saved := "Q"
}
else
{
    chkQ := 0
    chkE := 1
    saved := "E"
}
Gui, ICScriptHub:Add, Radio, vFormationRadioGroup x+5 vFormationRadioQ Checked%chkQ%, 'Q'
Gui, ICScriptHub:Add, Radio, vFormationRadioGroup x+5 vFormationRadioE Checked%chkE%, 'E'
Gui, ICScriptHub:Add, Text, x+5 vJimothyFormationRadioSaved, % "Saved value: " . saved

if ( g_JimothySettings.Mod5CB == "" )
{
    g_JimothySettings.Mod5CB := {}
    loop, 5
    {
        g_JimothySettings.Mod5CB.Push(0)
    }
}

Gui, ICScriptHub:Add, Text, x15 y+15, Mod 5:
loop, 5
{
    chk := g_JimothySettings.Mod5CB[A_Index]
    Gui, ICScriptHub:Add, Checkbox, vCbMod5Itm%A_Index% Checked%chk% Disabled%chk% x+5 gJimothy_CheckBox_Clicked, % A_Index
}
Gui, ICScriptHub:Add, Text, x15 y+5 vJimothyMod5Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod5CB)

if ( g_JimothySettings.Mod10CB == "" )
{
    g_JimothySettings.Mod10CB := {}
    loop, 10
    {
        g_JimothySettings.Mod10CB.Push(0)
    }
}
Gui, ICScriptHub:Add, Text, x15 y+15, Mod 10:
loop, 10
{
    chk := g_JimothySettings.Mod10CB[A_Index]
    Gui, ICScriptHub:Add, Checkbox, vCbMod10Itm%A_Index% Checked%chk% Disabled%chk% x+5 gJimothy_CheckBox_Clicked, % A_Index
}
Gui, ICScriptHub:Add, Text, x15 y+5 vJimothyMod10Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod10CB)

if ( g_JimothySettings.Mod50CB == "" )
{
    g_JimothySettings.Mod50CB := {}
    loop, 50
    {
        g_JimothySettings.Mod50CB.Push(0)
    }
}
Gui, ICScriptHub:Add, Text, x15 y+15, Mod 50:
loop, 50
{
    chk := g_JimothySettings.Mod50CB[A_Index]
    i := mod
    if (mod(A_Index, 10) != 1 OR A_Index == 1)
        Gui, ICScriptHub:Add, Checkbox, vCbMod50Itm%A_Index% Checked%chk% x+5 gJimothy_CheckBox_Clicked, % A_Index
    else
        Gui, ICScriptHub:Add, Checkbox, vCbMod50Itm%A_Index% Checked%chk% x15 y+5 gJimothy_CheckBox_Clicked, % A_Index
}
Gui, ICScriptHub:Add, Text, x15 y+5 w400 h60 vJimothyMod50Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod50CB)

global g_jim := new Jimothy(g_JimothySettings, true, Jimothy_GuiUpdater)

Jimothy_Run_Clicked()
{
    GuiControl, ICScriptHub:, JimothyStatus, This Addon is currently running.
    g_jim.Jimothy()
    GuiControl, ICScriptHub:, JimothyStatus, % g_jim.EndRunTxt . " Jimothy run over."
    GuiControl, ICScriptHub:, JimothyHew,
    GuiControl, ICScriptHub:, JimothyMonsters,
    GuiControl, ICScriptHub:, JimothyZone,
    GuiControl, ICScriptHub:, JimothyHaste,
    GuiControl, ICScriptHub:, JimothyFormation,
    GuiControl, ICScriptHub:, JimothyFkeys,
    GuiControl, ICScriptHub:, JimothyClick,
    return
}

Jimothy_Save_Clicked()
{
    global
    Gui, ICScriptHub:Submit, NoHide

    g_JimothySettings.MaxZone := JimothyMaxZone
    GuiControl, ICScriptHub:, JimothyMaxZoneSaved, % "Saved value: " . g_JimothySettings.MaxZone

    g_JimothySettings.MaxMonsters := JimothyMaxMonsters
    GuiControl, ICScriptHub:, JimothyMaxMonstersSaved, % "Saved value: " . g_JimothySettings.MaxMonsters

    g_JimothySettings.UseFkeys := CbUseFkeys
    GuiControl, ICScriptHub:, JimothyUseFkeysSaved, % g_JimothySettings.UseFkeys == 1 ? "Saved value: True":"Saved value: False"

    g_JimothySettings.UseClick := CbUseClick
    GuiControl, ICScriptHub:, JimothyUseClickSaved, % g_JimothySettings.UseClick  == 1 ? "Saved value: True":"Saved value: False"

    g_JimothySettings.UseHew := CbUseHew
    GuiControl, ICScriptHub:, JimothyUseHewSaved, % g_JimothySettings.UseHew == 1 ? "Saved value: True":"Saved value: False"

    if (FormationRadioQ == 1)
    {
        g_JimothySettings.FormationRadio := 0
        ;chkQ := 1
        saved := "Q"
    }
    else if (FormationRadioE == 1)
    {
        g_JimothySettings.FormationRadio := 1
        ;chkE := 0
        saved := "E"
    }
    GuiControl, ICScriptHub:, JimothyFormationRadioSaved, % "Saved value: " . saved

    loop, 5
    {
        g_JimothySettings.Mod5CB[A_Index] := CbMod5Itm%A_Index%
    }
    GuiControl, ICScriptHub:, JimothyMod5Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod5CB)

    loop, 10
    {
        g_JimothySettings.Mod10CB[A_Index] := CbMod10Itm%A_Index%
    }
    GuiControl, ICScriptHub:, JimothyMod10Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod10CB)

    loop, 50
    {
        g_JimothySettings.Mod50CB[A_Index] := CbMod50Itm%A_Index%
    }
    GuiControl, ICScriptHub:, JimothyMod50Saved, % "Saved value: " . ArrFnc.GetDecFormattedAssocArrayString(g_JimothySettings.Mod50CB)

    Jimothy_ParseCheckBoxArrays()

    g_jim.UpdateSettings(g_JimothySettings)

    g_SF.WriteObjectToJSON( A_LineFile . "\..\JimothySettings.json" , g_JimothySettings )

    return
}

Jimothy_CheckBox_Clicked()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    chk := %A_GuiControl%
    FoundPos := InStr(A_GuiControl, "I")
    mod := SubStr(A_GuiControl, 6 , FoundPos - 6) + 0
    itm := SubStr(A_GuiControl, FoundPos + 3) + 0
    ;check the appropriate mod10 and mod50 boxes and disable the appropriate mod5 and mod10 boxes
    if (chk == 1 AND mod == 5)
    {
        j := itm
        loop, 2
        {
            GUiControl, ICScriptHub:, CbMod10Itm%j%, 1
            GuiControl, ICScriptHub:Disable, CbMod10Itm%j%
            j += 5
        }
        j := itm
        loop, 10
        {
            GUiControl, ICScriptHub:, CbMod50Itm%j%, 1
            j += 5
        }
        GuiControl, ICScriptHub:Disable, %A_GuiControl%
    }
    ;check if mod5 box should be checked, the appropriate mod50 boxes are checked, and disable the appropriate mod5 and mod10 boxes
    else if (chk == 1 AND mod == 10)
    {
        i := mod(itm, 5)
        if (i == itm)
            i += 5
        if (CbMod10Itm%i% == 1)
        {
            j := mod(itm, 5)
            GUiControl, ICScriptHub:, CbMod5Itm%j%, 1
            GuiControl, ICScriptHub:Disable, CbMod5Itm%j%
        }
        i := mod(itm, 10)
        loop, 5
        {
            GUiControl, ICScriptHub:, CbMod50Itm%i%, 1
            i += 10
        }
        GuiControl, ICScriptHub:Disable, %A_GuiControl%
    }
    ;uncheck and enable the appropriate mod5 and mod10 boxes
    else if (chk == 0 AND mod == 50)
    {
        i := mod(itm, 5)
        if (i == 0)
            i := 5
        j := mod(itm, 10)
        if (j == 0)
            j := 10
        GUiControl, ICScriptHub:, CbMod5Itm%i%, 0
        GuiControl, ICScriptHub:Enable, CbMod5Itm%i%
        GUiControl, ICScriptHub:, CbMod10Itm%j%, 0
        GuiControl, ICScriptHub:Enable, CbMod10Itm%j%
    }
    else if (chk == 1 AND mod == 50)
    {
        ;check if mod5 cb should be checked
        i := mod(itm, 5)
        if (i == 0)
            i := 5
        iChkCount := 0
        loop, 10
        {
            if (CbMod50Itm%i% == 1)
                ++iChkCount
            Else
                break
            i += 5
        }
        if (iChkCount == 10)
        {
            i := mod(itm, 5)
            if (i == 0)
                i := 5
            GUiControl, ICScriptHub:, CbMod5Itm%i%, 1
            GuiControl, ICScriptHub:Disable, CbMod5Itm%i%
        }
        ;check if mod10 cb should be checked.
        i := mod(itm, 10)
        if (i == 0)
            i := 10
        iChkCount := 0
        loop, 5
        {
            if (CbMod50Itm%i% == 1)
                ++iChkCount
            Else
                break
            i += 10
        }
        if (iChkCount == 5)
        {
            i := mod(itm, 10)
            if (i == 0)
                i := 10
            GUiControl, ICScriptHub:, CbMod10Itm%i%, 1
            GuiControl, ICScriptHub:Disable, CbMod10Itm%i%
        }
    }
    Jimothy_Save_Clicked()
}

;instead of iterating through three complete arrays of 1s and 0s, we can shorten the array to specific zones or eliinate redundant arrays
Jimothy_ParseCheckBoxArrays()
{
    g_JimothySettings.Mod5 := {}
    counter := 0
    loop, 5
    {
        if (g_JimothySettings.Mod5CB[A_Index] == 1)
        {
            g_JimothySettings.Mod5.Push(A_Index)
            ++counter
        }
    }
    if (counter == 0)
        g_JimothySettings.Mod5 := false
    
    g_JimothySettings.Mod10 := {}
    counter := 0
    loop, 10
    {
        if (g_JimothySettings.Mod5 != false)
        {
            i := A_Index
            for k, v in g_JimothySettings.Mod5
            {
                if (v == mod(i, 5))
                    Continue 2
            }
        }
        if (g_JimothySettings.Mod10CB[A_Index] == 1)
        {
            g_JimothySettings.Mod10.Push(A_Index)
            ++counter
        }
    }
    if (counter == 0)
        g_JimothySettings.Mod10 := false

    g_JimothySettings.Mod50 := {}
    counter := 0
    loop, 50
    {
        if (g_JimothySettings.Mod5 != false)
        {
            i := A_Index
            for k, v in g_JimothySettings.Mod5
            {
                if (v == mod(i, 5))
                    Continue 2
            }
        }
        if (g_JimothySettings.Mod10 != false)
        {
            i := A_Index
            for k, v in g_JimothySettings.Mod10
            {
                if (v == mod(i, 10))
                    Continue 2
            }
        }
        if (g_JimothySettings.Mod50CB[A_Index] == 1)
        {
            g_JimothySettings.Mod50.Push(A_Index)
            ++counter
        }
    }
    if (counter == 0)
        g_JimothySettings.Mod50 := false
}

class Jimothy_GuiUpdater
{
    Update(obj)
    {
        global
        if (!IsObject(obj))
            return
        
        static IsHewAlive
        if (IsHewAlive != obj.IsHewAlive)
        {
            IsHewAlive := obj.IsHewAlive
            GuiControl, ICScriptHub:, JimothyHew, % "Is Hew alive? " . IsHewAlive
        }
        static Monsters
        if (Monsters != obj.Monsters)
        {
            Monsters := obj.Monsters
            if (Monsters == "Too many monsers spawned, resetting zone.")
                GuiControl, ICScriptHub:, JimothyMonsters, % Monsters
            else
                GuiControl, ICScriptHub:, JimothyMonsters, % "Monsters spawned: " . Monsters
        }
        static Zone
        if (Zone != obj.Zone)
        {
            Zone := obj.Zone
            GuiControl, ICScriptHub:, JimothyZone, % "Current zone: " . Zone
        }
        static Haste
        if (Haste != obj.Haste)
        {
            Haste := obj.Haste
            GuiControl, ICScriptHub:, JimothyHaste, % "Haste stacks: " . Haste
        }
        static Formation
        if (Formation != obj.Formation)
        {
            Formation := obj.Formation
            if (Formation == "Formation 'e', canceling jump animation.")
                GuiControl, ICScriptHub:, JimothyFormation, % Formation
            else
                GuiControl, ICScriptHub:, JimothyFormation, % "formation: '" . Formation . "'"
        }
        static Fkeys
        Fkeys := 2
        if (Fkeys != obj.UseFkeys)
        {
            Fkeys := obj.UseFkeys
            if Fkeys
                GuiControl, ICScriptHub:, JimothyFkeys, % "Inputting the following Fkeys: " . obj.KeySpamTxt
            else
                GuiControl, ICScriptHub:, JimothyFkeys, % "Not inputting Fkeys."
        }
        static clickDamage
        clickDamage := 2
        if (clickDamage != obj.UseClick)
        {
            clickDamage := obj.UseClick
            if clickDamage
                GuiControl, ICScriptHub:, JimothyClick, % "Leveling click damage."
            else
                GuiControl, ICScriptHub:, JimothyClick, % "Not leveling click damage."
        }
    }
}

#include %A_LineFile%\..\IC_Jimothy_Functions.ahk
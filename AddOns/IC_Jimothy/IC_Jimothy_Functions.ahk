/*  A class to automate jimothy push runs.
    TODO: Error checking

    Usage:
    global g_jim := new Jimothy(settings, useMsgBox, external) ;Create instance of class.
    g_jim.UpdateSettings(settings) ;Use when settings change.
    g_jim.Jimothy() ;Begin a jimothy push run.

    See docs below for parameters.
*/
class Jimothy
{
    /*  Creates an instance of the class.

        Parameter(s):
        settings ;See UpdateSettings method below.
        useMsgBox ;Bool to enable or disable message box pop up at end of run or errors.
        external ;An object with method Update() with parameter this. Update() method can be defined to update GUI or other things.
        useFkeys ;Bool to enable or disable using Fkeys to level formation q to max level.

        Returns an instance of the class.
    */
    __new(settings, useMsgBox, external)
    {
        this.UpdateSettings(settings)
        this.UseMsgBox := useMsgBox
        this.External := external
        return this
    }
    
    /*  A method to import settings

        Parameter(s):
        settings ;object containint the following key pairs:
            settings.MaxZone ;When current zone memory reads grater than this value, the script ends. type: integer
            settings.MaxMonsters ;When monsters spawned memory reads greater than this value, the script resets the zone. type: integer
            settings.UseBriv ;Determines which formation to use for the following arrays of zones. 1 for 'q' formation, 0 for 'e' formation
            settings.Mod5 ;An array of up to 5 unique values between 1 and 5. When mod(mod(current zone, 50), 5) == a value from the
                array, the script will set the formation as determined by settings.UseBriv.
            settings.Mod10 ;Save as above, but up to 10 unique values between 1 and 10 and for mod(mod(current zone, 50), 10). For better
                performance, parse this array, i.e. mod5 := [1] and mod10 := false is superior to mod5 := false and mod10 := [1,6]
            settings.Mod50 ;same as above, but up to 50 unique values between 1 and 50 for mod(current zone, 50). Parsing is recommended.
    */
    UpdateSettings(settings)
    {
        this.MaxZone := settings.MaxZone
        this.MaxMonsters := settings.MaxMonsters
        this.UseBriv := settings.UseBriv
        if (this.UseBriv == 1)
        {
            this.ModFormation := "q"
            this.NotModFormation := "e"
        }
        else
        {
            this.ModFormation := "e"
            this.NotModFormation := "q"
        }
        this.Mod5 := settings.Mod5
        this.Mod10 := settings.Mod10
        this.Mod50 := settings.Mod50
        this.UseFkeys := settings.useFkeys
        this.UseClick := settings.useClick
        return
    }

    /*  A  method to automate jimothy push runs. The method will first confirm the correct formations are saved and find Hew's location in
        save formation 1. Note, Hew's location in save formation 3 must be the same. The method then will loop through functions checking
        if the desired level has been reached or if Briv runs out of haste stacks, in either case the script will end. The method will loop
        through additional functions to reset the zone if Hew dies or too many monsters have spawned. The method will also loop through
        arrays to use the correct formation, favorite 1 with Briv or favorite 3 without Briv on the correct zone as defined by the settings.
        Finally, the method will confirm Auto Progress button is toggled on and spam Fkeys associated with formation 'q' if enabled until max level.
    */
    Jimothy()
    {
        init := this.Initialize()
        if (init == 0)
        {
            if (this.UseMsgBox)
                MsgBox, % this.EndRunTxt . " Jimothy run over."
            return
        }
        if (init == 1)
        {
            this.EndRunTxt := "Could not find Hew's slot."
            if (this.UseMsgBox)
                MsgBox, %  this.EndRunTxt . " Jimothy run over."
            return
        }
        this.DoPartySetup()
        Loop
        {
            this.SetFormation()
            this.CheckToResetZone()
            if (this.CheckToEndRun())
                break
            this.External.Update(this)
            g_SF.ToggleAutoProgress()
            if(this.UseFkeys)
                g_SF.DirectedInput(,,this.KeySpam*)
            ;if (this.UseFkeys AND g_SF.areChampionsUpgraded(this.formationQ))
            ;    this.UseFkeys := false
            if (this.UseClick)
                g_SF.DirectedInput(,,"{ClickDmg}")
        }
        if (this.UseMsgBox)
            MsgBox, % this.EndRunTxt . " Jimothy run over."
        return
    }

    Initialize()
    {
        g_SF.Hwnd := WinExist("ahk_exe IdleDragons.exe")
        g_SF.Memory.OpenProcessReader()
        if (this.CheckSetup() == 0)
            return 0
        this.formationQ := g_SF.Memory.GetFormationByFavorite(1)
        g_SF.LevelChampByID( 75, 10, 7000, "{q}") ; level hew once
        this.HewSlot := this.GetHewSlot()
        if (this.HewSlot == -1)
            return 1
        if (this.UseFkeys)
        {
            this.KeySpam := g_SF.GetFormationFKeys(this.formationQ)
            this.KeySpamTxt := ArrFnc.GetAlphaNumericArrayString(this.KeySpam)
        }
        return 2
    }

    DoPartySetup()
    {
        isShandieInFormation := g_SF.IsChampInFormation( 47, this.formationQ )
        if(isShandieInFormation)
            g_SF.LevelChampByID( 47, 230, 7000, "{q}") ; level shandie
        g_SF.LevelChampByID( 58, 170, 7000, "{q}") ; level briv
        isHavilarInFormation := g_SF.IsChampInFormation( 56, this.formationQ )
        if(isHavilarInFormation)
        {
            g_SF.ToggleAutoProgress(0)
            g_SF.LevelChampByID( 56, 15, 7000, "{q}") ; level havi
            ultButton := g_SF.GetUltimateButtonByChampID(56)
            if (ultButton != -1)
                g_SF.DirectedInput(,, ultButton)
            g_SF.ToggleAutoProgress(1)
        }
    }

    SetFormation()
    {
        if ( !g_SF.Memory.ReadQuestRemaining() AND g_SF.Memory.ReadTransitioning() )  ; swap out briv for faster transition
        {
            g_SF.DirectedInput(,,"e")
            this.Formation := "Formation 'e', canceling jump animation."
            Return
        }

        currentZone := g_SF.Memory.ReadCurrentZone()
        mod50 := mod(CurrentZone, 50)
        mod5 := mod(mod50, 5)
        mod10 := mod(mod50, 10)

        if (this.Mod5 != false)
        {
            for k, v in this.Mod5
            {
                if (v == mod5)
                {
                    this.Formation := this.ModFormation
                    g_SF.DirectedInput(,,this.Formation)
                    return
                }
            }
        }
        else if (this.Mod10 != false)
        {
            for k, v in this.Mod10
            {
                if (v == mod10)
                {
                    this.Formation := this.ModFormation
                    g_SF.DirectedInput(,,this.Formation)
                    return
                }
            }
        }
        else if (this.Mod50 != false)
        {
            for k, v in this.Mod50
            {
                if (v == mod50)
                {
                    this.Formation := this.ModFormation
                    g_SF.DirectedInput(,,this.Formation)
                    return
                }
            }
        }

        this.Formation := this.NotModFormation
        g_SF.DirectedInput(,,this.Formation)
        Return
    }

    CheckSetup()
    {
        if (g_SF.FindChampIDinSavedFormation(1, "Jimothy", 1, 75) == "") ;hew
        {
            this.EndRunTxt := "Could not find Hew in favorite formation 1."
            return 0
        }
        if (g_SF.FindChampIDinSavedFormation(1, "Jimothy", 1, 48) == "") ;jim
        {
            this.EndRunTxt := "Could not find Jim in favorite formation 1."
            return 0
        }
        if (g_SF.FindChampIDinSavedFormation(1, "Jimothy", 1, 58) == "") ;briv
        {
            this.EndRunTxt := "Could not find Briv in favorite formation 1."
            return 0
        }
        if (g_SF.FindChampIDinSavedFormation(3, "Jimothy No Briv", 0, 58) == "") ;no briv
        {
            this.EndRunTxt := "Found Briv in favorite formation 3."
            return 0
        }
        return 1
    }

    GetHewSlot()
    {
        for k, v in this.formationQ
        {
            if (v == 75)
                return k - 1
        }
        return -1
    }

    CheckToEndRun()
    {
        this.Zone := g_SF.Memory.ReadCurrentZone()
        if (this.Zone > this.MaxZone)
        {
            this.EndRunTxt := "Reached target zone."
            return true
        }
        
        this.Haste := g_SF.Memory.ReadHasteStacks()
        if (this.Haste < 50)
        {
            this.EndRunTxt := "Ran out of Haste Stacks."
            return true
        }
        
        return false
    }

    CheckToResetZone()
    {
        if !(this.CheckHewIsAlive())
            this.ResetZone()
        if !(this.CheckMaxMonsters())
            this.ResetZone()
    }

    ResetZone()
    {
        g_SF.FallBackFromZone()
        g_SF.ToggleAutoProgress(,,true)
    }

    CheckHewIsAlive()
    {
        if (g_SF.Memory.ReadHeroAliveBySlot(this.HewSlot) == 1)
        {

            this.IsHewAlive := "Yes."
            return true
        }
        else
        {
            this.IsHewAlive := "No, resetting zone."
            return false
        }
    }

    CheckMaxMonsters()
    {
        this.Monsters := g_SF.Memory.ReadMonstersSpawned() 
        if (this.Monsters < this.MaxMonsters)
            return true
        else
        {
            this.Monsters := "Too many monsers spawned, resetting zone."
            return false
        }
    }
}
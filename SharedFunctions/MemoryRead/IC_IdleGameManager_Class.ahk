; GameManager class contains the in game data structure layout

; GameManager class contains the offsets as found in mono-disected memory structures. Specifically, the offsets for the IdleGameManager structure.
; It was designed to make future updates easier by clarifying where each offset is found and (hopefully) reduce the difficulty of updating offsets for structures that remain largely the same.
; - Variable names are based on the layout within the structure not including GameManager itself. e.g. this.Game.GameUser will be IdleGameManager->Game->GameUser.
; - Each offset is built off of a previous offsets. e.g. this.Game.GameUser.ID will be this.game.GameUser + ID, or IdleGameManager->Game->GameUser->ID
; - GameObjectStructure is what is used to combine offsets.
; - Items defined by "List" will have an Item[x] offset that is dynamically selected in code via object.GetGameObjectFromListValues(x).
; - There can be multiple missing list offsets as the game can traverse multiple lists to get to the value you want.
; - i.e. Instead of using:
;            this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount
;   you would use
;            this.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount.GetGameObjectFromListValues( hero_id )
;   as hero_id will tell it which hero from the HeroList is being accessed.
;   Each extra list used will require an extra location passed. e.g. GetGameObjectFromListValues( first_id, second_id, third_id )

#include %A_LineFile%\..\IC_GameObjectStructure_Class.ahk

class IC_IdleGameManager_Class
{
    moduleOffset := 0
    structureOffsets := 0

    __new(moduleOffset := 0, structureOffsets := 0)
    {
        this.moduleOffset := moduleOffset
        this.structureOffsets := structureOffsets
        this.Refresh()
    }

    __Get(key)
    {
        if(this.HasKey(key))
        {
            if(IsObject(this[key])) ; This will never get triggered because __Get does not get called if the key already exists (not as a property/function)
            {
                this[key].FullOffsets.Push(this.structureOffsets*)
                this[key].FullOffsets.Push(this[key].Offset*)
            }
            ;return ; Not returning a value allows AHK to use standard behavior for gets.
            return this[key] 
        }
    }

    GetVersion()
    {
        return "v2.0.2, 2022-08-28, IC v0.463+"
    }

    is64Bit()
    {
        return this.Main.isTarget64bit
    }

    Refresh()
    {
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;hProcessCopy is an optional variable in which the opened handled is stored.
        ;==================
        ;structure pointers
        ;==================
        this.Main := new _ClassMemory("ahk_exe " . g_userSettings[ "ExeName"], "", hProcessCopy)
        this.BaseAddress := this.Main.getModuleBaseAddress("mono-2.0-bdwgc.dll")+this.moduleOffset
        ; Note: Using example Offsets 0xCB0,0 from CE, 0 is a mod (+) and disappears leaving just 0xCB0
        this.IdleGameManager := New GameObjectStructure(this.structureOffsets)
        this.IdleGameManager.Is64Bit := this.Main.isTarget64bit
        this.IdleGameManager.BaseAddress := this.BaseAddress
        this.IdleGameManager.IsBaseObject := true
        if(!this.Main.isTarget64bit)
        {
            ; Build offsets for class using imported AHK files.
            #include *i %A_LineFile%\..\Imports\IC_IdleGameManager32_Import.ahk
            ; special case for Dictionary<List<Action<action>>>
            this.game.gameInstances.Controller.formation.TransitionOverrides.ActionListSize := New GameObjectStructure(this.game.gameInstances.Controller.formation.TransitionOverrides,, [0x1C, 0xC]) ; entries, value[0] (CE doesn't build this on it's own), _size
        }
        else
        {
            #include *i %A_LineFile%\..\Imports\IC_IdleGameManager64_Import.ahk
            this.game.gameInstances.Controller.formation.TransitionOverrides.ActionListSize := New GameObjectStructure(this.game.gameInstances.Controller.formation.TransitionOverrides,, [0x30, 0x18]) ; entries, value[0] (CE doesn't build this on it's own), _size
        }
    }
}
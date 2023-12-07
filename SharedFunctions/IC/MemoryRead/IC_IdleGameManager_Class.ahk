; GameManager class contains the in game data structure layout

; GameManager class contains the offsets as found in mono-disected memory structures. Specifically, the offsets for the IdleGameManager structure.
; It was designed to make future updates easier by clarifying where each offset is found and (hopefully) reduce the difficulty of updating offsets for structures that remain largely the same.
; - Variable names are based on the layout within the structure not including GameManager itself. e.g. this.Game.GameUser will be IdleGameManager->Game->GameUser.
; - Each offset is built off of a previous offsets. e.g. this.Game.GameUser.ID will be this.game.GameUser + ID, or IdleGameManager->Game->GameUser->ID
; - GameObjectStructure is what is used to combine offsets.
; - Note: 03/2023 lookup behavior has changed. GetGameObjectFromListValues is no longer used.
; - Items defined by "List" will have an Item[x] offset that is dynamically selected in code via object[x].
; - There can be multiple missing list offsets as the game can traverse multiple lists to get to the value you want.
; - Dictionary lookups are done by index of its entry in memory. To find a specific key you must loop over the entries until you find the key that matches.
; - Dictionary entry values are looked up using the format of: dictObject[entryIndex] or dictObject["value", entryIndex]
; - Dictionary key values are looked up using the format of: dictObject["key", entryIndex]

class IC_IdleGameManager_Class extends SH_MemoryPointer
{

    GetVersion()
    {
        return "v2.1.0, 2023-03-19"
    }

    Refresh()
    {

        ;==================
        ;structure pointers
        ;==================
        this.BaseAddress := _MemoryManager.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.Is64Bit != _MemoryManager.is64Bit) ; Build structure one time. 
        {
            this.Is64Bit := _MemoryManager.is64bit
            ; Note: Using example Offsets 0xCB0,0 from CE, 0 is a mod (+) and disappears leaving just 0xCB0
            this.IdleGameManager := New GameObjectStructure(this.StructureOffsets)
            this.IdleGameManager.BasePtr := this
            this.IdleGameManager.Is64Bit := _MemoryManager.is64bit
            if(!_MemoryManager.is64bit)
            {
                ; Build offsets for class using imported AHK files.
                #include *i %A_LineFile%\..\Imports\IC_IdleGameManager32_Import.ahk
            }
            else
            {
                #include *i %A_LineFile%\..\Imports\IC_IdleGameManager64_Import.ahk
            }
            ; DEBUG: Enable this line to be able to view the variable name of the GameObject. (e.g. this.game would have a GSOName variable that says "game" )
            ; this.game.SetNames()
        }
    }
}
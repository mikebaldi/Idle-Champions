#include IC_ArrayFunctions.ahk
; GameManager class contains the in game data structure layout
;Script Date := "11/04/21"
;Script Ver := "v0.411.1"


class GameObjectStructure
{
    FullOffsets := Array()
    Offsets := Array()
    ValueType := "Int"
    Name := ""
    GetOffsets()
    {
        return this.FullOffsets
    }

     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*)
    {
        if(!appendedOffsets[1])
        {
            this.ValueType := ValueType
            this.FullOffsets.Push(baseStructureOrFullOffsets*)
            this.Offsets.Push(baseStructureOrFullOffsets*)
        }
        else
        {
            this.ValueType := ValueType
            this.FullOffsets.Push(ArrFnc.Concat(baseStructureOrFullOffsets.GetOffsets(), appendedOffsets[1])*)
            this.Offsets.Push(appendedOffsets[1]*)
            this.ParentStructure := baseStructureOrFullOffsets.Clone()
            this.BaseAddress := baseStructureOrFullOffsets.BaseAddress
        }
    }

    Clone()
    {
        var := new GameObjectStructure
        var.Offsets := this.Offsets.Clone()
        var.FullOffsets := this.FullOffsets.Clone()
        var.ParentStructure := this.ParentStructure.Clone()
        var.Name := this.Name
        var.BaseAddress := this.BaseAddress
        return var
    }
}
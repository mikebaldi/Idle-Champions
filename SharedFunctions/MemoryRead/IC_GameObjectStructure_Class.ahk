#include %A_LineFile%\..\..\IC_ArrayFunctions_Class.ahk
; GameManager class contains the in game data structure layout
; LastUpdated := "11/24/21"


; Class used to describe a memory location. 
; ListIndexes is an array that contains the locations of where to insert offsets when accessing specific items in lists.
; ValueType describes what kind of data is at the location in memory. 
;       Note: "List" is not a memory data type but is being used to identify when a ListIndex must be added.
; Name is not yet used.
; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; ParentStructure contains the stucture that this originated and expanded from. This allows for reverse traversal of mem locations if needed. (Currently unused)
; Is64Bit identifies if the object is using 32-bit (e.g. Steam) or 64-bit addresses (e.g. EGS)
class GameObjectStructure
{
    ListIndexes := Array()
    FullOffsets := Array()
    ValueType := "Int"
    Name := ""
    BaseAddress := 0x0
    ParentStructure := {}
    Is64Bit := 0
 
     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*)
    {
        
        this.ValueType := ValueType
        if(!appendedOffsets[1]) ; When using an array, create a base structure
        {
            this.FullOffsets.Push(baseStructureOrFullOffsets*)
        }
        else
        {
            this.FullOffsets.Push(ArrFnc.Concat(baseStructureOrFullOffsets.GetOffsets(), appendedOffsets[1])*)
            this.ParentStructure := baseStructureOrFullOffsets.Clone()
            this.BaseAddress := baseStructureOrFullOffsets.BaseAddress
            this.ListIndexes := baseStructureOrFullOffsets.ListIndexes.Clone()
            this.Is64Bit := baseStructureOrFullOffsets.Is64Bit
        }
        if(ValueType == "List")
        {
            this.ListIndexes.Push(this.FullOffsets.Count() + 1)
        }
    }

    ; Function used to make a deep copy of the current object.
    Clone()
    {
        var := new GameObjectStructure
        var.FullOffsets := this.FullOffsets.Clone()
        var.ParentStructure := this.ParentStructure.Clone()
        var.Name := this.Name
        var.BaseAddress := this.BaseAddress
        var.ListIndexes := this.ListIndexes.Clone()
        var.ValueType := this.ValueType
        var.Is64Bit := this.Is64Bit
        return var
    }

    ; Returns the full offsets of this object after BaseAddress.
    GetOffsets()
    {
        return this.FullOffsets
    }

    ; Takes an array of values. Each value in the array is an offset to multiply the offsets by in a list.
    ; There can be multiple values as there can be multiple lists in a location.
    GetOffsetsWithListValues(values*)
    {
        if(values.Count() > this.ListIndexes.Count() )
        {
            stringVal := "More parameters were passed than there are list objects"
            throw stringVal
        }
        currentOffsets := this.FullOffsets.Clone()
        i := 0
        for k,v in values
        {
            currentOffsets.InsertAt(this.ListIndexes[i+1] + i, this.CalculateOffset(v))
            i++
        }
        return currentOffsets
    }

    ; Uses list location values to create a new object that has the correst FullOffsets and ValueType of the item being looked up.
    GetGameObjectFromListValues(values*)
    {
        newObject := this.Clone()
        newObject.FullOffsets := this.GetOffsetsWithListValues(values*)
        ;var := ArrFnc.GetHexFormattedArrayString(newObject.FullOffsets)
        return newObject
    }

    ; Used to calculate offsets the offsets of an item in a list by its index value.
    ; Note: Some EGS lists will still use 4 byte offsets. In these cases, pass (index/2) to GetGameObjectFromListValues 
    CalculateOffset( listItem, indexStart := 0 )
    {
        if(indexStart) ; If list is not 0 based indexing
            listItem--             ; AHK uses 0 based array indexing, switch to 0 based
        if(this.Is64Bit)
            return 0x20 + ( listItem * 0x8 )
        else
            return 0x10 + ( listItem * 0x4 )
    }

    ; Uses dict location values to create a new object that has the correst FullOffsets and ValueType of the item being looked up.
    GetGameObjectFromDictValues(values*)
    {
        newObject := this.Clone()
        newObject.FullOffsets := this.GetOffsetsWithDictValues(values*)
        ;var := ArrFnc.GetHexFormattedArrayString(newObject.FullOffsets)
        return newObject
    }
    ; probably doesn't work with EGS/64bit
    ; Takes an array of values. Each value in the array is an offset to multiply the offsets by in a list or dict.
    ; values for list should be integers, values for dict should be an array with first item either "key" or "value" as appropriate and second item corresponding to the dict index
    ; For now, this method only works with dict with key entries are pointers
    ; There can be multiple values as there can be multiple lists or dicts in a location.
    GetOffsetsWithDictValues(values*)
    {
        if(values.Count() > this.ListIndexes.Count() )
        {
            stringVal := "More parameters were passed than there are list objects"
            throw stringVal
        }
        currentOffsets := this.FullOffsets.Clone()
        i := 0
        for k,v in values
        {
            if (!IsObject(v))
                currentOffsets.InsertAt(this.ListIndexes[i+1] + i, this.CalculateOffset(v))
            else
                currentOffsets.InsertAt(this.ListIndexes[i+1] + i, this.CalculateDictOffset(v))
            i++
        }
        return currentOffsets
    }

    ; EGS (64bit) is a complete guess, probably doesn't work.
    ; Used to calculate offsets of an item in a dict. requires an array with "key" or "value" as first entry and the dict index as second. indices start at 0.
    CalculateDictOffset(array)
    {
        if(this.Is64Bit)
        {
            baseOffset := 0x28
            offsetInterval := 0x18
            valueOffset := 0x8
        }
        else
        {
            baseOffset := 0x18
            offsetInterval := 0x10
            valueOffset := 0x4
        }
        offset := baseOffset + ( offsetInterval * array.2 )
        if (array.1 == "value")
            offset += valueOffset
        return offset
    }
}
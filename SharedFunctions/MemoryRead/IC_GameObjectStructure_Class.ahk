#include %A_LineFile%\..\..\IC_ArrayFunctions_Class.ahk
; GameManager class contains the in game data structure layout
; LastUpdated := "2022-02-01"


; Class used to describe a memory location. 
; ListIndexes is an array that contains the locations of where to insert offsets when accessing specific items in lists.
; ValueType describes what kind of data is at the location in memory. 
;       Note: "List" is not a memory data type but is being used to identify when a ListIndex must be added.
; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; Is64Bit identifies if the object is using 32-bit (e.g. Steam) or 64-bit addresses (e.g. EGS)
class GameObjectStructure
{
    ListIndexes := Array()
    DictIndexes := Array()
    FullOffsets := Array()
    FullOffsetsHexString := ""
    ValueType := "Int"
    BaseAddress := 0x0
    Is64Bit := 0
    Offset := 0x0

    __Get(index)
    {
        if index is integer
        {
            
        }
        else
        {
            OutputDebug, %index%
        }
    }

    ; returns a a GameObjectStructure which can point to the size of a memory structure such as a dictionary or list
    size[]
    {
        get
        {
            if(this.ValueType == "List")
            {
                sizeObject := this.Clone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Pop()
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x18 : 0xC)
                return sizeObject
            }
            else if(this.ValueType == "Dict")
            {
                sizeObject := this.Clone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Pop()
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x40 : 0x20)
                return sizeObject
            }
            else if(this.ValueType == "HashSet")
            {
                sizeObject := this.Clone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Pop()
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x4C : 0x18) ; get 64 Bit variation
                return sizeObject
            }
            else
            {
                return ""
            }
        }
    }
 
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
            this.BaseAddress := baseStructureOrFullOffsets.BaseAddress
            this.ListIndexes := baseStructureOrFullOffsets.ListIndexes.Clone()
            this.Is64Bit := baseStructureOrFullOffsets.Is64Bit
            this.Offset := appendedOffsets[1]
        }
        if(ValueType == "List" or ValueType == "HashSet")
        {
            ;items/_entries
            this.FullOffsets.Push(this.Is64Bit ? 0x10 : 0x8)
            this.ListIndexes.Push(this.FullOffsets.Count())
        }
        if(ValueType == "Dict")
        {
            this.FullOffsets.Push(this.Is64Bit ? 0x18 : 0xC)
            this.DictIndexes.Push(this.FullOffsets.Count())
        }
        this.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
    }

    ; Function used to make a deep copy of the current object.
    Clone()
    {
        var := new GameObjectStructure
        var.FullOffsets := this.FullOffsets.Clone()
        var.BaseAddress := this.BaseAddress
        var.ListIndexes := this.ListIndexes.Clone()
        var.ValueType := this.ValueType
        var.Is64Bit := this.Is64Bit
        var.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
        var.Offset := this.Offset
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
            ; insert which item
            currentOffsets.InsertAt(this.ListIndexes[i+1] + i+1, this.CalculateOffset(v))
            i++
        }
        return currentOffsets
    }

    ; Uses list location values to create a new object that has the correst FullOffsets and ValueType of the item being looked up.
    GetGameObjectFromListValues(values*)
    {
        newObject := this.Clone()
        newObject.FullOffsets := this.GetOffsetsWithListValues(values*)
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
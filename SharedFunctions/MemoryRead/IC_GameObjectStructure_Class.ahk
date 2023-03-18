#include %A_LineFile%\..\..\IC_ArrayFunctions_Class.ahk
; GameManager class contains the in game data structure layout
; LastUpdated := "2022-02-01"


; Class used to describe a memory location. 
; ListIndexes is an array that contains the locations of where to insert offsets when accessing specific items in lists.
; ValueType describes what kind of data is at the location in memory. 
;       Note: "List", "Dict", and "HashSet" are not a memory data type but are being used to identify conditions such as when a ListIndex must be added.
; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; Is64Bit identifies if the object is using 32-bit (e.g. Steam) or 64-bit addresses (e.g. EGS)

class GameObjectStructure
{
    FullOffsets := Array()
    FullOffsetsHexString := ""
    ValueType := "Int"
    BaseAddress := 0x0
    Is64Bit := 0
    Offset := 0x0
    IsBaseObject := false

    ; BEWARE of cases where you may be looking in a dictionary for a key that is the same as a value of the object in the dictionary (e.g. dictionary["Effect"].Effect)
    ; When a key is not found for objects which have collections, use this function. 
    __Get(key)
    {
        if(this.HasKey(key))
        {
            if(IsObject(this[key])) ; This will never get triggered because __Get does not get called if the key already exists (not as a property/function)
            {
                this[key].FullOffsets := this.FullOffsets.Clone()
                this[key].FullOffsets.Push(this[key].Offset*)
            }
            ;return ; Not returning a value allows AHK to use standard behavior for gets.
            return this[key] 
        }
        ; Properties are not found using HasKey(). size is a property so ignore it.
        if(key == "size")
        {
            if(this.ValueType == "List")
            {
                sizeObject := this.QuickClone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x18 : 0xC)
                return sizeObject
            }
            else if(this.ValueType == "Dict")
            {
                sizeObject := this.QuickClone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x40 : 0x20)
                return sizeObject
            }
            else if(this.ValueType == "HashSet")
            {
                sizeObject := this.QuickClone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x4C : 0x18) ; get 64 Bit variation
                return sizeObject
            }
            else
            {
                return ""
            }
        }
        else
        {
            ; Special case for collections in a gameobject.
            ; Calculate the offset using the value.
            if(this.ValueType == "List")
            {
                offset := this.CalculateOffset(key)
                collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
            }
            else if(this.ValueType == "HashSet")
            {
                ; TODO: Verify hashset has same offsets as lists
                offset := this.CalculateOffset(key)
                collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
            }
            else if(this.ValueType == "Dict")
            {
                offset := this.CalculateDictOffset(["value",v]) + 0
                collectionEntriesOffset := this.Is64Bit ? 0x18 : 0xC
            }
            else
            {
                return
            }
            this[key] := this.Clone()
            this[key].Offset := offset
            this[key].FullOffsets.Push(collectionEntriesOffset, offset)
        }
    }
 
    ; Creates a new instance of GameObjectStructure
     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*)
    {
        this.ValueType := ValueType
        if(appendedOffsets[1]) ; Copy base and add offset
        {
            this.BaseAddress := baseStructureOrFullOffsets.BaseAddress
            this.Is64Bit := baseStructureOrFullOffsets.Is64Bit
            this.Offset := appendedOffsets[1]
        }
        ; this.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
    }

    ; Function makes copy of the current object and its lists but not a full deep copy.
    QuickClone()
    {
        var := new GameObjectStructure
        var.FullOffsets := this.FullOffsets.Clone()
        var.BaseAddress := this.BaseAddress
        var.ValueType := this.ValueType
        var.Is64Bit := this.Is64Bit
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        ; var.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
        var.Offset := this.Offset
        return var
    }

    ; Function makes a deep copy of the current object.
    Clone()
    {
        var := new GameObjectStructure
        ; Iterate all the elements of the game object structure and clone time
        for k,v in this
        {
            if(IsObject(v))
                var[k] := v.Clone()
            else
                var[k] := v
        }
        return var
    }

    ; Returns the full offsets of this object after BaseAddress.
    GetOffsets()
    {
        return this.FullOffsets
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

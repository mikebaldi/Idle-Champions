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
        ; Special case for collections in a gameobject.
        else if(this.ValueType == "List")
        {
            if key is integer
            {
                offset := this.CalculateOffset(key)
                collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
                this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
            }
            else
            {
                return
            }
        }
        else if(this.ValueType == "HashSet")
        {
            ; TODO: Verify hashset has same offsets as lists
            offset := this.CalculateOffset(key)
            collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
            this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
        }
        else if(this.ValueType == "Dict")
        {
            offset := this.CalculateDictOffset(["value",key]) + 0
            collectionEntriesOffset := this.Is64Bit ? 0x18 : 0xC
            this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
        }
        else
        {
            return
        }
        return this[key]
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
            this.FullOffsets := baseStructureOrFullOffsets.FullOffsets.Clone()
            this.FullOffsets.Push(this.Offset*)
        }
        else
        {
            this.FullOffsets.Push(baseStructureOrFullOffsets*)
        }
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        this.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
    }

    ; Returns the full offsets of this object after BaseAddress.
    GetOffsets()
    {
        return this.FullOffsets
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

    ; Creates a gameobject at key, updates its offsets, and updates all children's offsets. 
    UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
    {
        this[key] := this.Clone()
        location := this.FullOffsets.Count() + 1
        this[key].FullOffsets.Push(collectionEntriesOffset, offset)
        this.UpdateChildrenWithFullOffsets(this[key], location, [collectionEntriesOffset, offset])
    }

    ; Starting at key, updates the fulloffsets variable in key and all children of key recursively.
    UpdateChildrenWithFullOffsets(key, insertLoc := 0, offset := "")
    {
        for k,v in key
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure" and v.FullOffsets != "")
            {
                v.FullOffsets.InsertAt(insertLoc, offset*)
                v.UpdateChildrenWithFullOffsets(v, insertLoc, offset)
                ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
                v.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(v.FullOffsets)
            }
        }
    }

    ; Used to calculate offsets the offsets of an item in a list by its index value.
    ; Note: Some EGS lists will still use 4 byte offsets. In these cases, pass (index/2) as the index of the list. 
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
        ; Special Case not included here:
        ; 64-Bit Entries start at 0x18
        ; Values follow rule: [0x20 + 0x10 + (index * 0x18)
        ; 0x20 = baseOffset ? 
        ; 0x10 = valueOffset ? 
        ; index = array.2
        ; 0x18 = offsetInterval

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
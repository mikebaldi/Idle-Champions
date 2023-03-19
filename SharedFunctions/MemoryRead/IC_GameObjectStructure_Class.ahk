#include %A_LineFile%\..\..\IC_ArrayFunctions_Class.ahk
; Class used to describe a memory locations. 
; LastUpdated := "2023-03-19"
; ValueType describes what kind of data is at the location in memory. 
;       Note: "List", "Dict", and "HashSet" are not a memory data type but are being used to identify conditions such as when a ListIndex must be added.
; BaseAddress is the original pointer location all offsets are based off of. Typically something like: getModuleBaseAddress("mono-2.0-bdwgc.dll")+0x00491A90
; Is64Bit identifies if the object is using 32-bit (e.g. Steam) or 64-bit addresses (e.g. EGS)

class GameObjectStructure
{
    FullOffsets := Array()          ; Full list of offsets required to get from base pointer to this object
    FullOffsetsHexString := ""      ; Same as above but in readable hex string format. (Enable commented lines assigning this value to use for debugging)
    ValueType := "Int"              ; What type of value should be expected for the memory read.
    BaseAddress := 0x0              ; The address the base pointer points to. Must read memory from target exe first to set this.
    Is64Bit := 0                    ; Boolean indicating the system is 64 bit and not 32.
    Offset := 0x0                   ; The offset from last object to this object.
    IsAddedIndex := false           ; __Get lookups on non-existent keys will create key objects with this value being true. Prevents cloning non-existent values.

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
        ; this.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
    }

    ; BEWARE of cases where you may be looking in a dictionary for a key that is the same as a value of the object in the dictionary (e.g. dictionary["Effect"].Effect)
    ; When a key is not found for objects which have collections, use this function. 
    __Get(key, index := 0)
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
            if key is number
            {
                offset := this.CalculateOffset(key)
                collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
                this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
            }
            else if (key == "_items")
            {
                collectionEntriesOffset := this.Is64Bit ? 0x10 : 0x8
                _items := this.StableClone()
                _items.FullOffsets.Push(collectionEntriesOffset)
                _items.ValueType := this.Is64Bit ? "Int64" : "UInt"
                return _items
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
            if (key == "key")
            {
                offset := this.CalculateDictOffset(["key",index]) + 0
                collectionEntriesOffset := this.Is64Bit ? 0x18 : 0xC
                tempObj := this.Clone()
                tempObj.FullOffsets.Push(collectionEntriesOffset, offset)
                tempObj.UpdateChildrenWithFullOffsets(tempObj, tempObj.FullOffsets.Count() + 1, [collectionEntriesOffset, offset])
                return tempObj
            }
            else if (key == "value")
            {
                offset := this.CalculateDictOffset(["value",index]) + 0
                collectionEntriesOffset := this.Is64Bit ? 0x18 : 0xC
                this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
            }
            else
            {
                offset := this.CalculateDictOffset(["value",key]) + 0
                collectionEntriesOffset := this.Is64Bit ? 0x18 : 0xC
                this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
            }
        }
        else
        {
            return
        }
        return this[key]
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

    ; For cloning without copying dynamically added items to the clone.
    StableClone()
    {
        var := new GameObjectStructure
        ; Iterate all the elements of the game object structure and clone time
        for k,v in this
        {
            if(!IsObject(v))
            {
                var[k] := v
                continue
            }
            if(ObjGetBase(v).__Class == "GameObjectStructure" AND !v.IsAddedIndex)
            {   
                var[k] := v.StableClone()
            }
            else if(ObjGetBase(v).__Class != "GameObjectStructure")
            {
                var[k] := v.Clone()
            }
        }
        return var
    }

    ; Creates a gameobject at key, updates its offsets, copies the other values in the object to key object, propegates changes down chain of objects under key. 
    UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
    {
        this[key] := this.StableClone()
        this[key].IsAddedIndex := true
        location := this.FullOffsets.Count() + 1
        this[key].FullOffsets.Push(collectionEntriesOffset, offset)
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        ; this[key].FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this[key].FullOffsets)
        this.UpdateChildrenWithFullOffsets(this[key], location, [collectionEntriesOffset, offset])
    }

    ; Starting at currentObj, updates the fulloffsets variable in key and all children of key recursively.
    UpdateChildrenWithFullOffsets(currentObj, insertLoc := 0, offset := "")
    {
        for k,v in currentObj
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure" and v.FullOffsets != "")
            {
                v.FullOffsets.InsertAt(insertLoc, offset*)
                v.UpdateChildrenWithFullOffsets(v, insertLoc, offset)
                ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
                ; v.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(v.FullOffsets)
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
        ; Second Special case:
        ; 0x20 + (A_index - 1) * 0x10 | 0x10 + (A_Index - 1) * 0x10

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
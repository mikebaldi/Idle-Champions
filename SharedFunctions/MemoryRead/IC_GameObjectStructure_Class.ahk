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
    ListIndexes := Array()
    DictIndexes := Array()
    FullOffsets := Array()
    FullOffsetsHexString := ""
    ValueType := "Int"
    BaseAddress := 0x0
    Is64Bit := 0
    Offset := 0x0

    ; DEBUG: Helps debug missing objects in dot chains of GameObjectStructures.
    ; __Get(index)
    ; {
    ;     if index is not integer
    ;         OutputDebug, %index%
    ; }

    ; returns a a GameObjectStructure which can point to the size of a memory structure such as a Dictionary, List, or HashSet
    size[]
    {
        get
        {
            if(this.ValueType == "List")
            {
                sizeObject := this.QuickClone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Pop()
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x18 : 0xC)
                return sizeObject
            }
            else if(this.ValueType == "Dict")
            {
                sizeObject := this.QuickClone()
                sizeObject.ValueType := "Int"
                sizeObject.FullOffsets.Pop()
                sizeObject.FullOffsets.Push(this.Is64Bit ? 0x40 : 0x20)
                return sizeObject
            }
            else if(this.ValueType == "HashSet")
            {
                sizeObject := this.QuickClone()
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
 
    ; Creates a new instance of GameObjectStructure
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
            this.DictIndexes := baseStructureOrFullOffsets.DictIndexes.Clone()
            this.Is64Bit := baseStructureOrFullOffsets.Is64Bit
            this.Offset := appendedOffsets[1]
        }
        if(ValueType == "List" or ValueType == "HashSet")
        {
            ;add items
            this.FullOffsets.Push(this.Is64Bit ? 0x10 : 0x8)
            this.ListIndexes.Push(this.FullOffsets.Count())
        }
        if(ValueType == "Dict")
        {
            ;add _entries
            this.FullOffsets.Push(this.Is64Bit ? 0x18 : 0xC)
            this.DictIndexes.Push(this.FullOffsets.Count())
        }
        ; this.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
    }

    ; Function makes copy of the current object and its lists but not a full deep copy.
    QuickClone()
    {
        var := new GameObjectStructure
        var.FullOffsets := this.FullOffsets.Clone()
        var.BaseAddress := this.BaseAddress
        var.ListIndexes := this.ListIndexes.Clone()
        var.DictIndexes := this.DictIndexes.Clone()
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

    ; Takes an array of values. Each value in the array is an offset to multiply the offsets by in a list.
    ; There can be multiple values as there can be multiple lists in a memory location.
    ; Note: iterates from first items in list and checks in order. There is no picking and choosing which list items to grab.
    GetOffsetsWithListOrDictValues(insertType := "List", values*)
    {
        if( (values.Count() > this.ListIndexes.Count() AND insertType == "List") OR (values.Count() > this.DictIndexes.Count() AND insertType == "Dict") )
        {
            stringVal := "More parameters were passed than there are list objects"
            throw stringVal
        }
        currentOffsets := this.FullOffsets.Clone()
        i := 0
        for k,v in values
        {
            ; insert which item
            if (insertType == "List")
                currentOffsets.InsertAt(this.ListIndexes[i+1] + i+1, this.CalculateOffset(v))
            else if (insertType == "Dict")
                currentOffsets.InsertAt(this.DictIndexes[i+1] + i+1, (this.CalculateDictOffset(["value",v]) + 0))
                ;currentOffsets[this.DictIndexes[i+1] + i] += (this.CalculateDictOffset(["value",v]) + 0)
            i++
        }
        return currentOffsets
    }

    ; Uses list location values to create a new object that has the correst FullOffsets and ValueType of the item being looked up.
    GetGameObjectFromListValues(values*)
    {
        newObject := this.QuickClone()
        newObject.FullOffsets := newObject.GetOffsetsWithListOrDictValues("List", values*)
        return newObject
    }

    ; Note: Must update IndexType (e.g. list) after other collection (e.g. dict) becaust the Update<Collection> functions remove objects that the other (dict) needs for comparisons.
    ; Uses list location values to create a new object that has the correst FullOffsets and ValueType of the item being looked up.
    GetFullGameObjectFromListOrDictValues(indexType := "List", values*)
    {
        recursive = true
        valueCount := values.Count()
        newObject := this.Clone()
        ; Recursively update offsets
        if(recursive)
            newObject.UpdateOffsetsFromListOrDict(indexType, values*)
        else
            newObject.FullOffsets := newObject.GetOffsetsWithListOrDictValues(indexType, values*)
        newObject.UpdateCollections(indexType, valueCount, recursive)
        return newObject
    }

    ; Helper function for GetFullGameObjectFromListOrDictValues
    ; Updates the DictIndexs
    ; DeepUpdate updates DictIndexes in all sub objects as well
    UpdateCollections(collectionType, valueCount, deepUpdate := false)
    {
        ; Assumes only 2 types, Dict and List
        otherType := collectionType == "Dict" ? "List" : "Dict"
        collectionCount := collectionType == "Dict" ? this.ListIndexes.Count() : this.DictIndexes.Count()
        ; other collection first 
        loop, %collectionCount%
        {
            increaseAmount := 0
            currIndex := A_Index
            ; Note: can reduce time complexity by doing a binary search on value count.
            ; But it is unlikely to matter since list indexes are not likely to be > 3
            loop, %valueCount%
            {
                if(collectionType == "Dict")
                {
                    if(this.ListIndexes[currIndex] > this.DictIndexes[A_Index])
                        increaseAmount += 1
                    else
                        break
                }
                else if (collectionType == "List")
                {
                    if(this.DictIndexes[currIndex] > this.ListIndexes[A_Index])
                        increaseAmount += 1
                    else
                        break
                }
            }
            if(collectionType == "Dict")
                this.ListIndexes[currIndex] += increaseAmount 
            else if (collectionType == "List")
                this.DictIndexes[currIndex] += increaseAmount
        }
        if(collectionType == "Dict")
            this.DictIndexes.RemoveAt(1, valueCount)
        else if (collectionType == "List")
            this.ListIndexes.RemoveAt(1, valueCount)

        ; Update remainning values with added increased indexes
        collectionCount := collectionType == "Dict" ? this.DictIndexes.Count() : this.ListIndexes.Count()
        loop, %collectionCount%
        {
            if(collectionType == "Dict")
                this.DictIndexes[A_Index] += valueCount
            else if (collectionType == "List")
                this.ListIndexes[A_Index] += valueCount
        }   
        if(deepUpdate)
        {
            for k,v in this
            {
                ; Note: Automatically ignores call if 'this' is not a GameObject
                ; All GameObjects have a DictIndexes field
                if (IsObject(this[k]))
                    this[k].UpdateCollections(collectionType, valueCount, deepUpdate)
            }
        }
    }

    ; Helper function for GetFullGameObjectFromListOrDictValues
    ; Updates the FullOffsets recursively
    UpdateOffsetsFromListOrDict(indexType := "List", values*)
    {
        this.FullOffsets := this.GetOffsetsWithListOrDictValues(indexType, values*)
        for k,v in this
        {
            if(IsObject(this[k]) AND this[k]["FullOffsets"] != "")
            {
                this[k].UpdateOffsetsFromListOrDict(indexType, values*)
            }
        }
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
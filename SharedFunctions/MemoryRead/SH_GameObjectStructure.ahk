#include %A_LineFile%\..\..\SH_ArrFnc.ahk
#include %A_LineFile%\..\SH__MemoryManager.ahk
; Class used to describe a memory locations. 
; LastUpdated := "2023-03-19"
; ValueType describes what kind of data is at the location in memory. 
;       Note: "List", "Dict", "Stack", "Queue" and "HashSet" are not a memory data type but are being used to identify conditions such as when a ListIndex must be added.
class GameObjectStructure
{
    ; Reserved words for GameObjectStructure. Imports with same  name will cause unpredictable behavior.
    FullOffsets := Array()          ; Full list of offsets required to get from base pointer to this object
    FullOffsetsHexString := ""      ; Same as above but in readable hex string format. (Enable commented lines assigning this value to use for debugging)
    ValueType := "Int"              ; What type of value should be expected for the memory read.
    Offset := 0x0                   ; The offset from last object to this object.
    IsAddedIndex := false           ; __Get lookups on non-existent keys will create key objects with this value being true. Prevents cloning non-existent values.
    _CollectionKeyType := ""
    _CollectionValType := ""
    BasePtr := {}
    LastDictVersion := ""
    StartAtLastPos := False
    LastDictIndex := {}
    DictionaryObject := {}
    static LastDictPos = 0

    static ReadIsLocked := False
    static InvalidDictionaryKeyString := "<invalid key>"
    static SystemTypes := { "System.Byte" : "Char"
        ,"System.UByte" : "UChar"
        ,"System.Short" : "Short"
        ,"System.UShort" : "UShort"
        ,"System.Int32" : "Int"
        ,"System.UInt32" : "UInt"
        ,"System.Int64" : "Int64"
        ,"System.Enum" : "Int"
        ,"System.UInt64" : "Int64"
        ,"System.Single" : "Float"
        ,"System.USingle" : "UFloat"
        ,"System.Double" : "Double"
        ,"System.Boolean" : "Char" 
        ,"System.String" : "UTF-16"
        ,"Engine.Numeric.Quad" : "Quad" }
    static ValueTypeToBytes := { "Char": 0x4, "UChar": 0x4, "Short": 0x4
                                , "UShort": 0x4, "Int": 0x4, "UInt": 0x4
                                , "Int64": 0x8, "UInt64": 0x8, "Float": 0x4
                                , "UFloat": 0x4, "Double": 0x8, "Char": 0x4, "UTF-16" : 0x8, "Quad": 0x10 }
    ; Creates a new instance of GameObjectStructure
     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*)
    {
        this.ValueType := ValueType
        if(appendedOffsets[1]) ; Copy base and add offset
        {
            this.BasePtr := baseStructureOrFullOffsets.BasePtr
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
    __Get(key, index := 0, startAtLastPos := False, byteSizeOverride := 0x0)
    {
        static debugRecursionDepth := 0
        static notificationSet := False
        this.StartAtLastPos := startAtLastPos ;always default to false unless set otherwise 
        debugRecursionDepth++
        if (debugRecursionDepth > 6 and !notificationSet) ; Should be < 3
        {
            MsgBox, % "Infinite recursion detected on a gameObject using key = " . key . ". Crash likely incoming."
            notificationSet := True
        }
        ; Properties are not found using HasKey().
        ; size attempts to find choose the offset for the size of the collection and return a GameObjectStructure that has that offset included.
        if(key == "")
            return debugRecursionDepth := 0 ? "" : "" ; reset recursion depth and ReadIsLocked
        if(key == "_ArrayDimensions") ; Prevent infinite recursion.
            return debugRecursionDepth := 0 ? "" : "" ; reset recursion depth and ReadIsLocked
        if(key == "size")
        {
            debugRecursionDepth := 0
            return this.CreateSizeObject()
        }
        if (key == "__version") 
        {
            debugRecursionDepth := 0
            return this.CreateVersionObject()
        }
        ; Special case for Dictionary collections in a gameobject. Store dictionary items with keys that have a system type to speed up future lookups. Do not store unstable keys.
        if(this.ValueType == "Dict")
        {
            debugRecursionDepth := 0
            return this.GetDictionaryObject(key, index)
        }
        ; Special case for List/Stack/Queue collections in a gameobject.
        if(this.ValueType == "List" OR this.ValueType == "Stack" OR this.ValueType == "Queue")
        {
            resultObject := this.HandleListStackQueue(key)
            if (resultObject != "")
            {
                debugRecursionDepth := 0
                return resultObject
            }
        }
        if(this.ValueType == "HashSet")
        {
            if key is not integer ; Don't try to create key objects when keys are invalid
                return debugRecursionDepth := 0 ? "" : "" ; reset recursion depth and ReadIsLocked
            offset := this.CalculateHashSetOffset(key) + 0
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x18 : 0xC
            this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
        }
        else if key is number
            this.UpdateCollectionOffsets(key, "", (this.CalculateArrayOffset(key,, byteSizeOverride) + 0))
        else
            return debugRecursionDepth := 0 ? "" : "" ;reset recursion depth
        debugRecursionDepth := 0
        GameObjectStructure.ReadIsLocked := False
        return this[key]
    }

    GetVersion()
    {
        Return "v3.4.1, 2025-08-11"
    }

    ; Returns the full offsets of this object after BaseAddress.
    GetOffsets()
    {
        return this.FullOffsets
    }

    ; Function makes copy of the current object and its lists but not a full deep copy.
    QuickClone()
    {
        var := new GameObjectStructure(this.FullOffsets)
        var.BasePtr := this.BasePtr
        var.ValueType := this.ValueType
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        ; var.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
        var.Offset := this.Offset
        var._CollectionKeyType := this._CollectionKeyType
        var._CollectionValType := this._CollectionValType
        if (this._ArrayDimensions)
            var._ArrayDimensions := this._ArrayDimensions
        return var
    }

    CreateSizeObject()
    {
        ; TODO: Find 32-bit location for size in stacks and queues
        ; TODO: Is "count" in a hashset at offset 0x18 in 32-bit?
        ; TODO: Check HashSet<T> variations that appear to have ox20, 0x30 for "count"
        sizeObject := this.QuickClone()
        sizeObject.ValueType := "Int"
        if(this.ValueType == "Stack")
            sizeObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x20 : 0x0)
        else if(this.ValueType == "Queue")
            sizeObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x28 : 0x0)
        else if(this.ValueType == "Dict")
            sizeObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x40 : 0x20)
        else if(this.ValueType == "HashSet")
            sizeObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x30 : 0x18)
        else 
        { ; Assume Array / this.ValueType == "List"
            sizeObject.ValueType := this.ValueType
            sizeObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x18 : 0xC)
        }
        return sizeObject
    }

    CreateVersionObject()
    {
        ; TODO: Find 32-bit locations
        versionObject := this.QuickClone()
        versionObject.ValueType := "Int"
        if(this.ValueType == "Stack")
            versionObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x2C : 0x0)
        else if(this.ValueType == "List")
            versionObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x1C : 0x0)
        else if(this.ValueType == "Queue")
            versionObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x28 : 0x0)
        else if(this.ValueType == "Dict")
            versionObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x4C : 0x0)
        else if(this.ValueType == "HashSet")
            versionObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x104 : 0x0)
        else ; Unsupported ValueType
            return ""
        return versionObject
    }

    HandleListStackQueue(key)
    {
        GameObjectStructure.ReadIsLocked := True                                            ; Lock before creating list/stack/queue collections
        if key is number
        {
            offset := this.CalculateOffset(key) + 0
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x10 : 0x8
            this.UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
            GameObjectStructure.ReadIsLocked := False                                       ; Reset read lock before returning   
            return this[key]
        }
        else if (key == "_items")
        {
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x10 : 0x8
            _items := this.StableClone()
            _items.FullOffsets.Push(collectionEntriesOffset)
            _items.ValueType := _MemoryManager.Is64Bit ? "Int64" : "UInt"
            GameObjectStructure.ReadIsLocked := False                                       ; Reset read lock before returning   
            return _items
        }
        GameObjectStructure.ReadIsLocked := False                                           ; Reset read lock before returning   
        return ""
    }

    GetDictionaryObject(key, index)
    {
        GameObjectStructure.ReadIsLocked := True                                    ; Lock gameobject reads while a dictionary is being built
        if(IsObject(key) AND key.Count() == 2)
        {
            index := key[2]
            key := key[1]
        }
        isUnstable := GameObjectStructure.SystemTypes[this._CollectionKeyType] == ""        ; Check if Key value is not a known type - Unstable is a dictionary of pointers that can change k,v pairs often.
        if(isUnstable AND this.DoesCollectionNeedReset())
            this.ResetCollection()
        if (key == "key")
        {
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x18 : 0xC                  ; Offset for the entries (key/value location) of the collection
            offset := this.CalculateDictOffset(["key",index]) + 0                           ; Expected offset to the key for the <index>th entry.
            tempObj := this.Clone()                                                         ; Deep copy of this object.
            tempObj.ValueType := GameObjectStructure.SystemTypes[this._CollectionKeyType]   ; Update value type if it is known
            if (tempObj.ValueType == "")
                tempObj.ValueType := _MemoryManager.Is64Bit ? "Int64" : "Int"               ; If there is no lookup value type then assume type is a pointer
            offsetInsertLoc := tempObj.FullOffsets.Count() + 1,                             ; Current offsets count
            tempObj.FullOffsets.Push(collectionEntriesOffset, offset)                       ; Add the offsets to this object so the .Read() will give the value of the key
            this.UpdateChildrenWithFullOffsets(tempObj, offsetInsertLoc, [collectionEntriesOffset, offset])  ; Update all sub-objects with their missing collection/item offsets.
            GameObjectStructure.ReadIsLocked := False                                       ; Reset read lock before returning
            return tempObj                                                                  ; return temporary key object
        }
        else if (key == "value")
        {
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x18 : 0xC                  ; Offset for the entries (key/value location) of the collection.
            offset := this.CalculateDictOffset(["value",index]) + 0                         ; Expected offset to the key for the <index>th entry.
            keyOffset := this.CalculateDictOffset(["key",index]) + 0                        ; Expected offset to the value for the <index>th entry.
            keyReadObject := this.QuickClone()                                                  ; temp object for lookup
            keyReadObject.FullOffsets.Push(collectionEntriesOffset, keyOffset)                  ; add offsets for key
            keyReadObject.ValueType := GameObjectStructure.SystemTypes[this._CollectionKeyType] ; Update key's value type if it is known
            GameObjectStructure.ReadIsLocked := False                                           ; Disable lock before read
            if (keyReadObject.ValueType == "")
                key := keyReadObject.Read(_MemoryManager.Is64Bit ? "Int64" : "Int")         ; If there is no lookup value type then assume type is a pointer
            else
                key := keyReadObject.Read()                                                 ; Retrieve the value of the key
            if(index == this.LastDictIndex[key])                                            ; Use previously created object if it is still being used.
                return this.DictionaryObject[key]                                           ; Key value is not a known type which means the key is likely a pointer and subject to unpredictable changes. (Do not cache these dictionary lookups)
            GameObjectStructure.ReadIsLocked := True                                        ; Enable Lock before building entry
            this.BuildDictionaryEntry(key, index, collectionEntriesOffset, offset) ; Build a dictionary entry for this key.
            GameObjectStructure.ReadIsLocked := False                                       ; Reset read lock before returning            
            return this.DictionaryObject[key]                                               ; return the temporary value object with access to all objects it has access to.
        }
        else
        {
            ; TODO: Look into feasibility of using same dictionary hash function to look up keys. (Requires DLL call?)
            keyIndex := this.GetDictIndexOfKeyQuick(key)                                    ; Look up what index has the key entry equal to the key passed in.
            if(keyIndex < 0)                                                                ; Failed to find index, do not create an entry.
                return ((GameObjectStructure.ReadIsLocked := False) ? "" : "")              ; Reset read lock before returning   
            if(keyIndex == this.LastDictIndex[key])                                         ; Use previously created object if it is still being used.
            {
                GameObjectStructure.ReadIsLocked := False                                   ; Reset read lock before returning   
                return this.DictionaryObject[key]
            }
            collectionEntriesOffset := _MemoryManager.Is64Bit ? 0x18 : 0xC                  ; Offset for the entries (key/value location) of the collection.
            offset := this.CalculateDictOffset(["value",keyIndex]) + 0                      ; Expected offset to the value corresponding to the key.
            this.BuildDictionaryEntry(key, keyIndex, collectionEntriesOffset, offset)       ; Build a dictionary entry for this key.
            GameObjectStructure.ReadIsLocked := False                                       ; Reset read lock before returning   
            return this.DictionaryObject[key]                                               ; return the temporary value object with access to all objects it has access to.
        }
        GameObjectStructure.ReadIsLocked := False                                           ; Reset read lock before returning if needed
    }

    ; Function makes a deep copy of the current object.
    Clone(typeOfObject := "")
    {
        var := new GameObjectStructure(this.FullOffsets)
        ; Iterate all the elements of the game object structure and clone time
        for k,v in this
        {
            if(isObject(v) AND k =="DictionaryObject") ; Ignore self referential dictionary.
                continue
            else if(IsObject(v) AND k != "BasePtr") ; Keep BasePtr as a reference
                var[k] := v.Clone()
            else
                var[k] := v
        }
        return var
    }

    ; For cloning without copying dynamically added items to the clone. Ignores objects with IsAddedIndex = true
    StableClone(key := "")
    {
        var := new GameObjectStructure(this.FullOffsets)
        ; Iterate all the elements of the game object structure and clone time
        for k,v in this
        {
            if(isObject(v) AND k =="DictionaryObject") ; Do not copy self referential dictionary objects
                continue
            if(!IsObject(v) OR k == "BasePtr") ; Keep BasePtr as a reference
            {
                var[k] := v
                continue
            }
            if(ObjGetBase(v).__Class == "GameObjectStructure" AND !v.IsAddedIndex)
                var[k] := v.StableClone()
            else if(ObjGetBase(v).__Class != "GameObjectStructure")
                var[k] := v.Clone()
        }
        return var
    }

    ; Build a dictonary entry for the key.
    BuildDictionaryEntry(key, keyindex, collectionEntriesOffset, offset)
    {
        this.DictionaryObject.Delete(key)                                              ; Delete key object before building new ones.
        this.DictionaryObject[key] := this.Clone()                                     ; Deep copy of this object.
        this.LastDictIndex[key] := keyIndex                                        ; Creating new index for key; remember this index.
        this.DictionaryObject[key].IsAddedIndex := true                                ; Stable clones won't copy this object
        offsetInsertLoc := this.DictionaryObject[key].FullOffsets.Count() + 1,         ; Current offsets count.
        this.DictionaryObject[key].FullOffsets.Push(collectionEntriesOffset, offset)   ; Add the offsets to this object so the .Read() will give the value of the value.
        this.DictionaryObject[key].ValueType := GameObjectStructure.SystemTypes[this._CollectionValType] ? GameObjectStructure.SystemTypes[this._CollectionValType] : this.DictionaryObject[key].ValueType
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
        ; this.DictionaryObject[key].FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this.DictionaryObject[key].FullOffsets)
        ; this.DictionaryObject[key].GSOName := key                                     
        this.UpdateChildrenWithFullOffsets(this.DictionaryObject[key], offsetInsertLoc, [collectionEntriesOffset, offset]) ; Update all sub-objects with their missing collection/item offsets.
    }

    ; Creates a gameobject at key, updates its offsets, copies the other values in the object to key object, propagates changes down chain of objects under key. 
    UpdateCollectionOffsets(key, collectionEntriesOffset, offset)
    {
        this[key] := this.StableClone()
        this[key].IsAddedIndex := true
        if (this._ArrayDimensions)
            this[key]._ArrayDimensions := this._ArrayDimensions - 1
        location := this.FullOffsets.Count() == 0 ? this.FullOffsets.Count() : this.FullOffsets.Count() + 1
        if(collectionEntriesOffset == "") ; Array type, has no items 
        {
            this[key].FullOffsets.Push( offset)
            ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
            ; this[key].FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this[key].FullOffsets)
            ; this[key].GSOName := key
            this.UpdateChildrenWithFullOffsets(this[key], location, [offset])
        }
        else
        {
            this[key].FullOffsets.Push(collectionEntriesOffset, offset)
            ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
            ; this[key].FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(this[key].FullOffsets)
            ; this[key].GSOName := key
            this.UpdateChildrenWithFullOffsets(this[key], location, [collectionEntriesOffset, offset])
        }
        
    }

    ; Starting at currentObj, updates the fulloffsets variable in key and all children of key recursively.
    UpdateChildrenWithFullOffsets(currentObj, insertLoc := 0, offset := "")
    {
        for k,v in currentObj
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure" AND v.FullOffsets != "")
            {
                v.FullOffsets.InsertAt(insertLoc, offset*)
                v.UpdateChildrenWithFullOffsets(v, insertLoc, offset)
                ; DEBUG: Uncomment following line to enable a readable offset string when debugging GameObjectStructure Offsets
                ; v.FullOffsetsHexString := ArrFnc.GetHexFormattedArrayString(v.FullOffsets)
            }
            else if (k == "DictionaryObject")
            {
                for x,y in v
                    y.UpdateChildrenWithFullOffsets(y, insertLoc, offset)
            }
        }
    }

    Read(valueType := "")
    {
        if(GameObjectStructure.ReadIsLocked)
            return ""
        if(!valueType)
            valueType := this.ValueType
        ; DEBUG: Uncomment following line to enable a readable offset string when debugging thisStructure Offsets
        ; val := ArrFnc.GetHexFormattedArrayString(this.FullOffsets)
        baseAddress := this.BasePtr.BaseAddress ? this.BasePtr.BaseAddress + 0 : this.BasePtr.BaseAddress ; do math on non-null non-zero value to ensure number instead of string. Prevents memory leaks.
        if (baseAddress <= 0)
            return ""
        if(valueType == "UTF-16") ; take offsets of string and add offset to "value" of string based on 64/32bit
        {
            offsets := this.FullOffsets.Clone()
            offsets.Push(_MemoryManager.Is64Bit ? 0x14 : 0xC)
            var := _MemoryManager.instance.readstring(baseAddress, bytes := 0, valueType, offsets*)
        }
        else if (valueType == "List" OR valueType == "Dict" OR valueType == "HashSet" OR valueType == "Stack"  OR valueType == "Queue") ; custom ValueTypes not in classMemory.ahk
        {
            var := _MemoryManager.instance.read(baseAddress, "Int", (this.GetOffsets())*)
        }
        else if (valueType == "Array" )
        {
            valueType := GameObjectStructure.SystemTypes[this._CollectionValType]
            if (this._ArrayDimensions > 0)
                valueType := "Int64"
            var := _MemoryManager.instance.read(baseAddress, , (this.GetOffsets())*)
        }
        else if (valueType == "Quad") ; custom ValueTypes not in classMemory.ahk
        {
            offsets := this.GetOffsets().Clone()
            first8 := _MemoryManager.instance.read(baseAddress, "Int64", (offsets)*)
            lastIndex := offsets.Count()
            offsets[lastIndex] := offsets[lastIndex] + 0x8
            second8 := _MemoryManager.instance.read(baseAddress, "Int64", (offsets)*)
            var := this.ConvQuadToString3( first8, second8 )
        }
        else if (valueType == "Double?")
        {
            var := _MemoryManager.instance.read(baseAddress, "Double", (this.GetOffsets())*)
            if !var
            {
                offsets := this.GetOffsets().Clone()
                lastIndex := offsets.Count()
                offsets[lastIndex] := offsets[lastIndex] + 0x8
                var := _MemoryManager.instance.read(baseAddress, "Double", (offsets)*)
            }
        }
        else
        {
            var := _MemoryManager.instance.read(baseAddress, valueType, (this.GetOffsets())*)
        }
        return var
    }
    
    ;==============
    ;Helper Methods
    ;==============


    ; Used to calculate offsets the offsets of an item in a list by its index value.
    CalculateOffset( listItem, indexStart := 0 )
    {
        if(indexStart) ; If list is not 0 based indexing
            listItem--             ; AHK uses 1 based array indexing, switch to 0 based
        
         if(_MemoryManager.Is64Bit)
         {
            ; Note: Some 64-bit lists will still use 4 byte offsets instead of 8.
            ; Handle lists of varying size items 
            hasType1 := GameObjectStructure.SystemTypes[this._CollectionValType] != ""
            type1Bytes := hasType1 ? GameObjectStructure.ValueTypeToBytes[GameObjectStructure.SystemTypes[this._CollectionValType]] : 0x8
            itemSize := hasType1 ? type1Bytes : 0x8
            offset := 0x20 + ( listItem * itemSize )
            return offset
         }
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

        if(_MemoryManager.Is64Bit)
        {
                    
            ; --- handle dictionary types with different size offsets ---
            ; Look up if it's a key/value are standard types
            hasType1 := GameObjectStructure.SystemTypes[this._CollectionKeyType] != ""
            hasType2 := GameObjectStructure.SystemTypes[this._CollectionValType] != ""
            ; Look up correct byte sizes for standard types used in c# dictionaries. Default non-standard byte size (8) otherwise.
            type1Bytes := hasType1 ? GameObjectStructure.ValueTypeToBytes[GameObjectStructure.SystemTypes[this._CollectionKeyType]] : 0x8
            type2Bytes := hasType2 ? GameObjectStructure.ValueTypeToBytes[GameObjectStructure.SystemTypes[this._CollectionValType]] : 0x8
            itemSize := (hasType1 AND hasType2 AND type1Bytes == 0x4 and type2Bytes == 0x4) ? 0x4 : 0x8
            ; --- 
            ; 64-bit dictionary entries start at 0x28
            baseOffset := 0x28
            ; Default entry sizes (e.g. int/int dict entries will be 0x10 bytes apart)
            offsetInterval := itemSize == 0x4 ? 0x10 : 0x18
            ; Special case for Quads as values
            offsetInterval := GameObjectStructure.SystemTypes[this._CollectionValType] == "Quad" ? 0x20 : offsetInterval
            ; value of entry starts after the key for the entry
            valueOffset := itemSize
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

    CalculateArrayOffset(indexLoc, indexStart := 0, byteSizeOverride := 0x0)
    {
        if(indexStart) ; If list is not 0 based indexing
            indexLoc--             ; AHK uses 0 based array indexing, switch to 0 based
        
         if(_MemoryManager.Is64Bit)
         {
            if(!byteSizeOverride) ; _ArrayDimensions not decremented until after this function is called. 1 is effectively 0.
                itemSize := (this._ArrayDimensions != "" AND  this._ArrayDimensions <= 1 AND _ClassMemory.aTypeSize[GameObjectStructure.SystemTypes[this._CollectionValType]]) ? _ClassMemory.aTypeSize[GameObjectStructure.SystemTypes[this._CollectionValType]] : 0x8
            else
                itemSize := byteSizeOverride
            offset := 0x20 + ( indexLoc * itemSize )
            return offset
         }
        return 0x10 + ( indexLoc * 0x4 )
    }

    ; Used to calculate offsets of an item in a dict. requires an array with "key" or "value" as first entry and the dict index as second. indices start at 0.
    CalculateHashSetOffset(key)
    {
        if(_MemoryManager.Is64Bit)
        {
            ; Look up if key is a standard type
            hasType1 := GameObjectStructure.SystemTypes[this._CollectionKeyType] != ""
            ; Look up correct byte sizes for standard types used in c# HashSets. Default non-standard byte size (8) otherwise.
            type1Bytes := hasType1 ? GameObjectStructure.ValueTypeToBytes[GameObjectStructure.SystemTypes[this._CollectionKeyType]] : 0x8
            itemSize := (hasType1 AND type1Bytes == 0x4) ? 0x4 : 0x8
            ; 64-bit HashSet entries start at 0x20 for base types, 0x28 for class types
            baseOffset := itemSize == 0x4 ? 0x20 : 0x28 
            ; Default entry sizes (e.g. int hash entries will be 0xC bytes apart. Class types willbe 0x10 bytes apart)
            offsetInterval := itemSize == 0x4 ? 0xC : 0x10
            ; Special case for Quads as values
            ;offsetInterval := GameObjectStructure.SystemTypes[this._CollectionValType] == "Quad" ? 0x20 : offsetInterval
            ; value of entry starts after the key for the entry
            valueOffset := itemSize
        }
        else
        {
            baseOffset := 0x18
            offsetInterval := 0x10
            valueOffset := 0x4
        }
        offset := baseOffset + ( offsetInterval * key )
        return offset
    }

    ; TODO: Convert to proper dictionary lookup.  Current method is O(n) instead of O(1)
    ; Iterates a dictionary collection looking for the matching key value
    GetDictIndexOfKeyQuick(key)
    {
        startAtLastPos := this.StartAtLastPos
        wasLocked := GameObjectStructure.ReadIsLocked
        GameObjectStructure.ReadIsLocked := False                                           ; Disable lock before read
        dictCount := this.size.Read()
        GameObjectStructure.ReadIsLocked := wasLocked                                           ; Reset read lock after read
        ; skip attempts on unreasonable dictionary sizes.
        if (dictCount < 0 OR dictCount > 32000)
            return ""
        currIndex := Array()
        currIndex[1] := "Key"
        indexReadObject := new GameObjectStructure(this.FullOffsets)
        indexReadObject.BasePtr := this.BasePtr
        indexReadObject.FullOffsets.Push(_MemoryManager.Is64Bit ? 0x18 : 0xC) ; Collection Items offset for Dictionaries
        if key is not integer ; test if key is int or string or other?
            indexReadObject.ValueType := "UTF-16" ; Read() will use default if no value set
        loop, % dictCount
        {
            if (A_Index > 1)
                indexReadObject.FullOffsets.Pop()                                               ; pop last index offset that was added in loop
            if (startAtLastPos)
                currIndex[2] := position := Mod(A_Index + GameObjectStructure.LastDictPos, dictCount + 1)  ; Continue lookup from last location searched. Useful for ordered dictionaries.
            else
                currIndex[2] := position := A_Index - 1
            ; if (currIndex[2] == 0)
            ;     test := reset
            indexReadObject.FullOffsets.Push(this.CalculateDictOffset(currIndex))               ; Index Offset
            wasLocked := GameObjectStructure.ReadIsLocked
            GameObjectStructure.ReadIsLocked := False                                           ; Disable lock before read
            currKey := indexReadObject.Read()
            GameObjectStructure.ReadIsLocked := wasLocked                                       ; Reset read lock after read
            if (currKey == key)
            {
                this["key", position] ; Build relevant dictionary object fully.
                GameObjectStructure.LastDictPos := position
                return position
            }
        }
        GameObjectStructure.LastDictPos := 0
        return -1
    } 

    ; Converts 16 byte Quad value into a string representation.
    ConvQuadToString3( FirstEight, SecondEight )
    {
        f := log( FirstEight + ( 2.0 ** 63 ) )
        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + f
        if(decimated <= 4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 2) . ""
        exponent := floor( decimated )
        significand := round( 10 ** ( decimated - exponent ), 2 )
        return significand . "e" . exponent
    }

    ; Iterate all the elements of the game object structure recursively and name them
    SetNames()
    {
        
        for k,v in this
        {
            if(!IsObject(v))
                continue
            if(ObjGetBase(v).__Class == "GameObjectStructure" AND !v.IsAddedIndex)
            {   
                this[k].GSOName := k
                this[k].SetNames()
            }
        }
    }

    ResetBasePtr(currentObj, name :="")
    {
        this.BasePtr := currentObj.BasePtr
        for k,v in this
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure" AND v.FullOffsets != "")
                v.ResetBasePtr(currentObj)
            else if(k == "DictionaryObject")
                for dictKey, dictValue in v
                    dictValue.ResetBasePtr(currentObj) ; Assume gameobjects, since dictionaryObject should be dict of gameobjects.
        }
    }

    DoesCollectionNeedReset()
    {
        
        wasLocked := GameObjectStructure.ReadIsLocked
        GameObjectStructure.ReadIsLocked := False                                           ; Disable lock before read
        needsReset := (this.LastDictVersion != this.__version.Read())
        GameObjectStructure.ReadIsLocked := wasLocked                                       ; Reset lock before return
        return needsReset
    }

    ResetCollection()
    {
        this.DictionaryObject := {}
        this.LastDictIndex := {}
        wasLocked := GameObjectStructure.ReadIsLocked
        GameObjectStructure.ReadIsLocked := False                                           ; Disable lock before read
        this.LastDictVersion := this.__version.Read()
        GameObjectStructure.ReadIsLocked := wasLocked                                       ; Reset lock before return
    }


    ResetCollections()
    {
        this.DictionaryObject := {}
        this.LastDictIndex := {}
        for k,v in this
        {
            if(!IsObject(v) OR !ObjGetBase(v).__Class == "GameObjectStructure" OR k == "BasePtr")
                continue
            if(v.IsAddedIndex)
                this.Delete(k)
            else
                this[k].ResetCollections()
        }
    }

    ; Outputs a string of every chain of objects down from this one and saves them to ObjectsLog.json (not in actual json)
    BuildNames(name)
    {
        global g_string
        for k,v in this
        {
            if(k == "DictionaryObject" AND v.Count() > 0)
                for j,x in v
                    value := x.BuildNames(name . k . ".")
            if(IsObject(v) AND ObjGetBase(v).__Class == "GameObjectStructure")
                value := v.BuildNames(name . k . ".")  
        }
        if (value == "")
        {
            name := name . "`n"
            FileAppend, %name%, % A_LineFile . "\..\ObjectsLog.json"
        }
        value := "STOP"
        return value
    }

    GetBaseLocation()
    {
        global g_SF
        if(g_SF != "" and g_SF.Memory != "")
            return g_SF.Memory[this.BasePtr.ClassName]
        return ""
    }
}
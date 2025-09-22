class SH_UpdateClass
{
    static UpdatedFunctions := {}

    ; Make classWithOverrideFunctions extend classToUpdate 
    UpdateClassFunctions(byref classToUpdate, byref classWithOverrideFunctions)
    {
        if (!IsObject(classToUpdate) OR !IsObject(classWithOverrideFunctions))
            return
        if (ObjRawGet(classToUpdate, "__Class") == "") ; class is generated with "new" - make it the very bottom base class.
        {
            newObj := classToUpdate.base
            currentObj := classToUpdate
            while(ObjGetBase(currentObj) != "")         ; find ultimate base of classToUpdate.
                currentObj := ObjGetBase(currentObj)
            bottomBase := classToUpdate.Clone()         ; create a copy of classToUpdate
            ObjSetBase(bottomBase, "")                      ; and remove its base.
            currentObj.base := bottomBase               ; set the copy to be the new ultimate base
            classToUpdate := newObj                         ; newObj is now classDoUpdate with only base and everything else swapped to the ultimate base.
        }
        ObjSetBase(classWithOverrideFunctions, classToUpdate)
        classToUpdate := classWithOverrideFunctions     ; place classWithOverrideFunctions as the new top level class

        ; this.AddClassFunctions(classToUpdate, classWithOverrideFunctions)
        ;ObjRawSet(classToUpdate, "base", classWithOverrideFunctions)
    }

    AddClassFunctions(byref classToUpdate, byref classWithOverrideFunctions, ignoreWarnings := false)
    {
        ; Use name from base class if it exists
        classToUpdateName := classToUpdate.base.__Class != "" ? classToUpdate.base.__Class : classToUpdate.__Class
        ; Use name from class unless it doesn't exist
        classWithOverridesName := classWithOverrideFunctions.__Class != "" ? classWithOverrideFunctions.__Class : classWithOverrideFunctions.base.__Class

        for functionName,func in classWithOverrideFunctions
        {
            if(IsFunc(func))
            {
                if(SH_UpdateClass.UpdatedFunctions[classToUpdateName . "." . functionName] AND !ignoreWarnings)
                    MsgBox, 48, CONFLICT NOTICE:, % func.Name . "() overwrites " . classToUpdateName . "." . functionName . "() which was previously overwritten by " SH_UpdateClass.UpdatedFunctions[classToUpdateName . "." . functionName] . "." . functionName . "()."
                classToUpdate[functionName] := func
                SH_UpdateClass.UpdatedFunctions[classToUpdateName . "." . functionName] := classWithOverridesName
            }
        }
    }
}
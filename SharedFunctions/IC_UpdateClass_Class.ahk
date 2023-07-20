class IC_UpdateClass_Class
{
    static UpdatedFunctions := {}
    UpdateClassFunctions(byref classToUpdate, classWithOverrideFunctions, ignoreWarnings := false)
    {
        ; Use name from base class if it exists
        classToUpdateName := classToUpdate.base.__Class != "" ? classToUpdate.base.__Class : classToUpdate.__Class
        ; Use name from class unless it doesn't exist
        classWithOverridesName := classWithOverrideFunctions.__Class != "" ? classWithOverrideFunctions.__Class : classWithOverrideFunctions.base.__Class

        for functionName,func in classWithOverrideFunctions
        {
            if(IsFunc(func))
            {
                if(IC_UpdateClass_Class.UpdatedFunctions[classToUpdateName . "." . functionName] AND !ignoreWarnings)
                    MsgBox, 48, CONFLICT NOTICE:, % func.Name . "() overwrites " . classToUpdateName . "." . functionName . "() which was previously overwritten by " IC_UpdateClass_Class.UpdatedFunctions[classToUpdateName . "." . functionName] . "." . functionName . "()."
                classToUpdate[functionName] := func
                IC_UpdateClass_Class.UpdatedFunctions[classToUpdateName . "." . functionName] := classWithOverridesName
            }
        }
    }
}
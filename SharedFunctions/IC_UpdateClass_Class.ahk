class IC_UpdateClass_Class
{
    static UpdatedFunctions := {}
    UpdateClassFunctions(byref classToUpdate, classWithOverrideFunctions)
    {
        for k,v in classWithOverrideFunctions
        {
            if(IsFunc(v))
            {
                if(IC_UpdateClass_Class.UpdatedFunctions[classToUpdate.base.__Class . "." . k])
                    MsgBox, 48, CONFLICT NOTICE:, % v.Name . "() overwrites " . classWithOverrideFunctions.base.__Class . "." . k . "() which was previously overwritten by " IC_UpdateClass_Class.UpdatedFunctions[classToUpdate.base.__Class . "." . k] . "." . k . "()."
                classToUpdate[k] := v
                IC_UpdateClass_Class.UpdatedFunctions[classToUpdate.base.__Class . "." . k] := classWithOverrideFunctions.__Class
            }
        }
    }
}
class IC_UpdateClass_Class
{
    UpdateClassFunctions(byref classToUpdate, classWithOverrideFunctions)
    {
        for k,v in classWithOverrideFunctions
        {
            if(IsFunc(v))
                classToUpdate[k] := v
        }
    }
}
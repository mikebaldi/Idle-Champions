class ArrFnc
{
    Append(source, value)
    {
        var := source.Clone()
        var.Push(value)
        return var
    }

    Concat(source, value)
    {
        var := source.Clone()
        var.Push(value*)
        return var
    }

    GetHexFormattedArrayString(array1)
    {
        itemCount := array1.Count()
        var := "[ "
        loop, %itemCount%
        {
             if IsObject(array1[A_Index])
                  var .= this.GetHexFormattedArrayString(array1[A_Index]) . "] "
            if ( A_Index < itemCount )
            var .= Format("0x{:X}", array1[A_Index]) . ", "
            else
            var .= Format("0x{:X}", array1[A_Index])
        }
        var .= " ]"
        return var
    }

    GetDecFormattedArrayString(array1)
    {
        itemCount := array1.Count()
        var := "[ "
        loop, %itemCount%
        {
            ; if IsObject(array1[A_Index])
            ;      var .= this.GetHexFormattedArrayString(array1[A_Index]) . "] "
            if ( A_Index < itemCount )
            var .= Format("{:d}", array1[A_Index]) . ", "
            else
            var .= Format("{:d}", array1[A_Index])
        }
        var .= " ]"
        return var
    }
}
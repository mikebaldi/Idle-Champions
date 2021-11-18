; Class that contains functions for dealing with 1 dimentional arrays

class ArrFnc
{
    ; Appends a value to the end of a source array
    Append(source, value)
    {
        var := source.Clone()
        var.Push(value)
        return var
    }

    ; Takes two arrays and appends the second to the end of the first
    Concat(source, value)
    {
        var := source.Clone()
        var.Push(value*)
        return var
    }

    ; Creates a string from an array of numbers showing the array in hex format. e.g. [0x1, 0x2, 0xF]
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

    ; Creates a string from an array of numbers showing the array in decimal format. e.g. [1, 2, 3]
    GetDecFormattedArrayString(array1)
    {
        itemCount := array1.Count()
        var := "[ "
        loop, %itemCount%
        {
            if IsObject(array1[A_Index])
                  var .= this.GetDecFormattedArrayString(array1[A_Index]) . "] "
            if ( A_Index < itemCount )
            var .= Format("{:d}", array1[A_Index]) . ", "
            else
            var .= Format("{:d}", array1[A_Index])
        }
        var .= " ]"
        return var
    }
}
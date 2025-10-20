; Class that contains functions for working with 1 dimentional arrays

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
        if(!array1.MaxIndex()) ; Array test
            return ""
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
        if(!array1.MaxIndex()) ; Array test
            return ""
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

    ; Creates a string from an associative array of numbers showing the array in decimal format. e.g. {1:1, 2:2, 3:3}
    GetDecFormattedAssocArrayString(array1)
    {
        itemCount := array1.Count()
        var := "{ "
        for k, v in array1
        {
            if IsObject(v)
                var .= this.GetDecFormattedAssocArrayString(v) . "] "
            if ( A_Index < itemCount )
                var .= k . ":" . Format("{:d}", v) . ", "
            else
            var .= k . ":" . Format("{:d}", v)
        }
        var .= " }"
        return var
    }

    ; Creates a string from an array. e.g. [1, F2, q, 6]
    GetAlphaNumericArrayString(array1)
    {   
        if(!array1.MaxIndex()) ; Array test
            return ""
        itemCount := array1.Count()
        var := "[ "
        loop, %itemCount%
        {
            if IsObject(array1[A_Index])
                  var .= this.GetAlphaNumericArrayString(array1[A_Index]) . "] "
            if ( A_Index < itemCount )
            var .= array1[A_Index] . ", "
            else
            var .= array1[A_Index]
        }
        var .= " ]"
        return var
    }

    BinarySearch(array, leftIndex, rightIndex, searchValue)
    {
        if(rightIndex >= 1)
        {
            middle := Ceil(leftIndex + ((rightIndex-leftIndex) / 2))
            if (array[middle] == searchValue)
                return middle
            else if (array[middle] > searchValue)
                return this.BinarySearch(array, leftIndex, middle-1, searchValue)
            else
                return this.BinarySearch(array, middle, rightIndex, searchValue)
        }
        else
        {
            return false
        }
    }
}
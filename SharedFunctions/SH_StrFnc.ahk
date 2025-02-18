; Class that contains functions for working with strings

class StrFnc {
    NumberFormat(value) {
        ; Convert value to string and handle decimal parts
        value := value . ""
        if (value = "") {
            return "0"
        }

        if InStr(value, ".") {
            decimalPart := SubStr(value, InStr(value, "."))
            value := SubStr(value, 1, InStr(value, ".") - 1)
        }

        ; Format the whole number part with spaces
        formatted := ""
        while (StrLen(value) > 3) {
            formatted := " " . SubStr(value, -2) . formatted
            value := SubStr(value, 1, StrLen(value) - 3)
        }
        formatted := value . formatted

        ; Add back decimal part if it exists
        return decimalPart ? (formatted . decimalPart) : formatted
    }
}
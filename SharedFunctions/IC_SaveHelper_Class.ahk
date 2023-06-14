/*  A class to handle save data's compression and decompression and checksum validation via interaction with GzipWrapper.dll and advapi32.dll
    GzipWrapper.dll must be kept in the Libraries folder (Update zlibLoc to change this).

    Usage:
    ;initialize class
    classObj := new IC_SaveHelper_Class
*/

class IC_SaveHelper_Class
{
    md5Module := ""
    brivStackDic := ""

    ; loads libraries for use in script.
    __new()
    {
        this.md5Module := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    }

    ; frees libraries after use
    __delete()
    {
        DllCall("FreeLibrary", "Ptr", this.md5Module)
    }

    Init()
    {
        if(!isObject(this.brivStackDic))
            this.brivStackDic := g_SF.LoadObjectFromJSON(A_LineFile . "\..\BrivStackDictionary.json")
    }

    ; Modified from https://www.autohotkey.com/boards/viewtopic.php?f=6&t=21
    ; Creates a salted md5 checksum for a save string.
    Md5Save(stringVal)
    {
        stringVal := stringVal . "som" . "ethin" . "gpoli" . "tical" . "lycor" . "rect"
        , VarSetCapacity(MD5_CTX, 104, 0), DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
        , DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", stringVal, "UInt", StrLen(stringVal))
        , DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
        loop, 16
            o .= Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
        StringLower, o,o
        return o
    }

    ; Computes compressed string used in a save given a number of stacks.
    GetCompressedDataFromBrivStacks(stackValue := 0)
    {
        compressStringAppend := this.brivStackDic[stackValue]
        compressString := "eNqrViouSSwpVrKqVkoqyiyLLy5JTc1Jys9LLQYyE5OzgTIKBjpQuYKizLw" . compressStringAppend
        return compressString
    }

    ; Computes checksum for saved data based on a give number of stacks.
    GetSaveCheckSumFromBrivStacks(stackValue := 0)
    {
        jsonObj := "{""stats"":{""briv_steelbones_stacks"": 0,""briv_sprint_stacks"":" . stackValue . "}}"
        checksum := this.Md5Save(jsonObj)
        return checksum
    }

    ; Converts user's data into form data that can be submitted for a save.
    GetSave(userData, checksum, userID, userHash, networkID, clientVersion, instanceID, timeStamp := "0")
    {
        mimicSave := ""
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""call""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: 15`n`n" 
        mimicSave .= "saveuserdetails`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""language_id""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: 1`n`n" 
        mimicSave .= "1`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""user_id""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: "  StrLen(userID)  "`n`n" 
        mimicSave .= userID  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""hash""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: 32`n`n" 
        mimicSave .= userHash  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""details_compressed""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: "  (StrLen(userData) + 1)  "`n`n" 
        mimicSave .= userData  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""checksum""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: 32`n`n" 
        mimicSave .= checksum  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""timestamp""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: "  StrLen(timeStamp)  "`n`n" 
        mimicSave .= timeStamp  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""request_id""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: 1`n`n" 
        mimicSave .= "1`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""network_id""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: " StrLen(networkID)  "`n`n" 
        mimicSave .= networkID  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""mobile_client_version""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: "  StrLen(clientVersion)  "`n`n" 
        mimicSave .= clientVersion  "`n" 
        mimicSave .= "--BestHTTP`n" 
        mimicSave .= "Content-Disposition: form-data; name=""instance_id""`n" 
        mimicSave .= "Content-Type: text/plain; charset=utf-8`n" 
        mimicSave .= "Content-Length: "  StrLen(instanceID)  "`n`n" 
        mimicSave .= instanceID  "`n" 
        mimicSave .= "--BestHTTP--`n"
        return mimicSave
    }

    ; Returns closest value for stacks that has a pre-calculated compression string.
    GetEstimatedStackValue(val)
    {
        if (val > 5046)
        {
            if (val > (5046 + 2500*9))
            {
                if (val > (5046 + 2500*9 + 1500*99))
                {
                    val := (5046 + 2500*9 + 1500*99)
                }
                else
                {
                    val -= (5046 + 2500*9)
                    val := Floor(val / 99)
                    val := (99*val + 5046 + 2500*9)
                }
            }
            else
            {
                val -= 5046
                val := Floor(val / 9)
                val := (9*val + 5046)
            }
        }
        else if (val <= 48)
        {
            val := 48
        }
        return val
    }
}

#include %A_LineFile%\..\CLR.ahk
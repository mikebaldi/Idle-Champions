/*  A class to handle save data's compression and decompression and checksum validation via interaction with GzipWrapper.dll and advapi32.dll
    GzipWrapper.dll must be kept in the Libraries folder (Update zlibLoc to change this).

    Usage:
    ;initialize class
    classObj := new IC_SaveHelper_Class
*/

class IC_SaveHelper_Class
{
    asm := ""
    obj := ""
    zlibLoc := ""
    md5Module := ""

    ; loads libraries for use in script.
    __new()
    {
        this.zlibLoc := A_LineFile . "\..\..\Libraries\GzipWrapper.dll"
        this.asm := CLR_LoadLibrary(this.zlibLoc)
        this.obj := CLR_CreateObject(this.asm, "Gzipper")
        this.md5Module := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    }

    ; frees libraries after use
    __delete()
    {
        DLLCall("FreeLibrary", "Str", this.zlibLoc)
        DllCall("FreeLibrary", "Ptr", this.md5Module)
    }

    ; gzip compresses a string
    Compress(decompressedString)
    {
        returnVal := this.obj.Compress(decompressedString)
        return returnVal
    }

    ; gzip decompresses a base64 string
    Decompress(compressedString)
    {
        returnVal := this.obj.Decompress(compressedString)
        return returnVal
    }

    ; builds a save post string from parameters
    CompressSave(savestring, checksum, userID, userHash, networkID, clientVersion, instanceID, timeStamp := "0")
    {
        userID .= ""
        userHash .= ""
        networkID .= ""
        clientVersion .= ""
        instanceID .= ""
        timeStamp .= ""
        someString = 
        (
            "--BestHTTP\nContent-Disposition: form-data; name=\"call\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 15\n\nsaveuserdetails\n--BestHTTP\nContent-Disposition: form-data; name=\"language_id\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 1\n\n1\n--BestHTTP\nContent-Disposition: form-data; name=\"user_id\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 6\n\nuserID\n--BestHTTP\nContent-Disposition: form-data; name=\"hash\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 32\n\nuserHash\n--BestHTTP\nContent-Disposition: form-data; name=\"details_compressed\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 32\n\neNorLU4tckksSQQADukDOg==\0\0\0\0\0\0\0\0\n--BestHTTP\nContent-Disposition: form-data; name=\"checksum\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 32\n\nchecksum\n--BestHTTP\nContent-Disposition: form-data; name=\"timestamp\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 1\n\n0\n--BestHTTP\nContent-Disposition: form-data; name=\"request_id\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 1\n\n1\n--BestHTTP\nContent-Disposition: form-data; name=\"network_id\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 9\n\nnetworkID\n--BestHTTP\nContent-Disposition: form-data; name=\"mobile_client_version\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 13\n\nclientVersion\n--BestHTTP\nContent-Disposition: form-data; name=\"instance_id\"\nContent-Type: text/plain; charset=utf-8\nContent-Length: 10\n\ninstanceID\n--BestHTTP--\n"
        )
        returnVal := this.obj.CompressSave(savestring, checksum, userID, userHash, networkID, clientVersion, instanceID, timeStamp)      
        return returnVal
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
}

#include %A_LineFile%\..\CLR.ahk
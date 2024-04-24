#include %A_LineFile%\..\json.ahk
#include %A_LineFile%\..\SH_SharedFunctions.ahk
; Build a map of key inputs used by the script
; KeyMap keys contains all basic keys built (e.g. "a", "b") as well as dictionaries of those keys (e.g. "{a}", "{b}").
; GetKeySC() built in function to get scancode keys. Value is left as decimal to allow for bitshifting when creating lparam args for SendMessage calls.
; GetKeyVK() built in function to get the virtual key. Value is formatted to hex for use in SendMessage calls.
; ScanCode is key at physical keyboard location and needed in new builds for multi-language keyboards.
; Mapping saved in ScanCodes.json is created using us-en qwerty keyboard layout.
class KeyHelper
{
    ; Add virtual keys from a JSON file
    AddVirtualKeysToMap(filePath, ByRef vKeys, ByRef scKeys)
    {
        sharedFunctions := new SH_SharedFunctions
        scancodes := sharedFunctions.LoadObjectFromJSON(filePath)
        for key,sc in scancodes
        {
            index := "{" . key . "}"
            formattedSC := Format("sc{:X}", sc)     ; Reformat for use in GetKeyVK (sc + hex. e.g. scC0)
            vk := GetKeyVK(formattedSC)             ; Get virtual key value (dec)
            formattedVK := Format("0x{:X}", vk)     ; convert virtual key to hex code 
            vKeys[index] := formattedVK
            vKeys[key] := formattedVK
            scKeys[index] := sc
            scKeys[key] := sc
        }
    }

    ; Updates virtual key and scancode keymaps.
    BuildVirtualKeysMap(ByRef vKeys, ByRef scKeys)
    {
        fileName := A_LineFile . "/../ScanCodes.json"
        KeyHelper.AddVirtualKeysToMap(fileName, vKeys, scKeys)

        fileName := A_LineFile . "/../ScanCodesOverride.json"
        if FileExist(fileName)
            KeyHelper.AddVirtualKeysToMap(fileName, vKeys, scKeys)
    }

    WriteScanCodesToJSON()
    {
        sharedFunctions := new SH_SharedFunctions
        output := {}
        fileName := A_LineFile . "/../ScanCodesOverride.json"
        alphabet := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
        extraKeys := ["Left","Right","Esc","Shift","Alt","Ctrl","``","RCtrl","LCtrl"]
        fKeys := ["F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"]
        numKeys := ["0","1","2","3","4","5","6","7","8","9"]
        allKeys := {}
        allKeys.Push(alphabet*)
        allKeys.Push(extraKeys*)
        allKeys.Push(fKeys*)
        allKeys.Push(numKeys*)

        for k,v in allKeys
        {
            output[v] := Format("0x{:X}", GetKeySC(v)) . ""
        }
        ; output["ClickDmg"] := 0x29
        output["ClickDmg"] := output["``"]

        sharedFunctions.WriteObjectToJSON( fileName, output )
        return
    }         
}
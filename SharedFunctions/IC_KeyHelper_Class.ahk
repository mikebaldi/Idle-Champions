; Build a map of key inputs used by the script
class KeyHelper
{
    BuildVirtualKeysMap()
    {
        KeyMap := {}
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
            index := "{" . v . "}"
            vk := GetKeyVK(v)
            formattedHexCode := Format("0x{:X}", vk)
            KeyMap[index] := formattedHexCode
            KeyMap[v] := formattedHexCode
        }
        
        return KeyMap
    }           
}
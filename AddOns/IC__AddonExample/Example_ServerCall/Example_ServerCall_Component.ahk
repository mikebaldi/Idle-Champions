
; Sample class for server calls
class IC_Example_ServerCall_Class
{
    ; Prompts the user for a chest code, sends it to the server, and displays the response.
    GetChestCode()
    {
        ; A shared function that retrieves all of the information needed for a servercall such as user id, hash, server, and instance ID
        g_SF.ResetServerCall()
        ; Promp the user for the chest code which will be stored in the variable chestCode
        InputBox, chestCode , Enter Chest Code, Enter Chest Code,, Width := 375, Height := 189, X := 0, Y := 0, Locale,, 
        ; user pressed cancel, exit function.
        if (ErrorLevel == 1)
            return
        ; split the code at hyphens
        splitCode := StrSplit(chestCode, "-")
        
        ; combine the code back together without hyphens
        for k,v in splitCode
        {
            code .= v
        }

        ; Error catch block in case of failed server call or json parsing of response.
        try
        {
            ; store the parsed json object as response
            response := this.CallSendChestCode(code)
        }
        catch 
        {
            ; Show an error for a failed request.
            MsgBox, There was an unknown error when sending the code.
            return
        }
        lootString := ""
        ; Loop through the actions in the response
        for actionItem,actionObject in response.actions
        {
            ; loop through the items in each action
            for k,v in actionObject
            {
                ; Add the action to the loot string.
                lootString .= k . ": " . v . "`n"
            }
        }
        ; Show if the call was successful by showing chest counts added if the request was replied to and there is no failure reason. Otherwise show the failure reason.
        MsgBox, % ((response.success AND NOT response.failure_reason) ? "Chest Count Updates:`n" . lootString : "Failed. " . response.failure_reason)
    }

    ; Calling this loses everything earned during the adventure, should only be used when stuck.
    CallSendChestCode(code) 
    {
        ; The parameters attached to the server call's GET request
        advParams := g_ServerCall.dummyData "&user_id=" g_ServerCall.userID "&hash=" g_ServerCall.userHash "&instance_id=" g_ServerCall.instanceID "&code=" code
        
        ; Error catch block in case of failed server call or json parsing of response.
        try
        {
            ; Use the ServerCall class's ServerCall function to send the request to the server.
            return g_ServerCall.ServerCall( "redeemcoupon", advParams )
        }
        catch
        {
            ; rethrow the error
            throw
        }
        
    }
}
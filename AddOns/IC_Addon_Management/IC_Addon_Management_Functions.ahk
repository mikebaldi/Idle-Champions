; functions to be added

;------------------------------
;
; Function: LVM_CalculateSize
;
; Description:
;
;   Calculate the width and height required to display a given number of rows of
;   a ListView control.
;
; Parameters:
;
;   p_NumberOfRows - The number of rows to be displayed in the control.  Set to
;       -1 (the default) to use the current number of rows in the ListView
;       control.
;
;   r_Width, r_Height - [Output, Optional] The calculated width and height of
;       ListView control.
;
; Returns:
;
;   An integer that holds the calculated width (in the LOWORD) and height (in
;   the HIWORD) needed to display the rows, in pixels.
;
;   If the output variables are defined (r_Width and r_Height), the calculated
;   values are also returned in these variables.
;
; The AutoHotkey Method:
;
;   This function uses the LVM_APPROXIMATEVIEWRECT message to calculate the
;   approximate width and height required to display a given number of rows in a
;   ListView control.  The AutoHotkey method (extracted from the AutoHotkey
;   source) makes minor changes to the data that is passed to the message and to
;   the results that are returned from the message.
;
;   The AutoHotkey method is the following.
;
;   _Input_: The actual or requested number of row is used minus 1.  For
;   example, if 10 rows is requested, 9 is passed to the LVM_APPROXIMATEVIEWRECT
;   message instead.
;
;   _Output_: 4 is added to both the width and height return values.  For
;   example, if the message returned a size of 300x200, the size is adjusted to
;   304x204.
;
;   The final result (in most cases) is a ListView control that is the exact
;   size needed to show all of the specified rows and columns without showing
;   the horizontal or vertical scroll bars.  Exception: If the requested number
;   of rows is less than the actual number of rows, the horizontal and/or
;   vertical scroll bars may show as a result.
;
; Remarks:
;
;   This function should only be used on a ListView control in the Report view.
;
;-------------------------------------------------------------------------------
LVM_CalculateSize(hLV,p_NumberOfRows:=-1,ByRef r_Width:="",ByRef r_Height:="")
    {
    Static Dummy67950827

          ;-- Messages
          ,LVM_GETITEMCOUNT       :=0x1004              ;-- LVM_FIRST + 4
          ,LVM_APPROXIMATEVIEWRECT:=0x1040              ;-- LVM_FIRST + 64

    ;-- Collect and/or adjust the number of rows
    if (p_NumberOfRows<0)
        {
        SendMessage LVM_GETITEMCOUNT,0,0,,ahk_id %hLV%
        p_NumberOfRows:=ErrorLevel
        }

    if p_NumberOfRows  ;-- Not zero
        p_NumberOfRows-=1

    ;-- Calculate size
    SendMessage LVM_APPROXIMATEVIEWRECT,p_NumberOfRows,-1,,ahk_id %hLV%

    ;-- Extract, adjust, and return values
    r_Width :=(ErrorLevel&0xFFFF)+4 ;-- LOWORD
    r_Height:=(ErrorLevel>>16)+4    ;-- HIWORD
    Return r_Height<<16|r_Width
    }



AddTab(Tabname){
    addedTabs := Tabname . "|"
    GuiControl,,ModronTabControl, % addedTabs
    g_TabList .= addedTabs
    ; Increase UI width to accommodate new tab.
    StrReplace(g_TabList,"|",,tabCount)
    g_TabControlWidth := Max(Max(g_TabControlWidth,475), tabCount * 75)
    GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
    Gui, show, % "w" . g_TabControlWidth+5 . " h" . g_TabControlHeight+40
}

Class AddonManagement
{
    Addons := []
    AddonSettings := []

    Add(AddonSettings){
        Addon := new Addon(AddonSettings)
        this.Addons.Push(Addon)
    }

    CheckDependencies(){
        for k,v in this.Addons {
            if (this.AddonSettings[v.Name][v.Version]["Enabled"]){
                ; check if the dependencies exist and are enabled
                for i, j in v.Dependencies {
                    ; check if dependency exists
                    DepExists := 0
                    for y,z in this.Addons {
                        if(z.Name = i){
                            DepExists := 1
                            break
                        }
                    }
                    if(DepExists){
                        if(!this.AddonSettings[i][j]["Enabled"]){
                            MsgBox, 52, Warning, % "Addon " . i . " is required by " . v.Name . " but is disabled!`ndo you want to Enable this addon?`nYes: enable " . i . "`nNo: disable " . v.Name
                            IfMsgBox Yes 
                            {
                                this.EnableAddon(y)
                                this.GenerateIncludeFile()
                                this.WriteAddonManagementSettings()
                            }
                            else{
                                this.DisableAddon(k)
                                this.GenerateIncludeFile()
                                this.WriteAddonManagementSettings()                                
                            }
                        }
                    }
                    else{
                        MsgBox, 48, Warning, % "Can't find the addon " . i . " required by " . v.Name . "`n" . v.Name . " will be disabled"
                        this.DisableAddon(k)
                        this.GenerateIncludeFile()
                        this.WriteAddonManagementSettings()    
                    }
                }
            }
        }
    }

    CheckIfAddon(AddonBaseFolder,AddonFolder){
        if FileExist(AddonBaseFolder . AddonFolder . "\Addon.json"){
            AddonSettings := g_SF.LoadObjectFromJSON(AddonBaseFolder . AddonFolder . "\Addon.json")
            ; check if the needed settings are in the addon.json
            if (AddonSettings["Name"] && AddonSettings ["Version"]) {
                AddonSettings["Dir"] := AddonFolder
                return AddonSettings
            }
        }
        return 0
    }

    DisableAddon(AddonNumber){
        Addon := this.Addons[AddonNumber]
        if(Addon.Name != "Addon Management"){
            this.AddonSettings[Addon.Name] := { Addon.Version : { "Enabled" : 0}}
            this.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
        }
        else{
            MsgBox, 48, Warning, Can't disable the Addon Manager
        }
    }
    EnableAddon(AddonNumber){
        Addon := this.Addons[AddonNumber]
        this.AddonSettings[Addon.Name] := { Addon.Version : { "Enabled" : 1}}
        this.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
    }

    GetAddonManagementSettings(){
        this.AddonSettings:= g_SF.LoadObjectFromJSON(A_LineFile . "\..\AddonManagement.json")
        if (!IsObject(this.AddonSettings))
            this.AddonSettings := []
    }

    GetAvailableAddons(){
        AddonBaseFolder := A_LineFile . "\..\..\"
        Loop, Files, % AddonBaseFolder . "*" , D 
        {
            if(AddonSettings := this.CheckIfAddon(AddonBaseFolder,A_LoopFileName)){
                this.Add(AddonSettings)
            }
        }
    }

    GenerateIncludeFile(){
        IncludeFile := A_LineFile . "\..\..\GeneratedAddonInclude.ahk"
        IfExist, %IncludeFile%
            FileDelete, %IncludeFile%
        FileAppend, `;Automatic generated by Addon Management`n, %IncludeFile%
        for k,v in this.Addons {
            if (this.AddonSettings[v.Name][v.Version]["Enabled"] AND this.AddonSettings[v.Name] != "Addon Management"){
                IncludeLine := "#include *i " . A_LineFile "\..\..\" . v.Dir . "\" . v.Includes
                FileAppend, %IncludeLine%`n, %IncludeFile%
            }
        }
    }

    GenerateListViewContent(GuiWindowName, ListViewName){
        Gui, %GuiWindowName%:ListView, %ListViewName%
        LV_Delete()
        for k,v in this.Addons {
            IsEnabled := this.AddonSettings[v.Name][v.Version]["Enabled"] ? "yes" : "no"
            LV_Add( , IsEnabled, v.Name, v.Version, v.Dir)
        }
        loop, 4{
            LV_ModifyCol(A_Index, "AutoHdr")
        }
    }

    Remove(){

    }

    ShowAddonInfo(AddonNumber){
        Addon := this.Addons[AddonNumber]
        GuiControl, AddonInfo: , AddonInfoNameID, % Addon.Name
        GuiControl, AddonInfo: , AddonInfoFoldernameID, % Addon.Dir
        GuiControl, AddonInfo: , AddonInfoVersionID, % Addon.Version
        GuiControl, AddonInfo: , AddonInfoUrlID, % Addon.Url
        GuiControl, AddonInfo: , AddonInfoAuthorID, % Addon.Author
        GuiControl, AddonInfo: , AddonInfoInfoID, % Addon.Info
        DependenciesText := ""
        for k,v in Addon.Dependencies {
            DependenciesText .= "- " . k . ": " . v "`n"
        }
        GuiControl, AddonInfo: , AddonInfoDependenciesID, % DependenciesText
        Gui, AddonInfo:Show
    }

    WriteAddonManagementSettings(){
        g_SF.WriteObjectToJSON(A_LineFile . "\..\AddonManagement.json", this.AddonSettings)
        this.GenerateIncludeFile()
        MsgBox, 36, Restart, To make change to addon loading\deloading active you do need to restart the script.`nDo you want to do this now?
        IfMsgBox, Yes
            Reload
    }

    FirstRunCheck()
    {
        generatedIncludesLoc := A_LineFile . "\..\..\GeneratedAddonInclude.ahk"
        if(!FileExist(generatedIncludesLoc))
        {
            this.GenerateIncludeFile()
            MsgBox, 36, Restart, This looks like your first time running Script Hub. `nSettings have been updated. `nDo you wish to reload now?
            IfMsgBox, Yes
                Reload
        }
    }

}

Class Addon
{
    Dir :=
    Name :=
    Version :=
    Includes :=
    Author :=
    Url :=
    Info :=
    Dependencies := []

    __New(SettingsObject) {
        If IsObject( SettingsObject ){
            this.Dir := SettingsObject["Dir"]
            this.Name := SettingsObject["Name"]
            this.Version := SettingsObject["Version"]
            this.Includes := SettingsObject["Includes"]
            this.Author := SettingsObject["Author"]
            this.Url := SettingsObject["Url"]
            this.Info := SettingsObject["Info"]
            this.Dependencies := SettingsObject["Dependencies"]
        }
    }
}
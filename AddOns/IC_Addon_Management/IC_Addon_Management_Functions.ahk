; functions to be added




Class AddonManagement
{
    Addons := []
    AddonSettings := []
    AddonManagementConfigFile := A_LineFile . "\..\AddonManagement.json"
    GeneratedAddonIncludeFile := A_LineFile . "\..\..\GeneratedAddonInclude.ahk"

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

    ; Checks if a folder in the addons folder is an addon
    ; Parameters: none
    ; Result : returns Addon settings 
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

    ; Disable an addon in the addonsettings, will only be persisting if combined with WriteAddonManagementSettings()
    ; Parameters: none
    ; Result : object this.AddonSettings  
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

    ; Enable an addon in the addonsettings, will only be persisting if combined with WriteAddonManagementSettings()
    ; Parameters: none
    ; Result : object this.AddonSettings  
    EnableAddon(AddonNumber){
        Addon := this.Addons[AddonNumber]
        this.AddonSettings[Addon.Name] := { Addon.Version : { "Enabled" : 1}}
        this.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
    }

    ; Get the parameters of the addons to load
    ; Parameters: none
    ; Result : object this.AddonSettings   
    GetAddonManagementSettings(){
        ; If the file does not exist we should create it with the default settings
        if(!FileExist(this.AddonManagementConfigFile)) {
            ; Here we load the Addons that are required on first startup
            this.AddonSettings["Addon Management"] := { "v0.1." : { "Enabled" : 1}}
            this.AddonSettings["Briv Gem Farm"] := { "v1.0." : { "Enabled" : 1}}
            this.WriteAddonManagementSettings()
        }
        else {
            this.AddonSettings:= g_SF.LoadObjectFromJSON(this.AddonManagementConfigFile)
            if (!IsObject(this.AddonSettings))
                this.AddonSettings := []
        }


    }

    ; Get a list of all available addons in the Addon folder
    ; Parameters: none
    ; Result : object this.Addons 
    GetAvailableAddons(){
        AddonBaseFolder := A_LineFile . "\..\..\"
        Loop, Files, % AddonBaseFolder . "*" , D 
        {
            if(AddonSettings := this.CheckIfAddon(AddonBaseFolder,A_LoopFileName)){
                this.Add(AddonSettings)
            }
        }
    }

    ; Generatates the Include File for the addons that need to be loaded
    ; Parameters: none
    ; Result : object this.AddonSettings  
    GenerateIncludeFile(){
        IncludeFile := this.GeneratedAddonIncludeFile
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
        g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, this.AddonSettings)
        this.GenerateIncludeFile()
        MsgBox, 36, Restart, To make change to addon loading\deloading active you do need to restart the script.`nDo you want to do this now?
        IfMsgBox, Yes
            Reload
    }

    FirstRunCheck()
    {
        if(!FileExist(this.GeneratedAddonIncludeFile))
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
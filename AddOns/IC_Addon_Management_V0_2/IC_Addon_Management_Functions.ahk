; functions to be added




Class AddonManagement
{
    Addons := []
    AddonSettings := []
    AddonOrder := []
    AddonManagementConfigFile := A_LineFile . "\..\AddonManagement.json"
    GeneratedAddonIncludeFile := A_LineFile . "\..\..\GeneratedAddonInclude.ahk"

    Add(AddonSettings){
        Addon := new Addon(AddonSettings)
        this.Addons.Push(Addon)
    }

    CheckDependenciesEnabled(Name, Version){
        for k,v in this.Addons {
            if (v.Name=Name AND v.Version=Version){
                ; Check the dependencies
                for i, j in v.Dependencies{
                    ;First check if the dependencies DepExists
                    DependancieFound:=0
                    for y,z in this.Addons {
                        if(z.Name = j.Name AND z.Version = j.Version){
                            ; Check if the dependencie is enabled
                            DependancieFound:=1
                            if (!z.Enabled){
                                MsgBox, 52, Warning, % "Addon " . j.Name . " is required by " . v.Name . " but is disabled!`ndo you want to Enable this addon?`nYes: enable " . j.Name . "`nNo: disable " . v.Name
                                IfMsgBox Yes 
                                {
                                    this.EnableAddon(j.Name,j.Version)
                                }
                                Else
                                {
                                    this.DisableAddon(v.Name,v.Version)
                                }
                                this.WriteAddonManagementSettings()
                            }
                            else{
                                break
                            }
                        }
                    }
                    if(DependancieFound){
                        if(k<y){
                            this.SwitchOrderAddons(k,y)
                            this.GenerateListViewContent("ICScriptHub", "AddonsAvailableID")
                        }
                    }
                    else{
                        MsgBox, 48, Warning, % "Can't find the addon " . j.Name . " required by " . v.Name . "`n" . v.Name . " will be disabled"
                        this.DisableAddon(v.Name,v.Version)
                        this.WriteAddonManagementSettings()
                        return 0
                    }
                }
            }
        }
        return 1
    }

    CheckIsDependedOn(Name,Version){
        for k,v in this.Addons{
            for i,j in v.Dependencies{
                if (j.Name = Name AND j.Version = Version) {
                    ;We have a addon who depends on the name, now check it it's enabled
                    if(this.Addons[k]["Enabled"]){
                        return k
                    }
                }
            }
        }
        return 0
    }

    CheckDependencieOrder(AddonNumber,PositionWanted){
        if(AddonNumber > PositionWanted){
            ; moving Up
            LoopCounter:=PositionWanted
            for k, v in this.Addons[AddonNumber]["Dependencies"]{
                while(LoopCounter<AddonNumber){
                    if(v.Name=this.Addons[Loopcounter]["Name"] AND v.Version=this.Addons[Loopcounter]["Version"]){
                        Return 0
                    }
                    ++LoopCounter
                }
            }
            Return 1
        }
        else if(AddonNumber<PositionWanted){
            ; moving down
            LoopCounter:=AddonNumber+1
            While(LoopCounter<=PositionWanted){
                for k, v in this.Addons[LoopCounter]["Dependencies"]{
                    if(this.Addons[AddonNumber]["Name"]=v.Name AND this.Addons[AddonNumber]["Version"]=v.Version){
                        return k
                    }
                }
                ++LoopCounter
            }
            return 0
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
    ; Parameters:   Name: the name of the addon
    ;               Version: the version of the addon
    DisableAddon(Name, Version){
        if(Name!="Addon Management" AND Name != "Briv Gem Farm"){
            if (DependendAddon := this.CheckIsDependedOn(Name,Version)){
                MsgBox, 48, Warning, % "Addon " . this.Addons[DependendAddon]["Name"] . " needs this addon, can't disable"

            }
            else{
                    for k, v in this.Addons {
                    if (v.Name=Name AND v.Version=Version){
                        v.disable()
                        break
                    }
                }
            }

        }
        else{
            MsgBox, 48, Warning, Can't disable the Addon Manager or Briv Gem Farm
        }
    }

    ; Enable an addon in the addonsettings, will only be persisting if combined with WriteAddonManagementSettings()
    ; Parameters:   Name: the name of the addon
    ;               Version: the version of the addon
    EnableAddon(Name, Version){
        ; Check if another version is allready enabled
        for k,v in this.Addons {
            if(v.Name = Name AND v.Version != Version AND v.Enabled){
                MsgBox, 48, Warning, Another version of this script is allready enabled, please disable that addon first!
                return
            }
        }
        if(this.CheckDependenciesEnabled(Name,Version)){
            for k, v in this.Addons {
                if (v.Name=Name AND v.Version=Version){
                    v.enable()
                    break
                }
            }
        }

    }

    ; Get the parameters of the addons to load
    ; Parameters: none
    GetAddonManagementSettings(){
        ; If the file does not exist we should create it with the default settings
        if(!FileExist(this.AddonManagementConfigFile)) {
            ; Here we load the Addons that are required on first startup
            ;EnabledAddons:=[]
            ;EnabledAddons["Addon Management"]:=[]
            ;EnabledAddons["Addon Management"]:=Object("Version","v0.2.","Enabled",1)
            EnabledAddons:=Object("Addon Management",Object("Version","v0.2.","Enabled",1),"Briv Gem Farm",Object("Version","v1.0.","Enabled",1))
            g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, EnabledAddons)
            this.GenerateIncludeFile()
        }
        ; here we will enable all addons that needed to be added
        AddonSettings:= g_SF.LoadObjectFromJSON(this.AddonManagementConfigFile)
        for k,v in AddonSettings {
            if (k = "Addon Order"){
                this.AddonOrder := v
            }
            else {
                if (v.Enabled){
                    this.EnableAddon(k,v.Version)
                }     
            }
        }

        if(IsObject(this.AddonOrder)){
            for k, v in this.AddonOrder {
                ; Search for the correct Addon
                for i, j in this.Addons{
                    if(j.Name=v.Name AND j.Version=v.Version){
                        ; put the addons in order
                        if (k<>i){
                            this.SwitchOrderAddons(i,k)
                        }
                    }
                }
            }
        }
        
    }

    SwitchOrderAddons(AddonNumber,Position){
        if(this.CheckDependencieOrder(AddonNumber,Position)){
            NumberOfAddons:=this.Addons.Count()
            temp:=this.Addons[AddonNumber]
            if(AddonNumber > Position){
                Loopnumber := AddonNumber
                While(Loopnumber > Position) {
                    this.Addons[Loopnumber]:=this.Addons[Loopnumber-1]
                    --Loopnumber
                }
            }
            else if(AddonNumber < Position){
                Loopnumber := AddonNumber
                While(Loopnumber < Position) {
                    this.Addons[Loopnumber]:=this.Addons[Loopnumber+1]
                    ++Loopnumber
                }
            }
            this.Addons[Position]:=temp
            return 1
        }
        else{
            return 0
        }
    }

    ; Get a list of all available addons in the Addon folder
    ; Parameters: none
    ; Result : object this.Addons 
    GetAvailableAddons(){
        Loop, Files, % g_AddonFolder . "*" , D 
        {
            if(AddonSettings := this.CheckIfAddon(g_AddonFolder,A_LoopFileName)){
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
            if (v.Enabled AND v.Name != "Addon Management"){
                IncludeLine := "#include *i " . g_AddonFolder . v.Dir . "\" . v.Includes
                FileAppend, %IncludeLine%`n, %IncludeFile%
            }
        }
    }


    GenerateListViewContent(GuiWindowName, ListViewName){
        Gui, %GuiWindowName%:ListView, %ListViewName%
        LV_Delete()
        for k,v in this.Addons {
            IsEnabled := v["Enabled"] ? "yes" : "no"
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
        ; Get the order of the Addons
        Gui, ICScriptHub:ListView, AddonsAvailableID
        Order:=[]
        Loop % LV_GetCount()
        {
            LV_GetText(AddonName, A_Index , 2)
		    LV_GetText(AddonVersion, A_Index , 3)
            Order.Push(Object("Name",AddonName,"Version",AddonVersion))
        }
        this.AddonOrder:=Order
        EnabledAddons:=[]
        for k,v in this.Addons{
            if (v.Enabled){
                EnabledAddons[v.Name]:=[]
                EnabledAddons[v.Name]:=Object("Version",v.Version,"Enabled",1)
            }
        }

        ThingsToWrite:=EnabledAddons
        ThingsToWrite["Addon Order"]:=Order
        g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, ThingsToWrite)
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
    Enabled := 

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
            this.Enabled := 0
        }
    }
    enable(){
        this.Enabled := 1
    }
    disable(){
        this.Enabled := 0
    }
}
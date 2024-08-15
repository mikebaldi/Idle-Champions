    ; ############################################################
    ;                   Class AddonManagement
    ; ############################################################
Class AddonManagement
{
    ; ############################################################
    ;                        Variables
    ; ############################################################
    ; Addons
    ;   Object containing all addons
    ; AddonOrder
    ;   Object containing the order in which de addons need to be loaded
    ; EnabledAddons
    ;   Object containing a list of addons that should be enabled
    ; NeedSave
    ;   Boolean for whether the gui and settings file need to be updated
    ; AddonManagementConfigFile
    ;   Link to the AddonManagement configuration File
    ; GeneratedAddonIncludeFile
    ;   Link to the GeneratedAddonInclude File    
    Addons := []
    AddonOrder := []
    EnabledAddons := []
    NewerEnabledAddons := {}
    NeedSave := 0
    AddonManagementConfigFile := A_LineFile . "\..\AddonManagement.json"
    GeneratedAddonIncludeFile := A_LineFile . "\..\..\GeneratedAddonInclude.ahk"

    ; ############################################################
    ;                        Functions
    ; ############################################################

    ; ------------------------------------------------------------
    ;   
    ;     Function: Add(AddonSettings)
    ;               Adds an Addon to the Addons object
    ;   Parameters: Object containing Addon settings
    ; Side Effects: Updates the Addons object
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    Add(AddonSettings)
    {
        Addon := new Addon(AddonSettings)
        this.Addons.Push(Addon)
    }
    ; ------------------------------------------------------------
    ;   
    ;   Function: BuildToolTips()
    ;               Adds tooltips to objects in the addon.
    ; Parameters: None
    ;     Return: None
    ;
    ; ------------------------------------------------------------
    BuildToolTips()
    {
        GUIFunctions.AddToolTip("AddonOpenGUIClickedButton", "AddOns")
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: CheckDependenciesEnabled(Name, Version)
    ;               Checks if the Dependencies of an addon are enabled
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return:  true: All dependencies are enabled
    ;             false: One or more dependencies are not enabled
    ;                
    ;       Note: The function will ask to enable disabled dependencies
    ;
    ; ------------------------------------------------------------
    CheckDependenciesEnabled(Name, Version, byref isModified := false)
    {
        currAddon := this.GetAddon(Name, Version, indexOfAddon)
        subDependiciesEnabled := True
        ; Check the dependencies
        for k,v in currAddon.Dependencies
        {
            ; Check if dependency is installed
            currDependency := this.GetAddon(v.Name, v.Version, indexODependency)
            if (!IsObject(currDependency))
            {
                MsgBox, 48, Warning, % "Can't find the addon """ . v.Name . " " . v.Version . """ required by " . Name . "`n" . Name . " will be disabled."
                this.DisableAddon(Name,Version)
                return false
            }
            ; Force correct dependency load order.
            if(IsObject(currDependency) AND indexOfAddon < indexOfDependency)
            {
                this.SwitchOrderAddons(indexOfAddon,indexOfDependency, true)
                isModified := true
            }      
            ; Check if current version or newer dependency is enabled
            if (!currDependency.Enabled)
            {
                MsgBox, 52, Warning, % "Addon " . currDependency.Name . " is required by " . currAddon.Name . " but is disabled!`nDo you want to Enable this addon?`nYes: Enable " . currDependency.Name . "`nNo: Disable " . Name
                IfMsgBox Yes 
                {
                    isEnabled := this.EnableAddon(currDependency.Name,currDependency.Version)
                    isModified := isEnabled OR isModified
                }
                else
                {
                    this.DisableAddon(Name,Version)
                    return false
                }
            }
            ; Check sub-dependencies
            subDependiciesEnabled := this.CheckDependenciesEnabled(currDependency.Name, currDependency.Version, isModified) AND subDependiciesEnabled
            if (subDependiciesEnabled == false)
                return false  
        }
        return true
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: CheckIsDependedOn(Name,Version)
    ;               Checks if an enabled Addon is depending on the given addon
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return: index of dependent if Addon is required by another enabled addon
    ;             0: Addon is not required by another enabled addon
    ;
    ; ------------------------------------------------------------
    CheckIsDependedOn(Name,Version){
        ; Test for exact match
        for addonIndex,addonObject in this.Addons{
            for dependencyIndex,dependencyObject in addonObject.Dependencies{
                if (dependencyObject.Name == Name AND dependencyObject.Version = Version) {
                    ;We have a addon who depends on the name, now check it it's enabled
                    if(this.Addons[addonIndex]["Enabled"]){
                        return addonIndex
                    }
                    else{
                        break
                    }
                }
            }
        }
        ; test for higher version 
        for addonIndex,addonObject in this.Addons{
            for dependencyIndex,dependencyObject in addonObject.Dependencies{
                if (dependencyObject.Name == Name AND SH_VersionHelper.IsVersionSameOrNewer(Version, dependencyObject.Version)) {
                    ;We have a addon who depends on the name, now check it it's enabled
                    if(this.Addons[addonIndex]["Enabled"]){
                        return addonIndex
                    }
                }
            }
        }
        return false
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: CheckDependencyOrder(AddonNumber,PositionWanted)
    ;               Checks if an addon can be moved to the wanted position.
    ;               As an addon that requires another addon needs to be loaded after the dependency
    ; Parameters:    AddonNumber: Key of the addon in object Addons
    ;             PositionWanted: Position wanted in the object Addons
    ;     Return: <number>: Key of addon that is the problem
    ;             0: No problem
    ;
    ; ------------------------------------------------------------
    CheckDependencyOrder(AddonNumber,PositionWanted)
    {
        ; Check to make sure none of this addon's dependencies are before it
        for k, v in this.Addons[AddonNumber]["Dependencies"]
        {
            this.GetAddon(v.Name, v.Version, indexOfDependency)
            if(indexOfDependency >= PositionWanted)
                return indexOfDependency
        }
        ; Check to make sure this addon is not after any addons that depend on it 
        for k,v in this.AddonsEnabled
        {
            for _, dependency in v.Dependencies 
            {
                if(this.Addons[AddonNumber]["Name"] == dependency.Name AND SH_VersionHelper.IsVersionSameOrNewer(this.Addons[AddonNumber]["Version"], dependency.Version))
                    if (k <= PositionWanted)
                        return k
            }
        }
        return 0
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: CheckIfAddon(AddonBaseFolder,AddonFolder)
    ;               Checks if an folder contains an addon by looking for the addon.json file
    ; Parameters: AddonBaseFolder: Base folder where the addons are stored
    ;                 AddonFolder: Folder where the addon is stored
    ;     Return: Object containing the settings from the addon.json file
    ;             0: Valid addon not found
    ;
    ; ------------------------------------------------------------
    CheckIfAddon(AddonBaseFolder,AddonFolder)
    {
        if (!FileExist(AddonBaseFolder . AddonFolder . "\Addon.json"))
            return 0
        AddonSettings := g_SF.LoadObjectFromJSON(AddonBaseFolder . AddonFolder . "\Addon.json")
        ; check if the needed settings are in the addon.json
        if (!AddonSettings["Name"] OR !AddonSettings ["Version"])
            return 0
        AddonSettings["Dir"] := AddonFolder
        return AddonSettings
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: DisableAddon(Name, Version)
    ;               Disables the given addon
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return: Disables in the addon in the Addons object
    ;
    ; ------------------------------------------------------------
    DisableAddon(Name, Version)
    {
        if (Name=="Addon Management")
        {
            MsgBox, 48, Warning, Can't disable the Addon Manager.
            return
        }
        while(DependedAddon := this.CheckIsDependedOn(Name,Version))
        {
            MsgBox, 52, Warning, % "Addon " . this.Addons[DependedAddon]["Name"] . " needs " . Name . ".`nDo you want to disable this addon?`nYes: Disable " . this.Addons[DependendAddon]["Name"] . "`nNo: Keep " . Name . " enabled."
            IfMsgBox Yes 
            {
                this.DisableAddon(this.Addons[DependedAddon]["Name"],this.Addons[DependedAddon]["Version"])
            }
            else
            {
                return 
            }               
        }
        for k, v in this.Addons 
        {
            if (v.Name=Name AND v.Version=Version)
            {
                this.NeedSave:=1
                v.disable()
                break
            }
        }
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: EnableAddon(Name, Version)
    ;               Enables the given addon
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return: 
    ;              1: if enabled without issue
    ;              0: if enabled addons needed to be modified
    ; Side Effects: Enables in the addon in the Addons object
    ;
    ; ------------------------------------------------------------
    EnableAddon(Name, byref Version)
    {
        isNewer := false
        ; Check if another version is allready enabled
        for k,v in this.Addons 
        {
            if(v.Name = Name AND v.Version != Version AND v.Enabled)
            {
                MsgBox, 48, Warning, % "Another version of " . v.Name . " is already enabled, please disable that addon first!"
                return 1
            }
        }
        currAddon := this.GetAddon(Name, Version, indexOfAddon)
        isNewer := (SH_VersionHelper.IsVersionSameOrNewer(currAddon.Version, Version) == -1)
        if(isNewer)
            Version := currAddon.Version
        lastSwap := 0
        ; Force enable dependency before enabling this addon.
        while(IsObject(currAddon) AND indexOfSwap := this.CheckDependencyOrder(indexOfAddon,indexOfAddon))
        {
            this.SwitchOrderAddons(indexOfSwap, indexOfAddon, true)
            lastSwap := indexOfSwap
        }
        if(lastSwap) ; If dependency was required, enable dependency
            isNewer := (this.EnableAddon(this.Addons[lastSwap].Name, this.Addons[lastSwap].Version) == -1) OR isNewer
        if(IsObject(currAddon) AND this.CheckDependenciesEnabled(Name, Version, isModified))
        {
            this.NeedSave:=1
            currAddon.enable()
        }
        if(isModified)
            this.NeedSave:=1
        return isNewer
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: GetAddonManagementSettings()
    ;               Reads settings from configuration file if available.
    ;   Parameters: None
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    GetAddonManagementSettings()
    {
        forceType := 0
        ; If the file does not exist we should create it with the default settings
        if(!FileExist(this.AddonManagementConfigFile)) 
        {
            ; Here we load the Addons that are required on first startup
            startupAddons := []
            startupAddons.Push(Object("Name","Addon Management","Version","v1.0."))
            startupAddons.Push(Object("Name","IC Core","Version","v.1."))
            this.EnabledAddons := startupAddons 
            ; this.EnabledAddons := [Object("Name","Addon Management","Version","v1.0."),Object("Name","Briv Gem Farm","Version","v1.0."),Object("Name","Game Location Settings","Version","v0.1.")]
            forceType := 2
        }
        ; enable all addons that needed to be added
        AddonSettings:= g_SF.LoadObjectFromJSON(this.AddonManagementConfigFile)
        this.AddonOrder := AddonSettings["Addon Order"]
        ; Update old settings if needed.
        if(AddonSettings["Enabled Addons"] == "" AND forceType != 2)
        {
            this.UpdateFromOldSettings(AddonSettings)
            forceType := 2
        }
        ; Check if all addons in Addon Order are still available
        For k,v in this.AddonOrder
        {
            this.GetAddon(v.Name, v.Version, indexOfAddon)
            if(!indexOfAddon)
                this.AddonOrder.RemoveAt(k, 1)
        }
        ; Order addons
        this.OrderAddons()
        ; Enable addons
        this.EnabledAddons := IsObject(AddonSettings["Enabled Addons"]) ? AddonSettings["Enabled Addons"] : this.EnabledAddons
        for k, v in this.EnabledAddons
        {
            versionValue := v.Version
            isNewer := this.EnableAddon(v.Name, versionValue)
            v.version := versionValue
            if(isNewer)
            {
                this.NewerEnabledAddons.Push(v.Clone())
                forceType := 1
            }
        }
        if (!FileExist(this.GeneratedAddonIncludeFile) or forceType == 2)
            this.GenerateIncludeFile() 
        this.ForceWrite(forceType)
    }

    ForceWrite(forceType)
    {
        if(forceType == 1 AND this.NewerEnabledAddons.Length() > 0)
        {
            this.ForceWriteSettings()
            updatedAddonsString := "The following addons have been updated and the new version has been enabled:"
            for k,v in this.NewerEnabledAddons
            {
                updatedAddonsString .= "`n" . v.Name . " " . v.Version 
            }
            MsgBox, % updatedAddonsString
        }
        if(forceType == 2)
        {
            this.ForceWriteSettings()
            MsgBox, 36, Restart, Your settings file has been updated. `nIC Script Hub may need to reload. `nDo you wish to reload now?
            IfMsgBox, Yes
                Reload
        }
        
    }

    ForceWriteSettings()
    {
            configuration := {}
            configuration["Enabled Addons"] := this.EnabledAddons
            configuration["Addon Order"] := {}
            for k,v in this.Addons
                configuration["Addon Order"].Push(Object("Name", v.Name, "Version",v.Version))
            g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, configuration)
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: UpdateFromOldSettings(AddonSettings)
    ;               Converts old settings file to new one.
    ;   Parameters: AddonSettings: Configuration from old settings file.
    ;       Return: newSettings: New configuration file.
    ; Side Effects: this.EnabledAddons will be updated.
    ;               Configuration file will be written.
    ;
    ; ------------------------------------------------------------
    UpdateFromOldSettings(AddonSettings)
    {
        newSettings := []
        for k,v in AddonSettings
            if(k != "Addon Order")
                newSettings.Push(Object("Name",k,"Version",v.Version))
        this.EnabledAddons := newSettings
        fileSettings := Object("Addon Order", AddonSettings["Addon Order"], "Enabled Addons", newSettings)
        g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, fileSettings)
        return newSettings
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: OrderAddons()
    ;               Updates Addons class variable based on AddonOrder
    ;   Parameters: None
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    OrderAddons()
    {
        for k, v in this.AddonOrder 
        {
            ; Search for the correct Addon
            this.GetAddon(v.Name, v.Version, addonIndex) 
            ; put the addons in order
            if (k != addonIndex)
                this.SwitchOrderAddons(addonIndex,k, true)
        }
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: SwitchOrderAddons(AddonNumber,Position)
    ;               Tries to switch the given addon to the position wanted
    ;               The function will check for dependencies
    ; Parameters: AddonNumber: key of the addon in Object Addons to move
    ;                Position: Postition where we want the Addon to get
    ;     Return: Moves the Addons to wanted position if possible
    ;
    ; ------------------------------------------------------------
    SwitchOrderAddons(AddonNumber,Position, Force := false)
    {
        ; If can't rearrange due to dependencies, return false
        if (this.CheckDependencyOrder(AddonNumber,Position) AND !Force)
            return false
        NumberOfAddons := this.Addons.Count()
        temp := this.Addons[Position]
        this.Addons[Position] := this.Addons[AddonNumber]
        this.Addons[AddonNumber] := temp
        return true
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: GetAvailableAddons()
    ;               Fills the object Addons with all available addons
    ; Parameters: none
    ;     Return: object Addons
    ;
    ; ------------------------------------------------------------
    GetAvailableAddons()
    {
        Loop, Files, % g_AddonFolder . "*" , D 
        {
            if(AddonSettings := this.CheckIfAddon(g_AddonFolder,A_LoopFileName))
            {
                this.Add(AddonSettings)
            }
        }
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: GenerateIncludeFile()
    ;               Generates the include files for the enabled addons in the addons object
    ; Parameters: none
    ;     Return: Generated include file
    ;
    ; ------------------------------------------------------------
    GenerateIncludeFile()
    {
        generatedText := "; Automatically generated by Addon Management`n"
        for k,v in this.Addons 
            if (v.Enabled)
                generatedText .= "#include *i %A_LineFile%\..\" . v.Dir . "\" . v.Includes . "`n"
        IncludeFile := this.GeneratedAddonIncludeFile
        if(!FileExist(IncludeFile))
        {
            FileAppend, %generatedText%, %IncludeFile%
            MsgBox, 36, Restart, This looks like your first time running Script Hub. `nSettings have been updated. `nDo you wish to reload now?
            IfMsgBox, Yes
                Reload
        }
        else
        {
            FileDelete, %IncludeFile%
            FileAppend, %generatedText%, %IncludeFile%
        }
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: GenerateListViewContent(GuiWindowName, ListViewName)
    ;               Generates the contents of a ListView
    ; Parameters: GuiWindowName : Windowname of the parent window of the listvies
    ;              ListViewName : Name of the ListView object
    ;     Return: Generates the content of the listview
    ;
    ; ------------------------------------------------------------
    GenerateListViewContent(GuiWindowName, ListViewName)
    {
        oldGUI := A_DefaultGui
        Gui, %GuiWindowName%:Default
        Gui, %GuiWindowName%:ListView, ahk_id %ListViewName%
        test := LV_Delete()
        for k,v in this.Addons 
        {
            IsEnabled := v["Enabled"] ? "yes" : "no"
            LV_Add( , IsEnabled, v.Name, v.Version, v.Dir)
        }
        loop, 4
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        Gui, %oldGUI%:Default
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: ShowAddonIfno(AddonNumber)
    ;               Shows a GUI window with addon details listed
    ;   Parameters: AddonNumber: The index of the addon in Addons class member
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    ShowAddonInfo(AddonNumber)
    {
        Addon := this.Addons[AddonNumber]
        GuiControl, AddonInfo: , AddonInfoNameID, % Addon.Name
        GuiControl, AddonInfo: , AddonInfoFoldernameID, % Addon.Dir
        GuiControl, AddonInfo: , AddonInfoVersionID, % Addon.Version
        GuiControl, AddonInfo: , AddonInfoUrlID, % Addon.Url
        GuiControl, AddonInfo: , AddonInfoAuthorID, % Addon.Author
        GuiControl, AddonInfo: , AddonInfoInfoID, % Addon.Info
        DependenciesText := ""
        for k,v in Addon.Dependencies {
            DependenciesText .= "- " . v.Name . ": " . v.Version "`n"
        }
        GuiControl, AddonInfo: , AddonInfoDependenciesID, % DependenciesText
        Gui, AddonInfo:Show
        GUIFunctions.UseThemeTitleBar("AddonInfo")
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: WriteAddonManagementSettings()
    ;               Outputs configuration settings to file.
    ;   Parameters: None
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    WriteAddonManagementSettings()
    {
        ; Get the order of the Addons
        Gui, AddonManagement:ListView, AddonsAvailableID
        Order := []
        Loop % LV_GetCount()
        {
            LV_GetText(AddonName, A_Index , 2)
		    LV_GetText(AddonVersion, A_Index , 3)
            Order.Push(Object("Name",AddonName,"Version",AddonVersion))
        }
        this.AddonOrder := Order
        EnabledAddons := []
        for k,v in this.Addons
            if (v.Enabled)
                EnabledAddons.Push(Object("Name", v.Name, "Version",v.Version))
        ThingsToWrite := {}
        ThingsToWrite["Enabled Addons"] := EnabledAddons
        ThingsToWrite["Addon Order"] := Order
        g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, ThingsToWrite)
        this.GenerateIncludeFile()
    }
    ; ------------------------------------------------------------
    ;   
    ;     Function: GetAddon(Name, Version, i)
    ;               Finds the matching addon or the first instance of an addon that matches the name and minimum version.
    ;   Parameters: Name: Target addon name
    ;            Version: Target addon version
    ;                  i: Output variable containing index of addon if found
    ;       Return: None
    ;
    ; ------------------------------------------------------------
    GetAddon(Name, Version, byref i := "")
    {
        ; try to find exact match
        for k,v in this.Addons
        {
            if (v.Name == Name AND v.Version == Version)
            {
                i := k
                return v
            }
        }
        ; try to higher version match
        for k,v in this.Addons
        {
            if (v.Name == Name AND SH_VersionHelper.IsVersionSameOrNewer(v.Version,Version))
            {
                i := k
                return v
            }
        }
        ; failed to match
        i := ""
        return ""
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
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
    ;   Object containing the oder in which de addons need to be loaded
    ; AddonManagementConfigFile
    ;   Link to the AddonManagement Configuration File
    ; GeneratedAddonIncludeFile
    ;   Link to the GeneratedAddonInclude File    
    Addons := []
    AddonOrder := []
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
                MsgBox, 48, Warning, % "Can't find the addon " . currDependency.Name . " required by " . Name . "`n" . Name . " will be disabled."
                this.DisableAddon(Name,Version)
                return false
            }
            ; Force correct dependency load order.
            if(IsObject(currDependency) AND indexOfAddon < indexOfDependency)
            {
                this.SwitchOrderAddons(indexOfAddon,indexOfDependency)
                isModified := true
            }      
            ; Check if current version or newer dependency is enabled
            if (!currDependency.Enabled)
            {
                MsgBox, 52, Warning, % "Addon " . currDependency.Name . " is required by " . currAddon.Name . " but is disabled!`nDo you want to Enable this addon?`nYes: Enable " . currDependency.Name . "`nNo: Disable " . Name
                IfMsgBox Yes 
                {
                    this.EnableAddon(currDependency.Name,currDependency.Version)
                    isModified := true
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
    ;     Return: 1: Addon is required by another enabled addon
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
                if (dependencyObject.Name == Name AND IC_VersionHelper_class.IsVersionSameOrNewer(dependencyObject.Version, Version)) {
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
    ;   Function: CheckDependencieOrder(AddonNumber,PositionWanted)
    ;               Checks if an addon can be moved to the wanted position.
    ;               As an addon that requires another addon needs to be loaded after the dependency
    ; Parameters:    AddonNumber: Key of the addon in object Addons
    ;             PositionWanted: Position wanted in the object Addons
    ;     Return: <number>: Key of addon that is the problem
    ;             0: No problem
    ;
    ; ------------------------------------------------------------
    CheckDependencieOrder(AddonNumber,PositionWanted){
        if(AddonNumber > PositionWanted){
            ; moving Up
            for k, v in this.Addons[AddonNumber]["Dependencies"]{
                LoopCounter:=PositionWanted
                while(LoopCounter<AddonNumber){
                    if(v.Name=this.Addons[Loopcounter]["Name"] AND IC_VersionHelper_class.IsVersionSameOrNewer(this.Addons[Loopcounter]["Version"], v.Version)){
                        Return Loopcounter
                    }
                    ++LoopCounter
                }
            }
            Return 0
        }
        else if(AddonNumber<PositionWanted){
            ; moving down
            LoopCounter:=AddonNumber+1
            While(LoopCounter<=PositionWanted){
                for k, v in this.Addons[LoopCounter]["Dependencies"]{
                    if(this.Addons[AddonNumber]["Name"]=v.Name AND IC_VersionHelper_class.IsVersionSameOrNewer(this.Addons[AddonNumber]["Version"], v.Version)){
                        return k
                    }
                }
                ++LoopCounter
            }
            return 0
        }

    }
    ; ------------------------------------------------------------
    ;
    ;   Function: CheckIfAddon(AddonBaseFolder,AddonFolder)
    ;               Checks if an folder contains an addon by looking for the addon.json file
    ; Parameters: AddonBaseFolder: Base folder where the addons are stored
    ;                 AddonFolder: Folder where the addon is stored
    ;     Return: Object containing the settings from the addon.json file
    ;             0: Folder not found
    ;
    ; ------------------------------------------------------------
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
    ; ------------------------------------------------------------
    ;
    ;   Function: DisableAddon(Name, Version)
    ;               Disables the given addon
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return: Disables in the addon in the Addons object
    ;
    ; ------------------------------------------------------------
    DisableAddon(Name, Version){
        if(Name!="Addon Management"){
            while(DependendAddon := this.CheckIsDependedOn(Name,Version)){
                MsgBox, 52, Warning, % "Addon " . this.Addons[DependendAddon]["Name"] . " needs " . Name . ".`nDo you want to disable this addon?`nYes: Disable " . this.Addons[DependendAddon]["Name"] . "`nNo: Keep " . Name . " enabled."
                IfMsgBox Yes 
                {
                    this.DisableAddon(this.Addons[DependendAddon]["Name"],this.Addons[DependendAddon]["Version"])
                }
                Else
                {
                    return 
                }               
            }
            ;if (DependendAddon := this.CheckIsDependedOn(Name,Version)){
            ;    MsgBox, 48, Warning, % "Addon " . this.Addons[DependendAddon]["Name"] . " needs this addon, can't disable."
            ;}
            ;else{
                    for k, v in this.Addons {
                    if (v.Name=Name AND v.Version=Version){
                        this.NeedSave:=1
                        v.disable()
                        break
                    }
                }
            ;}

        }
        else{
            MsgBox, 48, Warning, Can't disable the Addon Manager.
        }
    }
    ; ------------------------------------------------------------
    ;
    ;   Function: EnableAddon(Name, Version)
    ;               Enables the given addon
    ; Parameters:    Name: Name of the addon as defined in the Addon.json
    ;             Version: Version of the addon as defined in the Addon.json
    ;     Return: Enables in the addon in the Addons object
    ;
    ; ------------------------------------------------------------
    EnableAddon(Name, Version){
        ; Check if another version is allready enabled
        for k,v in this.Addons {
            if(v.Name = Name AND v.Version != Version AND v.Enabled){
                MsgBox, 48, Warning, % "Another version of " . v.Name . " is already enabled, please disable that addon first!"
                return
            }
        }
        versionFound := false
        isModified := false
        if(this.CheckDependenciesEnabled(Name,Version)){
            if(isModified)
                this.GenerateListViewContent("AddonManagement", "AddonsAvailableID")
            for k, v in this.Addons {
                if (v.Name=Name AND v.Version=Version){
                    versionFound := true
                    this.NeedSave:=1
                    v.enable()
                    break
                }
            }
            ; if didn't find exact match, find first fit
            if(!versionFound)
            {
                for k, v in this.Addons {
                    ; Enable if version > version being checked.
                    if (v.Name=Name AND IC_VersionHelper_class.IsVersionSameOrNewer(v.Version, Version)){
                        versionFound := true
                        this.NeedSave:=1
                        v.enable()
                        break
                    }
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
            EnabledAddons:=Object("Addon Management",Object("Version","v1.0.","Enabled",1),"Briv Gem Farm",Object("Version","v1.0.","Enabled",1),"Game Location Settings",Object("Version","v0.1.","Enabled",1))
            g_SF.WriteObjectToJSON(this.AddonManagementConfigFile, EnabledAddons)
        }
        ; here we will enable all addons that needed to be added
        AddonSettings:= g_SF.LoadObjectFromJSON(this.AddonManagementConfigFile)
        this.AddonOrder := AddonSettings["Addon Order"]
        if (IsObject(this.AddonOrder)){
            for k, v in this.AddonOrder {
                if (AddonSettings[v.Name].Enabled){
                    this.EnableAddon(v.Name,v.Version)
                }
            }
        }
        else{
            for k,v in AddonSettings {
                if (v.Enabled){
                    this.EnableAddon(k,v.Version)
                }
            }
        }

        ; Check if all addons in Addon Order are still available
        For k,v in this.AddonOrder{
            FoundAddon:=0
            for i, j in this.Addons{
                if(j.Name=v.Name AND j.Version=v.Version){
                    FoundAddon:=1
                    break
                }
            }
            if(!FoundAddon){
                NumberOfAddons:=this.AddonOrder.Count()             
                While(k<NumberOfAddons){
                    this.AddonOrder[k]:=this.AddonOrder[k+1]
                    ++k
                }
                this.AddonOrder.Delete(NumberOfAddons)
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
        if(!FileExist(this.GeneratedAddonIncludeFile))
        {
            this.GenerateIncludeFile() 
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
    SwitchOrderAddons(AddonNumber,Position){
        if(!this.CheckDependencieOrder(AddonNumber,Position)){
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
    ; ------------------------------------------------------------
    ;
    ;   Function: GetAvailableAddons()
    ;               Fills the object Addons with all available addons
    ; Parameters: none
    ;     Return: object Addons
    ;
    ; ------------------------------------------------------------
    GetAvailableAddons(){
        Loop, Files, % g_AddonFolder . "*" , D 
        {
            if(AddonSettings := this.CheckIfAddon(g_AddonFolder,A_LoopFileName)){
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
    GenerateIncludeFile(){
        if(!FileExist(this.GeneratedAddonIncludeFile))
        {
            FirstRun:=1
        }
        IncludeFile := this.GeneratedAddonIncludeFile
        IfExist, %IncludeFile%
            FileDelete, %IncludeFile%
        FileAppend, `;Automatic generated by Addon Management`n, %IncludeFile%
        for k,v in this.Addons {
            if (v.Enabled AND v.Name != "Addon Management"){
                IncludeLine := "#include *i %A_LineFile%\..\" . v.Dir . "\" . v.Includes
                FileAppend, %IncludeLine%`n, %IncludeFile%
            }
        }
        if(FirstRun){
            MsgBox, 36, Restart, This looks like your first time running Script Hub. `nSettings have been updated. `nDo you wish to reload now?
            IfMsgBox, Yes
                Reload
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
            DependenciesText .= "- " . v.Name . ": " . v.Version "`n"
        }
        GuiControl, AddonInfo: , AddonInfoDependenciesID, % DependenciesText
        Gui, AddonInfo:Show
        GUIFunctions.UseThemeTitleBar("AddonInfo")
    }

    WriteAddonManagementSettings(){
        ; Get the order of the Addons
        Gui, AddonManagement:ListView, AddonsAvailableID
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
        MsgBox, 36, Restart, To activate changes to enabled/disabled addons you need to restart the script.`nDo you want to do this now?
        IfMsgBox, Yes
            Reload
    }

    FirstRunCheck()
    {

    }

    ; Finds the matching addon or the first instance of an addon that matches the name and minimum version.
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
            if (v.Name == Name AND IC_VersionHelper_class.IsVersionSameOrNewer(v.Version,Version))
            {
                i := k
                return v
            }
        }
        ; failed to match
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
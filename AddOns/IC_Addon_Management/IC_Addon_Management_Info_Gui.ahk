AddonInfowColLeft:=70

Gui, AddonInfo:New , ,Addon info
GUIFunctions.LoadTheme("AddonInfo")
Gui, AddonInfo:+Resize -MaximizeBox
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()

Gui, AddonInfo:Font, w700
Gui, AddonInfo:Add, Text, x10 y10 w200 vAddonInfoNameID, Addon Name
Gui, AddonInfo:Font, w400

Gui, AddonInfo:Add, Text, vAddonInfoInfoID x5 y+5 w670 h50,

Gui, AddonInfo:Add, Text, x10 y+2 w%AddonInfowColLeft% Right, Version: 
Gui, AddonInfo:Add, Text, vAddonInfoVersionID x+2 w600,

Gui, AddonInfo:Add, Text, x10 y+5 w%AddonInfowColLeft% Right, Foldername: 
Gui, AddonInfo:Add, Text, vAddonInfoFoldernameID x+2 w600,

Gui, AddonInfo:Add, Text, x10 y+2 w%AddonInfowColLeft% Right, Url:
Gui, AddonInfo:Font, underline 
GUIFunctions.UseThemeTextColor("SpecialTextColor1", 600)
Gui, AddonInfo:Add, Text, gAddonInfoVisitUrl vAddonInfoUrlID x+2 w600,
GUIFunctions.UseThemeTextColor()
Gui, AddonInfo:Font, norm
Gui, AddonInfo:Add, Text, x10 y+2 w%AddonInfowColLeft% Right, Author: 
Gui, AddonInfo:Add, Text, vAddonInfoAuthorID x+2 w600,

Gui, AddonInfo:Add, Text, x10 y+10 w%AddonInfowColLeft% Right, Dependencies: 
Gui, AddonInfo:Add, Text, x20 y+2 vAddonInfoDependenciesID w600 h50,

AddonInfoVisitUrl(){
    GuiControlGet, UrlToRun, AddonInfo:, AddonInfoUrlID
    If RegExMatch(UrlToRun, "^(https?://|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$")
        Run % UrlToRun 
}

; Going back to the ICScripthub gui 
GUIFunctions.LoadTheme()
;Gui, ICScriptHub:Default
class GUIFunctions
{
    AddTab(Tabname){
        addedTabs := Tabname . "|"
        GuiControl,,ModronTabControl, % addedTabs
        g_TabList .= addedTabs
        ; Increase UI width to accommodate new tab.
        StrReplace(g_TabList,"|",,tabCount)
        g_TabControlWidth := Min(Max(Max(g_TabControlWidth,475), tabCount * 75), 550)
        GuiControl, Move, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
        Gui, show, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
    }
}
# Themes

Script Hub uses customizable themes. When building an addon, use of themes are available through the following functions.

- [Functions](#functions)
  - [**``GUIFunctions.LoadTheme(guiName)``**](#guifunctionsloadthemeguiname)
  - [**``GUIFunctions.UseThemeTextColor(textType, weight)``**](#guifunctionsusethemetextcolortexttype-weight)
  - [**``GUIFunctions.UseThemeBackgroundColor()``**](#guifunctionsusethemebackgroundcolor)
  - [**``GUIFunctions.UseThemeListViewBackgroundColor(controlID)``**](#guifunctionsusethemelistviewbackgroundcolorcontrolid)
  - [**``GUIFunctions.UseThemeTitleBar(guiName)``**](#guifunctionsusethemetitlebarguiname)
- [Other theme configuration settings:](#other-theme-configuration-settings)


# Functions

## **``GUIFunctions.LoadTheme(guiName, fileOverride)``**  
Use this function immediately after ``Gui, <GUIName>:New``.

This function loads the settings if they have not been previously loaded and sets tells the script which GUI to use for future functions.

``"guiName"`` (required unless default) is the name of the GUI (e.g. "ICScriptHub"). 

``"fileOverride"`` (optional) A theme json file location passed to the function will force the new theme to be used. 
> Note: When using ``fileOverride`` use a ``GuiFunctions.LoadTheme()`` when done to allow the rest of the script to use its own configuration.

## **``GUIFunctions.UseThemeTextColor(textType, weight)``**
Use this function before any text that needs coloring. 

``"textType"`` (optional) is which text in the theme's settings to use. Default themes have the following texts defined:

- ``DefaultTextColor``
- ``HeaderTextColor``
- ``WarningTextColor``
- ``ErrorTextColor``
- ``SpecialTextColor1``
- ``SpecialTextColor2``
- ``TableTextColor``
- ``InputBoxTextColor``

Passing no parameter or passing "default" will use the color defined in ``DefaultTextColor``.

``"weight"`` (optional) is how bold the text is.

## **``GUIFunctions.UseThemeBackgroundColor()``**
Use this function immediately after using ``LoadTheme()`` for the current GUI.

Tells the script to use the value of "WindowColor" as the background color of the window.

## **``GUIFunctions.UseThemeListViewBackgroundColor(controlID)``**
Use immediately after building a ListView in the script. ``UseThemeTextColor("TableTextColor")`` should be used immediately before building the ListView to compliment each other.

Tells the script to use the value of "TableBackgroundColor" to color a ListView's background. 

``"controlID"`` (required) is the variable name of the ListView control must be passed to the function.

## **``GUIFunctions.UseThemeTitleBar(guiName, refresh)``**
Use immediately after setting the ``Show`` property on the GUI (e.g. after ``Gui, ICScriptHub:Show``)

Sets the window title bar to dark if theme is a dark theme. 

``"guiName"`` (required) is the name of the GUI (e.g. "ICScriptHub").

> Note: Even though the GUIName is set with LoadTheme, this function still also requires it to be passed in otherwise it may show other GUIs that have loaded themes previously.  

``"refresh"`` (optional) by default the function shows/hides the GUI to make the bar correctly refresh colors. If a GUI is meant to remain hidden this should be set to false.
  
# Other theme configuration settings:

- ``UseDarkThemeGraphics`` - This setting lets the script know that various dark mode options should be used, such as using graphics fitting for dark themes and changing the title bars to be dark.
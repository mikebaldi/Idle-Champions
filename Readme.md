# IC Script Hub
## ``New: v4.4.3 - 2025-10-19:``
**Important**: This update requires updated addons for them to function properly. I have converted ImpEGamer's and Emmote's to function with the new version and they can be found at [https://github.com/antilectual/IC_Addons-1/tree/Anti-Changes](https://github.com/antilectual/IC_Addons-1/tree/Anti-Changes) (for ImpEGamer's like Levelup) and [https://github.com/antilectual/IC_Addons-2/tree/Anti-Changes](https://github.com/antilectual/IC_Addons-2/tree/Anti-Changes) for Emmote's (until I complete a pull request).

##
2025-08-02:  

Added important [imports](#imports) section. Please read it before running IC Script Hub.

As of game version 629, due to changes with hotkeys the [LevelUp](https://github.com/imp444/IC_Addons/tree/main/IC_BrivGemFarm_LevelUp_Extra) addon is required to run smoothly. Refer to [Addons.md](Addons.md) for links to more commonly used addons.

---  
## Introduction

> "This is your last chance. After this, there is no turning back. You take the blue pill—the story ends, you wake up in your bed and believe whatever you want to believe. You take the red pill—you stay in Wonderland, and I show you how deep the rabbit hole goes. Remember: all I'm offering is the truth. Nothing more." 
>  
> --- Morpheus 


> "I feel the need, the need for speed!"
> 
> --- Maverick

Welcome to 2022 and Happy New Year!  

New year, new script. We hope you like it.   
  
This script is the successor to ModronGUI.

**Warning**:
This script reads system memory. I do not know CNE's stance on reading system memory used by the game, so use at your own risk. Pointers may break on any given update and I may no longer decide to update them.

**Warning2**:
CNE will at times push out multiple patches during the week, changing classes and thus their structure in memory. This can change offsets which will break memory reading functions. It is advised you disable auto updates and keep a back up of a working Assembly-CSharp.dll from your install folder. Refer to the [imports](#imports) section for updating offsets.

## Prerequisites

You need AutoHotKey installed to be able to use `IC Script Hub`. The version of AutoHotKey installed also needs to be version 1.1 and support the switch command. 

[Download AutoHotKey](https://www.autohotkey.com/)

It is recommended that you set up Git and pull `IC Script Hub` via Git. 

This will be the easiest way for you to keep up to date with any changes made in the future. There is a little bit more to do upfront, but you will save so much time in the long run (kinda like scripting the game in the first place).

You may use any Git client you wish. [Here is a step-by-step guide](docfiles/getting-started-with-ic-script-hub-using-git.md) to installing and using Git Desktop with `IC Script Hub`.

If you would rather grab the latest version of the code manually, [head over here to learn how to do that](docfiles/getting-started-with-ic-script-hub-using-zip.md). I really don't recommend it though, as you will have to repeat this entire process every single time as opposed to simply opening an application and clicking a button.

## Imports

IC updates often and because of this the script needs to be updated to be able read the game properly. This is done using `imports`. These currently differ based on if you play on Steam, EGS, or another service.

To create them yourself you can use the export/import tools here: [ScriptHub-AutomaticOffsets](https://github.com/antilectual/ScriptHub-AutomaticOffsets).

To update the imports for your version you can use community created imports, which [Emmote](https://github.com/Emmotes) so generously keeps updated [here](https://github.com/Emmotes/ic_scripting_imports) or on the official [IC discord server](https://discord.com/invite/idlechampions/).

And to update the script:
In `[Script Hub Folder]\AddOns\IC_Core\MemoryRead\` replace the `Imports` folder there with the `Imports` folder from the zip/repository. Then completely restart the script.

## I know Git Fu!

You now have the latest version of `IC Script Hub` on your machine.

Let's go down the rabbit hole and see what awaits.

Where do you play the game?

[I play on Steam](docfiles/using-ic-script-hub-with-steam.md) 

[I play on EGS](docfiles/using-ic-script-hub-with-egs.md)

[I play on Standalone](docfiles/using-ic-script-hub-with-standalone.md)

[I play on Kartridge](docfiles/using-ic-script-hub-with-kartridge.md)

## Reading this documentation offline

You can open Readme.md (this file) in any Markdown editor on Windows that has a preview function. I use VS Code. 

1. Open the repository folder in VS Code
2. Open Readme.md
3. Press `Control+Shift+V` or right click on the file tab and pick `Open Preview`
4. Read and navigate using the preview pane that just opened




[< Return to the Readme](../Readme.md)

# Setting Idle Champions game location for Standalone

## Overview

The scripts inside `IC Script Hub` need to know where your game is installed.

## Opening `IC Script Hub`

Navigate to the folder you cloned the repo into using Windows Explorer. 

You can press `Ctrl+Shift+F` from within GitHub Desktop if you used that to clone the repository.

Double-click on `ICScriptHub.ahk` in the explorer window that opens to launch `IC Script Hub`.

You should see the `IC Script Hub` window and it should look something like this:

![IC Script Hub window](../docimages/ic-script-hub-v2.png)

You may need to [install or update AutoHotKey](https://www.autohotkey.com/) if you receive an error at this point.

## Setting the standalone game location
### Step 0: Make sure your addons are enabled

You'll want to make sure you have the game shortcut addon enabled. Open the addons dialog and ensure the addon highlighted by the green arrow is enabled and saved.

![Addons button](../docimages/addons-button.png)

I recommend making sure the ones with the yellow arrow are also enabled too.

![Addons tab](../docimages/addons-dialog.png)

It should reload your Script Hub for you but should you ever want to do a manual reload (to reset the stats screen for instance, just remember to reconnect to your Gem Farm script if you do this) hit the reload button:

![Reload button](../docimages/reload-script-hub-v2.png)

### Step 1: Grab your support URL

> ⚠️ Do not reveal your support URL, or your user_id and device_hash to anyone else ⚠️

1. Start the game
2. Press Escape
3. Click Support
4. Copy the entire URL that is opened in your browser to Notepad or similar
5. Look at the last portion of the Support URL to find your user_id and device_hash.

### Step 2: Grab the shortcut you need

1. Locate your `client`, typically in `%AppData%\..\Local\Kartridge.kongregate.com\games\309647`
2. Find `IdleDragons.exe`
3. Create a shortcut for `IdleDragons.exe`
4. Edit the properties for the shortcut.
5. Copy the entire path including `IdleDragons.exe`
6. Right click on the shortcut on your Desktop and pick `Properties`
8. Copy the contents of the Target box in the shortcut Properties.

### Step 3: Populate the location in `IC Script Hub`

1. Return to your `IC Script Hub` window
2. Click the `Briv Gem Farm` tab
3. Click the `Change Game Location` button at the bottom of the `Briv Gem Farm` window
4. Paste the link copied from the `Idle Champions` shortcut into the top box.
5. Click `Save and Close`

## Now that's done, what can I do with this thing?

[Let's find out.](an-introduction-to-ic-script-hub.md)
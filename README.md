# Linux Godot Automatically Build and Deploy to itch.io

This is a script I built to make it ridiculously easy to automatically build for all release platforms using ```godot --headless``` and automatically deploy them to itch.io using the itch.io ```butler``` utility.

This is useful for deploying initial releases and updating releases for games you have on itch.io.

I created this for my own use and distributing it as others are likely to find it useful. I consider this feature complete so there will not be updates to this unless there are bugs found or changes to the tools the script uses.

## You should setup the following in your Godot project before using this script:
### Godot Export Presets:
You need to set the Godot Export Presets in Godot which you can do by going to the ```Project``` menu and then ```Export```. This will create the ```export_presets.cfg``` file which is needed by the ```godot --headless``` command for building your project.

**The default export preset names used in this script are:**
* web
* win64
* linux_x64
* linux_arm64
* mac
  
You also need the export templates downloaded for your version of Godot.

### Godot Project Settings:
You need to set the following values in the Godot Project Settings which you can do by going to the ```Project``` menu then ```Project Settings...``` then in the ```General``` tab go to the ```Application``` secction and set the ```Name``` and ```Version``` values.

**Name** is the name of you project and will be used for the game executable name. e.g. name.exe, name.app etc.

**Version** is the version of the build for the game and is used by the butler utility for itch.io keeping track of versions.

## User defined values in this script:
I have made it easy for users to use this script in their project by making minimal changes. Most the values are read from the ```project.godot``` file.

**itch_path="user_name/game_name"** for this user_name is your itch.io username and game_name is the game name used in the url. So if the itch.io game url is https://examplegames.itch.io/example-game then the ```itch_path``` variable would be set as ```itch_path="examplegames/example-game"```.

**use_git=false** If you want the script to do a ```git pull``` before building the project then you change it the value to ```true```.

**deploy_to_itch=true** If you want to do testing before deploying to itch.io you can change the value to ```false``` and the script will build for the platforms defined in the export presets but not upload the builds to itch.io.

### Godot Export Preset Names:

As mentioned earlier the default preset names are as follows:

* **web="web"**
* **linux_x64="linux_x64"**
* **linux_arm64="linux_arm64"**
* **win64="win64"**
* **mac="mac"**

Change the values to the presets you set in the Godot Export Settings.

## Troubleshooting:

**The executable files are ```run_game.exe```, ```run_game.app``` etc.** If this is the case then the ```Name``` is not set in the ```Application``` section in the ```General``` tab of the ```Godot Project Settings```.

**The version is always 1.0.0** If this is the case then the ```Version``` is not set in the ```Application``` section in the ```General``` tab of the ```Godot Project Settings```.

**Butler is not uploading the game files** Make sure you have [installed butler](https://itch.io/docs/butler/installing.html) and have [logged into butler](https://itch.io/docs/butler/login.html) at least once, it remembers your credentials. See the buttler documentation below for further details. Also make sure the ```itch_path``` value is correct and that the ```builds/``` directory exists with the game build files.

## Other documentation:

* https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting
* https://itch.io/docs/butler/

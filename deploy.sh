#!/usr/bin/env sh
# deploy.sh version 1.0.0
#
# This script can automatically build and deploy godot projects to itch.io using godot --headless
# and the itch.io butler utility https://itch.io/docs/butler/
#
# At the time this script was written godot --headless option only supported linux systems.
# https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting

################################################################################
# START of User Defined Settings 
# Change the values below to suit your setup
################################################################################

# itch.io user_name/game_name e.g. for web url of game is https://user_name.itch.io/game_name
itch_path="user_name/game_name"

# if use_git=true then it will do a git pull before building/deploying
use_git=false

# if deploy_to_itch=true then it will use butler to deploy to itch.io. 
deploy_to_itch=true

# Godot Export Preset Names
# comment out the presets you don't use and it will not build or deploy them
web="web"
linux_x64="linux_x64"
linux_arm64="linux_arm64"
win64="win64"
mac="mac"

################################################################################
# # END of User Defined Settings 
# You should not need to make changes past this point
################################################################################

# make sure path is an absolute path
path=$(dirname "$0")
path=$(cd "$path";pwd)

# define the export paths
web_path="$path/build/$web"
linux_x64_path="$path/build/$linux_x64"
linux_arm64_path="$path/build/$linux_arm64"
win64_path="$path/build/$win64"
mac_path="$path/build/$mac"

if [ -f "$path/project.godot" ]
then 
  # get the project version from the godot project file
  version=$(cat $path/project.godot|grep config/version|cut -d= -f2|tr -d \")

  # if version is empty set it to 1.0.0
  [ -z "$version" ] && version="1.0.0"

  # get the name of the project from the godot project file
  # store project name as file_name and replace space characters with a hyphen character
  file_name=$(cat $path/project.godot|grep config/name|cut -d= -f2|tr -d \"|tr " " "-")
  
  # if the filename is empty set it to run_game
  [ -z "$file_name" ] && file_name="run_game" 
else
  echo "Error: $path/project.godot does not exist. Unable to continue"
  exit 1
fi

# download the latest files from git if use_git = true
if $use_git; then git -C "$path" pull; fi

# delete all existing builds if they exist
[ -d "$path/build" ] && rm -Rf "$path/build"

# build the releases using godot headless. Requires the presets be named in the godot exports and
# that the export_presets.cfg file exits.
# it only builds if the godot export variables exist and not empty
# https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting
if [ -f "$path/export_presets.cfg" ]
then
  # make directories for each build if the godot export preset variables exist and not empty
  [ ! -z "$web" ] && mkdir -p "$web_path"
  [ ! -z "$linux_x64" ] && mkdir -p "$linux_x64_path"
  [ ! -z "$linux_arm64" ] && mkdir -p "$linux_arm64_path"
  [ ! -z "$win64" ] && mkdir -p "$win64_path"
  [ ! -z "$mac" ] && mkdir -p "$mac_path"

  web_file="$web_path/index.html"
  linux_x64_file="$linux_x64_path/$file_name"
  linux_arm64_file="$linux_arm64_path/$file_name"
  win64_file="$win64_path/$file_name.exe"
  mac_file="$mac_path/$file_name.app"

  [ ! -z "$web" ] && godot --headless --export-release "$web" "$web_file"
  [ ! -z "$linux_x64" ] && godot --headless --export-release "$linux_x64" "$linux_x64_file"
  [ ! -z "$linux_arm64" ] && godot --headless --export-release "$linux_arm64" "$linux_arm64_file"
  [ ! -z "$win64" ] && godot --headless --export-release "$win64" "$win64_file"
  [ ! -z "$mac" ] && godot --headless --export-release "$mac" "$mac_file"
else
  echo "Error: $path/export_presets.cfg file does not exist, cannot build using godot --headless"
  echo "You can configure Godot Export Presets in Godot in the 'Project' -> 'Export' menu"
  exit 1
fi

# Use itch.io butler utility to automatically deploy new version to itch.io
# it only deploys if deploy_to_itch = true
# it only deploys if the platform executable files exist
# https://itch.io/docs/butler/
if $deploy_to_itch 
then
  [ -f "$web_file" ] && butler push "$web_path" "$itch_path:$web" --userversion $version
  [ -f "$linux_x64_file" ] && butler push "$win64_path" "$itch_path:$win64" --userversion $version
  [ -f "$linux_arm64_file" ] && butler push "$linux_x64_path" "$itch_path:$linux_x64" --userversion $version
  [ -f "$win64_file" ] && butler push "$linux_arm64_path" "$itch_path:$linux_arm64" --userversion $version
  [ -d "$mac_file" ] && butler push "$mac_path" "$itch_path:$mac" --userversion $version
fi

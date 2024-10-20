#!/usr/bin/env sh
# deploy.sh version 1.1.0
# you can get the latest version of this script at 
# https://github.com/anthonyirwin82/linux-godot-build-and-deploy-to-itch
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

# variable to allow commandline argument to prevent building project
build_with_godot=true

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

# distribution directory for extra files to distribute on for all platforms
all_dist_path="$path/dist/all"

# define the export paths and filenames if the export preset name exists
if [ ! -z "$web" ]; then
  web_path="$path/build/$web"
  web_file="$web_path/index.html"
  web_dist_path="$path/dist/$web"
fi

if [ ! -z "$linux_x64" ]; then
  linux_x64_path="$path/build/$linux_x64"
  linux_x64_file="$linux_x64_path/$file_name.x86_64"
  linux_x64_dist_path="$path/dist/$linux_x64"
fi

if [ ! -z "$linux_arm64" ]; then
  linux_arm64_path="$path/build/$linux_arm64"
  linux_arm64_file="$linux_arm64_path/$file_name.arm64"
  linux_arm64_dist_path="$path/dist/$linux_arm64"
fi

if [ ! -z "$win64" ]; then
  win64_path="$path/build/$win64"
  win64_file="$win64_path/$file_name.exe"
  win64_dist_path="$path/dist/$win64"
fi

if [ ! -z "$mac" ]; then
  mac_path="$path/build/$mac"
  mac_file="$mac_path/$file_name.app"
  mac_dist_path="$path/dist/$mac"
fi

function echo_script_header() {
  echo "======================================================================================"
  echo "Linux Godot Build and Deploy to itch.io"
  echo "Automatically builds godot projects for multiple platforms and deploys them to itch.io"
  echo "Newest Version: https://github.com/anthonyirwin82/linux-godot-build-and-deploy-to-itch"
  echo "======================================================================================"
  echo
}

function echo_no_dist_dirs() {
  echo "---------------------------------------------------------------------------------------------------"
  echo "You don't have any additional files being distributed with the builds."
  echo "To generate the dist directories you can run '$0 --generate-dist-dirs' or '$0 -g'"
  echo "You can then distribute additional files to all platforms or files for specific platforms."
  echo "---------------------------------------------------------------------------------------------------"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -g|--generate-dist-dirs)
      # make the dist directories if export preset name exists
      mkdir -p $all_dist_path
      [ ! -z "$web" ] && mkdir -p $web_dist_path
      [ ! -z "$linux_x64" ] && mkdir -p $linux_x64_dist_path && mkdir -p $path/dist/linux_all
      [ ! -z "$linux_arm64" ] && mkdir -p $linux_arm64_dist_path && mkdir -p $path/dist/linux_all
      [ ! -z "$win64" ] && mkdir -p $win64_dist_path
      [ ! -z "$mac" ] && mkdir -p $mac_dist_path
      exit 0
      ;;
    -nb|--no-build)
      shift
      build_with_godot=false
      ;;
    -nd|--no-deploy)
      shift
      deploy_to_itch=false
      ;;
    -dd|--delete-dist-dirs)
      shift
      [ -d "$path/dist" ] && rm -Rf "$path/dist"
      exit 0
      ;;
    -db|--delete-build-dirs)
      shift
      [ -d "$path/build" ] && rm -Rf "$path/build"
      exit 0
      ;; 
    -i|--info)
      shift
      echo_script_header
      echo "-----------------------"
      echo "Deployment information:"
      echo "-----------------------"
      echo
      echo "Do git pull before build: $use_git"
      echo "Building projects with Godot: $build_with_godot"
      echo "Deploying to itch.io: $deploy_to_itch"
      echo "Project Version: $version"
      echo "Project Filename: $file_name (.exe .app etc) (Web build is always index.html)"
      echo
      echo "-------------------------------------"
      echo "Building for the following platforms:"
      echo "-------------------------------------"
      echo
      [ ! -z "$web" ] && echo "- Web to $web_path"
      [ ! -z "$linux_x64" ] && echo "- Linux x86_64 to $linux_x64_path"
      [ ! -z "$linux_arm64" ] && echo "- Linux arm64 to $linux_arm64_path"
      [ ! -z "$win64" ] && echo "- Windows 64 bit to $win64_path"
      [ ! -z "$mac" ] && echo "- MacOS to $mac_path"
      echo
      if [ -d "$path/dist" ]; then
        echo "---------------------------------------------------------------------"
        echo "The following distribution files will be included in relevant builds:"
        echo "---------------------------------------------------------------------"
        echo
        [ -d "$all_dist_path" ] && echo "- All builds from $all_dist_path"
        [ -d "$web_dist_path" ] && echo "- Web builds only from $web_dist_path"
        [ -d "$path/dist/linux_all" ] && echo "- All Linux builds from $path/dist/linux_all"
        [ -d "$linux_x64_dist_path" ] && echo "- Linux x86_64 builds only from $linux_x64_dist_path"
        [ -d "$linux_arm64_dist_path" ] && echo "- Linux arm64 builds only from $linux_arm64_dist_path"
        [ -d "$win64_dist_path" ] && echo "- Windows 64 bit builds only from $win64_dist_path"
        [ -d "$mac_dist_path" ] && echo "- MacOS builds only from $mac_dist_path"
      else
        echo
        echo_no_dist_dirs
      fi
      exit 0
      ;;
    -h|--help)
      shift
      echo_script_header
      echo
      echo "Running the script to build and deploy/Running the script to only build or only deploy:"
      echo "- To run the script with the default options run '$0' without any arguments."
      echo "- To run the script without building the project run '$0 --no-build' or '$0 -nb'"
      echo "- To run the script without deploying to itch.io run '$0 --no-deploy' or '$0 -nd'"
      echo
      echo "Display deployment information:"
      echo "You can display information about the build before running the '$0' script to see what the script will do"
      echo "You can get this information by running '$0 --info' or '$0 -i'"
      echo
      echo "Distributing additional files with your release builds:"
      echo "You can distribute extra files that are not part of the Godot Project from a dist directory."
      echo "You can distribute files to all platforms and files to specific platforms."
      echo "You can generate the dist directories by running '$0 --generate-dist-dirs' or '$0 -g'"
      echo "After the directories are generated you can add extra files to the dist directories to be added to builds."
      echo
      echo "Deleting the build directories:"
      echo "You can safely delete the build directories and they will be regenerated."
      echo "You can delete the build directories by running '$0 --delete-build-dirs' or '$0 -db'"
      echo
      echo "Deleting the dist directories:"
      echo "WARNING: You probably don't want to do this because these are files you put there and are not dynamically created"
      echo "You can delete the dist directories by running '$0 --delete-dist-dirs' or '$0 -dd'"

      exit 0
      ;;
    *)
      echo "Error: $1 is an unknown argument. Run '$0 -h' or '$0 --help' for help"
      exit 1
  esac
done


# build the releases using godot headless. Requires the presets be named in the godot exports and
# that the export_presets.cfg file exits.
# it only builds if the godot export variables exist and not empty
# it only builds if the $build_with_godot variable is true
# https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting
if [ -f "$path/export_presets.cfg" ] && [ $build_with_godot == true ]; then
  # download the latest files from git if use_git = true
  if $use_git; then git -C "$path" pull; fi

  # delete all existing builds if they exist
  [ -d "$path/build" ] && rm -Rf "$path/build"  
  
  # make directories for each build if the godot export preset variables exist and not empty
  [ ! -z "$web" ] && mkdir -p "$web_path"
  [ ! -z "$linux_x64" ] && mkdir -p "$linux_x64_path"
  [ ! -z "$linux_arm64" ] && mkdir -p "$linux_arm64_path"
  [ ! -z "$win64" ] && mkdir -p "$win64_path"
  [ ! -z "$mac" ] && mkdir -p "$mac_path"

  # Build the Godot project for platforms that have export presets setup
  # Copy any distribution files to the relevant builds
  if [ ! -z "$web" ]; then
    echo "Running: godot --headless --export-release \"$web\" $web_file\""
    echo
    godot --headless --export-release "$web" "$web_file"
    [ -d "$all_dist_path" ] && [ $(ls -A "$all_dist_path") ] && cd "$all_dist_path" && cp -Rf * "$web_path"
    [ -d "$web_dist_path" ] && [ $(ls -A "$web_dist_path") ] && cd "$web_dist_path" && cp -Rf * "$web_path"
    cd $path
  fi

  if [ ! -z "$linux_x64" ]; then
    echo "Running: godot --headless --export-release \"$linux_x64\" $linux_x64_file\""
    echo
    godot --headless --export-release "$linux_x64" "$linux_x64_file"
    [ -d "$all_dist_path" ] && [ $(ls -A "$all_dist_path") ] && cd "$all_dist_path" && cp -Rf * "$linux_x64_path"   
    [ -d "$linux_x64_dist_path" ] && [ $(ls -A "$linux_x64_dist_path") ] && cd "$linux_x64_dist_path" && cp -Rf * "$linux_x64_path"   
    [ -d "$path/dist/linux_all" ] && [ $(ls -A "$path/dist/linux_all") ] && cd "$path/dist/linux_all" && cp -Rf * "$linux_x64_path"
    cd $path   
  fi

  if [ ! -z "$linux_arm64" ]; then
    echo "Running: godot --headless --export-release \"$linux_arm64\" \"$linux_arm64_file\""
    echo
    godot --headless --export-release "$linux_arm64" "$linux_arm64_file"
    [ -d "$all_dist_path" ] && [ $(ls -A "$all_dist_path") ] && cd "$all_dist_path" && cp -Rf * "$linux_arm64_path"
    [ -d "$linux_arm64_dist_path" ] && [ $(ls -A "$linux_arm64_dist_path") ] && cd "$linux_arm64_dist_path" && cp -Rf * "$linux_arm64_path"
    [ -d "$path/dist/linux_all" ] && [ $(ls -A "$path/dist/linux_all") ] && cd "$path/dist/linux_all" && cp -Rf * "$linux_arm64_path"
    cd $path
  fi
  
  if [ ! -z "$win64" ]; then
    echo "godot --headless --export-release \"$win64\" \"$win64_file\""
    echo
    godot --headless --export-release "$win64" "$win64_file"
    [ -d "$all_dist_path" ] && [ $(ls -A "$all_dist_path") ] && cd "$all_dist_path" && cp -Rf * "$win64_path"
    [ -d "$win64_dist_path" ]&& [ $(ls -A "$win64_dist_path") ] && cd "$win64_dist_path" && cp -Rf * "$win64_path"
    cd $path
  fi
  
  if [ ! -z "$mac" ]; then
    echo "Running: godot --headless --export-release \"$mac\" \"$mac_file\""
    echo
    godot --headless --export-release "$mac" "$mac_file"
    [ -d "$all_dist_path" ] && [ $(ls -A "$all_dist_path") ] && cd "$all_dist_path" && cp -Rf * "$mac_path"
    [ -d "$mac_dist_path" ] && [ $(ls -A "$mac_dist_path") ] && cd "$mac_dist_path" && cp -Rf * "$mac_path"
    cd $path
  fi

  if [ ! -f "$path/export_presets.cfg" ]; then
    echo "Error: $path/export_presets.cfg file does not exist, cannot build using godot --headless"
    echo "You can configure Godot Export Presets in Godot in the 'Project' -> 'Export' menu"
    exit 1
  fi

  # display information about distributing additional files with the build
  [ ! -d "$path/dist" ] && echo && echo_no_dist_dirs && echo
fi

# Use itch.io butler utility to automatically deploy new version to itch.io
# it only deploys if deploy_to_itch = true
# it only deploys if the platform executable files exist
# https://itch.io/docs/butler/
if $deploy_to_itch ; then
  [ -f "$web_file" ] && butler push "$web_path" "$itch_path:$web" --userversion $version
  [ -f "$linux_x64_file" ] && butler push "$win64_path" "$itch_path:$win64" --userversion $version
  [ -f "$linux_arm64_file" ] && butler push "$linux_x64_path" "$itch_path:$linux_x64" --userversion $version
  [ -f "$win64_file" ] && butler push "$linux_arm64_path" "$itch_path:$linux_arm64" --userversion $version
  [ -d "$mac_file" ] && butler push "$mac_path" "$itch_path:$mac" --userversion $version
fi

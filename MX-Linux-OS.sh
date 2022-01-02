#!/bin/bash
# script Installer MX-Linux
# By chris1111 2021
#
# Vars
PARENTDIR=$(dirname "$0")
cd "$PARENTDIR"
apptitle="MX-Linux Packager"
version="1.0"
# Set Icon directory and file
cp -rp ./Extract/.AppIcon.icns /Private/tmp/AppIcon.icns
iconfile="/Private/tmp/AppIcon.icns"
# Delete build if exist
rm -rf ./Package
rm -rf ./MX-Linux.pkg
rm -rf ./pkgbuild/MX_x64
# Select USB
response=$(osascript -e 'tell app "System Events" to display dialog "Select your USB key\n\nCancel for Exit" buttons {"Cancel","Select USB"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')

action=$(echo $response | cut -d ':' -f2)
# Exit if Canceled
if [ ! "$action" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
  exit 0
fi
### RESTORE : Select usbdisk location
if [ "$action" == "Select USB" ] ; then

  # Get input folder of usbdisk disk 
  usbdiskpath=`/usr/bin/osascript << EOT
    tell application "Finder"
        activate
        set folderpath to choose folder default location "/Volumes" with prompt "Select your USB key"
    end tell 
    return (posix path of folderpath) 
  EOT`

  # Cancel is user selects Cancel
  if [ ! "$usbdiskpath" ] ; then
    osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
    exit 0
  fi

fi

# Parse usbdisk disk volume
usbdisk=$( echo $usbdiskpath | awk -F '\/Volumes\/' '{print $2}' | cut -d '/' -f1 )
disknum=$( diskutil list | grep "$usbdisk" | awk -F 'disk' '{print $2}' | cut -d 's' -f1 )
devdisk="/dev/disk$disknum"
# use rdisk for faster copy
devdiskr="/dev/rdisk$disknum"
# Get Drive size
drivesize=$( diskutil list | grep "disk$disknum" | grep "0\:" | cut -d "*" -f2 | awk '{print $1 " " $2}' )

# Set output option
if [ "$action" == "Select USB" ] ; then
  source=$inputfile
  dest="$drivesize $usbdisk (disk$disknum)"
  outputfile=$devdiskr
  check=$source
fi

# Confirmation Dialog
response=$(osascript -e 'tell app "System Events" to display dialog "Please confirm your choice and click OK\n\nDestination: \n'"$dest"' \n\n\nNOTE: The volumes will be formatted into a single partition, the data will be erased!" buttons {"Cancel", "OK"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'" ')
answer=$(echo $response | grep "OK")

# Cancel is user does not select OK
if [ ! "$answer" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
  exit 0
fi

# Unmount Volume
response=$(diskutil unmountDisk $devdisk)
answer=$(echo $response | grep "successful")
# Cancel if unable to unmount
if [ ! "$answer" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "Cannot Unmount '"$usbdisk"'"'
  exit 0
fi

# script Notifications
osascript -e 'display notification "Formatting" with title "USB"'
diskutil partitiondisk "$outputfile" 1 MBR FAT32 MX-LINUX 100%
echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`
************************************************
Formatting USB Done!
Download ➤ MX-Linux-OS"
echo "************************************************`tput sgr0` `tput setaf 7``tput sgr0`  "
# script Notifications
osascript -e 'display notification "'"$drivesize"' Formatting USB '$fsize'  MX-LINUX-USB
Completed " with title "'"$apptitle"'" subtitle " '"$version"' "'

response=$(osascript -e 'tell app "System Events" to display dialog "'"$drivesize"' Formatting USB Done '"$fsize"' " buttons {"Download MX-Linux-OS"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'" ')
curl --progress-bar -L https://sourceforge.net/projects/mx-linux/files/latest/download -o /tmp/MX_x64.iso
Sleep 1
echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`
************************************************
Downloading Done
Extracting image using unar"
Sleep 2
# create the base folder
mkdir -p ./pkgbuild
Sleep 1
./Extract/unar -r /Private/tmp/MX_x64.iso -o ./pkgbuild
cp -rp ./Extract/.VolumeIcon.icns ./pkgbuild/MX_x64
# Delete build if exist
rm -rf ./Package
rm -rf ./MX-Linux.pkg
Sleep 1
mkdir -p ./Package/BUILD-PACKAGE

# Create Packages with pkgbuild
echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`
************************************************
Create package with PkgBuild "
Sleep 1
# Create finale package with Productbuild
pkgbuild --root ./pkgbuild/MX_x64 --identifier com.MXLinux.MX-Linux.pkg --version 1.0 --install-location / ./Package/BUILD-PACKAGE/MX-Linux.pkg

echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`Done!
************************************************"
echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`
************************************************
Create finale package with Productbuild "

productbuild --distribution "./Distribution.xml"  \
--package-path "./Package/BUILD-PACKAGE/" \
--resources "./Resources" \
"./MX-Linux.pkg"

echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`Done!
************************************************"
# Clean Up
rm -rf ./Package
rm -rf /Private/tmp/AppIcon.icns
rm -rf /Private/tmp/MX_x64.iso
echo "`tput setaf 7``tput sgr0``tput bold``tput setaf 10`
************************************************
PACKAGE BUILD SUCCEEDED "
echo "************************************************`tput sgr0` `tput setaf 7``tput sgr0`  "
Sleep 1
echo "
Open Package Installer "
Open ./MX-Linux.pkg

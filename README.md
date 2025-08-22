# IOS Media Backup

These scripts were made by me to backup my iPhone's images to a Linux PC. There is a script for backing up images (`heic_to_png.sh`) and a script for backing up videos (`backup_videos.sh`). Note that `heic_to_png.sh` does not preserve live photo functionality.

## Setup
I use `ifuse` to mount my iPhone on Linux.
```sh
sudo pacman -S libimobiledevice ifuse usbmuxd

# check if usbmuxd is avaiable
systemctl status usbmuxd
```

## Usage
1. Connect iPhone via USB to PC. Verify connection by:
```sh
lsusb | grep -i apple
```
2. Mount with `ifuse`:
```sh
ifuse -o allow_other /mnt/iphone
```
3. Run `heic_to_png.sh` to backup images: Here is the usage:
```sh
Usage: ./heic_to_png.sh <source_directory1> [source_directory2] ... <destination_directory>
Example: ./heic_to_png.sh /mnt/iphone/DCIM/107APPLE ~/Pictures/converted
Example: ./heic_to_png.sh /mnt/iphone/DCIM/107APPLE /mnt/iphone/DCIM/108APPLE ~/Pictures/converted
```
4. Run `backup_videos.sh` to backup videos. Same usage. This file only backs up actual videos , ignoring any live photos.

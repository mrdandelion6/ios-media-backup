# iOS Media Backup

These scripts were made by me to backup my iPhone's media to a Linux PC. Each script handles different file types and formats found on iOS devices.

## Scripts Overview

### `heic_to_png.sh`

Converts HEIC photos to PNG format with date-based renaming. Does not preserve Live Photo functionality - only converts the still image component.

### `backup_movs.sh`

Backs up genuine MOV videos only. Automatically detects and skips Live Photo components by checking if a corresponding HEIC file exists. Only backs up actual videos (screen recordings, regular videos, slow-motion, time-lapse, etc.).

### `backup_pngs.sh`

Backs up all PNG files (primarily iPhone screenshots) with date-based renaming.

### `backup_jpgs.sh`

Backs up all JPG/JPEG files (edited photos, downloaded images, photos saved in JPEG format) with date-based renaming.

## File Types on iPhone

- **HEIC files**: Main photo format (iOS 11+)
- **MOV files**: Videos OR Live Photo components
- **PNG files**: Screenshots
- **JPG/JPEG files**: Edited photos, downloads, or photos saved in "Most Compatible" mode
- **Live Photos**: HEIC + MOV pairs (same filename, different extensions)

## Setup

I use `ifuse` to mount my iPhone on Linux.

```sh
sudo pacman -S libimobiledevice ifuse usbmuxd

# check if usbmuxd is available
systemctl status usbmuxd
```

## Usage

1. Connect iPhone via USB to PC. Verify connection by:

```sh
lsusb | grep -i apple
```

2. Mount with `ifuse`:

```sh
sudo ifuse -o allow_other /mnt/iphone
```

3. Run the appropriate backup script(s):

### All scripts use the same argument pattern:

```sh
Usage: ./script_name.sh <source_directory1> [source_directory2] ... <destination_directory>
```

### Examples:

```sh
# Convert HEIC photos to PNG
./heic_to_png.sh /mnt/iphone/DCIM/107APPLE ~/Pictures/converted_photos

# Backup genuine videos (excludes Live Photo components)
./backup_movs.sh /mnt/iphone/DCIM ~/Videos/iphone_videos

# Backup screenshots
./backup_pngs.sh /mnt/iphone/DCIM ~/Pictures/screenshots

# Backup JPG photos
./backup_jpgs.sh /mnt/iphone/DCIM ~/Pictures/jpg_photos

# Multiple sources, single destination
./heic_to_png.sh /mnt/iphone/DCIM/107APPLE /mnt/iphone/DCIM/108APPLE ~/Pictures/all_converted

# Backup everything from entire DCIM folder
./backup_movs.sh /mnt/iphone/DCIM ~/Videos/all_videos
./backup_pngs.sh /mnt/iphone/DCIM ~/Pictures/all_screenshots
```

## Output Format

All scripts rename files using the last modified date in format: `YY_MM_DD_HHMM.extension`

- Example: `25_08_21_1430.png` (Aug 21, 2025 at 2:30 PM)
- Conflicts are resolved by adding `_1`, `_2`, etc.

## Notes

- All scripts search recursively through subdirectories
- Live Photos consist of HEIC + MOV pairs with matching filenames
- `backup_movs.sh` intelligently distinguishes between genuine videos and Live Photo components

## TODO

fix bug with counters not updating , leading to stats always printing 0 at end

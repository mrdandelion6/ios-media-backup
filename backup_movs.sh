#!/bin/bash

# MOV video backup script (genuine videos only, excludes Live Photo components)
# Usage: ./backup_videos.sh <source_directory1> [source_directory2] ... <destination_directory>

# Check if at least 2 arguments provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_directory1> [source_directory2] ... <destination_directory>"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE ~/Videos/backup"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE /mnt/iphone/DCIM/108APPLE ~/Videos/backup"
    echo ""
    echo "This script backs up genuine MOV videos (excludes Live Photo components)"
    echo "A MOV file is considered genuine if NO corresponding HEIC file exists"
    exit 1
fi

# Get all arguments
args=("$@")
# Last argument is the destination directory
DST_DIR="${args[-1]}"
# All other arguments are source directories
SRC_DIRS=("${args[@]:0:$#-1}")

# Check if all source directories exist
for src_dir in "${SRC_DIRS[@]}"; do
    if [ ! -d "$src_dir" ]; then
        echo "Error: Source directory '$src_dir' does not exist"
        exit 1
    fi
done

# Create destination directory if it doesn't exist
mkdir -p "$DST_DIR"

# Check if destination directory was created successfully
if [ ! -d "$DST_DIR" ]; then
    echo "Error: Could not create destination directory '$DST_DIR'"
    exit 1
fi

echo "Will process ${#SRC_DIRS[@]} source director(ies):"
    for src_dir in "${SRC_DIRS[@]}"; do
        echo "  - $src_dir"
    done
    echo "Output destination: $DST_DIR"

# Counter for processed files
count=0
backed_up=0
skipped_live_photos=0
errors=0

echo "Backing up genuine MOV videos to '$DST_DIR'"
echo "----------------------------------------"

# Process each source directory
for src_dir in "${SRC_DIRS[@]}"; do
    echo "Processing source: $src_dir"

    # Find and process all MOV files (case insensitive) in this source directory
    find "$src_dir" -type f \( -iname "*.mov" -o -iname "*.MOV" \) | while read -r mov_file; do
    count=$((count + 1))

        # Get the base filename without extension
        base_name=$(basename "$mov_file")
        base_name_no_ext="${base_name%.*}"

        # Check if corresponding HEIC file exists in the same directory
        mov_dir=$(dirname "$mov_file")
        heic_file1="$mov_dir/${base_name_no_ext}.HEIC"
        heic_file2="$mov_dir/${base_name_no_ext}.heic"

        if [ -f "$heic_file1" ] || [ -f "$heic_file2" ]; then
            # This is a Live Photo component, skip it
            echo "  Skipping Live Photo: $(basename "$mov_file")"
            skipped_live_photos=$((skipped_live_photos + 1))
        else
            # This is a genuine video, back it up

            # Get the last modified time of the file for renaming
            # Format: YY_MM_DD_HHMM
            file_date=$(stat -c %Y "$mov_file" | xargs -I {} date -d @{} +"%y_%m_%d_%H%M")

            # Create output filename with original extension
            file_extension="${base_name##*.}"
            output_file="$DST_DIR/${file_date}.${file_extension}"

            # Handle filename conflicts by adding a suffix
            counter=1
            original_output="$output_file"
            while [ -f "$output_file" ]; do
                # Remove extension, add counter, add extension back
                base_output="${original_output%.*}"
                ext_output="${original_output##*.}"
                output_file="${base_output}_${counter}.${ext_output}"
                counter=$((counter + 1))
            done

            echo "  Backing up: $(basename "$mov_file") -> $(basename "$output_file")"

            # Copy the MOV file
            if cp "$mov_file" "$output_file" 2>/dev/null; then
                backed_up=$((backed_up + 1))
                echo "    ✓ Success"
            else
                errors=$((errors + 1))
                echo "    ✗ Error backing up $(basename "$mov_file")"
            fi
        fi
    done
done

echo "----------------------------------------"
echo "Backup complete!"
echo "MOV files found: $count"
echo "Genuine videos backed up: $backed_up"
echo "Live Photo components skipped: $skipped_live_photos"
echo "Errors: $errors"

# Check if any files were found
if [ $count -eq 0 ]; then
    echo "No MOV files found in the specified directories"
fi

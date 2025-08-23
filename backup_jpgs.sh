#!/bin/bash

# JPG/JPEG backup script
# Usage: ./backup_jpgs.sh <source_directory1> [source_directory2] ... <destination_directory>

# Check if at least 2 arguments provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_directory1> [source_directory2] ... <destination_directory>"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE ~/Pictures/jpgs"
    echo "Example: $0 /mnt/iphone/DCIM ~/Pictures/all_jpgs"
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
errors=0

echo "Backing up JPG/JPEG files to '$DST_DIR'"
echo "----------------------------------------"

# Process each source directory
for src_dir in "${SRC_DIRS[@]}"; do
    echo "Processing source: $src_dir"

    # Find and process all JPG/JPEG files (case insensitive) in this source directory
    find "$src_dir" -type f \( -iname "*.jpg" -o -iname "*.JPG" -o -iname "*.jpeg" -o -iname "*.JPEG" \) | while read -r jpg_file; do
    count=$((count + 1))

        # Get the last modified time of the file for renaming
        # Format: YY_MM_DD_HHMM
        file_date=$(stat -c %Y "$jpg_file" | xargs -I {} date -d @{} +"%y_%m_%d_%H%M")

        # Get original extension to preserve it
        original_ext="${jpg_file##*.}"
        # Convert to lowercase for consistency
        ext=$(echo "$original_ext" | tr '[:upper:]' '[:lower:]')

        # Create output filename
        output_file="$DST_DIR/${file_date}.${ext}"

        # Handle filename conflicts by adding a suffix
        counter=1
        original_output="$output_file"
        while [ -f "$output_file" ]; do
            # Remove extension, add counter, add extension back
            base_name="${original_output%.*}"
            file_ext="${original_output##*.}"
            output_file="${base_name}_${counter}.${file_ext}"
            counter=$((counter + 1))
        done

        echo "  Backing up: $(basename "$jpg_file") -> $(basename "$output_file")"

        # Copy the JPG file
        if cp "$jpg_file" "$output_file" 2>/dev/null; then
            backed_up=$((backed_up + 1))
            echo "    ✓ Success"
        else
            errors=$((errors + 1))
            echo "    ✗ Error backing up $(basename "$jpg_file")"
        fi
    done
done

echo "----------------------------------------"
echo "Backup complete!"
echo "JPG/JPEG files found: $count"
echo "Successfully backed up: $backed_up"
echo "Errors: $errors"

# Check if any files were found
if [ $count -eq 0 ]; then
    echo "No JPG/JPEG files found in the specified directories"
fi

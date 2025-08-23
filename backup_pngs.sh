#!/bin/bash

# PNG backup script (screenshots and other PNG images)
# Usage: ./backup_pngs.sh <source_directory1> [source_directory2] ... <destination_directory>

# Check if at least 2 arguments provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_directory1> [source_directory2] ... <destination_directory>"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE ~/Pictures/screenshots"
    echo "Example: $0 /mnt/iphone/DCIM ~/Pictures/pngs"
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

echo "Backing up PNG files to '$DST_DIR'"
echo "----------------------------------------"

# Process each source directory
for src_dir in "${SRC_DIRS[@]}"; do
    echo "Processing source: $src_dir"

    # Find and process all PNG files (case insensitive) in this source directory
    find "$src_dir" -type f \( -iname "*.png" -o -iname "*.PNG" \) | while read -r png_file; do
    count=$((count + 1))

        # Get the last modified time of the file for renaming
        # Format: YY_MM_DD_HHMM
        file_date=$(stat -c %Y "$png_file" | xargs -I {} date -d @{} +"%y_%m_%d_%H%M")

        # Create output filename
        output_file="$DST_DIR/${file_date}.png"

        # Handle filename conflicts by adding a suffix
        counter=1
        original_output="$output_file"
        while [ -f "$output_file" ]; do
            # Remove .png extension, add counter, add .png back
            base_name="${original_output%.png}"
            output_file="${base_name}_${counter}.png"
            counter=$((counter + 1))
        done

        echo "  Backing up: $(basename "$png_file") -> $(basename "$output_file")"

        # Copy the PNG file
        if cp "$png_file" "$output_file" 2>/dev/null; then
            backed_up=$((backed_up + 1))
            echo "    ✓ Success"
        else
            errors=$((errors + 1))
            echo "    ✗ Error backing up $(basename "$png_file")"
        fi
    done
done

echo "----------------------------------------"
echo "Backup complete!"
echo "PNG files found: $count"
echo "Successfully backed up: $backed_up"
echo "Errors: $errors"

# Check if any files were found
if [ $count -eq 0 ]; then
    echo "No PNG files found in the specified directories"
fi

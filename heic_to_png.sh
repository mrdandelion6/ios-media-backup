#!/bin/bash

# HEIC to PNG converter with date-based renaming
# Usage: ./convert_heic.sh <source_directory1> [source_directory2] ... <destination_directory>

# Check if at least 2 arguments provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_directory1> [source_directory2] ... <destination_directory>"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE ~/Pictures/converted"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE /mnt/iphone/DCIM/108APPLE ~/backup/heic ~/Pictures/converted"
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
converted=0
errors=0

echo "Converting HEIC files to '$DST_DIR'"
echo "----------------------------------------"

# Process each source directory
for src_dir in "${SRC_DIRS[@]}"; do
    echo "Processing source: $src_dir"

    # Find and process all HEIC files (case insensitive) in this source directory
    find "$src_dir" -type f \( -iname "*.heic" -o -iname "*.HEIC" \) | while read -r heic_file; do
    count=$((count + 1))

        # Get the last modified time of the file
        # Format: YY_MM_DD_HHMM
        file_date=$(stat -c %Y "$heic_file" | xargs -I {} date -d @{} +"%y_%m_%d_%H%M")

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

        echo "  Converting: $(basename "$heic_file") -> $(basename "$output_file")"

        # Convert HEIC to PNG
        if convert "$heic_file" "$output_file" 2>/dev/null; then
            converted=$((converted + 1))
            echo "    ✓ Success"
        else
            errors=$((errors + 1))
            echo "    ✗ Error converting $(basename "$heic_file")"
        fi
    done
done

echo "----------------------------------------"
echo "Conversion complete!"
echo "Files processed: $count"
echo "Successfully converted: $converted"
echo "Errors: $errors"

# Check if any files were found
if [ $count -eq 0 ]; then
    echo "No HEIC files found in '$SRC_DIR'"
fi

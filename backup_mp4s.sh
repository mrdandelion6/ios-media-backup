#!/bin/bash

# MP4 video backup script
# Usage: ./backup_mp4s.sh [--log-errors] <source_directory1> [source_directory2] ... <destination_directory>

LOG_ERRORS=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --log-errors) LOG_ERRORS=true ;;
        *) ARGS+=("$arg") ;;
    esac
done
set -- "${ARGS[@]}"
# Check if at least 2 arguments provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [--log-errors] <source_directory1> [source_directory2] ... <destination_directory>"
    echo "Example: $0 /mnt/iphone/DCIM/107APPLE ~/Videos/mp4s"
    echo "Example: $0 /mnt/iphone/DCIM ~/Videos/all_mp4s"
    exit 1
fi

SCRIPT_NAME="$(basename "$0" .sh)"
ERROR_LOG=""
if "$LOG_ERRORS"; then
    ERROR_LOG="$PWD/error_log_${SCRIPT_NAME}_$(date +"%y_%m_%d_%H_%M_%S").txt"
    touch "$ERROR_LOG"
    echo "Command errors will be logged to: $ERROR_LOG"
fi

run_command() {
    if [ -n "$ERROR_LOG" ]; then
        "$@" 2>>"$ERROR_LOG"
    else
        "$@"
    fi
}
is_already_backed_up() {
    local source_file="$1"
    local file_date="$2"
    local extension="$3"
    local candidate

    for candidate in "$DST_DIR"/"${file_date}"*."${extension}"; do
        [ -f "$candidate" ] || continue
        if cmp -s "$source_file" "$candidate"; then
            return 0
        fi
    done
    return 1
}

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
skipped_existing=0

echo "Backing up MP4 files to '$DST_DIR'"
echo "----------------------------------------"

# Process each source directory
for src_dir in "${SRC_DIRS[@]}"; do
    echo "Processing source: $src_dir"

    # Find and process all MP4 files (case insensitive) in this source directory
    while IFS= read -r -d '' mp4_file; do
    count=$((count + 1))

        # Get the last modified time of the file for renaming
        # Format: YY_MM_DD_HHMM
        file_date=$(stat -c %Y "$mp4_file" | xargs -I {} date -d @{} +"%y_%m_%d_%H%M")

        # Create output filename
        output_file="$DST_DIR/${file_date}.mp4"

        if is_already_backed_up "$mp4_file" "$file_date" "mp4"; then
            skipped_existing=$((skipped_existing + 1))
            echo "  Skipping existing identical file: $(basename "$mp4_file")"
            continue
        fi

        # Handle filename conflicts by adding a suffix
        counter=1
        original_output="$output_file"
        while [ -f "$output_file" ]; do
            # Remove .mp4 extension, add counter, add .mp4 back
            base_name="${original_output%.mp4}"
            output_file="${base_name}_${counter}.mp4"
            counter=$((counter + 1))
        done

        echo "  Backing up: $(basename "$mp4_file") -> $(basename "$output_file")"

        # Copy the MP4 file
        if run_command cp "$mp4_file" "$output_file"; then
            backed_up=$((backed_up + 1))
            echo "    ✓ Success"
        else
            errors=$((errors + 1))
            echo "    ✗ Error backing up $(basename "$mp4_file")"
        fi
    done < <(find "$src_dir" -type f \( -iname "*.mp4" -o -iname "*.MP4" \) -print0)
done

echo "----------------------------------------"
echo "Backup complete!"
echo "MP4 files found: $count"
echo "Successfully backed up: $backed_up"
echo "Existing identical files skipped: $skipped_existing"
echo "Errors: $errors"

# Check if any files were found
if [ $count -eq 0 ]; then
    echo "No MP4 files found in the specified directories"
fi

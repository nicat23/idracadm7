#!/bin/sh
# This script overlays custom scripts from /hooks into the acme.sh directories.
# For this to work, you should have directories like /hooks/deploy, /hooks/dnsapi, etc.
# containing your custom .sh files.
set -e

OVERLAY_TYPES="deploy dnsapi notify"
echo "Looking for custom scripts in /hooks to copy into ${LE_WORKING_DIR}"

if [ ! -d "$LE_WORKING_DIR" ]; then
    echo "Error: LE_WORKING_DIR ($LE_WORKING_DIR) does not exist"
    exit 1
fi

if [ ! -d "/hooks" ]; then
    echo "No /hooks directory found, skipping overlay setup"
    exit 0
fi

copy_count=0
for NAME in $OVERLAY_TYPES; do
    HOOK_DIR="/hooks/$NAME"
    TARGET_PARENT_DIR="${LE_WORKING_DIR}/${NAME}"

    if [ ! -d "$HOOK_DIR" ]; then
        echo "No custom $NAME scripts found in $HOOK_DIR, skipping..."
        continue
    fi

    echo "Found custom scripts in $HOOK_DIR. Installing them..."

    if [ ! -d "$TARGET_PARENT_DIR" ]; then
        mkdir -p "$TARGET_PARENT_DIR"
        chmod 755 "$TARGET_PARENT_DIR"
    fi

    # Check if there are actually .sh files in the directory
    set -- "$HOOK_DIR"/*.sh
    if [ ! -e "$1" ]; then
        echo "No .sh files found in $HOOK_DIR, skipping..."
        continue
    fi

    for SCRIPT in "$HOOK_DIR"/*.sh; do
        if [ -f "$SCRIPT" ]; then
            SCRIPT_NAME=$(basename "$SCRIPT")
            TARGET_FILE="${TARGET_PARENT_DIR}/${SCRIPT_NAME}"
            case "$SCRIPT_NAME" in
                *[!a-zA-Z0-9._-]*)
                    echo "Warning: Skipping script with unsafe name: $SCRIPT_NAME"
                    continue
                    ;;
            esac
            rm -f "$TARGET_FILE"
            if cp "$SCRIPT" "$TARGET_FILE"; then
                chmod 755 "$TARGET_FILE"
                echo "Installed $SCRIPT to $TARGET_FILE"
                copy_count=$((copy_count + 1))
            else
                echo "Failed to install $SCRIPT to $TARGET_FILE"
                exit 1
            fi
        fi
    done
done

if [ "$copy_count" -eq 0 ]; then
    echo "No custom scripts were installed"
else
    echo "Successfully installed $copy_count custom script(s)"
fi

echo "Finished container initialization."
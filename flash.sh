#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if nice!nano is connected
check_nicenano() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        diskutil list | grep -q "NICENANO"
    else
        # Linux
        lsblk | grep -q "NICENANO"
    fi
}

# Function to wait for nice!nano device
wait_for_nicenano() {
    print_status "Waiting for nice!nano device to be connected..."
    
    while ! check_nicenano; do
        sleep 1
    done
    
    print_success "nice!nano device detected!"
    sleep 2  # Give the system a moment to fully mount the device
}

# Function to get the mount point of nice!nano
get_nicenano_mount() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - get the device identifier
        diskutil list | grep "NICENANO" | awk '{print $NF}'
    else
        # Linux - get the mount point
        lsblk | grep "NICENANO" | awk '{print $1}'
    fi
}

# Function to copy firmware file
copy_firmware() {
    local side=$1
    local firmware_file="res/${side}.uf2"
    
    # Check if firmware file exists
    if [ ! -f "$firmware_file" ]; then
        print_error "Firmware file '$firmware_file' not found!"
        return 1
    fi
    
    print_status "Copying $firmware_file to nice!nano..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - copy to the mounted volume
        local volume_path="/Volumes/NICENANO"
        if [ -d "$volume_path" ]; then
            cp "$firmware_file" "$volume_path/"
            if [ $? -eq 0 ]; then
                print_success "Firmware copied successfully!"
                print_status "The nice!nano should now restart with the new firmware."
            else
                print_error "Failed to copy firmware!"
                return 1
            fi
        else
            print_error "Could not find NICENANO volume at $volume_path"
            return 1
        fi
    else
        # Linux - get the mount point and copy to the device
        local mount_point=$(get_nicenano_mount)
        
        if [ -z "$mount_point" ]; then
            print_error "Could not find nice!nano mount point!"
            return 1
        fi
        
        # Linux - copy to the device
        sudo dd if="$firmware_file" of="$mount_point" bs=1M conv=notrunc
        if [ $? -eq 0 ]; then
            print_success "Firmware copied successfully!"
            print_status "The nice!nano should now restart with the new firmware."
        else
            print_error "Failed to copy firmware!"
            return 1
        fi
    fi
}

# Main script
main() {
    print_status "ZMK Firmware Flasher for nice!nano"
    print_status "This script will help you flash firmware to your nice!nano device."
    echo
    
    # Wait for nice!nano to be connected
    wait_for_nicenano
    
    # Ask user for side selection
    while true; do
        echo
        print_status "Which side would you like to flash?"
        echo "1) Left"
        echo "2) Right"
        echo "3) Abort"
        echo
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1)
                print_status "Selected: Left"
                copy_firmware "left"
                break
                ;;
            2)
                print_status "Selected: Right"
                copy_firmware "right"
                break
                ;;
            3)
                print_warning "Operation aborted by user."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Run the main function
main "$@" 
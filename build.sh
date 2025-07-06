#!/bin/bash

# Default workspace folder is current directory
zmk_root="/Users/vadim/Developer/sources/zmkfirmware/zmk"

# ZMK configuration path
zmk_config="/workspaces/zmk-config/zmk-config-fuji44"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --zmk-root|-z)
            zmk_root="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--workspace-folder <path>]"
            echo "  --zmk-root, -z <path>  Path to workspace folder (default: current directory)"
            echo "  --help, -h                     Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if the workspace folder exists
if [ ! -d "$zmk_root" ]; then
    echo "Error: Workspace folder '$zmk_root' does not exist"
    exit 1
fi

# Run the devcontainer up command
echo "Starting devcontainer for workspace: $zmk_root"
devcontainer up --workspace-folder "$zmk_root"

# Connect to the container and run the build command
echo "Clear build folder..."
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "rm -rf /workspaces/zmk/app/build"

echo "Building binary..."
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "cd /workspaces/zmk/app && west build -d build/left -b nice_nano_v2 -- -DSHIELD=fuji44_left -DZMK_CONFIG=\"$zmk_config/config\""
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "cd /workspaces/zmk/app && west build -d build/right -b nice_nano_v2 -- -DSHIELD=fuji44_right -DZMK_CONFIG=\"$zmk_config/config\""

# Copy the built firmware files to the config folder
echo "Copying firmware files to config folder..."
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "mkdir -p $zmk_config/res"
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "cp /workspaces/zmk/app/build/left/zephyr/zmk.uf2 $zmk_config/res/left.uf2"
devcontainer exec --workspace-folder "$zmk_root" -- bash -c "cp /workspaces/zmk/app/build/right/zephyr/zmk.uf2 $zmk_config/res/right.uf2"
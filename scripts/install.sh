#!/bin/bash

# Script to build all submodules in parallel
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBMODULES_DIR="$SCRIPT_DIR/../submodules"
SUBMODULE_BUILD_SCRIPT="scripts/build.sh"

BUILD_DIR=build-native

echo "Installing all submodules in parallel..."

# Array to store background job PIDs and project names
declare -a PIDS
declare -a PROJECTS

# Iterate through all directories in submodules
for platform_dir in "$SUBMODULES_DIR"/*; do
    if [ -d "$platform_dir" ]; then
        platform_name=$(basename "$platform_dir")
        
        # Iterate through all subdirectories in the platform
        for project_dir in "$platform_dir"/*; do
            if [ -d "$project_dir" ]; then
                project_name=$(basename "$project_dir")
                build_script="$project_dir/$SUBMODULE_BUILD_SCRIPT"
                
                if [ -f "$build_script" ]; then
                    echo "Starting install: $platform_name/$project_name"
                    (
                        cd "$project_dir" || exit 1
                        cmake --install $BUILD_DIR > /dev/null 2>&1
                    ) &
                    PIDS+=($!)
                    PROJECTS+=("$platform_name/$project_name")
                else
                    echo "⊘ Skipping $platform_name/$project_name (no build script found)"
                fi
            fi
        done
    fi
done

# Wait for all background jobs and collect results as they complete
echo ""
echo "Waiting for install to complete..."
failed_count=0
success_count=0
total_installs=${#PIDS[@]}
completed_count=0

# Create associative arrays to track completion
declare -A pid_to_index
for i in "${!PIDS[@]}"; do
    pid_to_index[${PIDS[$i]}]=$i
done

# Monitor processes as they complete
while [ $completed_count -lt "$total_installs" ]; do
    for pid in "${!pid_to_index[@]}"; do
        # Check if process is still running
        if ! kill -0 "$pid" 2>/dev/null; then
            # Process has finished, get its exit status
            wait "$pid"
            exit_status=$?
            
            # Get the index and project name
            i=${pid_to_index[$pid]}
            project=${PROJECTS[$i]}
            
            # Display result immediately
            if [ $exit_status -eq 0 ]; then
                echo "✓ $project installed successfully"
                ((success_count++))
            else
                echo "✗ $project install failed"
                ((failed_count++))
            fi
            
            # Remove from tracking
            unset "pid_to_index[$pid]"
            ((completed_count++))
        fi
    done
    
    # Small sleep to avoid busy-waiting
    [ $completed_count -lt "$total_installs" ] && sleep 0.1
done

echo ""
echo "Install process completed."
echo "Summary: $success_count succeeded, $failed_count failed"

cd "$SCRIPT_DIR" || exit
exit $failed_count


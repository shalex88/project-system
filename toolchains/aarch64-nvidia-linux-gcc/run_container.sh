#!/bin/bash
set -euo pipefail

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --update|-u        Force rebuild the Docker image even if it already exists"
    echo "  --exec|-e COMMAND  Command to execute inside the container"
    echo "  --args|-a ARGS        Additional arguments to pass to docker run"
    echo "  --help|-h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run container with existing image"
    echo "  $0 --update                          # Rebuild image and run container"
    echo "  $0 --args \"-v $(pwd):/workspace\"      # Run with additional volume mount"
    echo "  $0 --exec \"echo hello\"               # Run a command inside the container"
    echo "  $0 --args \"-v $(pwd):/workspace\" --exec \"ls /workspace\"  # Combined options"
}

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
UPDATE_IMAGE=false
DOCKER_ARGS=""
EXEC_COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --update|-u)
            UPDATE_IMAGE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        --exec|-e)
            if [[ -n "${2-}" ]]; then
                EXEC_COMMAND="$2"
                shift 2
            else
                echo "Error: --exec requires a command argument"
                exit 1
            fi
            ;;
        --args|-a)
            if [[ -n "${2-}" ]]; then
                DOCKER_ARGS="$2"
                shift 2
            else
                echo "Error: --args requires arguments"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Variables
IMAGE_NAME="jetson-cross-toolchain:latest"
DOCKERFILE_PATH="$CURRENT_SCRIPT_DIR/Dockerfile"
DOCKERFILE_DIR="$CURRENT_SCRIPT_DIR"

# Build image if it doesn't exist or if update is requested
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 || [ "$UPDATE_IMAGE" = true ]; then
    if [ "$UPDATE_IMAGE" = true ]; then
        echo "Updating Docker image: $IMAGE_NAME"
    else
        echo "Building Docker image: $IMAGE_NAME"
    fi
    docker build -t "$IMAGE_NAME" \
        --build-arg USER_ID=$(id -u) \
        --build-arg GROUP_ID=$(id -g) \
        --build-arg USERNAME=$(whoami) \
        -f "$DOCKERFILE_PATH" "$DOCKERFILE_DIR"
    echo "Docker image $IMAGE_NAME built successfully."
    
    # If only updating, exit without running the container
    if [ "$UPDATE_IMAGE" = true ] && [ -z "$EXEC_COMMAND" ] && [ -z "$DOCKER_ARGS" ]; then
        exit 0
    fi
fi

# Detect if we have a TTY available - if not, don't use -it
if [ -t 0 ]; then
    DOCKER_TTY_FLAG="-it"
else
    DOCKER_TTY_FLAG=""
fi

if [[ -n "$EXEC_COMMAND" ]]; then
    if [[ -n "$DOCKER_ARGS" ]]; then
        docker run $DOCKER_TTY_FLAG --rm --privileged --net=host -v /dev/bus/usb:/dev/bus/usb $DOCKER_ARGS $IMAGE_NAME $EXEC_COMMAND
    else
        docker run $DOCKER_TTY_FLAG --rm --privileged --net=host -v /dev/bus/usb:/dev/bus/usb $IMAGE_NAME $EXEC_COMMAND
    fi
else
    if [[ -n "$DOCKER_ARGS" ]]; then
        docker run $DOCKER_TTY_FLAG --rm --privileged --net=host -v /dev/bus/usb:/dev/bus/usb $DOCKER_ARGS $IMAGE_NAME
    else
        docker run $DOCKER_TTY_FLAG --rm --privileged --net=host -v /dev/bus/usb:/dev/bus/usb $IMAGE_NAME
    fi
fi
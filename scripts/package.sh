#!/bin/bash

BUILD_TYPE=$1

# Handle clean option
if [ "$BUILD_TYPE" == "clean" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "Cleaning package directory..."
    rm -rf "$PROJECT_ROOT/package"/*
    echo "Done."
    exit 0
fi

if [ -z "$BUILD_TYPE" ] || { [ "$BUILD_TYPE" != "native" ] && [ "$BUILD_TYPE" != "cross" ]; }; then
    echo "Usage: $(basename "$0") <native|cross|clean>" >&2
    exit 1
fi

if [ "$BUILD_TYPE" == "cross" ]; then
    ARCH="arm64"
else
    ARCH="amd64"
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(cat "$PROJECT_ROOT/VERSION")
PROJECT_NAME=$(basename "$PROJECT_ROOT")
PACKAGE_NAME="$PROJECT_NAME-$VERSION-$ARCH"

# Prepare bundle directory structure
BUNDLE_DIR="$PROJECT_ROOT/package/$PACKAGE_NAME"
ORIN_DIR="$BUNDLE_DIR/platforms/orin"
MPSOC_DIR="$BUNDLE_DIR/platforms/mpsoc"
mkdir -p "$ORIN_DIR/local-repo" "$ORIN_DIR/scripts" "$MPSOC_DIR/local-repo" "$MPSOC_DIR/scripts" "$BUNDLE_DIR/scripts"

# Determine the build directory based on build type
if [ "$BUILD_TYPE" == "cross" ]; then
    BUILD_DIR="build-cross"
else
    BUILD_DIR="build-native"
fi

# Iterate through all directories in submodules and copy .deb files to local-repo
echo "Collecting .deb packages from submodules..."
DEB_COUNT=0
# Collect per-platform package lines to group in RELEASE.yaml
declare -A PLATFORM_PACKAGES

for platform_dir in "$PROJECT_ROOT/submodules"/*; do
    if [ -d "$platform_dir" ]; then
        platform_name=$(basename "$platform_dir")
        
        # Recursively find all build directories (build-cross or build-native)
        while IFS= read -r build_path; do
            # Find .deb files in the build directory and subdirectories
            while IFS= read -r -d '' deb_file; do
                # Skip files in _CPack_Packages subdirectories
                if [[ ! "$deb_file" =~ _CPack_Packages ]]; then
                    echo "  Found: $(basename "$deb_file")"
                    # Copy into per-platform local repo
                    dest_repo="$ORIN_DIR/local-repo"
                    [ "$platform_name" == "mpsoc" ] && dest_repo="$MPSOC_DIR/local-repo"
                    cp "$deb_file" "$dest_repo/"
                    ((DEB_COUNT++))
                    
                    # Extract package info for RELEASE.yaml
                    deb_basename=$(basename "$deb_file")
                    deb_name=$(echo "$deb_basename" | sed 's/_[0-9].*//')
                    deb_version=$(echo "$deb_basename" | sed -n 's/.*_\([0-9][^_]*\)_.*/\1/p')
                    # Append to platform-specific list
                    PLATFORM_PACKAGES["$platform_name"]+=$'    - name: '"$deb_name"$'\n'
                    PLATFORM_PACKAGES["$platform_name"]+=$'      version: '"$deb_version"$'\n'
                    PLATFORM_PACKAGES["$platform_name"]+=$'      file: '"$deb_basename"$'\n'
                fi
            done < <(find "$build_path" -name "*.deb" -type f -print0)
        done < <(find "$platform_dir" -type d -name "$BUILD_DIR")
    fi
done

echo "Collected $DEB_COUNT .deb package(s)"

# Create RELEASE.yaml grouped by platform
echo "Creating RELEASE.yaml..."
release_file="$BUNDLE_DIR/RELEASE.yaml"
cat > "$release_file" << EOF
release:
    name: $PROJECT_NAME
    version: $VERSION
    architecture: $ARCH
    created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

platforms:
EOF

# Append grouped package information
for platform in "${!PLATFORM_PACKAGES[@]}"; do
    {
        echo "  - name: $platform"
        echo "    packages:"
        # shellcheck disable=SC2154
        echo -e "${PLATFORM_PACKAGES[$platform]}"
    } >> "$release_file"
done

pushd "$ORIN_DIR/local-repo" > /dev/null || exit
dpkg-scanpackages . /dev/null 2>/dev/null | gzip -9c > Packages.gz
popd > /dev/null || exit

pushd "$MPSOC_DIR/local-repo" > /dev/null || exit
dpkg-scanpackages . /dev/null 2>/dev/null | gzip -9c > Packages.gz
popd > /dev/null || exit

# Create orchestrator and per-platform install scripts
cat > "$BUNDLE_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Installing Orin packages from local repo..."
ORIN_REPO="$BUNDLE_ROOT/platforms/orin/local-repo"
sudo apt-get update || true
sudo apt-get install -y apt-transport-https gnupg || true

# Use dpkg + apt-fix to avoid persistent sources modification
sudo dpkg -i "$ORIN_REPO"/*.deb || sudo apt-get -f install -y

MPSOC_TARGET=${1:-}
if [ -n "$MPSOC_TARGET" ]; then
    echo "Deploying MPSOC packages to $MPSOC_TARGET..."
    bash "$BUNDLE_ROOT/scripts/deploy_mpsoc.sh" "$MPSOC_TARGET"
else
    echo "MPSOC target not provided; skipping remote install."
fi
EOF
chmod +x "$BUNDLE_DIR/scripts/install.sh"

cat > "$BUNDLE_DIR/scripts/deploy_mpsoc.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

TARGET=${1:?"Usage: deploy_mpsoc.sh <user@host>"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_DIR="/tmp/project-system-mpsoc"

echo "Copying MPSOC subtree to $TARGET:$REMOTE_DIR ..."
ssh "$TARGET" "mkdir -p '$REMOTE_DIR'"
scp -r "$BUNDLE_ROOT/platforms/mpsoc" "$TARGET:$REMOTE_DIR/"

echo "Running remote install on MPSOC..."
ssh -t "$TARGET" "bash '$REMOTE_DIR/mpsoc/scripts/install.sh'"
EOF
chmod +x "$BUNDLE_DIR/scripts/deploy_mpsoc.sh"

cat > "$ORIN_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local-repo"
echo "Installing Orin packages from $REPO_DIR"
sudo dpkg -i "$REPO_DIR"/*.deb || sudo apt-get -f install -y
EOF
chmod +x "$ORIN_DIR/scripts/install.sh"

cat > "$MPSOC_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local-repo"
echo "Installing MPSOC packages from $REPO_DIR"
sudo dpkg -i "$REPO_DIR"/*.deb || sudo apt-get -f install -y
EOF
chmod +x "$MPSOC_DIR/scripts/install.sh"

# Create bundle archive
pushd "$PROJECT_ROOT/package" > /dev/null || exit
tar czf "$PACKAGE_NAME.bundle" "$PACKAGE_NAME/"
popd > /dev/null || exit

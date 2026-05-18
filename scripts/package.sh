#!/bin/bash

BUILD_TYPE=$1
BUILD_MODE=$2

if [ -z "$BUILD_TYPE" ] || { [ "$BUILD_TYPE" != "native" ] && [ "$BUILD_TYPE" != "cross" ]; }; then
    echo "Usage: $(basename "$0") <native|cross> <debug|release>" >&2
    exit 1
fi

if [ -z "$BUILD_MODE" ] || { [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release" ]; }; then
    echo "Usage: $(basename "$0") <native|cross> <debug|release>" >&2
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
PACKAGE_NAME="$PROJECT_NAME-$VERSION-$ARCH-$BUILD_TYPE-$BUILD_MODE"

# Prepare bundle directory structure
BUNDLE_DIR="$PROJECT_ROOT/package/$PACKAGE_NAME"
ORIN_DIR="$BUNDLE_DIR/platforms/orin"
MPSOC_DIR="$BUNDLE_DIR/platforms/mpsoc"
mkdir -p "$ORIN_DIR/local-repo" "$ORIN_DIR/scripts" "$MPSOC_DIR/local-repo" "$MPSOC_DIR/scripts" "$BUNDLE_DIR/scripts"

# Determine the build directory pattern based on build type and mode
# Standard pattern is build/<build-type>-<build-mode>
BUILD_DIR_PATTERN="$BUILD_TYPE-$BUILD_MODE"

# Iterate through all directories in submodules and copy .deb files to local-repo
echo "Collecting .deb packages from submodules..."
DEB_COUNT=0
# Collect per-platform package lines to group in RELEASE.yaml
declare -A PLATFORM_PACKAGES

for platform_dir in "$PROJECT_ROOT/submodules"/*; do
    if [ -d "$platform_dir" ]; then
        platform_name=$(basename "$platform_dir")

        # Recursively find all build directories matching the selected build pattern
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
        done < <(find "$platform_dir" -type d -name "$BUILD_DIR_PATTERN")
    fi
done

echo "Collected $DEB_COUNT .deb package(s)"

if [ "$DEB_COUNT" -eq 0 ]; then
    echo "Error: No .deb packages found for preset '$BUILD_DIR_PATTERN'." >&2
    echo "Build the selected preset first (e.g. ./scripts/build.sh $BUILD_TYPE $BUILD_MODE) and retry." >&2
    exit 1
fi

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

# Recompress any zstd-compressed .deb files to xz for compatibility with older dpkg
echo "Checking .deb compression compatibility..."
for repo_dir in "$ORIN_DIR/local-repo" "$MPSOC_DIR/local-repo"; do
    for deb_file in "$repo_dir"/*.deb; do
        [ -f "$deb_file" ] || continue
        if ar t "$deb_file" 2>/dev/null | grep -q "\.zst$"; then
            echo "  Recompressing $(basename "$deb_file") (zstd -> xz)..."
            tmpdir=$(mktemp -d)
            dpkg-deb -R "$deb_file" "$tmpdir"
            dpkg-deb -Zxz -b "$tmpdir" "$deb_file"
            rm -rf "$tmpdir"
        fi
    done
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
apt-get update || true

shopt -s nullglob
ORIN_DEBS=("$ORIN_REPO"/*.deb)
if [ ${#ORIN_DEBS[@]} -eq 0 ]; then
    echo "Error: No .deb packages found in $ORIN_REPO" >&2
    exit 1
fi

# Use dpkg + apt-fix to avoid persistent sources modification
dpkg -i "${ORIN_DEBS[@]}" || apt-get -f install -y

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
shopt -s nullglob
DEBS=("$REPO_DIR"/*.deb)
if [ ${#DEBS[@]} -eq 0 ]; then
    echo "Error: No .deb packages found in $REPO_DIR" >&2
    exit 1
fi
dpkg -i "${DEBS[@]}" || apt-get -f install -y
EOF
chmod +x "$ORIN_DIR/scripts/install.sh"

cat > "$MPSOC_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local-repo"
echo "Installing MPSOC packages from $REPO_DIR"
shopt -s nullglob
DEBS=("$REPO_DIR"/*.deb)
if [ ${#DEBS[@]} -eq 0 ]; then
    echo "Error: No .deb packages found in $REPO_DIR" >&2
    exit 1
fi
dpkg -i "${DEBS[@]}" || apt-get -f install -y
EOF
chmod +x "$MPSOC_DIR/scripts/install.sh"

# Create bundle archive
pushd "$PROJECT_ROOT/package" > /dev/null || exit
tar czf "$PACKAGE_NAME.bundle" "$PACKAGE_NAME/"
popd > /dev/null || exit

#!/bin/bash
set -euo pipefail

# This deploy script runs on the host machine.
# It copies the bundle to Orin, extracts it, and triggers install (Orin + MPSOC).

usage() {
	cat <<EOF
Usage: $(basename "$0") --orin <user@host> [--mpsoc <user@host>]

Options:
  --orin <user@host>   Target for Orin (main platform)
  --mpsoc <user@host>  Target for MPSOC (secondary platform, optional)

Examples:
  # Deploy to Orin only
  $(basename "$0") --orin user@192.168.1.10

  # Deploy to Orin and forward MPSOC install
  $(basename "$0") --orin user@192.168.1.10 --mpsoc user@192.168.1.20
EOF
	exit 1
}

ORIN_TARGET=""
MPSOC_TARGET=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--orin)
			ORIN_TARGET="$2"
			shift 2
			;;
		--mpsoc)
			MPSOC_TARGET="$2"
			shift 2
			;;
		*)
			echo "Unknown option: $1" >&2
			usage
			;;
	esac
done

if [ -z "$ORIN_TARGET" ]; then
	echo "Error: --orin target is required" >&2
	usage
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(cat "$PROJECT_ROOT/VERSION")
PROJECT_NAME=$(basename "$PROJECT_ROOT")
ARCH="arm64"
PACKAGE_NAME="$PROJECT_NAME-$VERSION-$ARCH"
BUNDLE_FILE="$PROJECT_ROOT/package/$PACKAGE_NAME.bundle"

if [ ! -f "$BUNDLE_FILE" ]; then
	echo "Error: Bundle not found at $BUNDLE_FILE" >&2
	echo "Run 'scripts/package.sh cross' first." >&2
	exit 1
fi

echo "Deploying $PACKAGE_NAME to Orin: $ORIN_TARGET"
echo "Copying bundle to Orin..."
scp "$BUNDLE_FILE" "$ORIN_TARGET:/tmp/"

echo "Extracting bundle on Orin..."
ssh "$ORIN_TARGET" "tar xzf /tmp/$PACKAGE_NAME.bundle -C /tmp"

REMOTE_BUNDLE_DIR="/tmp/$PACKAGE_NAME"
INSTALL_CMD="$REMOTE_BUNDLE_DIR/scripts/install.sh"

if [ -n "$MPSOC_TARGET" ]; then
	echo "Triggering install on Orin with MPSOC target: $MPSOC_TARGET"
	ssh -t "$ORIN_TARGET" "bash $INSTALL_CMD $MPSOC_TARGET"
else
	echo "Triggering install on Orin (no MPSOC target)"
	ssh -t "$ORIN_TARGET" "bash $INSTALL_CMD"
fi

echo "Deployment complete."


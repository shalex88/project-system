#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION=$(cat ../VERSION)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
PACKAGE_NAME="$PROJECT_NAME-$VERSION"

TARGET=$1

# scp "../package/$PACKAGE_NAME" "$TARGET:/tmp/" &&

# ssh "$TARGET" "
#     tar xzf /tmp/$PACKAGE_NAME.bundle &&
#     /tmp/$PACKAGE_NAME/scripts/install.sh
# "

cp "$PROJECT_ROOT/package/$PACKAGE_NAME.bundle" "/tmp/" &&
tar xzf "/tmp/$PACKAGE_NAME.bundle" -C /tmp


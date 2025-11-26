#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION=$(cat ../VERSION)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
#TODO: detect architecture
PACKAGE_NAME="$PROJECT_NAME-$VERSION-amd64"

mkdir -p "$PROJECT_ROOT/package/$PACKAGE_NAME/local-repo"
#TODO: copy necessary files to the package directory
#TODO: create RELEASE.yml

pushd "$PROJECT_ROOT/package/$PACKAGE_NAME/local-repo" > /dev/null || exit
dpkg-scanpackages . /dev/null 2>/dev/null | gzip -9c > Packages.gz

cd ../..
tar czf "$PACKAGE_NAME.bundle" "$PACKAGE_NAME/"
popd > /dev/null || exit

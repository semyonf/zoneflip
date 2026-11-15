#!/bin/sh
# Compiles Resources/AppIcon.icon (Icon Composer) into Resources/Assets.car and Resources/AppIcon.icns.
# Needs full Xcode 26+; the compiled files are committed, so build.sh works with Command Line Tools only.
set -e
cd "$(dirname "$0")"
R="$(pwd)/Resources" # absolute: actool resolves relative paths against a stale working directory
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun actool "$R/AppIcon.icon" --compile "$R" --platform macosx \
	--minimum-deployment-target 14.0 --app-icon AppIcon \
	--output-partial-info-plist /dev/null --output-format human-readable-text

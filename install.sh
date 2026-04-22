#!/usr/bin/env bash
#
# install.sh — Install or update xpath-dir to /usr/bin
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${SCRIPT_DIR}/xpath-dir"
TARGET="/usr/bin/xpath-dir"

# Check that the source file exists
if [[ ! -f "$SOURCE" ]]; then
    echo "Error: xpath-dir not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

# Install requires root privileges for /usr/bin
if [[ $EUID -ne 0 ]]; then
    echo "Installing to ${TARGET} requires root privileges. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# Copy (or overwrite) and set executable permissions
cp -f "$SOURCE" "$TARGET"
chmod 755 "$TARGET"

echo "xpath-dir installed successfully to ${TARGET}"

#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

packages=(
    brave-browser
    code
    coolercontrol
    ghostty
    mpv-nightly
)

if [[ "${#packages[@]}" -gt 0 ]]; then
    dnf5 install -yq "${packages[@]}"
else
    echo "No packages to install"
fi

echo "::endgroup::"
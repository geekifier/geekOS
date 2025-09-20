#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

packages=(
  "code:code"
  "brave-browser:brave-browser"
  "terra:coolercontrol"
  "terra:ghostty"
  "terra:mpv-nightly"
)

((${#packages[@]})) || {
  echo "No packages to install"
  exit 0
}

# CSV of unique repos, which can be supplied to --enablerepo
repos_csv=$(
  printf '%s\n' "${packages[@]}" |
    awk -F: '{print $1}' |
    sort -u |
    paste -sd,
)

mapfile -t pkgs < <(printf '%s\n' "${packages[@]##*:}")

DNF5_FORCE_INTERACTIVE=0 dnf5 install -yq --enable-repo="$repos_csv" "${pkgs[@]}"

echo "::endgroup::"

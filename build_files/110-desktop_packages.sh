#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

packages=(
  "code::code"
  "brave-browser::brave-browser"
  "fedora::hardinfo2"
  "fedora::solaar"
  "fedora::wireshark"
  "terra::coolercontrol"
  "terra::ghostty"
  "terra::mpv-nightly"
)

# Packages for non-nvidia images only

if [[ "${TARGET_IMAGE_NAME:-}" != *nvidia* ]]; then
  packages+=("copr:copr.fedorainfracloud.org:ilyaz:LACT::lact")
fi


((${#packages[@]})) || {
  echo "No packages to install"
  exit 0
}

# CSV of unique repos, which can be supplied to --enablerepo
repos_csv=$(
  printf '%s\n' "${packages[@]}" |
    awk -F:: '{print $1}' |
    sort -u |
    paste -sd,
)

mapfile -t pkgs < <(printf '%s\n' "${packages[@]##*::}")

DNF5_FORCE_INTERACTIVE=0 dnf5 install -yq --enable-repo="$repos_csv" "${pkgs[@]}"

# Disable copr repos after install

# awk indexes start from 1
# a[1]=copr, a[2]=copr.fedorainfracloud.org, a[3]=user, a[4]=project
copr_repos=$(
  printf '%s\n' "${packages[@]}" |
    awk -F'::' '$1 ~ /^copr:/ {
        n = split($1, a, ":");
        if (n >= 4 && a[3] != "" && a[4] != "") {
            print a[3] "/" a[4]
        }
    }' |
    sort -u
)

while IFS= read -r repo; do
  echo "Disabling COPR repo: $repo"
  if ! dnf5 -yq copr disable "$repo"; then
    echo "Warning: failed to disable COPR repo $repo" >&2
  fi
done <<< "$copr_repos"


echo "::endgroup::"

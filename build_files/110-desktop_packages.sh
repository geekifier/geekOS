#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

packages=(
  "code::code"
  "brave-browser::brave-browser"
  "copr:copr.fedorainfracloud.org:scottames:ghostty::ghostty"
  "fedora::hardinfo2"
  "fedora::iperf3"
  "fedora::solaar"
  "fedora::sysbench"
  "fedora::wireshark"
  "terra::coolercontrol"
  "terra::mpv-nightly"
)

# Packages for non-nvidia images only

if [[ "${TARGET_IMAGE_NAME:-}" != *nvidia* ]]; then
  packages+=("copr:copr.fedorainfracloud.org:ilyaz:LACT::lact")
fi


(( ${#packages[@]} )) || { echo "No packages to install"; exit 0; }

# Install with one transaction per repo to ensure correct prioritization.
declare -A repo_pkgs=()
for spec in "${packages[@]}"; do
  repo_id=${spec%%::*}
  pkg_name=${spec##*::}
  # Append (space separated) preserving order; guard for unset under set -u
  repo_pkgs[$repo_id]="${repo_pkgs[$repo_id]:-} ${pkg_name}"
done

for repo_id in "${!repo_pkgs[@]}"; do
  # Split the accumulated list into an array (handles leading space)
  read -r -a _repo_pkg_array <<< "${repo_pkgs[$repo_id]}"
  echo "Installing from repo '$repo_id': ${_repo_pkg_array[*]}"
  if ! DNF5_FORCE_INTERACTIVE=0 dnf5 install -yq --enable-repo="$repo_id" "${_repo_pkg_array[@]}"; then
    echo "Error: failed installing packages from repo '$repo_id'" >&2
    exit 1
  fi
done

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

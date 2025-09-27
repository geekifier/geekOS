#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Set up custom repo files, but do not enable them by default,
# as we do not expect users to update packages manually.

# Brave Browser
dnf5 -yq config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
dnf5 -yq config-manager setopt brave-browser.enabled=false

# # Terra repos
# dnf5 -yq config-manager setopt terra.enabled=true
# dnf5 -yq config-manager setopt terra-extras.enabled=true

# copr repos
copr_repos=(
    "ilyaz/LACT"
)

# Enable defined copr repos
for repo in "${copr_repos[@]}"; do
    dnf5 -yq copr enable "$repo"
done

# VSCode
rpm --quiet --import https://packages.microsoft.com/keys/microsoft.asc

cat > /etc/yum.repos.d/vscode.repo <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=0
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF


echo "::endgroup::"
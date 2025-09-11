#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

packages=(
    adcli
    krb5-workstation
    oddjob
    oddjob-mkhomedir
    printer-driver-brlaser
    neovim
    samba-common-tools
    samba-winbind
    samba-winbind-clients
    samba-winbind-modules
    samba-winbind-krb5-locator
    sssd-ad
    zsh
)

if [[ "${#packages[@]}" -gt 0 ]]; then
    dnf5 install -yq "${packages[@]}"
else
    echo "No packages to install"
fi

echo "::endgroup::"
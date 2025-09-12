#!/usr/bin/env bash

# Stolen from https://github.com/blue-build/modules/blob/main/modules/dnf/optfix.sh
# Later adapted to https://github.com/astrovm/amyos/blob/main/build_files/fix-opt.sh

echo "::group:: ===$(basename "$0")==="

set -euo pipefail

for dir in /var/opt/*/; do
  [ -d "$dir" ] || continue
  dirname=$(basename "$dir")
  mv "$dir" "/usr/lib/opt/$dirname"
  echo "L+ /var/opt/$dirname - - - - /usr/lib/opt/$dirname" >>/usr/lib/tmpfiles.d/geekos-optfix.conf
done

echo "::endgroup::"
#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="
set -euo pipefail

# This script bakes akmod + kmod metapackages for nct6687d into the image.

MODULE_NAME="nct6687d"
WORKDIR="/tmp/${MODULE_NAME}"
TOPDIR="${WORKDIR}/rpmbuild"
PKG_VERSION=""

# Ensure build prerequisites (some are also runtime requirements for akmods)
if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "Installing rpm build prerequisites..."
  dnf5 install -yq rpm-build kmodtool akmods gcc make elfutils-libelf-devel kernel-devel || {
    echo "Failed installing build prerequisites" >&2
    exit 1
  }
fi

rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}" && cd "${WORKDIR}"

echo "Cloning upstream source..."
git clone --depth 1 https://github.com/Fred78290/nct6687d src
cd src
COMMIT_HASH="$(git rev-parse --short=7 HEAD)"
COMMIT_COUNT="$(git rev-list --all --count 2>/dev/null || echo '1')"

# Use git commit count as patch version (like upstream does)
PKG_VERSION="${COMMIT_COUNT}"
echo "Derived module version: 1.0.${PKG_VERSION} (commit count)" >&2

# Prepare source tarball structure expected by spec
# Spec Version is "1.0.%{pkgver}" which expands to "1.0.${PKG_VERSION}"
SPEC_VERSION="1.0.${PKG_VERSION}"
BUILD_ROOT="${WORKDIR}/build" && rm -rf "${BUILD_ROOT}" && mkdir -p "${BUILD_ROOT}/${MODULE_NAME}-${SPEC_VERSION}/${MODULE_NAME}" && \
  cp LICENSE Makefile nct6687.c "${BUILD_ROOT}/${MODULE_NAME}-${SPEC_VERSION}/${MODULE_NAME}" && \
  cd "${BUILD_ROOT}" && tar -czf "${MODULE_NAME}-${SPEC_VERSION}.tar.gz" "${MODULE_NAME}-${SPEC_VERSION}" && cd -

if [[ ! -f "${BUILD_ROOT}/${MODULE_NAME}-${SPEC_VERSION}.tar.gz" ]]; then
  echo "Error: expected tarball ${BUILD_ROOT}/${MODULE_NAME}-${SPEC_VERSION}.tar.gz not found" >&2
  exit 1
fi

echo "Creating RPM build tree at ${TOPDIR}"
mkdir -p "${TOPDIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp "${BUILD_ROOT}/${MODULE_NAME}-${SPEC_VERSION}.tar.gz" "${TOPDIR}/SOURCES/"
# Spec expects nct6687.conf (without 'd'), and content should be module name without 'd'
echo "nct6687" > "${TOPDIR}/SOURCES/nct6687.conf"
cp fedora/*.spec "${TOPDIR}/SPECS/"

# Only replace placeholders if they exist; prevent unintended substitutions
for spec in "${TOPDIR}/SPECS"/*.spec; do
  grep -q 'MAKEFILE_COMMITHASH' "$spec" && sed -i "s/MAKEFILE_COMMITHASH/${COMMIT_HASH}/g" "$spec"
  grep -q 'MAKEFILE_PKGVER' "$spec" && sed -i "s/MAKEFILE_PKGVER/${PKG_VERSION}/g" "$spec"
done

echo "Specs present:" >&2; ls -1 "${TOPDIR}/SPECS" >&2
echo "Sources present:" >&2; ls -1 "${TOPDIR}/SOURCES" >&2

rpmb() {
  rpmbuild "$@" \
    --define "_topdir ${TOPDIR}" \
    --define "_sourcedir ${TOPDIR}/SOURCES" \
    --define "_specdir ${TOPDIR}/SPECS" \
    --define "_srcrpmdir ${TOPDIR}/SRPMS" \
    --define "_rpmdir ${TOPDIR}/RPMS" \
    --define "dist .fc42" \
    --define "make_build_target %{nil}"
}

echo "Building kmod-common package (provides modprobe config)..."
export HOME="${WORKDIR}"; mkdir -p "${HOME}/rpmbuild"; ln -sf "${TOPDIR}" "${HOME}/rpmbuild"

set -x
# First build the -common package from the non-kmod spec
rpmb -ba "${TOPDIR}/SPECS/${MODULE_NAME}.spec" || { echo "kmod-common spec build failed" >&2; exit 1; }
# Then build akmod + metapackage from kmod spec
rpmb -ba "${TOPDIR}/SPECS/${MODULE_NAME}-kmod.spec" || { echo "kmod spec build failed" >&2; exit 1; }
set +x

COMMON_RPMS=$(find "${TOPDIR}/RPMS" -type f -name "${MODULE_NAME}-[0-9]*.rpm")
AKMOD_RPMS=$(find "${TOPDIR}/RPMS" -type f -name "akmod-${MODULE_NAME}*.rpm")
META_RPMS=$(find "${TOPDIR}/RPMS" -type f -name "kmod-${MODULE_NAME}*.rpm")

if [[ -n "${AKMOD_RPMS}" ]]; then
  echo "Installing akmod RPM(s) into image..."
  dnf5 install -yq "${COMMON_RPMS}" "${AKMOD_RPMS}" "${META_RPMS}" || { echo "Failed to install akmod RPMs" >&2; exit 1; }
else
  echo "Warning: akmod RPM not found; skipping install" >&2
fi

# Note: nct6687d-kmod-common RPM provides /usr/lib/modules-load.d/nct6687d.conf

# Cleanup ephemeral build workspace to minimize final layer size
rm -rf "${WORKDIR}" || echo "Warning: failed to cleanup ${WORKDIR}" >&2

echo "Baked akmods packaging for ${MODULE_NAME} (version 1.0.${PKG_VERSION}, commit ${COMMIT_HASH})"
echo "::endgroup::"

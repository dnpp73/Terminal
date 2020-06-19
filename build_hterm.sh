#!/bin/bash

set -Ceu

HTERM_VERSION='1.89'

CURRENT_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

cd "${TMPDIR}" || exit 1

echo "CURRENT_DIR: ${CURRENT_DIR}"
echo "TMPDIR: ${TMPDIR}"

git clone 'https://chromium.googlesource.com/apps/libapps'
cd ./libapps || exit 1
git checkout "refs/tags/hterm-${HTERM_VERSION}"

./hterm/bin/mkdist

mkdir -p "${CURRENT_DIR}/Terminal/Resources"
cp -f './hterm/dist/js/hterm_all.js' "${CURRENT_DIR}/Terminal/Resources"

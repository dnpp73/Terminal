#!/bin/bash

set -euo pipefail

SRCROOT=$(cd "$(dirname "$0")/../" || exit 1; pwd)
PLATFORM_NAME='iphoneos'

echo "SRCROOT: ${SRCROOT}"
echo "PLATFORM_NAME: ${PLATFORM_NAME}"

if [ ! -x /usr/local/bin/carthage ]; then
    echo "error: Carthage not installed."
    exit 1
fi

# workaround for carthage 0.35.0 and 0.35.1 with Xcode 12
# see https://github.com/Carthage/Carthage/issues/3019#issuecomment-693381253
xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "${xcconfig}"' INT TERM HUP EXIT

# For Xcode 12 make sure EXCLUDED_ARCHS is set to arm architectures otherwise
# the build will fail on lipo due to duplicate architectures.

CURRENT_XCODE_VERSION=$(xcodebuild -version | grep "Build version" | cut -d ' ' -f3)
echo "CURRENT_XCODE_VERSION: ${CURRENT_XCODE_VERSION}"

echo "EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_${CURRENT_XCODE_VERSION} = arm64 arm64e armv7 armv7s armv6 armv8" >> "${xcconfig}"
echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$(XCODE_PRODUCT_BUILD_VERSION))' >> "${xcconfig}"
echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> "${xcconfig}"
echo 'ONLY_ACTIVE_ARCH=NO' >> "${xcconfig}"
echo 'VALID_ARCHS = $(inherited) x86_64' >> "${xcconfig}"

export XCODE_XCCONFIG_FILE="${xcconfig}"
echo "${XCODE_XCCONFIG_FILE}"

if [ $# -eq 1 ]; then
    /usr/local/bin/carthage "${1}" --platform "${PLATFORM_NAME}" --project-directory "${SRCROOT}" --cache-builds --no-use-binaries
elif [ $# -gt 0 ]; then
    /usr/local/bin/carthage "$@"
elif [ ! -d "${SRCROOT}/Carthage/Build" ]; then
    /usr/local/bin/carthage bootstrap --platform "${PLATFORM_NAME}" --project-directory "${SRCROOT}" --cache-builds --no-use-binaries
else
    /usr/local/bin/carthage build --platform "${PLATFORM_NAME}" --project-directory "${SRCROOT}" --cache-builds --no-use-binaries
fi

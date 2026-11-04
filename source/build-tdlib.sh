#!/usr/bin/env bash
# region @MadeByLLM("gpt-6", id = "android13-arm64")
set -e

TDLIB_SOURCE_DIR=${1:-td}
TDLIB_INSTALL_DIR=${2:-build/td}
OPENSSL_INSTALL_DIR=${3:-build/openssl}
ANDROID_SDK_PACKAGE=${4:-android-37.2}
TDLIB_BUILD_SCRIPT="$(pwd)/build-tdlib-impl.sh"
TGX_FLAVORS=${5:-"latest"}

source "$(pwd)/setup.sh" --light

if [ "$CMAKE_VERSION" != "3.22.1" ] ; then
  echo 'Error: CMAKE_VERSION must be 3.22.1'
  exit 1
fi

if [ ! -d "$JAVA_HOME" ] ; then
  echo "Error: directory \"$JAVA_HOME\" doesn't exist. Set a valid path via JAVA_HOME."
  exit 1
fi

if [ ! -d "$ANDROID_SDK_ROOT" ] ; then
  echo "Error: directory \"$ANDROID_SDK_ROOT\" doesn't exist. Set a valid path via ANDROID_SDK_ROOT."
  exit 1
fi

if [ ! -d "$OPENSSL_INSTALL_DIR" ] ; then
  echo "Error: directory \"$OPENSSL_INSTALL_DIR\" doesn't exists. Run ./build-openssl.sh first."
  exit 1
fi

if [ -e "$TDLIB_INSTALL_DIR" ] ; then
  echo "Error: file or directory \"$TDLIB_INSTALL_DIR\" already exists. Delete it manually to proceed."
  exit 1
fi

if [ ! -e "$TDLIB_BUILD_SCRIPT" ] ; then
  echo "Error: file or directory \"$TDLIB_BUILD_SCRIPT\" doesn't exists."
  exit 1
fi

ANDROID_SDK_ROOT="$(cd "$(dirname -- "$ANDROID_SDK_ROOT")" >/dev/null; pwd -P)/$(basename -- "$ANDROID_SDK_ROOT")"
TDLIB_SOURCE_DIR="$(cd "$(dirname -- "$TDLIB_SOURCE_DIR")" >/dev/null; pwd -P)/$(basename -- "$TDLIB_SOURCE_DIR")"
TDLIB_INSTALL_DIR="$(cd "$(dirname -- "$TDLIB_INSTALL_DIR")" >/dev/null; pwd -P)/$(basename -- "$TDLIB_INSTALL_DIR")"
OPENSSL_INSTALL_DIR="$(cd "$(dirname -- "$OPENSSL_INSTALL_DIR")" >/dev/null; pwd -P)/$(basename -- "$OPENSSL_INSTALL_DIR")"

pushd "$TDLIB_SOURCE_DIR" > /dev/null || exit 1
TDLIB_COMMIT="$(git rev-parse HEAD)"
popd > /dev/null || exit 1

for TGX_FLAVOR in $TGX_FLAVORS; do
  if [ "$TGX_FLAVOR" != "latest" ]; then
    echo "Only the latest flavor (Android 13+) is supported: $TGX_FLAVOR" >&2
    exit 1
  fi
  ANDROID_NDK_VERSION="$ANDROID_NDK_VERSION_PRIMARY"
  ANDROID_API_LEVEL=33
  ABIS="arm64-v8a"

  echo "Start build TDLib, flavor: $TGX_FLAVOR ndk: $ANDROID_NDK_VERSION, abi: $ABIS, api: $ANDROID_API_LEVEL"

  # Make sure configurations from different NDKs are not reused
  pushd "${TDLIB_SOURCE_DIR:?}" > /dev/null || exit 1
  git clean -ffdx
  popd > /dev/null || exit 1

  pushd "$TDLIB_SOURCE_DIR/example/android" > /dev/null || exit 1
  rm build-tdlib.sh
  cp "$TDLIB_BUILD_SCRIPT" build-tdlib.sh
  ./build-tdlib.sh "$ANDROID_SDK_ROOT" "$ANDROID_NDK_VERSION" "$OPENSSL_INSTALL_DIR" "c++_shared" Java "$ANDROID_API_LEVEL" "$ABIS" "$ANDROID_SDK_PACKAGE" || exit 1
  popd > /dev/null || exit 1

  mkdir -p "$TDLIB_INSTALL_DIR/$ANDROID_NDK_VERSION/android-$ANDROID_API_LEVEL"
  mv "$TDLIB_SOURCE_DIR/example/android/tdlib" "$TDLIB_INSTALL_DIR/$ANDROID_NDK_VERSION/android-$ANDROID_API_LEVEL/tdlib" || exit 1

done

echo "$TDLIB_COMMIT" > "$TDLIB_INSTALL_DIR/version.txt"

echo "Built TDLib: $TDLIB_INSTALL_DIR, commit: $TDLIB_COMMIT"
# endregion

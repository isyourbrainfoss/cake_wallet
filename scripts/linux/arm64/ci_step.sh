#!/bin/bash
# Steps for the native aarch64 Linux build (.github/workflows/linux-arm64.yml).
# Runs INSIDE the multi-arch Cake build image (arm64 variant) as root, repo mounted at $PWD.
# Usage: scripts/linux/arm64/ci_step.sh <step> [args]
set -x -e
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
export FORCE_UNSAFE_CONFIGURE=1
git config --global --add safe.directory '*'
git config --global user.email "ci@example.invalid"
git config --global user.name "CI"

TARGET_TRIPLE="aarch64-linux-gnu"

step="$1"; shift || true
case "$step" in
  info)
    uname -a; nproc; free -g; df -h "$ROOT"
    flutter --version; go version; rustc --version; cargo --version
    ;;
  monero)
    # $1 = monero | wownero
    COIN="$1" TARGET="$TARGET_TRIPLE" ./scripts/linux/build_monero_all.sh
    ls -la scripts/monero_c/release/*/"$TARGET_TRIPLE"/
    ;;
  zcash)
    ./scripts/linux/build_zcash.sh
    ls -la scripts/zcash_lib/target/release/libwarp_api_ffi.so
    ;;
  monero_c_checkout)
    # Lightweight (blobless, no checkout) clone so linux/CMakeLists.txt can resolve
    # `git describe --tags` and find release/<tag>/aarch64-linux-gnu.
    HASH=$(grep -Eo 'git checkout [0-9a-f]{40}' scripts/prepare_moneroc.sh | awk '{print $3}')
    if [[ ! -d scripts/monero_c/.git ]]; then
      rm -rf scripts/monero_c
      git clone --filter=blob:none --no-checkout https://github.com/mrcyjanek/monero_c scripts/monero_c
    fi
    git -C scripts/monero_c update-ref --no-deref HEAD "$HASH"
    git -C scripts/monero_c describe --tags
    ;;
  dart_deps)
    # Android-only native stages are not needed on Linux; only sources / Dart codegen.
    pushd scripts
      ./build_bitbox_flutter.sh clone-only
      ./prepare_torch.sh
    popd
    # mweb: MWEB is disabled on desktop, but ffigen bindings are still needed to compile.
    # Build a native linux c-shared lib just to obtain the cgo header ffigen reads.
    mkdir -p cw_mweb/android/src/main/jniLibs/arm64-v8a
    pushd cw_mweb/go
      CGO_ENABLED=1 go build -v -buildmode=c-shared -o ../android/src/main/jniLibs/arm64-v8a/libmweb.so .
    popd
    if ! ls /usr/lib/llvm-*/lib/libclang.so* >/dev/null 2>&1 && ! ls /usr/lib/*/libclang*.so* >/dev/null 2>&1; then
      apt-get update && apt-get install -y --no-install-recommends libclang-dev
    fi
    pushd cw_mweb
      flutter pub get
      dart run ffigen --config ffigen_config.yaml
    popd
    rm -f cw_mweb/android/src/main/jniLibs/arm64-v8a/libmweb.so
    ;;
  reown)
    # Mirrors scripts/linux/docker/Dockerfile.reown minus the Android (cargo-ndk) native build.
    # Run in a throwaway container: switches the image's Flutter to 3.32.0 like upstream does.
    cd "$(dirname "$(which flutter)")"
    git checkout 3.32.0
    cd "$ROOT"
    flutter --version
    ./scripts/prepare_reown.sh
    rm -rf scripts/reown_flutter/packages/*/.dart_tool scripts/reown_flutter/packages/*/example/.dart_tool \
      scripts/reown_flutter/packages/reown_appkit/example/*/.dart_tool scripts/reown_flutter/.dart_tool
    ;;
  app)
    pushd scripts/linux
      source ./app_env.sh cakewallet
      ./app_config.sh
    popd
    flutter pub get
    dart run tool/generate_new_secrets.dart
    ./model_generator.sh
    dart run tool/generate_localization.dart
    ./compile_graphics.sh
    flutter build linux --release
    ls -la build/linux/arm64/release/bundle build/linux/arm64/release/bundle/lib
    file build/linux/arm64/release/bundle/cake_wallet || true
    ;;
  *)
    echo "unknown step: $step"; exit 1;;
esac

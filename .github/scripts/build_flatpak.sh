#!/bin/bash
# Build the community Flatpak from a prebuilt bundle tarball on the arm64 runner.
set -x -e
TARBALL="$1"
cd "$GITHUB_WORKSPACE/linux/flatpak"
rm -rf bundle && tar xzf "$TARBALL"
test -x bundle/cake_wallet
sudo apt-get update
sudo apt-get install -y --no-install-recommends flatpak flatpak-builder elfutils
# Ubuntu 24.04 restricts unprivileged user namespaces, which bwrap needs.
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 || true
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y --noninteractive flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08
APP_ID=io.github.isyourbrainfoss.CakeWalletMobile
flatpak-builder --user --force-clean --repo=repo build-dir "$APP_ID.yml"
flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
  repo "$GITHUB_WORKSPACE/cakewallet-mobile-aarch64.flatpak" "$APP_ID"
ls -la "$GITHUB_WORKSPACE/cakewallet-mobile-aarch64.flatpak"

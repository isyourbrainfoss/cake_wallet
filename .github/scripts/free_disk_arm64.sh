#!/bin/bash
# Reclaim space on the GitHub arm64 runner before pulling the large build image.
set -x
df -h
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/.ghcup \
  /opt/hostedtoolcache/CodeQL /usr/local/share/boost /usr/share/swift \
  /usr/local/share/powershell /usr/local/lib/node_modules /opt/microsoft || true
sudo docker image prune -af >/dev/null 2>&1 || true
sudo apt-get clean || true
df -h

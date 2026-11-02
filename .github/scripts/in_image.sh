#!/bin/bash
# Run scripts/linux/arm64/ci_step.sh inside the (arm64) Cake build image.
set -e
mkdir -p "$RUNNER_TEMP/pub-cache" "$RUNNER_TEMP/cargo-registry"
docker run --rm \
  -v "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" -w "$GITHUB_WORKSPACE" \
  -v "$RUNNER_TEMP/pub-cache:/root/.pub-cache" \
  -v "$RUNNER_TEMP/cargo-registry:/root/.cargo/registry" \
  -e HOME=/root \
  "$CW_IMAGE" bash scripts/linux/arm64/ci_step.sh "$@"

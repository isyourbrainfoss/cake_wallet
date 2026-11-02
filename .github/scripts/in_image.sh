#!/bin/bash
# Run scripts/linux/arm64/ci_step.sh inside the (arm64) Cake build image.
# The image runs as root, so files it creates in the bind-mounted workspace are root-owned.
# Hand the workspace back to the runner user afterwards (even on failure) so later host-side
# steps (actions/download-artifact, upload-artifact, cache) can write there.
set -e
mkdir -p "$RUNNER_TEMP/pub-cache" "$RUNNER_TEMP/cargo-registry"
restore_owner() {
  sudo chown -R "$(id -u):$(id -g)" "$GITHUB_WORKSPACE" || true
}
trap restore_owner EXIT
docker run --rm \
  -v "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" -w "$GITHUB_WORKSPACE" \
  -v "$RUNNER_TEMP/pub-cache:/root/.pub-cache" \
  -v "$RUNNER_TEMP/cargo-registry:/root/.cargo/registry" \
  -e HOME=/root \
  "$CW_IMAGE" bash scripts/linux/arm64/ci_step.sh "$@"

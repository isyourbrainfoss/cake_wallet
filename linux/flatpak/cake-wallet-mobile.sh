#!/bin/sh
# Keep wallet data inside the sandbox (~/.var/app/<id>/data) instead of $HOME,
# since this Flatpak does not get --filesystem=home.
export CAKE_WALLET_DIR="${CAKE_WALLET_DIR:-${XDG_DATA_HOME}/cake_wallet}"
exec /app/cake_wallet/cake_wallet "$@"

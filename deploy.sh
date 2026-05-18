#!/usr/bin/env bash
set -e

NIX_BUILDER="10.201.3.146"
K3S_MASTER="10.201.3.138"
NIX_CACHE="10.201.3.150"
DASHBOARD="10.201.3.147"

deploy() {
  local host=$1 ip=$2
  echo "[${host}] deploying..."
  nixos-rebuild switch \
    --flake ".#${host}" \
    --target-host "root@${ip}" \
    --build-host "root@${NIX_BUILDER}"
}

deploy nix-builder "${NIX_BUILDER}"
deploy k3s-master  "${K3S_MASTER}"
deploy dashboard   "${DASHBOARD}"

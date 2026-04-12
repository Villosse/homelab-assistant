#!/usr/bin/env bash

set -e

BASE_URL="https://raw.githubusercontent.com/Villosse/homelab-assistant/main/hosts/nix-builder"

curl -o /etc/nixos/configuration.nix "$BASE_URL/configuration.nix"
curl -o /etc/nixos/root.keys "$BASE_URL/root.keys"
curl -o /etc/nixos/builder.keys "$BASE_URL/builder.keys"

nixos-rebuild switch

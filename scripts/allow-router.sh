#!/bin/bash
# Allow a router on PassportGatedHook — must be called once per router per chain.
# Requires ROUTER_ADMIN_ROLE (the deployer/admin EOA).
#
# Usage:
#   # ETH Sepolia (primary testnet):
#   PRIVATE_KEY=0x... bash scripts/allow-router.sh
#
#   # Base Sepolia (legacy testnet):
#   PRIVATE_KEY=0x... HOOK=0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80 \
#     UNIVERSAL_ROUTER=0x492e6456d9528771018deb9e87ef7750ef184104 \
#     RPC=https://sepolia.base.org bash scripts/allow-router.sh
#
# Add --broadcast to actually send the transaction (default: dry-run simulation)

set -e

# Default: ETH Sepolia (primary testnet — ZKPassport verifier is here)
HOOK="${HOOK:-0xA4c7d0f1bb255460C7b3CBE9910318CB57Cb8A80}"
UNIVERSAL_ROUTER="${UNIVERSAL_ROUTER:-0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b}"
RPC="${RPC:-${RPC_ETH_SEPOLIA:-https://rpc.sepolia.org}}"

echo "Hook:             $HOOK"
echo "Universal Router: $UNIVERSAL_ROUTER"
echo "RPC:              $RPC"
echo ""

# Check if already allowed
echo "Checking current allowedRouters status..."
cast call "$HOOK" "allowedRouters(address)(bool)" "$UNIVERSAL_ROUTER" --rpc-url "$RPC"

echo ""
echo "Sending allowRouter transaction..."

cast send "$HOOK" \
  "allowRouter(address)" \
  "$UNIVERSAL_ROUTER" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC" \
  "$@"

echo ""
echo "Verifying..."
cast call "$HOOK" "allowedRouters(address)(bool)" "$UNIVERSAL_ROUTER" --rpc-url "$RPC"

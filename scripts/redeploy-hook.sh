#!/bin/bash
# Redeploy PassportGatedHook on Base Sepolia with correct v4-core permission bits.
# The old hook at 0x6aCd36... was deployed with old v4-core (wrong bit layout).
# This script finds a new valid salt and deploys a fresh hook via Safe Singleton Factory.
# Usage: ./scripts/redeploy-hook.sh

set -e
source "$(dirname "$0")/../.env"

echo "Redeploying PassportGatedHook on Base Sepolia..."
echo "This will find a valid CREATE2 salt and deploy at an address with bits 0x0A80."
echo ""

forge script script/RedeployPassportGatedHook.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv

echo ""
echo "IMPORTANT: Copy the new HOOK_ADDRESS from the output above."
echo "Update pool-init.sh and pool-add-liquidity.sh with the new address."

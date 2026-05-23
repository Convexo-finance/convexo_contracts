#!/bin/bash
# Redeploy PassportGatedHook on ETH Sepolia (primary testnet).
# Finds a new valid CREATE2 salt and deploys via Safe Singleton Factory.
# The deployed address will have lower 14 bits == 0x0A80 (Uniswap V4 requirement).
#
# Usage: ./scripts/redeploy-hook.sh

set -e
source "$(dirname "$0")/../.env"

echo "Redeploying PassportGatedHook on ETH Sepolia..."
echo "ReputationManager: 0x28a9b3bA5ddf3D7542a2BCC00Bc7eC72363bEB8b (v3.19 — points to new Passport)"
echo "Searching for valid CREATE2 salt (bits 0x0A80)..."
echo ""

forge script script/RedeployPassportGatedHook.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv

echo ""
echo "IMPORTANT: Copy the new hook address from '[SUCCESS] PassportGatedHook deployed at:' above."
echo "Then run in order:"
echo "  1. NEW_HOOK=<address> ./scripts/allow-router.sh"
echo "  2. NEW_HOOK=<address> ROUTER=0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4 ./scripts/allow-router.sh"
echo "  3. NEW_HOOK=<address> ./scripts/pool-init.sh"
echo "  4. NEW_HOOK=<address> ./scripts/pool-add-liquidity.sh 6250000000"
echo "  5. NEW_HOOK=<address> FULL_RANGE=true ./scripts/pool-add-liquidity.sh 500000000"

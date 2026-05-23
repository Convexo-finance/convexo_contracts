#!/bin/bash
# Remove liquidity from the OLD USDC/ECOP pool on ETH Sepolia (deprecated hook).
# Recovered tokens go to the deployer wallet, ready to seed the new pool.
#
# Usage:   ./scripts/pool-remove-liquidity.sh <TOKEN_IDS>
# Example: ./scripts/pool-remove-liquidity.sh 25627
#          ./scripts/pool-remove-liquidity.sh 25627,25628

set -e
source "$(dirname "$0")/../.env"

OLD_HOOK=0xaDdEb4E0cC9E7Eaf96ccC24aEEccb6C1c3758a80
TOKEN_IDS=${1:?"Usage: $0 <TOKEN_IDS> (comma-separated position token IDs)"}

echo "Removing liquidity from OLD pool (deprecated hook):"
echo "  Old hook:   $OLD_HOOK"
echo "  Positions:  $TOKEN_IDS"
echo ""

OLD_HOOK=$OLD_HOOK \
TOKEN0=$USDC_ADDRESS_ETHSEPOLIA \
TOKEN1=$ECOP_ADDRESS_ETHSEPOLIA \
TOKEN_IDS=$TOKEN_IDS \
forge script script/RemoveLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast -vv

echo ""
echo "Done. Tokens are now in your wallet."
echo "Next: seed the new pool — run pool-add-liquidity.sh"

#!/bin/bash
# Add concentrated liquidity to the USDC/ECOP pool on ETH Sepolia (primary testnet)
# Usage: NEW_HOOK=<address> ./scripts/pool-add-liquidity.sh [USDC_AMOUNT_RAW]
# Example: NEW_HOOK=0xABC... ./scripts/pool-add-liquidity.sh 6250000000   (= 6,250 USDC)

set -e
source "$(dirname "$0")/../.env"

if [ -z "$NEW_HOOK" ]; then
  echo "ERROR: Set NEW_HOOK=<deployed hook address> before running this script."
  exit 1
fi

HOOK_ADDRESS=$NEW_HOOK
RATE=3650
AMOUNT0=${1:-6250000000}  # default 6,250 USDC

echo "Adding concentrated liquidity:"
echo "  USDC: $AMOUNT0 raw (= $(echo "$AMOUNT0 / 1000000" | bc) USDC)"
echo "  ECOP: auto-computed from rate $RATE"
echo "  Range: +-5% around rate $RATE"

TOKEN0=$USDC_ADDRESS_ETHSEPOLIA \
TOKEN1=$ECOP_ADDRESS_ETHSEPOLIA \
HOOK_ADDRESS=$HOOK_ADDRESS \
RATE=$RATE \
AMOUNT0=$AMOUNT0 \
forge script script/AddLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast

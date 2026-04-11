#!/bin/bash
# Add concentrated liquidity to the USDC/ECOP pool on Base Sepolia
# Usage: ./scripts/pool-add-liquidity.sh [USDC_AMOUNT_RAW]
# Example: ./scripts/pool-add-liquidity.sh 6250000000   (= 6,250 USDC)

set -e
source "$(dirname "$0")/../.env"

HOOK_ADDRESS=0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80
RATE=3650
AMOUNT0=${1:-6250000000}  # default 6,250 USDC

echo "Adding concentrated liquidity:"
echo "  USDC: $AMOUNT0 raw (= $(echo "$AMOUNT0 / 1000000" | bc) USDC)"
echo "  ECOP: auto-computed from rate $RATE"
echo "  Range: +-5% around rate $RATE"

TOKEN0=$USDC_ADDRESS_BASESEPOLIA \
TOKEN1=$ECOP_ADDRESS_BASESEPOLIA \
HOOK_ADDRESS=$HOOK_ADDRESS \
RATE=$RATE \
AMOUNT0=$AMOUNT0 \
forge script script/AddLiquidity.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

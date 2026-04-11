#!/bin/bash
# Initialize the USDC/ECOP pool on Base Sepolia
# Usage: ./scripts/pool-init.sh

set -e
source "$(dirname "$0")/../.env"

HOOK_ADDRESS=0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80
RATE=3650

echo "Initializing USDC/ECOP pool at rate $RATE COP/USDC..."

TOKEN0=$USDC_ADDRESS_BASESEPOLIA \
TOKEN1=$ECOP_ADDRESS_BASESEPOLIA \
HOOK_ADDRESS=$HOOK_ADDRESS \
RATE=$RATE \
forge script script/InitializePool.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

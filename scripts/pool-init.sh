#!/bin/bash
# Initialize the USDC/ECOP pool on ETH Sepolia (primary testnet).
# Usage: NEW_HOOK=<address> ./scripts/pool-init.sh

set -e
source "$(dirname "$0")/../.env"

if [ -z "$NEW_HOOK" ]; then
  echo "ERROR: Set NEW_HOOK=<deployed hook address> before running this script."
  exit 1
fi

RATE=3650

echo "Initializing USDC/ECOP pool on ETH Sepolia..."
echo "  Hook:  $NEW_HOOK"
echo "  Rate:  $RATE COP/USDC"

TOKEN0=$USDC_ADDRESS_ETHSEPOLIA \
TOKEN1=$ECOP_ADDRESS_ETHSEPOLIA \
HOOK_ADDRESS=$NEW_HOOK \
RATE=$RATE \
forge script script/InitializePool.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast

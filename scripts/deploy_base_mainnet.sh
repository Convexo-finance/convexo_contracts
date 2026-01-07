#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Deploy to Base Mainnet (Chain ID: 8453)
# Deploys 14 contracts with Basescan verification
# Usage: ./scripts/deploy_base_mainnet.sh
# ═══════════════════════════════════════════════════════════════

set -e

CHAIN_NAME="Base Mainnet"
CHAIN_ID="8453"
EXPLORER="https://basescan.org"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           🚀 Deploying to $CHAIN_NAME                 ║"
echo "║             Chain ID: $CHAIN_ID | 14 Contracts            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: MAINNET deployment - Real ETH required!"
echo ""
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Source environment
source .env

# Validate environment
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$BASESCAN_API_KEY" ]; then
    echo "❌ BASESCAN_API_KEY not set in .env"
    exit 1
fi

# RPC URL - fallback to public RPC
RPC_URL="${BASE_MAINNET_RPC_URL:-https://base.llamarpc.com}"
echo "📡 RPC: $RPC_URL"
echo ""

# Bypass macOS proxy issues
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy with verification
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --verify \
    --etherscan-api-key "$BASESCAN_API_KEY" \
    --chain-id $CHAIN_ID \
    --slow \
    -vvv

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ Deployment Complete!                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Broadcast: broadcast/DeployAll.s.sol/$CHAIN_ID/run-latest.json"
echo "🔍 Explorer: $EXPLORER"
echo ""
echo "Next steps:"
echo "  ./scripts/update-addresses.sh $CHAIN_ID"
echo "  ./scripts/extract-abis.sh"

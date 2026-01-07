#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Deploy to Ethereum Sepolia (Chain ID: 11155111)
# Deploys 14 contracts with Etherscan verification
# Usage: ./scripts/deploy_ethereum_sepolia.sh
# ═══════════════════════════════════════════════════════════════

set -e

CHAIN_NAME="Ethereum Sepolia"
CHAIN_ID="11155111"
EXPLORER="https://sepolia.etherscan.io"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         Deploying to $CHAIN_NAME                    ║"
echo "║         Chain ID: $CHAIN_ID | 14 Contracts               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Source environment
source .env

# Validate environment
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ ETHERSCAN_API_KEY not set in .env"
    exit 1
fi

# RPC URL - fallback to public RPC
RPC_URL="${ETHEREUM_SEPOLIA_RPC_URL:-https://ethereum-sepolia-rpc.publicnode.com}"
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
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
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

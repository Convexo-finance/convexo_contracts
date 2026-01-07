#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Deploy to Unichain Mainnet (Chain ID: 130)
# Deploys 14 contracts with Blockscout verification
# Usage: ./scripts/deploy_unichain_mainnet.sh
# ═══════════════════════════════════════════════════════════════

set -e

CHAIN_NAME="Unichain Mainnet"
CHAIN_ID="130"
EXPLORER="https://unichain.blockscout.com"

# Public RPC for Unichain Mainnet (fallback)
PUBLIC_RPC="https://mainnet.unichain.org"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         🚀 Deploying to $CHAIN_NAME                ║"
echo "║            Chain ID: $CHAIN_ID | 14 Contracts                ║"
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

# Use UNICHAIN_MAINNET_RPC_URL if set, otherwise use public RPC
if [ -n "$UNICHAIN_MAINNET_RPC_URL" ]; then
    RPC_URL="$UNICHAIN_MAINNET_RPC_URL"
    echo "📡 Using .env RPC: $RPC_URL"
else
    RPC_URL="$PUBLIC_RPC"
    echo "📡 Using public RPC: $RPC_URL"
fi

# Verify RPC is for Unichain (should NOT contain "base")
if [[ "$RPC_URL" == *"base"* ]]; then
    echo "❌ ERROR: RPC URL contains 'base' - this is wrong for Unichain!"
    echo "   Current RPC: $RPC_URL"
    echo "   Please fix UNICHAIN_MAINNET_RPC_URL in .env"
    echo "   Expected: https://mainnet.unichain.org or similar"
    exit 1
fi

echo ""

# Bypass macOS proxy issues
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy with Blockscout verification
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain.blockscout.com/api \
    --chain-id $CHAIN_ID \
    --legacy \
    --slow \
    --skip-simulation \
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

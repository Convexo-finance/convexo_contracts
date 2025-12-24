#!/bin/bash

# Deploy and verify all contracts on Unichain Mainnet
# Usage: ./scripts/deploy_unichain_mainnet.sh

set -e

echo "=================================="
echo "🚀 Deploying to Unichain Mainnet"
echo "=================================="
echo ""
echo "⚠️  WARNING: You are deploying to MAINNET!"
echo "⚠️  This will cost real ETH. Press Ctrl+C to cancel."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Source environment variables
source .env

# Check if RPC URL is set
if [ -z "$UNICHAIN_MAINNET_RPC_URL" ]; then
    echo "❌ Error: UNICHAIN_MAINNET_RPC_URL not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

echo "Using RPC: $UNICHAIN_MAINNET_RPC_URL"
echo ""

# Set environment variables to bypass macOS proxy detection bug
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy all contracts with Unichain Mainnet specific configuration
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$UNICHAIN_MAINNET_RPC_URL" \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain.blockscout.com/api \
    --chain-id 130 \
    --legacy \
    --slow \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/130/run-latest.json"
echo ""
echo "🔍 All contracts should be verified on Blockscout:"
echo "https://unichain.blockscout.com"


#!/bin/bash

# Deploy and verify all contracts on Unichain Sepolia
# Usage: ./scripts/deploy_unichain_sepolia.sh

set -e

echo "=================================="
echo "Deploying to Unichain Sepolia"
echo "=================================="

# Source environment variables
source .env

# Check if RPC URL is set
if [ -z "$UNICHAIN_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: UNICHAIN_SEPOLIA_RPC_URL not set in .env"
    exit 1
fi

echo "Using RPC: $UNICHAIN_SEPOLIA_RPC_URL"
echo ""

# Set environment variables to bypass macOS proxy detection bug
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy all contracts with Blockscout verification
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain-sepolia.blockscout.com/api \
    --chain-id 1301 \
    --legacy \
    --slow \
    --with-gas-price 1000000 \
    --skip-simulation \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/1301/run-latest.json"
echo ""
echo "🔍 All contracts should be verified on Blockscout:"
echo "https://unichain-sepolia.blockscout.com"


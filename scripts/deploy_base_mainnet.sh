#!/bin/bash

# Deploy and verify all contracts on Base Mainnet
# Usage: ./scripts/deploy_base_mainnet.sh

set -e

echo "=================================="
echo "🚀 Deploying to Base Mainnet"
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
if [ -z "$BASE_MAINNET_RPC_URL" ]; then
    echo "❌ Error: BASE_MAINNET_RPC_URL not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

echo "Using RPC: $BASE_MAINNET_RPC_URL"
echo ""

# Set environment variables to bypass macOS proxy detection bug
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Check if API key is set
if [ -z "$BASESCAN_API_KEY" ]; then
    echo "❌ Error: BASESCAN_API_KEY not set in .env"
    echo "   Set BASESCAN_API_KEY in .env to enable contract verification"
    exit 1
fi

echo "Using Basescan API Key: ${BASESCAN_API_KEY:0:10}..."
echo ""

# Deploy all contracts with Base Mainnet specific configuration
# Note: Basescan uses Etherscan API format, so we use --verifier etherscan
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$BASE_MAINNET_RPC_URL" \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key "$BASESCAN_API_KEY" \
    --chain-id 8453 \
    --slow \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/8453/run-latest.json"
echo ""
echo "🔍 All contracts should be verified on Basescan:"
echo "https://basescan.org"
echo ""
echo "📝 Next steps:"
echo "1. Extract ABIs: ./scripts/extract-abis.sh"
echo "2. Update addresses.json: ./scripts/update-addresses.sh 8453"

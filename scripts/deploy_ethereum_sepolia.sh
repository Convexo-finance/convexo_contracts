#!/bin/bash

# Deploy and verify all contracts on Ethereum Sepolia
# Usage: ./scripts/deploy_ethereum_sepolia.sh

set -e

echo "=================================="
echo "Deploying to Ethereum Sepolia"
echo "=================================="

# Source environment variables
source .env

# Check if RPC URL and API key are set
if [ -z "$ETHEREUM_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: ETHEREUM_SEPOLIA_RPC_URL not set in .env"
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ Error: ETHERSCAN_API_KEY not set in .env"
    exit 1
fi

echo "Using RPC: $ETHEREUM_SEPOLIA_RPC_URL"
echo ""

# Set environment variables to bypass macOS proxy detection bug
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy all contracts with Etherscan verification
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --chain-id 11155111 \
    --legacy \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/11155111/run-latest.json"
echo ""
echo "🔍 All contracts should be verified on Etherscan:"
echo "https://sepolia.etherscan.io"


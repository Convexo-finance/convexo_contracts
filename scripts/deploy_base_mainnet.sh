#!/bin/bash

# Deploy and verify all contracts on Base Mainnet
# Usage: ./scripts/deploy_base_mainnet.sh

set -e

echo "=================================="
echo "🚀 Deploying to Base Mainnet"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts with Base Mainnet specific configuration
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url base_mainnet \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key $BASESCAN_API_KEY \
    --chain-id 8453 \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/8453/run-latest.json"


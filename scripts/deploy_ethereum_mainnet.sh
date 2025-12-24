#!/bin/bash

# Deploy and verify all contracts on Ethereum Mainnet
# Usage: ./scripts/deploy_ethereum_mainnet.sh

set -e

echo "=================================="
echo "🚀 Deploying to Ethereum Mainnet"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts with Ethereum Mainnet specific configuration
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url ethereum_mainnet \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --chain-id 1 \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/1/run-latest.json"


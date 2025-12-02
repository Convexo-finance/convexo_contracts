#!/bin/bash

# Deploy and verify all contracts on Base Sepolia
# Usage: ./scripts/deploy_base_sepolia.sh

set -e

echo "=================================="
echo "Deploying to Base Sepolia"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url base_sepolia \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvv

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Check addresses in broadcast/DeployAll.s.sol/84532/run-latest.json"


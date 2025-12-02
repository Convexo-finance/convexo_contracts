#!/bin/bash

# Deploy and verify all contracts on Unichain Sepolia
# Usage: ./scripts/deploy_unichain_sepolia.sh

set -e

echo "=================================="
echo "Deploying to Unichain Sepolia"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url unichain_sepolia \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain-sepolia.blockscout.com/api \
    -vvv

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Check addresses in broadcast/DeployAll.s.sol/1301/run-latest.json"


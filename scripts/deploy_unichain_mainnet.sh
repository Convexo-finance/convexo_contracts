#!/bin/bash

# Deploy and verify all contracts on Unichain Mainnet
# Usage: ./scripts/deploy_unichain_mainnet.sh

set -e

echo "=================================="
echo "🚀 Deploying to Unichain Mainnet"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts with Unichain Mainnet specific configuration
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url unichain_mainnet \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain.blockscout.com/api \
    --chain-id 130 \
    -vvv

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "📁 Check addresses in broadcast/DeployAll.s.sol/130/run-latest.json"


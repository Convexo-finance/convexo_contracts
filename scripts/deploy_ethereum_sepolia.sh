#!/bin/bash

# Deploy and verify all contracts on Ethereum Sepolia
# Usage: ./scripts/deploy_ethereum_sepolia.sh

set -e

echo "=================================="
echo "Deploying to Ethereum Sepolia"
echo "=================================="

# Source environment variables
source .env

# Deploy all contracts with Etherscan verification
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url ethereum_sepolia \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --chain-id 11155111 \
    -vvv

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Check addresses in broadcast/DeployAll.s.sol/11155111/run-latest.json"
echo ""
echo "All contracts should be verified on Etherscan:"
echo "https://sepolia.etherscan.io"


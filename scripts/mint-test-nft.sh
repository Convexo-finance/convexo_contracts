#!/bin/bash
# Mint LP_Individuals NFT to deployer wallet (testnet only)
# Usage: ./scripts/mint-test-nft.sh [RECIPIENT_ADDRESS]

set -e
source "$(dirname "$0")/../.env"

LP_INDIVIDUALS_ADDRESS=0xE244e4B2B37EA6f6453d3154da548e7f2e1e5Df3
RECIPIENT=${1:-""}  # defaults to deployer inside the script

LP_INDIVIDUALS_ADDRESS=$LP_INDIVIDUALS_ADDRESS \
RECIPIENT=$RECIPIENT \
forge script script/MintTestNFT.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

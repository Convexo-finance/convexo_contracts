#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Unified Deployment Script for Convexo Protocol
# Uses Deterministic Deployment (CREATE2 via Safe Singleton Factory)
#
# Usage:
#   ./scripts/deploy.sh <network>
#
# Networks:
#   ethereum-sepolia, base-sepolia, unichain-sepolia
#   ethereum, base, unichain (mainnets)
#
# Examples:
#   ./scripts/deploy.sh ethereum-sepolia
#   ./scripts/deploy.sh base
# ═══════════════════════════════════════════════════════════════

set -e

NETWORK=$1

if [ -z "$NETWORK" ]; then
    echo "Usage: ./scripts/deploy.sh <network>"
    echo ""
    echo "Testnets:"
    echo "  ethereum-sepolia  (Chain ID: 11155111)"
    echo "  base-sepolia      (Chain ID: 84532)"
    echo "  unichain-sepolia  (Chain ID: 1301)"
    echo "  arbitrum-sepolia  (Chain ID: 421614)"
    echo ""
    echo "Mainnets:"
    echo "  ethereum          (Chain ID: 1)"
    echo "  base              (Chain ID: 8453)"
    echo "  unichain          (Chain ID: 130)"
    echo "  arbitrum          (Chain ID: 42161)"
    exit 1
fi

# Network configuration
case $NETWORK in
    "ethereum-sepolia")
        CHAIN_NAME="Ethereum Sepolia"
        CHAIN_ID="11155111"
        RPC_VAR="ETHEREUM_SEPOLIA_RPC_URL"
        RPC_FALLBACK="https://ethereum-sepolia-rpc.publicnode.com"
        EXPLORER="https://sepolia.etherscan.io"
        IS_MAINNET=false
        EXTRA_FLAGS=""
        ;;
    "base-sepolia")
        CHAIN_NAME="Base Sepolia"
        CHAIN_ID="84532"
        RPC_VAR="BASE_SEPOLIA_RPC_URL"
        RPC_FALLBACK="https://base-sepolia-rpc.publicnode.com"
        EXPLORER="https://sepolia.basescan.org"
        IS_MAINNET=false
        EXTRA_FLAGS=""
        ;;
    "unichain-sepolia")
        CHAIN_NAME="Unichain Sepolia"
        CHAIN_ID="1301"
        RPC_VAR="UNICHAIN_SEPOLIA_RPC_URL"
        RPC_FALLBACK="https://sepolia.unichain.org"
        EXPLORER="https://unichain-sepolia.blockscout.com"
        IS_MAINNET=false
        EXTRA_FLAGS="--legacy --skip-simulation"
        ;;
    "ethereum")
        CHAIN_NAME="Ethereum Mainnet"
        CHAIN_ID="1"
        RPC_VAR="MAINNET_RPC_URL"
        RPC_FALLBACK="https://eth.llamarpc.com"
        EXPLORER="https://etherscan.io"
        IS_MAINNET=true
        EXTRA_FLAGS=""
        ;;
    "base")
        CHAIN_NAME="Base Mainnet"
        CHAIN_ID="8453"
        RPC_VAR="BASE_MAINNET_RPC_URL"
        RPC_FALLBACK="https://base.llamarpc.com"
        EXPLORER="https://basescan.org"
        IS_MAINNET=true
        EXTRA_FLAGS=""
        ;;
    "unichain")
        CHAIN_NAME="Unichain Mainnet"
        CHAIN_ID="130"
        RPC_VAR="UNICHAIN_MAINNET_RPC_URL"
        RPC_FALLBACK="https://mainnet.unichain.org"
        EXPLORER="https://unichain.blockscout.com"
        IS_MAINNET=true
        EXTRA_FLAGS="--legacy --skip-simulation"
        ;;
    "arbitrum-sepolia")
        CHAIN_NAME="Arbitrum Sepolia"
        CHAIN_ID="421614"
        RPC_VAR="ARBITRUM_SEPOLIA_RPC_URL"
        RPC_FALLBACK="https://sepolia-rollup.arbitrum.io/rpc"
        EXPLORER="https://sepolia.arbiscan.io"
        IS_MAINNET=false
        EXTRA_FLAGS=""
        ;;
    "arbitrum")
        CHAIN_NAME="Arbitrum One"
        CHAIN_ID="42161"
        RPC_VAR="ARBITRUM_MAINNET_RPC_URL"
        RPC_FALLBACK="https://arb1.arbitrum.io/rpc"
        EXPLORER="https://arbiscan.io"
        IS_MAINNET=true
        EXTRA_FLAGS=""
        ;;
    *)
        echo "Unknown network: $NETWORK"
        echo "Run ./scripts/deploy.sh without arguments to see available networks."
        exit 1
        ;;
esac

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Deploying to $CHAIN_NAME"
echo "║  Chain ID: $CHAIN_ID | 12 Contracts"
echo "║  Mode: Deterministic (CREATE2)"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Mainnet warning
if [ "$IS_MAINNET" = true ]; then
    echo "⚠️  WARNING: MAINNET deployment - Real funds required!"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    echo ""
fi

# Source environment
if [ -f .env ]; then
    source .env
else
    echo "❌ .env file not found"
    exit 1
fi

# Validate environment
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$MINTER_ADDRESS" ]; then
    echo "❌ MINTER_ADDRESS not set in .env"
    exit 1
fi

# Get RPC URL
RPC_URL="${!RPC_VAR:-$RPC_FALLBACK}"
echo "📡 RPC: $RPC_URL"
echo "👤 Minter: $MINTER_ADDRESS"
echo ""

# Validate RPC for Unichain (should NOT contain "base")
if [[ "$NETWORK" == *"unichain"* ]] && [[ "$RPC_URL" == *"base"* ]]; then
    echo "❌ ERROR: RPC URL contains 'base' - wrong for Unichain!"
    echo "   Current: $RPC_URL"
    echo "   Fix $RPC_VAR in .env"
    exit 1
fi

# Bypass macOS proxy issues
export NO_PROXY="*"
export HTTP_PROXY=""
export HTTPS_PROXY=""

# Deploy
echo "🚀 Starting deployment..."
echo ""

forge script script/DeployDeterministic.s.sol:DeployDeterministic \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --chain-id $CHAIN_ID \
    --slow \
    $EXTRA_FLAGS \
    -vvv

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ Deployment Complete!                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Broadcast: broadcast/DeployDeterministic.s.sol/$CHAIN_ID/run-latest.json"
echo "🔍 Explorer: $EXPLORER"
echo ""
echo "Next steps:"
echo "  1. ./scripts/update-addresses.sh $CHAIN_ID"
echo "  2. ./scripts/verify-all.sh $CHAIN_ID"
echo "  3. ./scripts/extract-abis.sh"
echo ""

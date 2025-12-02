#!/bin/bash

# ABI Extraction Script for Convexo Protocol
# This script extracts ABIs from all compiled contracts for frontend integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ABI_OUTPUT_DIR="$PROJECT_DIR/abis"

echo "🔨 Building contracts..."
cd "$PROJECT_DIR"
forge build

echo "📦 Extracting ABIs..."

# Create abis directory if it doesn't exist
mkdir -p "$ABI_OUTPUT_DIR"

# Function to extract ABI
extract_abi() {
    local contract_name=$1
    local source_file=$2
    local output_name=${3:-$contract_name}
    
    local abi_path="$PROJECT_DIR/out/$source_file/$contract_name.json"
    
    if [ -f "$abi_path" ]; then
        jq '.abi' "$abi_path" > "$ABI_OUTPUT_DIR/$output_name.json"
        echo "✅ Extracted $contract_name ABI to abis/$output_name.json"
        return 0
    else
        echo "⚠️  Warning: $contract_name.json not found at $abi_path"
        return 1
    fi
}

# Extract all contract ABIs
echo ""
echo "Extracting NFT Contracts..."
extract_abi "Convexo_LPs" "convexolps.sol"
extract_abi "Convexo_Vaults" "convexovaults.sol"

echo ""
echo "Extracting Core Contracts..."
extract_abi "VaultFactory" "VaultFactory.sol"
extract_abi "TokenizedBondVault" "TokenizedBondVault.sol"
extract_abi "ContractSigner" "ContractSigner.sol"
extract_abi "ReputationManager" "ReputationManager.sol"
extract_abi "PriceFeedManager" "PriceFeedManager.sol"
extract_abi "PoolRegistry" "PoolRegistry.sol"

echo ""
echo "Extracting Hook Contracts..."
extract_abi "HookDeployer" "HookDeployer.sol"
extract_abi "CompliantLPHook" "CompliantLPHook.sol"

# Create a combined ABI file for convenience
echo ""
echo "📋 Creating combined ABI file..."
jq -s '{
    "Convexo_LPs": .[0],
    "Convexo_Vaults": .[1],
    "VaultFactory": .[2],
    "TokenizedBondVault": .[3],
    "ContractSigner": .[4],
    "ReputationManager": .[5],
    "PriceFeedManager": .[6],
    "PoolRegistry": .[7],
    "HookDeployer": .[8],
    "CompliantLPHook": .[9]
}' \
    "$ABI_OUTPUT_DIR/Convexo_LPs.json" \
    "$ABI_OUTPUT_DIR/Convexo_Vaults.json" \
    "$ABI_OUTPUT_DIR/VaultFactory.json" \
    "$ABI_OUTPUT_DIR/TokenizedBondVault.json" \
    "$ABI_OUTPUT_DIR/ContractSigner.json" \
    "$ABI_OUTPUT_DIR/ReputationManager.json" \
    "$ABI_OUTPUT_DIR/PriceFeedManager.json" \
    "$ABI_OUTPUT_DIR/PoolRegistry.json" \
    "$ABI_OUTPUT_DIR/HookDeployer.json" \
    "$ABI_OUTPUT_DIR/CompliantLPHook.json" \
    > "$ABI_OUTPUT_DIR/combined.json"
echo "✅ Created combined ABI file at abis/combined.json"

echo ""
echo "✨ ABI extraction complete!"
echo "📁 ABIs saved to: $ABI_OUTPUT_DIR"
echo ""
echo "Files created:"
echo "  - abis/Convexo_LPs.json"
echo "  - abis/Convexo_Vaults.json"
echo "  - abis/VaultFactory.json"
echo "  - abis/TokenizedBondVault.json"
echo "  - abis/ContractSigner.json"
echo "  - abis/ReputationManager.json"
echo "  - abis/PriceFeedManager.json"
echo "  - abis/PoolRegistry.json"
echo "  - abis/HookDeployer.json"
echo "  - abis/CompliantLPHook.json"
echo "  - abis/combined.json"
echo ""
echo "🎯 Total: 11 ABI files ready for frontend integration!"


#!/bin/bash

# ABI Extraction Script for Convexo NFT Contracts
# This script extracts ABIs from compiled contracts for frontend integration

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

# Extract Convexo_LPs ABI
CONVEXO_LPS_ABI_PATH="$PROJECT_DIR/out/convexolps.sol/Convexo_LPs.json"
if [ -f "$CONVEXO_LPS_ABI_PATH" ]; then
    jq -r '.abi' "$CONVEXO_LPS_ABI_PATH" > "$ABI_OUTPUT_DIR/Convexo_LPs.json"
    echo "✅ Extracted Convexo_LPs ABI to abis/Convexo_LPs.json"
else
    echo "❌ Error: Convexo_LPs.json not found at $CONVEXO_LPS_ABI_PATH. Make sure contracts are compiled."
    exit 1
fi

# Extract Convexo_Vaults ABI
CONVEXO_VAULTS_ABI_PATH="$PROJECT_DIR/out/convexovaults.sol/Convexo_Vaults.json"
if [ -f "$CONVEXO_VAULTS_ABI_PATH" ]; then
    jq -r '.abi' "$CONVEXO_VAULTS_ABI_PATH" > "$ABI_OUTPUT_DIR/Convexo_Vaults.json"
    echo "✅ Extracted Convexo_Vaults ABI to abis/Convexo_Vaults.json"
else
    echo "❌ Error: Convexo_Vaults.json not found at $CONVEXO_VAULTS_ABI_PATH. Make sure contracts are compiled."
    exit 1
fi

# Create a combined ABI file for convenience
echo "📋 Creating combined ABI file..."
jq -s '{
    "Convexo_LPs": .[0],
    "Convexo_Vaults": .[1]
}' "$ABI_OUTPUT_DIR/Convexo_LPs.json" "$ABI_OUTPUT_DIR/Convexo_Vaults.json" > "$ABI_OUTPUT_DIR/combined.json"
echo "✅ Created combined ABI file at abis/combined.json"

echo ""
echo "✨ ABI extraction complete!"
echo "📁 ABIs saved to: $ABI_OUTPUT_DIR"
echo ""
echo "Files created:"
echo "  - abis/Convexo_LPs.json"
echo "  - abis/Convexo_Vaults.json"
echo "  - abis/combined.json"


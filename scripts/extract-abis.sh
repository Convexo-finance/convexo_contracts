#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ABI Extraction Script for Convexo Protocol v3.17
# Extracts ABIs only for existing contracts
# ═══════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ABI_OUTPUT_DIR="$PROJECT_DIR/abis"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Convexo ABI Extraction v3.17                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_DIR"

# Clean old ABIs
echo "🧹 Cleaning old ABIs..."
rm -rf "$ABI_OUTPUT_DIR"
mkdir -p "$ABI_OUTPUT_DIR"

# Build contracts
echo "🔨 Building contracts..."
forge build --silent

# Extract ABI function
extract_abi() {
    local contract_name=$1
    local source_file=$2
    
    local abi_path="$PROJECT_DIR/out/$source_file/$contract_name.json"
    
    if [ -f "$abi_path" ]; then
        jq '.abi' "$abi_path" > "$ABI_OUTPUT_DIR/$contract_name.json"
        echo "  ✅ $contract_name"
        return 0
    else
        echo "  ⚠️  $contract_name (not found at $abi_path)"
        return 1
    fi
}

echo ""
echo "📦 Extracting ABIs..."

# ═══════════════════════════════════════════════════════════════
# DEPLOYED CONTRACTS (12 total)
# ═══════════════════════════════════════════════════════════════

echo ""
echo "NFT Contracts (Tier 1-3):"
extract_abi "Convexo_Passport" "Convexo_Passport.sol"
extract_abi "Limited_Partners_Individuals" "Limited_Partners_Individuals.sol"
extract_abi "Limited_Partners_Business" "Limited_Partners_Business.sol"
extract_abi "Ecreditscoring" "Ecreditscoring.sol"

echo ""
echo "Core Infrastructure:"
extract_abi "ReputationManager" "ReputationManager.sol"

echo ""
echo "Hook System:"
extract_abi "HookDeployer" "HookDeployer.sol"
extract_abi "PassportGatedHook" "PassportGatedHook.sol"
extract_abi "PoolRegistry" "PoolRegistry.sol"
extract_abi "PriceFeedManager" "PriceFeedManager.sol"

echo ""
echo "Vault System:"
extract_abi "ContractSigner" "ContractSigner.sol"
extract_abi "VaultFactory" "VaultFactory.sol"

echo ""
echo "Verification System:"
extract_abi "VeriffVerifier" "VeriffVerifier.sol"
extract_abi "SumsubVerifier" "SumsubVerifier.sol"

# ═══════════════════════════════════════════════════════════════
# FACTORY-CREATED CONTRACTS (for frontend interaction)
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Factory Templates (not deployed, created by factories):"
extract_abi "TokenizedBondVault" "TokenizedBondVault.sol"

# ═══════════════════════════════════════════════════════════════
# CREATE COMBINED JSON
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📋 Creating combined.json..."

cat > "$ABI_OUTPUT_DIR/combined.json" << 'EOF'
{
  "version": "3.17",
  "description": "Convexo Protocol ABIs",
  "contracts": {}
}
EOF

# Add each ABI to combined.json
for file in "$ABI_OUTPUT_DIR"/*.json; do
    filename=$(basename "$file" .json)
    if [ "$filename" != "combined" ]; then
        # Add contract ABI to combined.json
        jq --arg name "$filename" --slurpfile abi "$file" \
           '.contracts[$name] = $abi[0]' \
           "$ABI_OUTPUT_DIR/combined.json" > "$ABI_OUTPUT_DIR/combined.tmp.json"
        mv "$ABI_OUTPUT_DIR/combined.tmp.json" "$ABI_OUTPUT_DIR/combined.json"
    fi
done

echo "✅ Created combined.json"

# Count files
ABI_COUNT=$(ls -1 "$ABI_OUTPUT_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ ABI Extraction Complete!                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Output: $ABI_OUTPUT_DIR"
echo "📄 Files: $ABI_COUNT ABIs extracted"
echo ""
echo "Contracts:"
echo "  Deployed (12):"
echo "    - Convexo_Passport, Limited_Partners_Individuals"
echo "    - Limited_Partners_Business, Ecreditscoring"
echo "    - ReputationManager, HookDeployer, PassportGatedHook"
echo "    - PoolRegistry, PriceFeedManager, ContractSigner"
echo "    - VaultFactory, VeriffVerifier, SumsubVerifier"
echo ""
echo "  Template (1):"
echo "    - TokenizedBondVault"
echo ""

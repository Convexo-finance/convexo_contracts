#!/bin/bash
# scripts/update-addresses.sh
# Updates addresses.json using deterministic address computation
# Updated for v3.1 - Computes addresses directly via CREATE2
#
# Usage:
#   ./scripts/update-addresses.sh              # Update all deployed chains
#   ./scripts/update-addresses.sh <chain_id>   # Update specific chain
#
# Environment:
#   DEPLOY_VERSION=convexo.v3.1  # Optional: specify version for address computation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BROADCAST_DIR="$PROJECT_DIR/broadcast/DeployDeterministic.s.sol"
ADDRESSES_FILE="$PROJECT_DIR/addresses.json"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Install it with: brew install jq"
    exit 1
fi

# Chain configuration
get_chain_info() {
    case "$1" in
        "11155111") echo "Ethereum Sepolia|https://sepolia.etherscan.io/address|etherscan" ;;
        "84532") echo "Base Sepolia|https://sepolia.basescan.org/address|basescan" ;;
        "1301") echo "Unichain Sepolia|https://unichain-sepolia.blockscout.com/address|blockscout" ;;
        "1") echo "Ethereum Mainnet|https://etherscan.io/address|etherscan" ;;
        "8453") echo "Base Mainnet|https://basescan.org/address|basescan" ;;
        "130") echo "Unichain Mainnet|https://unichain.blockscout.com/address|blockscout" ;;
        *) echo "Unknown Network||" ;;
    esac
}

# Get USDC and Pool Manager addresses for each chain
get_chain_deps() {
    case "$1" in
        "11155111") echo "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238|0xE03A1074c86CFeDd5C142C4F04F1a1536e203543" ;;
        "84532") echo "0x036CbD53842c5426634e7929541eC2318f3dCF7e|0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408" ;;
        "1301") echo "0x31d0220469e10c4E71834a79b1f276d740d3768F|0x00B036B58a818B1BC34d502D3fE730Db729e62AC" ;;
        "1") echo "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48|0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A" ;;
        "8453") echo "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913|0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829" ;;
        "130") echo "0x078D782b760474a361dDA0AF3839290b0EF57AD6|0x1F98400000000000000000000000000000000004" ;;
        *) echo "|" ;;
    esac
}

# Store the full prediction output
PREDICTION_OUTPUT=""

# Compute deterministic addresses using forge
compute_addresses() {
    echo "Computing deterministic addresses..."
    echo ""

    # Run PredictAddresses script and capture output
    PREDICTION_OUTPUT=$(forge script script/PredictAddresses.s.sol 2>&1)

    # Extract addresses from the output using grep and awk
    # Format: "  Address: 0x..."
    CONVEXO_PASSPORT=$(echo "$PREDICTION_OUTPUT" | grep -A1 "Convexo_Passport" | grep "Address:" | awk '{print $2}')
    LP_INDIVIDUALS=$(echo "$PREDICTION_OUTPUT" | grep -A1 "Limited_Partners_Individuals" | grep "Address:" | awk '{print $2}')
    LP_BUSINESS=$(echo "$PREDICTION_OUTPUT" | grep -A1 "Limited_Partners_Business" | grep "Address:" | awk '{print $2}')
    ECREDITSCORING=$(echo "$PREDICTION_OUTPUT" | grep -A1 "Ecreditscoring" | grep "Address:" | awk '{print $2}')
    VERIFF_VERIFIER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "VeriffVerifier" | grep "Address:" | awk '{print $2}')
    SUMSUB_VERIFIER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "SumsubVerifier" | grep "Address:" | awk '{print $2}')
    REPUTATION_MANAGER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "ReputationManager" | head -2 | grep "Address:" | awk '{print $2}')
    CONTRACT_SIGNER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "ContractSigner" | grep "Address:" | awk '{print $2}')
    POOL_REGISTRY=$(echo "$PREDICTION_OUTPUT" | grep -A1 "PoolRegistry" | grep "Address:" | awk '{print $2}')
    PRICE_FEED_MANAGER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "PriceFeedManager" | grep "Address:" | awk '{print $2}')
    HOOK_DEPLOYER=$(echo "$PREDICTION_OUTPUT" | grep -A1 "HookDeployer" | grep "Address:" | awk '{print $2}')
}

# Get chain-specific addresses from prediction output
get_chain_specific_from_prediction() {
    local chain_id=$1

    # Extract chain-specific section and get addresses
    # Look for the chain section by chain ID, limit to 12 lines (one chain section)
    local section=$(echo "$PREDICTION_OUTPUT" | grep -A12 "Chain ID: $chain_id " | head -12)

    PASSPORT_GATED_HOOK=$(echo "$section" | grep -A1 "PassportGatedHook:" | grep "Address:" | head -1 | awk '{print $2}')
    VAULT_FACTORY=$(echo "$section" | grep -A1 "VaultFactory:" | grep "Address:" | head -1 | awk '{print $2}')
    TREASURY_FACTORY=$(echo "$section" | grep -A1 "TreasuryFactory:" | grep "Address:" | head -1 | awk '{print $2}')
}

# Get chain-specific addresses - computed from prediction (CREATE2)
get_chain_specific_addresses() {
    local chain_id=$1

    # Use prediction output to get chain-specific addresses (deterministic)
    get_chain_specific_from_prediction "$chain_id"
}

update_chain_addresses() {
    local chain_id=$1
    local broadcast_file="$BROADCAST_DIR/$chain_id/run-latest.json"

    if [ ! -f "$broadcast_file" ]; then
        echo "⚠️  Broadcast file not found: $broadcast_file"
        echo "   Run deployment first: ./scripts/deploy.sh <network>"
        return 1
    fi

    local chain_info=$(get_chain_info "$chain_id")
    local chain_name=$(echo "$chain_info" | cut -d'|' -f1)
    local explorer_base=$(echo "$chain_info" | cut -d'|' -f2)
    local explorer_key=$(echo "$chain_info" | cut -d'|' -f3)

    local chain_deps=$(get_chain_deps "$chain_id")
    local usdc_address=$(echo "$chain_deps" | cut -d'|' -f1)
    local pool_manager=$(echo "$chain_deps" | cut -d'|' -f2)

    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  Updating addresses for $chain_name (Chain ID: $chain_id)"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # Initialize addresses.json if it doesn't exist
    if [ ! -f "$ADDRESSES_FILE" ]; then
        echo "{}" > "$ADDRESSES_FILE"
    fi

    local temp_json=$(mktemp)
    local deploy_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local version="${DEPLOY_VERSION:-convexo.v3.1}"

    # Start fresh for this chain (remove legacy data)
    if [ -f "$ADDRESSES_FILE" ]; then
        # Remove existing chain entry to start clean
        jq --arg chain_id "$chain_id" 'del(.[$chain_id])' "$ADDRESSES_FILE" > "$temp_json"
    else
        echo "{}" > "$temp_json"
    fi

    # Get chain-specific addresses from prediction
    get_chain_specific_addresses "$chain_id"

    # Initialize chain entry with clean structure
    jq --arg chain_id "$chain_id" \
       --arg chain_name "$chain_name" \
       --arg usdc "$usdc_address" \
       --arg pool_manager "$pool_manager" \
       --arg version "$version" \
       '.[$chain_id] = {
            "name": $chain_name,
            "version": $version,
            "external": {
                "usdc": $usdc,
                "pool_manager": $pool_manager,
                "zkpassport_verifier": "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
            }
        }' "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"

    local found_count=0

    # Helper function to add contract
    add_contract() {
        local json_key=$1
        local addr=$2
        local name=$3

        if [ -n "$addr" ] && [ "$addr" != "null" ] && [ "$addr" != "" ]; then
            local explorer_url="${explorer_base}/${addr}"

            jq --arg chain_id "$chain_id" \
               --arg json_key "$json_key" \
               --arg addr "$addr" \
               --arg explorer_url "$explorer_url" \
               '.[$chain_id].contracts[$json_key] = {
                   "address": $addr,
                   "explorer": $explorer_url
               }' "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"

            echo "  ✅ $name: $addr"
            found_count=$((found_count + 1))
        else
            echo "  ⚠️  $name: Not available"
        fi
    }

    echo "--- Deterministic Addresses (Same on All Chains) ---"
    add_contract "convexo_passport" "$CONVEXO_PASSPORT" "Convexo_Passport"
    add_contract "lp_individuals" "$LP_INDIVIDUALS" "Limited_Partners_Individuals"
    add_contract "lp_business" "$LP_BUSINESS" "Limited_Partners_Business"
    add_contract "ecreditscoring" "$ECREDITSCORING" "Ecreditscoring"
    add_contract "veriff_verifier" "$VERIFF_VERIFIER" "VeriffVerifier"
    add_contract "sumsub_verifier" "$SUMSUB_VERIFIER" "SumsubVerifier"
    add_contract "reputation_manager" "$REPUTATION_MANAGER" "ReputationManager"
    add_contract "contract_signer" "$CONTRACT_SIGNER" "ContractSigner"
    add_contract "pool_registry" "$POOL_REGISTRY" "PoolRegistry"
    add_contract "price_feed_manager" "$PRICE_FEED_MANAGER" "PriceFeedManager"
    add_contract "hook_deployer" "$HOOK_DEPLOYER" "HookDeployer"

    echo ""
    echo "--- Chain-Specific Addresses ---"
    add_contract "passport_gated_hook" "$PASSPORT_GATED_HOOK" "PassportGatedHook"
    add_contract "vault_factory" "$VAULT_FACTORY" "VaultFactory"
    add_contract "treasury_factory" "$TREASURY_FACTORY" "TreasuryFactory"

    # Update contract count
    jq --arg chain_id "$chain_id" \
       --argjson count "$found_count" \
       '.[$chain_id].contract_count = "\($count)/14"' \
       "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"

    # Validate JSON before moving
    if jq empty "$temp_json" 2>/dev/null; then
        mv "$temp_json" "$ADDRESSES_FILE"
        echo ""
        echo "✅ Updated addresses.json for $chain_name ($found_count/14 contracts)"
    else
        echo "❌ Error: Invalid JSON generated"
        rm -f "$temp_json"
        return 1
    fi
}

# Main execution
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      Updating addresses.json from deterministic deploy    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# First, compute all deterministic addresses (same for all chains)
compute_addresses

if [ $# -eq 0 ]; then
    # Update all chains that have broadcast files
    for chain_dir in "$BROADCAST_DIR"/*/; do
        if [ -d "$chain_dir" ]; then
            chain_id=$(basename "$chain_dir")
            if [ -f "$chain_dir/run-latest.json" ]; then
                echo ""
                update_chain_addresses "$chain_id"
            fi
        fi
    done
else
    echo ""
    update_chain_addresses "$1"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✨ Done!"
echo ""
echo "Next steps:"
echo "  1. Verify contracts:  ./scripts/verify-all.sh <chain_id>"
echo "  2. Extract ABIs:      ./scripts/extract-abis.sh"
echo "═══════════════════════════════════════════════════════════"

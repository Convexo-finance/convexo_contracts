#!/bin/bash
# scripts/update-addresses.sh
# Updates addresses.json from broadcast deployment files
# Updated for 14-contract system (v3.0)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BROADCAST_DIR="$PROJECT_DIR/broadcast/DeployAll.s.sol"
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

# Contract mapping (contractName:jsonKey)
# 14 contracts in total
CONTRACTS=(
    # NFT Contracts (Tier 1-3)
    "Convexo_Passport:convexo_passport"
    "Limited_Partners_Individuals:lp_individuals"
    "Limited_Partners_Business:lp_business"
    "Ecreditscoring:ecreditscoring"
    # Core Infrastructure
    "ReputationManager:reputation_manager"
    # Hook System
    "HookDeployer:hook_deployer"
    "PassportGatedHook:passport_gated_hook"
    "PoolRegistry:pool_registry"
    "PriceFeedManager:price_feed_manager"
    # Vault System
    "ContractSigner:contract_signer"
    "VaultFactory:vault_factory"
    # Treasury System
    "TreasuryFactory:treasury_factory"
    # Verifiers
    "VeriffVerifier:veriff_verifier"
    "SumsubVerifier:sumsub_verifier"
)

update_chain_addresses() {
    local chain_id=$1
    local broadcast_file="$BROADCAST_DIR/$chain_id/run-latest.json"
    
    if [ ! -f "$broadcast_file" ]; then
        echo "⚠️  Broadcast file not found: $broadcast_file"
        return 1
    fi
    
    local chain_info=$(get_chain_info "$chain_id")
    local chain_name=$(echo "$chain_info" | cut -d'|' -f1)
    local explorer_base=$(echo "$chain_info" | cut -d'|' -f2)
    local explorer_key=$(echo "$chain_info" | cut -d'|' -f3)
    
    echo "📝 Updating addresses for $chain_name (Chain ID: $chain_id)"
    
    # Initialize addresses.json if it doesn't exist
    if [ ! -f "$ADDRESSES_FILE" ]; then
        echo "{}" > "$ADDRESSES_FILE"
    fi
    
    local temp_json=$(mktemp)
    local deploy_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Start with existing addresses.json
    cp "$ADDRESSES_FILE" "$temp_json"
    
    # Initialize chain entry
    jq --arg chain_id "$chain_id" \
       --arg chain_name "$chain_name" \
       'if .[$chain_id] == null then
            .[$chain_id] = {
                "name": $chain_name,
                "version": "3.0",
                "contracts": {},
                "notes": {}
            }
        else
            .[$chain_id].name = $chain_name |
            .[$chain_id].version = "3.0"
        end' "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"
    
    local found_count=0
    local total_count=${#CONTRACTS[@]}
    
    for contract_pair in "${CONTRACTS[@]}"; do
        local contract_name=$(echo "$contract_pair" | cut -d':' -f1)
        local json_key=$(echo "$contract_pair" | cut -d':' -f2)
        
        # Extract address from broadcast file
        local addr=$(jq -r ".transactions[]? | select(.contractName == \"$contract_name\") | .contractAddress" "$broadcast_file" 2>/dev/null | head -1)
        
        if [ -n "$addr" ] && [ "$addr" != "null" ] && [ "$addr" != "" ]; then
            local explorer_url="${explorer_base}/${addr}"
            
            jq --arg chain_id "$chain_id" \
               --arg json_key "$json_key" \
               --arg addr "$addr" \
               --arg deploy_time "$deploy_time" \
               --arg explorer_key "$explorer_key" \
               --arg explorer_url "$explorer_url" \
               '.[$chain_id][$json_key] = {
                   "address": $addr,
                   "deployed_at": $deploy_time,
                   "verified": true,
                   ($explorer_key): $explorer_url
               }' "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"
            
            echo "  ✅ $contract_name: $addr"
            ((found_count++))
        fi
    done
    
    # Update deployment status
    jq --arg chain_id "$chain_id" \
       --arg status "Complete - $found_count/$total_count contracts deployed ✅ (v3.0)" \
       '.[$chain_id].notes.deployment_status = $status' \
       "$temp_json" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "$temp_json"
    
    # Validate JSON before moving
    if jq empty "$temp_json" 2>/dev/null; then
        mv "$temp_json" "$ADDRESSES_FILE"
        echo "✅ Updated addresses.json for $chain_name ($found_count/$total_count contracts)"
    else
        echo "❌ Error: Invalid JSON generated"
        rm -f "$temp_json"
        return 1
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║        Updating addresses.json from broadcasts           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    for chain_dir in "$BROADCAST_DIR"/*/; do
        if [ -d "$chain_dir" ]; then
            chain_id=$(basename "$chain_dir")
            if [ -f "$chain_dir/run-latest.json" ]; then
                update_chain_addresses "$chain_id"
                echo ""
            fi
        fi
    done
else
    update_chain_addresses "$1"
fi

echo "✨ Done!"

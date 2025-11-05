#!/bin/bash

# Comprehensive Deployment Script for Convexo NFT Contracts
# Deploys contracts, verifies them, and updates addresses.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ADDRESSES_FILE="$PROJECT_DIR/addresses.json"

# Chain configurations
declare -A CHAIN_NAMES
CHAIN_NAMES[1301]="unichain_sepolia"
CHAIN_NAMES[84532]="base_sepolia"
CHAIN_NAMES[11155111]="ethereum_sepolia"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to update addresses.json
update_addresses_json() {
    local chain_id=$1
    local contract_name=$2
    local address=$3
    local tx_hash=$4
    local block_number=$5
    
    print_info "Updating addresses.json for chain $chain_id, contract $contract_name..."
    
    # Use jq to update the JSON file
    local temp_file=$(mktemp)
    jq --arg chain_id "$chain_id" \
       --arg contract "$contract_name" \
       --arg address "$address" \
       --arg tx_hash "$tx_hash" \
       --arg block "$block_number" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.[$chain_id][$contract].address = $address |
        .[$chain_id][$contract].tx_hash = $tx_hash |
        .[$chain_id][$contract].block_number = ($block | tonumber) |
        .[$chain_id][$contract].deployed_at = $date' \
       "$ADDRESSES_FILE" > "$temp_file" && mv "$temp_file" "$ADDRESSES_FILE"
    
    print_info "✅ Updated addresses.json"
}

# Function to deploy a single contract
deploy_contract() {
    local contract_script=$1
    local contract_name=$2
    local chain_name=$3
    local chain_id=$4
    
    print_info "Deploying $contract_name to $chain_name (Chain ID: $chain_id)..."
    
    # Run deployment script
    local output=$(forge script "$contract_script" \
        --rpc-url "$chain_name" \
        --broadcast \
        --verify \
        --verifier etherscan \
        --etherscan-api-key "${ETHERSCAN_API_KEY}" \
        -vvvv 2>&1)
    
    # Extract contract address from output
    local address=$(echo "$output" | grep -oP 'Contract address: \K[0-9a-fA-Fx]+' | head -1 || echo "")
    
    if [ -z "$address" ]; then
        # Try alternative pattern
        address=$(echo "$output" | grep -oP 'Deployed to: \K[0-9a-fA-Fx]+' | head -1 || echo "")
    fi
    
    # Extract transaction hash
    local tx_hash=$(echo "$output" | grep -oP 'Transaction hash: \K[0-9a-fA-Fx]+' | head -1 || echo "")
    
    # Extract block number
    local block_number=$(echo "$output" | grep -oP 'Block number: \K[0-9]+' | head -1 || echo "0")
    
    if [ -z "$address" ]; then
        print_error "Failed to extract contract address from deployment output"
        echo "$output"
        return 1
    fi
    
    print_info "✅ $contract_name deployed to: $address"
    print_info "   Transaction: $tx_hash"
    print_info "   Block: $block_number"
    
    # Determine contract key for JSON
    local contract_key="convexo_lps"
    if [[ "$contract_name" == *"Vaults"* ]]; then
        contract_key="convexo_vaults"
    fi
    
    # Update addresses.json
    update_addresses_json "$chain_id" "$contract_key" "$address" "$tx_hash" "$block_number"
    
    return 0
}

# Main deployment function
main() {
    print_info "🚀 Starting deployment process..."
    
    # Check if .env is loaded
    if [ -z "$PRIVATE_KEY" ] || [ -z "$MINTER_ADDRESS" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
        print_error "Missing required environment variables!"
        print_error "Please ensure .env file is loaded with:"
        print_error "  - PRIVATE_KEY"
        print_error "  - MINTER_ADDRESS"
        print_error "  - ETHERSCAN_API_KEY"
        exit 1
    fi
    
    # Check if addresses.json exists
    if [ ! -f "$ADDRESSES_FILE" ]; then
        print_error "addresses.json not found at $ADDRESSES_FILE"
        exit 1
    fi
    
    # Parse command line arguments
    local chain_name="${1:-unichain_sepolia}"
    local deploy_lps="${2:-true}"
    local deploy_vaults="${3:-true}"
    
    # Determine chain ID
    local chain_id=""
    case "$chain_name" in
        unichain_sepolia)
            chain_id="1301"
            ;;
        base_sepolia)
            chain_id="84532"
            ;;
        ethereum_sepolia)
            chain_id="11155111"
            ;;
        *)
            print_error "Unknown chain: $chain_name"
            print_info "Available chains: unichain_sepolia, base_sepolia, ethereum_sepolia"
            exit 1
            ;;
    esac
    
    print_info "Target chain: $chain_name (ID: $chain_id)"
    
    # Deploy Convexo_LPs
    if [ "$deploy_lps" = "true" ]; then
        deploy_contract "script/DeployConvexoLPs.s.sol:DeployConvexoLPs" \
                       "Convexo_LPs" \
                       "$chain_name" \
                       "$chain_id"
    fi
    
    # Deploy Convexo_Vaults
    if [ "$deploy_vaults" = "true" ]; then
        deploy_contract "script/DeployConvexoVaults.s.sol:DeployConvexoVaults" \
                       "Convexo_Vaults" \
                       "$chain_name" \
                       "$chain_id"
    fi
    
    print_info "✨ Deployment complete!"
    print_info "📄 Updated addresses.json with deployment information"
    
    # Extract ABIs for frontend
    print_info "📦 Extracting ABIs..."
    "$SCRIPT_DIR/extract-abis.sh"
}

# Show usage if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [chain_name] [deploy_lps] [deploy_vaults]"
    echo ""
    echo "Arguments:"
    echo "  chain_name    - Chain to deploy to (default: unichain_sepolia)"
    echo "                  Options: unichain_sepolia, base_sepolia, ethereum_sepolia"
    echo "  deploy_lps    - Deploy Convexo_LPs (default: true)"
    echo "  deploy_vaults - Deploy Convexo_Vaults (default: true)"
    echo ""
    echo "Examples:"
    echo "  $0 unichain_sepolia true true    # Deploy both to Unichain Sepolia"
    echo "  $0 base_sepolia true false        # Deploy only LPs to Base Sepolia"
    echo "  $0 ethereum_sepolia               # Deploy both to Ethereum Sepolia"
    exit 0
fi

# Run main function
main "$@"


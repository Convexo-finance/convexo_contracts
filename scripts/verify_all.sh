#!/bin/bash
# verify_all.sh - Clean verification script for all Convexo contracts
# Usage: ./verify_all.sh [network]
# Networks: sepolia, base-sepolia, unichain-sepolia

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

source .env

# Network selection
NETWORK=${1:-"sepolia"}

echo -e "${BLUE}🔍 Starting verification for $NETWORK...${NC}\n"

# Set network-specific variables
case $NETWORK in
  "sepolia")
    RPC_URL=$ETHEREUM_SEPOLIA_RPC_URL
    CHAIN="sepolia"
    VERIFIER="etherscan"
    VERIFIER_URL=""
    USDC=$USDC_ADDRESS_ETHSEPOLIA
    ECOP=$ECOP_ADDRESS_ETHSEPOLIA
    POOL_MANAGER=$POOL_MANAGER_SEPOLIA
    CHAIN_ID="11155111"
    ;;
  "base-sepolia")
    RPC_URL=$BASE_SEPOLIA_RPC_URL
    CHAIN="base-sepolia"
    VERIFIER="etherscan"
    VERIFIER_URL=""
    USDC=$USDC_ADDRESS_BASESEPOLIA
    ECOP=$ECOP_ADDRESS_BASESEPOLIA
    POOL_MANAGER=$POOL_MANAGER_BASESEPOLIA
    CHAIN_ID="84532"
    ;;
  "unichain-sepolia")
    RPC_URL=$UNICHAIN_SEPOLIA_RPC_URL
    CHAIN="1301"
    VERIFIER="blockscout"
    VERIFIER_URL="https://unichain-sepolia.blockscout.com/api/"
    USDC=$USDC_ADDRESS_UNISEPOLIA
    ECOP=$ECOP_ADDRESS_UNISEPOLIA
    POOL_MANAGER=$POOL_MANAGER_UNISEPOLIA
    CHAIN_ID="1301"
    ;;
  *)
    echo -e "${RED}❌ Unknown network: $NETWORK${NC}"
    echo "Usage: ./verify_all.sh [sepolia|base-sepolia|unichain-sepolia]"
    exit 1
    ;;
esac

# Read addresses from addresses.json
ADDRESSES_FILE="addresses.json"

if [ ! -f $ADDRESSES_FILE ]; then
    echo -e "${RED}❌ addresses.json not found${NC}"
    exit 1
fi

# Extract addresses using jq (if available) or grep
get_address() {
    local key=$1
    if command -v jq &> /dev/null; then
        jq -r ".\"$CHAIN_ID\".$key.address" $ADDRESSES_FILE
    else
        # Fallback to grep if jq not available
        grep -A 3 "\"$key\"" $ADDRESSES_FILE | grep "address" | cut -d'"' -f4 | head -1
    fi
}

# Get all contract addresses
CONVEXO_LPS=$(get_address "convexo_lps")
CONVEXO_VAULTS=$(get_address "convexo_vaults")
HOOK_DEPLOYER=$(get_address "hook_deployer")
COMPLIANT_LP_HOOK=$(get_address "compliant_lp_hook")
POOL_REGISTRY=$(get_address "pool_registry")
REPUTATION_MANAGER=$(get_address "reputation_manager")
PRICE_FEED_MANAGER=$(get_address "price_feed_manager")
CONTRACT_SIGNER=$(get_address "contract_signer")
VAULT_FACTORY=$(get_address "vault_factory")

# Function to verify a contract
verify_contract() {
    local NAME=$1
    local ADDRESS=$2
    local CONTRACT_PATH=$3
    local CONTRACT_NAME=$4
    local CONSTRUCTOR_ARGS=$5
    
    echo -e "${YELLOW}📝 Verifying $NAME at $ADDRESS...${NC}"
    
    # Build verification command
    local CMD="forge verify-contract --watch --chain $CHAIN $ADDRESS $CONTRACT_PATH:$CONTRACT_NAME"
    
    if [ ! -z "$CONSTRUCTOR_ARGS" ]; then
        CMD="$CMD --constructor-args $CONSTRUCTOR_ARGS"
    fi
    
    if [ ! -z "$VERIFIER_URL" ]; then
        CMD="$CMD --verifier $VERIFIER --verifier-url $VERIFIER_URL"
    else
        CMD="$CMD --verifier $VERIFIER --etherscan-api-key $ETHERSCAN_API_KEY"
    fi
    
    # Execute verification
    if eval $CMD; then
        echo -e "${GREEN}✅ $NAME verified successfully!${NC}\n"
        return 0
    else
        echo -e "${RED}❌ Failed to verify $NAME${NC}\n"
        return 1
    fi
    
    # Rate limiting
    sleep 3
}

# Verify all contracts
VERIFIED=0
FAILED=0

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Starting verification of 9 contracts on $NETWORK${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# 1. Convexo_LPs
if verify_contract "Convexo_LPs" "$CONVEXO_LPS" \
    "src/convexolps.sol" "Convexo_LPs" \
    "$(cast abi-encode "constructor(address,address)" $MINTER_ADDRESS $MINTER_ADDRESS)"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 2. Convexo_Vaults
if verify_contract "Convexo_Vaults" "$CONVEXO_VAULTS" \
    "src/convexovaults.sol" "Convexo_Vaults" \
    "$(cast abi-encode "constructor(address,address)" $MINTER_ADDRESS $MINTER_ADDRESS)"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 3. HookDeployer
if verify_contract "HookDeployer" "$HOOK_DEPLOYER" \
    "src/hooks/HookDeployer.sol" "HookDeployer" \
    "$(cast abi-encode "constructor()")"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 4. CompliantLPHook
if verify_contract "CompliantLPHook" "$COMPLIANT_LP_HOOK" \
    "src/hooks/CompliantLPHook.sol" "CompliantLPHook" \
    "$(cast abi-encode "constructor(address,address)" $POOL_MANAGER $CONVEXO_LPS)"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 5. PoolRegistry
if verify_contract "PoolRegistry" "$POOL_REGISTRY" \
    "src/contracts/PoolRegistry.sol" "PoolRegistry" \
    "$(cast abi-encode "constructor()")"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 6. ReputationManager
if verify_contract "ReputationManager" "$REPUTATION_MANAGER" \
    "src/contracts/ReputationManager.sol" "ReputationManager" \
    "$(cast abi-encode "constructor()")"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 7. PriceFeedManager
if verify_contract "PriceFeedManager" "$PRICE_FEED_MANAGER" \
    "src/contracts/PriceFeedManager.sol" "PriceFeedManager" \
    "$(cast abi-encode "constructor()")"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 8. ContractSigner
if verify_contract "ContractSigner" "$CONTRACT_SIGNER" \
    "src/contracts/ContractSigner.sol" "ContractSigner" \
    "$(cast abi-encode "constructor()")"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# 9. VaultFactory
if verify_contract "VaultFactory" "$VAULT_FACTORY" \
    "src/contracts/VaultFactory.sol" "VaultFactory" \
    "$(cast abi-encode "constructor(address,address,address,address,address)" $MINTER_ADDRESS $USDC $MINTER_ADDRESS $CONTRACT_SIGNER $REPUTATION_MANAGER)"; then
    ((VERIFIED++))
else
    ((FAILED++))
fi

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Verification Summary for $NETWORK${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Verified: $VERIFIED/9${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Failed: $FAILED/9${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

if [ $VERIFIED -eq 9 ]; then
    echo -e "${GREEN}🎉 All contracts verified successfully on $NETWORK!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some contracts failed verification. Please check the errors above.${NC}"
    exit 1
fi


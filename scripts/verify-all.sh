#!/bin/bash
# Verify all Convexo contracts on block explorers
#
# Usage:
#   ./scripts/verify-all.sh <chain_id>
#
# Examples:
#   ./scripts/verify-all.sh 11155111  # Ethereum Sepolia
#   ./scripts/verify-all.sh 84532     # Base Sepolia
#   ./scripts/verify-all.sh 1301      # Unichain Sepolia
#   ./scripts/verify-all.sh 1         # Ethereum Mainnet
#   ./scripts/verify-all.sh 8453      # Base Mainnet
#   ./scripts/verify-all.sh 130       # Unichain Mainnet
#
# Prerequisites:
#   - jq installed (brew install jq)
#   - .env file with API keys: ETHERSCAN_API_KEY, BASESCAN_API_KEY
#   - addresses.json with deployed contract addresses

#!/bin/bash
# Verify all Convexo contracts on block explorers
#
# Usage:
#   ./scripts/verify-all.sh <chain_id>
#
# Examples:
#   ./scripts/verify-all.sh 11155111  # Ethereum Sepolia
#   ./scripts/verify-all.sh 84532     # Base Sepolia
#   ./scripts/verify-all.sh 1301      # Unichain Sepolia
#   ./scripts/verify-all.sh 1         # Ethereum Mainnet
#   ./scripts/verify-all.sh 8453      # Base Mainnet
#   ./scripts/verify-all.sh 130       # Unichain Mainnet
#
# Prerequisites:
#   - jq installed
#   - .env file with API keys
#   - addresses.json with deployed contract addresses

set -e

CHAIN_ID=$1

if [ -z "$CHAIN_ID" ]; then
    echo "Usage: ./scripts/verify-all.sh <chain_id>"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# -----------------------------
# Static configuration
# -----------------------------
ADMIN="0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8"
METADATA_URI="https://metadata.convexo.finance/passport"

# -----------------------------
# Explorer config
# -----------------------------
case $CHAIN_ID in
    1|11155111)
        API_KEY="$ETHERSCAN_API_KEY"
        VERIFIER="etherscan"
        ;;
    8453|84532)
        API_KEY="$BASESCAN_API_KEY"
        VERIFIER="etherscan"
        ;;
    130|1301)
        API_KEY="$UNISCAN_API_KEY"
        VERIFIER="uniscan"
        ;;
    *)
        echo "Unsupported chain ID: $CHAIN_ID"
        exit 1
        ;;
esac

echo "========================================"
echo "Verifying Convexo Contracts"
echo "Chain ID: $CHAIN_ID"
echo "========================================"
echo ""

# -----------------------------
# Load addresses.json
# -----------------------------
ADDRESSES_FILE="addresses.json"

if [ ! -f "$ADDRESSES_FILE" ]; then
    echo "Error: addresses.json not found"
    exit 1
fi

# -----------------------------
# Contract addresses
# -----------------------------
CONVEXO_PASSPORT=$(jq -r ".\"$CHAIN_ID\".contracts.convexo_passport.address // empty" $ADDRESSES_FILE)
LP_INDIVIDUALS=$(jq -r ".\"$CHAIN_ID\".contracts.lp_individuals.address // empty" $ADDRESSES_FILE)
LP_BUSINESS=$(jq -r ".\"$CHAIN_ID\".contracts.lp_business.address // empty" $ADDRESSES_FILE)
ECREDITSCORING=$(jq -r ".\"$CHAIN_ID\".contracts.ecreditscoring.address // empty" $ADDRESSES_FILE)
VERIFF_VERIFIER=$(jq -r ".\"$CHAIN_ID\".contracts.veriff_verifier.address // empty" $ADDRESSES_FILE)
SUMSUB_VERIFIER=$(jq -r ".\"$CHAIN_ID\".contracts.sumsub_verifier.address // empty" $ADDRESSES_FILE)
REPUTATION_MANAGER=$(jq -r ".\"$CHAIN_ID\".contracts.reputation_manager.address // empty" $ADDRESSES_FILE)
CONTRACT_SIGNER=$(jq -r ".\"$CHAIN_ID\".contracts.contract_signer.address // empty" $ADDRESSES_FILE)
POOL_REGISTRY=$(jq -r ".\"$CHAIN_ID\".contracts.pool_registry.address // empty" $ADDRESSES_FILE)
PRICE_FEED_MANAGER=$(jq -r ".\"$CHAIN_ID\".contracts.price_feed_manager.address // empty" $ADDRESSES_FILE)
HOOK_DEPLOYER=$(jq -r ".\"$CHAIN_ID\".contracts.hook_deployer.address // empty" $ADDRESSES_FILE)
VAULT_FACTORY=$(jq -r ".\"$CHAIN_ID\".contracts.vault_factory.address // empty" $ADDRESSES_FILE)
TREASURY_FACTORY=$(jq -r ".\"$CHAIN_ID\".contracts.treasury_factory.address // empty" $ADDRESSES_FILE)
PASSPORT_GATED_HOOK=$(jq -r ".\"$CHAIN_ID\".contracts.passport_gated_hook.address // empty" $ADDRESSES_FILE)

# -----------------------------
# External dependencies
# -----------------------------
USDC=$(jq -r ".\"$CHAIN_ID\".external.usdc // empty" $ADDRESSES_FILE)
POOL_MANAGER=$(jq -r ".\"$CHAIN_ID\".external.pool_manager // empty" $ADDRESSES_FILE)
ZK_PASSPORT_VERIFIER=$(jq -r ".\"$CHAIN_ID\".external.zkpassport_verifier // empty" $ADDRESSES_FILE)

# Use MINTER_ADDRESS from env or default to ADMIN
MINTER="${MINTER_ADDRESS:-$ADMIN}"

# -----------------------------
# Verify helper
# -----------------------------
verify_contract() {
    local ADDRESS=$1
    local CONTRACT_PATH=$2
    local CONSTRUCTOR_ARGS=$3
    local NAME=$4

    if [ -z "$ADDRESS" ] || [ "$ADDRESS" == "null" ]; then
        echo "[$NAME] Skipping – address not found"
        return
    fi

    echo "[$NAME] Verifying $ADDRESS"

    if [ -z "$CONSTRUCTOR_ARGS" ]; then
        forge verify-contract "$ADDRESS" "$CONTRACT_PATH" \
            --etherscan-api-key "$API_KEY" \
            --chain "$CHAIN_ID" \
            || echo "[$NAME] Verification failed or already verified"
    else
        forge verify-contract "$ADDRESS" "$CONTRACT_PATH" \
            --constructor-args "$CONSTRUCTOR_ARGS" \
            --etherscan-api-key "$API_KEY" \
            --chain "$CHAIN_ID" \
            || echo "[$NAME] Verification failed or already verified"
    fi

    echo ""
}

# =============================
# Phase 1: Core NFT Contracts
# =============================

ARGS=$(cast abi-encode "constructor(address,address,string)" \
    "$ADMIN" "$ZK_PASSPORT_VERIFIER" "$METADATA_URI")
verify_contract "$CONVEXO_PASSPORT" \
    "src/contracts/Convexo_Passport.sol:Convexo_Passport" "$ARGS" "Convexo_Passport"

ARGS=$(cast abi-encode "constructor(address,address,address)" \
    "$ADMIN" "$MINTER" "0x0000000000000000000000000000000000000000")
verify_contract "$LP_INDIVIDUALS" \
    "src/contracts/Limited_Partners_Individuals.sol:Limited_Partners_Individuals" "$ARGS" "LP_Individuals"

verify_contract "$LP_BUSINESS" \
    "src/contracts/Limited_Partners_Business.sol:Limited_Partners_Business" "$ARGS" "LP_Business"

if [ -n "$LP_INDIVIDUALS" ] && [ -n "$LP_BUSINESS" ]; then
    ARGS=$(cast abi-encode "constructor(address,address,address,address)" \
        "$ADMIN" "$MINTER" "$LP_INDIVIDUALS" "$LP_BUSINESS")
    verify_contract "$ECREDITSCORING" \
        "src/contracts/Ecreditscoring.sol:Ecreditscoring" "$ARGS" "Ecreditscoring"
fi

# =============================
# Phase 2: Verifiers
# =============================

if [ -n "$LP_INDIVIDUALS" ]; then
    ARGS=$(cast abi-encode "constructor(address,address)" "$ADMIN" "$LP_INDIVIDUALS")
    verify_contract "$VERIFF_VERIFIER" \
        "src/contracts/VeriffVerifier.sol:VeriffVerifier" "$ARGS" "VeriffVerifier"
fi

if [ -n "$LP_BUSINESS" ]; then
    ARGS=$(cast abi-encode "constructor(address,address)" "$ADMIN" "$LP_BUSINESS")
    verify_contract "$SUMSUB_VERIFIER" \
        "src/contracts/SumsubVerifier.sol:SumsubVerifier" "$ARGS" "SumsubVerifier"
fi

# =============================
# Phase 3: Infrastructure
# =============================

if [ -n "$CONVEXO_PASSPORT" ] && [ -n "$LP_INDIVIDUALS" ] && [ -n "$LP_BUSINESS" ] && [ -n "$ECREDITSCORING" ]; then
    ARGS=$(cast abi-encode "constructor(address,address,address,address)" \
        "$CONVEXO_PASSPORT" "$LP_INDIVIDUALS" "$LP_BUSINESS" "$ECREDITSCORING")
    verify_contract "$REPUTATION_MANAGER" \
        "src/contracts/ReputationManager.sol:ReputationManager" "$ARGS" "ReputationManager"
fi

ARGS=$(cast abi-encode "constructor(address)" "$ADMIN")
verify_contract "$CONTRACT_SIGNER" \
    "src/contracts/ContractSigner.sol:ContractSigner" "$ARGS" "ContractSigner"

verify_contract "$POOL_REGISTRY" \
    "src/contracts/PoolRegistry.sol:PoolRegistry" "$ARGS" "PoolRegistry"

verify_contract "$PRICE_FEED_MANAGER" \
    "src/contracts/PriceFeedManager.sol:PriceFeedManager" "$ARGS" "PriceFeedManager"

verify_contract "$HOOK_DEPLOYER" \
    "src/hooks/HookDeployer.sol:HookDeployer" "" "HookDeployer"

# =============================
# Phase 4: Chain-Specific
# =============================

if [ -n "$USDC" ] && [ -n "$CONTRACT_SIGNER" ] && [ -n "$REPUTATION_MANAGER" ]; then
    ARGS=$(cast abi-encode "constructor(address,address,address,address,address)" \
        "$ADMIN" "$USDC" "$ADMIN" "$CONTRACT_SIGNER" "$REPUTATION_MANAGER")
    verify_contract "$VAULT_FACTORY" \
        "src/contracts/VaultFactory.sol:VaultFactory" "$ARGS" "VaultFactory"
fi

if [ -n "$USDC" ] && [ -n "$REPUTATION_MANAGER" ]; then
    ARGS=$(cast abi-encode "constructor(address,address)" "$USDC" "$REPUTATION_MANAGER")
    verify_contract "$TREASURY_FACTORY" \
        "src/contracts/TreasuryFactory.sol:TreasuryFactory" "$ARGS" "TreasuryFactory"
fi

if [ -n "$POOL_MANAGER" ] && [ -n "$REPUTATION_MANAGER" ]; then
    ARGS=$(cast abi-encode "constructor(address,address)" "$POOL_MANAGER" "$REPUTATION_MANAGER")
    verify_contract "$PASSPORT_GATED_HOOK" \
        "src/hooks/PassportGatedHook.sol:PassportGatedHook" "$ARGS" "PassportGatedHook"
fi

echo "========================================"
echo "Verification Complete!"
echo "========================================"
echo "✅ verify-all.sh finished successfully"
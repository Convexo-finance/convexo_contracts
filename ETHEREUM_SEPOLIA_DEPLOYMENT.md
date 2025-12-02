# Ethereum Sepolia Deployment Summary

**Date:** December 2, 2025  
**Version:** 2.0 (New Vault Flow)
**Chain:** Ethereum Sepolia (Chain ID: 11155111)  
**Deployer:** `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`  
**Explorer:** https://sepolia.etherscan.io

---

## 📊 Deployment Status

### ✅ ALL CONTRACTS SUCCESSFULLY DEPLOYED & VERIFIED (9/9 contracts) 🎉

| Contract | Address | Status | Etherscan |
|----------|---------|--------|-----------|
| **Convexo_LPs** | `0x7fd91438eacffe828f61737d64926ee44cf6695c` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x7fd91438eacffe828f61737d64926ee44cf6695c) |
| **Convexo_Vaults** | `0xf02d84e56da48cec9233cb7982db0ac82f29a973` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0xf02d84e56da48cec9233cb7982db0ac82f29a973) |
| **HookDeployer** | `0x1843c76dfe7a353d239912d8e23bdebda712f4c9` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x1843c76dfe7a353d239912d8e23bdebda712f4c9) |
| **CompliantLPHook** | `0x9fe009296cc964573cc8fb394598a3d5b9800394` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x9fe009296cc964573cc8fb394598a3d5b9800394) |
| **PoolRegistry** | `0x0f0e9e5e7e6a47d35e261dd876438cd144f97f1e` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x0f0e9e5e7e6a47d35e261dd876438cd144f97f1e) |
| **ReputationManager** | `0x6ba429488cad3795af1ec65d80be760b70f58e4b` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x6ba429488cad3795af1ec65d80be760b70f58e4b) |
| **PriceFeedManager** | `0x64fd5631ffe78e907da7b48542abfb402680891a` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x64fd5631ffe78e907da7b48542abfb402680891a) |
| **ContractSigner** | `0x1917aac9c182454b3ab80aa8703734d2831adf08` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x1917aac9c182454b3ab80aa8703734d2831adf08) |
| **VaultFactory** | `0x3933f0018fc7d21756b86557640d66b97f514bae` | ✅ Verified | [View](https://sepolia.etherscan.io/address/0x3933f0018fc7d21756b86557640d66b97f514bae) |

---

## 🔧 Network Configuration

### Token Addresses
- **USDC:** `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **ECOP:** `0x19ac2612e560b2bbedf88660a2566ef53c0a15a1`

### Uniswap V4 Addresses
- **PoolManager:** `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- **Universal Router:** `0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b`
- **PositionManager:** `0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4`
- **Quoter:** `0x61b3f2011a92d183c7dbadbda940a7555ccf9227`
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

> See [NETWORK_ADDRESSES.md](./NETWORK_ADDRESSES.md) for complete Uniswap V4 addresses

---

## 📝 Deployment Order

Contracts were deployed in the following order to satisfy dependencies:

### Phase 1: NFTs
1. **Convexo_LPs** - Tier 1 NFT for liquidity pool access
2. **Convexo_Vaults** - Tier 2 NFT for vault creation

### Phase 2: Hook System
3. **HookDeployer** - Deploys hooks with correct addresses
4. **CompliantLPHook** - Uniswap V4 hook for NFT-gated pools
5. **PoolRegistry** - Tracks compliant liquidity pools

### Phase 3: Core Infrastructure
6. **ReputationManager** - Calculates user tiers based on NFT ownership
7. **PriceFeedManager** - Manages price feeds for currency conversions

### Phase 4: Vault System
8. **ContractSigner** - Multi-signature contract system
9. **VaultFactory** - Creates tokenized bond vaults

---

## 🧪 Test Results

All tests passing before deployment:

```bash
forge test
```

**Results:**
- ✅ 14/14 VaultFlow tests passing
- ✅ 63/63 total tests passing
- ✅ All integration tests successful

---

## 🚀 Deployment Command

```bash
./scripts/deploy_ethereum_sepolia.sh
```

Or manually:

```bash
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url ethereum_sepolia \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvv
```

---

## ✅ Verification

All contracts verified using:

```bash
./scripts/verify_contracts.sh ethereum_sepolia
```

Verification uses Etherscan V2 API with automatic constructor argument encoding.

---

## 📦 Next Steps

### 1. Configure Price Feeds
```solidity
// Admin calls on PriceFeedManager
addPriceFeed(CurrencyPair.USDC_ECOP, 0x...); // Chainlink feed or LP-based
addPriceFeed(CurrencyPair.USDC_ARS, 0x...);
addPriceFeed(CurrencyPair.USDC_MXN, 0x...);
```

### 2. Register Pools
```solidity
// Admin calls on PoolRegistry
registerPool(poolId, hookAddress);
```

### 3. Mint Initial NFTs
```solidity
// Minter calls on Convexo_LPs
safeMint(userAddress, "COMPANY_ID", "ipfs://metadata");

// Minter calls on Convexo_Vaults (after credit scoring)
safeMint(borrowerAddress, "COMPANY_ID", "ipfs://metadata");
```

### 4. Create First Vault
```solidity
// Borrower (with Tier 2 NFT) calls on VaultFactory
createVault(
    principalAmount,    // e.g., 10000 * 1e6 (10,000 USDC)
    interestRate,       // e.g., 1200 (12%)
    duration,           // e.g., 365 days
    "Vault Name",
    "VAULT"
);
```

### 5. Frontend Integration
- Update contract addresses in frontend
- Extract and use ABIs from `abis/` folder
- Test vault creation and funding flows
- Test liquidity pool swaps

---

## 📚 Documentation

- **Main README:** [README.md](./README.md)
- **Contract Reference:** [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md)
- **Frontend Integration:** [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)
- **Network Addresses:** [NETWORK_ADDRESSES.md](./NETWORK_ADDRESSES.md)
- **Deployment Scripts:** [scripts/README.md](./scripts/README.md)

---

## 🔗 Quick Links

- **Etherscan:** https://sepolia.etherscan.io
- **Uniswap V4 Docs:** https://docs.uniswap.org/contracts/v4/overview
- **Chainlink Feeds:** https://docs.chain.link/data-feeds/price-feeds/addresses

---

## 📝 Notes

### Version 2.0 Changes
- **New Vault Flow:** Borrower-initiated vault creation (requires Tier 2 NFT)
- **Flexible Repayment:** Pay anytime, any amount before maturity
- **Independent Withdrawals:** Protocol collector and investors withdraw separately
- **Contract Signing:** Vault requires signed contract before fund withdrawal
- **Removed Products:** Simplified to focus only on Tokenized Bond Vaults

### Key Improvements
- Cleaner codebase (9 contracts instead of 11)
- Better separation of concerns
- More flexible repayment system
- Transparent on-chain state tracking

---

**Deployment Completed:** December 2, 2025 at 07:30 UTC  
**Status:** ✅ Ready for frontend integration and testing

# Unichain Sepolia Deployment Summary

**Date:** December 2, 2025  
**Version:** 2.0 (New Vault Flow)
**Chain:** Unichain Sepolia (Chain ID: 1301)  
**Deployer:** `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`  
**Explorer:** https://unichain-sepolia.blockscout.com

---

## 📊 Deployment Status

### ✅ ALL CONTRACTS SUCCESSFULLY DEPLOYED & VERIFIED (9/9 contracts) 🎉

| Contract | Address | Status | Blockscout |
|----------|---------|--------|------------|
| **Convexo_LPs** | `0xbb13194b2792e291109402369cb4fc0358aed132` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0xbb13194b2792e291109402369cb4fc0358aed132) |
| **Convexo_Vaults** | `0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a) |
| **HookDeployer** | `0xc98bce4617f9708dd1363f21177be5ef21fb4993` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0xc98bce4617f9708dd1363f21177be5ef21fb4993) |
| **CompliantLPHook** | `0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7) |
| **PoolRegistry** | `0x5a1f415986a189d79d19d65cb6e3d6dd7b807268` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0x5a1f415986a189d79d19d65cb6e3d6dd7b807268) |
| **ReputationManager** | `0x6b51adc34a503b23db99444048ac7c2dc735a12e` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0x6b51adc34a503b23db99444048ac7c2dc735a12e) |
| **PriceFeedManager** | `0x5d88bcf0d62f17846d41e161e92e497d4224764d` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0x5d88bcf0d62f17846d41e161e92e497d4224764d) |
| **ContractSigner** | `0x6a6357c387331e75d6eeb4d4abc0f0200cd32830` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0x6a6357c387331e75d6eeb4d4abc0f0200cd32830) |
| **VaultFactory** | `0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3` | ✅ Verified | [View](https://unichain-sepolia.blockscout.com/address/0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3) |

---

## 🔧 Network Configuration

### Token Addresses
- **USDC:** `0x31d0220469e10c4E71834a79b1f276d740d3768F`
- **ECOP:** `0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260`

### Uniswap V4 Addresses
- **PoolManager:** `0x00B036B58a818B1BC34d502D3fE730Db729e62AC`
- **Universal Router:** `0xf70536b3bcc1bd1a972dc186a2cf84cc6da6be5d`
- **PositionManager:** `0xf969aee60879c54baaed9f3ed26147db216fd664`
- **Quoter:** `0x56dcd40a3f2d466f48e7f48bdbe5cc9b92ae4472`
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
./scripts/deploy_unichain_sepolia.sh
```

Or manually:

```bash
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url unichain_sepolia \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://unichain-sepolia.blockscout.com/api \
    -vvv
```

---

## ✅ Verification

To verify contracts manually:

```bash
./scripts/verify_contracts.sh unichain_sepolia
```

Verification uses Blockscout API for Unichain Sepolia.

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

- **Blockscout:** https://unichain-sepolia.blockscout.com
- **Unichain Docs:** https://docs.unichain.org
- **Uniswap V4 Docs:** https://docs.uniswap.org/contracts/v4/overview

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

### Unichain-Specific Notes
- Unichain is Uniswap's native L2 optimized for DeFi
- Lower gas costs compared to Ethereum mainnet
- Native Uniswap V4 integration
- Uses Blockscout for contract verification

---

**Deployment Completed:** December 2, 2025 at 07:40 UTC  
**Verification Completed:** December 2, 2025 at 08:00 UTC  
**Status:** ✅ Fully deployed and verified

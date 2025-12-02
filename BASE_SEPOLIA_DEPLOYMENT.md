# Base Sepolia Deployment Summary

**Date:** December 2, 2025  
**Version:** 2.0 (New Vault Flow)
**Chain:** Base Sepolia (Chain ID: 84532)  
**Deployer:** `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`  
**Explorer:** https://sepolia.basescan.org

---

## 📊 Deployment Status

### ✅ ALL CONTRACTS SUCCESSFULLY DEPLOYED & VERIFIED (9/9 contracts) 🎉

| Contract | Address | Status | Basescan |
|----------|---------|--------|----------|
| **Convexo_LPs** | `0xbABEe8acECC117c1295F8950f51Db59F7a881646` | ✅ Verified | [View](https://sepolia.basescan.org/address/0xbABEe8acECC117c1295F8950f51Db59F7a881646) |
| **Convexo_Vaults** | `0xd189d95eE1a126A66fc5A84934372Aa0Fc0bb6d2` | ✅ Verified | [View](https://sepolia.basescan.org/address/0xd189d95eE1a126A66fc5A84934372Aa0Fc0bb6d2) |
| **HookDeployer** | `0xE0c0d95701558eF10768A13A944F56311EAD4649` | ✅ Verified | [View](https://sepolia.basescan.org/address/0xE0c0d95701558eF10768A13A944F56311EAD4649) |
| **CompliantLPHook** | `0xDd973cE09ba55260e217d10f9DeC6D7945D73E79` | ✅ Verified | [View](https://sepolia.basescan.org/address/0xDd973cE09ba55260e217d10f9DeC6D7945D73E79) |
| **PoolRegistry** | `0x24d91b11B0Dd12d6520E58c72F8FCC9dC1C5b935` | ✅ Verified | [View](https://sepolia.basescan.org/address/0x24d91b11B0Dd12d6520E58c72F8FCC9dC1C5b935) |
| **ReputationManager** | `0x3770Bb3BBEb0102a36f51aA253E69034058E4F84` | ✅ Verified | [View](https://sepolia.basescan.org/address/0x3770Bb3BBEb0102a36f51aA253E69034058E4F84) |
| **PriceFeedManager** | `0x2Fa95f79Ce8C5c01581f6792ACc4181282aaEFB0` | ✅ Verified | [View](https://sepolia.basescan.org/address/0x2Fa95f79Ce8C5c01581f6792ACc4181282aaEFB0) |
| **ContractSigner** | `0xf8dce148AB008f7ae47A26377252673438801712` | ✅ Verified | [View](https://sepolia.basescan.org/address/0xf8dce148AB008f7ae47A26377252673438801712) |
| **VaultFactory** | `0x3D684Ac58f25a95c107565bCFfffb219B00557C7` | ✅ Verified | [View](https://sepolia.basescan.org/address/0x3D684Ac58f25a95c107565bCFfffb219B00557C7) |

---

## 🔧 Network Configuration

### Token Addresses
- **USDC:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **ECOP:** `0xb934dcb57fb0673b7bc0fca590c5508f1cde955d`

### Uniswap V4 Addresses
- **PoolManager:** `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408`
- **Universal Router:** `0x492e6456d9528771018deb9e87ef7750ef184104`
- **PositionManager:** `0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80`
- **Quoter:** `0x4a6513c898fe1b2d0e78d3b0e0a4a151589b1cba`
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
./scripts/deploy_base_sepolia.sh
```

Or manually:

```bash
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url base_sepolia \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvv
```

---

## ✅ Verification

To verify contracts manually:

```bash
./scripts/verify_contracts.sh base_sepolia
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

- **Basescan:** https://sepolia.basescan.org
- **Base Docs:** https://docs.base.org
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

---

**Deployment Completed:** December 2, 2025 at 07:35 UTC  
**Verification Completed:** December 2, 2025 at 08:00 UTC  
**Status:** ✅ Fully deployed and verified

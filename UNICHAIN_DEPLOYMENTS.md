# 🦄 Unichain Deployments

Complete deployment guide for all Unichain networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Unichain Mainnet** | 130 | ✅ Complete | 12/12 | [Blockscout](https://unichain.blockscout.com) |
| **Unichain Sepolia** | 1301 | ✅ Complete | 12/12 | [Blockscout](https://unichain-sepolia.blockscout.com) |

---

# 🚀 Unichain Mainnet

## Network Information
- **Chain ID**: 130
- **Network Name**: Unichain Mainnet
- **RPC URL**: https://mainnet.unichain.org
- **Block Explorer**: https://unichain.blockscout.com
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 12 contracts deployed and verified**  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)  
**Block Range**: 35816776-35816778  
**Total Gas Paid**: 0.000000046931112488 ETH

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96` | [View on Blockscout](https://unichain.blockscout.com/address/0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96) |
| **Convexo_Vaults** | `0x805b733cc50818dabede4847c4a775a7b1610f96` | [View on Blockscout](https://unichain.blockscout.com/address/0x805b733cc50818dabede4847c4a775a7b1610f96) |
| **Convexo_Passport** | `0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76` | [View on Blockscout](https://unichain.blockscout.com/address/0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xfb0157e0f904bfa464d09235a723fc2c462d1e76` | [View on Blockscout](https://unichain.blockscout.com/address/0xfb0157e0f904bfa464d09235a723fc2c462d1e76) |
| **CompliantLPHook** | `0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194` | [View on Blockscout](https://unichain.blockscout.com/address/0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194) |
| **PoolRegistry** | `0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8` | [View on Blockscout](https://unichain.blockscout.com/address/0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xb2785f4341b5bf26be07f7e2037550769ce830cd` | [View on Blockscout](https://unichain.blockscout.com/address/0xb2785f4341b5bf26be07f7e2037550769ce830cd) |
| **PriceFeedManager** | `0x3738d60fcb27d719fdd5113b855e1158b93a95b1` | [View on Blockscout](https://unichain.blockscout.com/address/0x3738d60fcb27d719fdd5113b855e1158b93a95b1) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff` | [View on Blockscout](https://unichain.blockscout.com/address/0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff) |
| **VaultFactory** | `0xe4a58592171cd0770e6792600ea3098060a42d46` | [View on Blockscout](https://unichain.blockscout.com/address/0xe4a58592171cd0770e6792600ea3098060a42d46) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0xd7cf4aba5b9b4877419ab8af3979da637493afb1` | [View on Blockscout](https://unichain.blockscout.com/address/0xd7cf4aba5b9b4877419ab8af3979da637493afb1) |
| **VeriffVerifier** | `0x99e9880a08e14112a18c091bd49a2b1713133687` | [View on Blockscout](https://unichain.blockscout.com/address/0x99e9880a08e14112a18c091bd49a2b1713133687) |

## Network Dependencies

### Uniswap V4 PoolManager
- **Address**: `0x1F98400000000000000000000000000000000004`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0x078D782b760474a361dDA0AF3839290b0EF57AD6`
- **Purpose**: Bridged USDC on Unichain - stablecoin used in VaultFactory

### ZKPassport Verifier
- **Address**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`
- **Purpose**: Official ZKPassport verifier for identity verification

## Frontend Integration (Mainnet)

```javascript
const UNICHAIN_MAINNET_CONFIG = {
  chainId: 130,
  name: "Unichain Mainnet",
  contracts: {
    convexoLPs: "0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96",
    convexoVaults: "0x805b733cc50818dabede4847c4a775a7b1610f96",
    convexoPassport: "0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76",
    hookDeployer: "0xfb0157e0f904bfa464d09235a723fc2c462d1e76",
    compliantLPHook: "0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194",
    poolRegistry: "0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8",
    reputationManager: "0xb2785f4341b5bf26be07f7e2037550769ce830cd",
    priceFeedManager: "0x3738d60fcb27d719fdd5113b855e1158b93a95b1",
    contractSigner: "0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff",
    vaultFactory: "0xe4a58592171cd0770e6792600ea3098060a42d46",
    treasuryFactory: "0xd7cf4aba5b9b4877419ab8af3979da637493afb1",
    veriffVerifier: "0x99e9880a08e14112a18c091bd49a2b1713133687"
  },
  usdc: "0x078D782b760474a361dDA0AF3839290b0EF57AD6",
  poolManager: "0x1F98400000000000000000000000000000000004",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

# 🧪 Unichain Sepolia Testnet

## Network Information
- **Chain ID**: 1301
- **Network Name**: Unichain Sepolia
- **RPC URL**: https://sepolia.unichain.org
- **Block Explorer**: https://unichain-sepolia.blockscout.com
- **Currency**: ETH (Testnet)

## Deployment Summary
**Status**: ✅ Complete - All 12 contracts deployed and verified  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xfb965542aa0b58538a9b50fe020314dd687eb128` | [View](https://unichain-sepolia.blockscout.com/address/0xfb965542aa0b58538a9b50fe020314dd687eb128) |
| **Convexo_Vaults** | `0x503f203ce6d6462f433cd04c7ad2b05d61b56548` | [View](https://unichain-sepolia.blockscout.com/address/0x503f203ce6d6462f433cd04c7ad2b05d61b56548) |
| **Convexo_Passport** | `0xab83ce760054c1d048d5a9de5194b05398a09d41` | [View](https://unichain-sepolia.blockscout.com/address/0xab83ce760054c1d048d5a9de5194b05398a09d41) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x18fb358bc74054b0c2530c48ef23f8a8d464cb18` | [View](https://unichain-sepolia.blockscout.com/address/0x18fb358bc74054b0c2530c48ef23f8a8d464cb18) |
| **CompliantLPHook** | `0x50ace0dce54df668477adee4e9d6a6c0df4fedee` | [View](https://unichain-sepolia.blockscout.com/address/0x50ace0dce54df668477adee4e9d6a6c0df4fedee) |
| **PoolRegistry** | `0xa46629011e0b8561a45ea03b822d28c0b2432c3a` | [View](https://unichain-sepolia.blockscout.com/address/0xa46629011e0b8561a45ea03b822d28c0b2432c3a) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x62227ff7ccbdb4d72c3511290b28c3424f1500ef` | [View](https://unichain-sepolia.blockscout.com/address/0x62227ff7ccbdb4d72c3511290b28c3424f1500ef) |
| **PriceFeedManager** | `0x8efc7e25c12a815329331da5f0e96affb4014472` | [View](https://unichain-sepolia.blockscout.com/address/0x8efc7e25c12a815329331da5f0e96affb4014472) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xa932e3eaa0a5e5e65f0567405207603266937618` | [View](https://unichain-sepolia.blockscout.com/address/0xa932e3eaa0a5e5e65f0567405207603266937618) |
| **VaultFactory** | `0x2cfa02372782cf20ef8342b0193fd69e4c5b04a8` | [View](https://unichain-sepolia.blockscout.com/address/0x2cfa02372782cf20ef8342b0193fd69e4c5b04a8) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0xecde45fefb5c2ef6e5cc615291de9be9a99b46a6` | [View](https://unichain-sepolia.blockscout.com/address/0xecde45fefb5c2ef6e5cc615291de9be9a99b46a6) |
| **VeriffVerifier** | `0xe99a49bd81bbe61cdf7f6b7d247f76cacc2e5776` | [View](https://unichain-sepolia.blockscout.com/address/0xe99a49bd81bbe61cdf7f6b7d247f76cacc2e5776) |

## Network Dependencies (Sepolia)

- **USDC**: `0x31d0220469e10c4E71834a79b1f276d740d3768F`
- **ECOP Token**: `0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260`
- **PoolManager**: `0x00B036B58a818B1BC34d502D3fE730Db729e62AC`
- **ZKPassport Verifier**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`

## Frontend Integration (Sepolia)

```javascript
const UNICHAIN_SEPOLIA_CONFIG = {
  chainId: 1301,
  name: "Unichain Sepolia",
  contracts: {
    convexoLPs: "0xfb965542aa0b58538a9b50fe020314dd687eb128",
    convexoVaults: "0x503f203ce6d6462f433cd04c7ad2b05d61b56548",
    convexoPassport: "0xab83ce760054c1d048d5a9de5194b05398a09d41",
    hookDeployer: "0x18fb358bc74054b0c2530c48ef23f8a8d464cb18",
    compliantLPHook: "0x50ace0dce54df668477adee4e9d6a6c0df4fedee",
    poolRegistry: "0xa46629011e0b8561a45ea03b822d28c0b2432c3a",
    reputationManager: "0x62227ff7ccbdb4d72c3511290b28c3424f1500ef",
    priceFeedManager: "0x8efc7e25c12a815329331da5f0e96affb4014472",
    contractSigner: "0xa932e3eaa0a5e5e65f0567405207603266937618",
    vaultFactory: "0x2cfa02372782cf20ef8342b0193fd69e4c5b04a8",
    treasuryFactory: "0xecde45fefb5c2ef6e5cc615291de9be9a99b46a6",
    veriffVerifier: "0xe99a49bd81bbe61cdf7f6b7d247f76cacc2e5776"
  },
  usdc: "0x31d0220469e10c4E71834a79b1f276d740d3768F",
  ecop: "0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260",
  poolManager: "0x00B036B58a818B1BC34d502D3fE730Db729e62AC",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

## 🔧 Deployment Scripts

### Deploy to Unichain Mainnet
```bash
./scripts/deploy_unichain_mainnet.sh
```

### Deploy to Unichain Sepolia
```bash
./scripts/deploy_unichain_sepolia.sh
```

---

## 🏆 Tier System (v2.1)

| Tier | NFT | User Type | Access |
|------|-----|-----------|--------|
| **Tier 0** | None | Unverified | No access |
| **Tier 1** | Convexo_Passport | Individual | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | Limited Partner | LP pools + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault Creator | All above + Vault creation |

---

## 💡 Unichain Benefits

### Why Unichain?
- **Uniswap native**: Built by Uniswap team for optimal DEX performance
- **Ultra-low gas**: Cheapest network for DeFi operations
- **Instant finality**: Fast transaction confirmations
- **MEV protection**: Built-in MEV resistance for fair trading

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 12 Contracts |
|---------|------------------|---------------------------|
| Ethereum Mainnet | ~30 gwei | ~0.0005 ETH (~$2) |
| Base Mainnet | ~0.0009 gwei | ~0.000011 ETH (~$0.04) |
| **Unichain Mainnet** | **~0.000004 gwei** | **~0.000047 ETH (~$0.0002)** |

**Unichain is 10,000x cheaper than Ethereum!**

---

## 📚 Additional Resources

### Documentation
- [Contract Reference](./CONTRACTS_REFERENCE.md)
- [Security Audit](./SECURITY_AUDIT.md)
- [Frontend Integration Guide](./FRONTEND_INTEGRATION.md)
- [ZKPassport Integration](./ZKPASSPORT_FRONTEND_INTEGRATION.md)

### Unichain Resources
- [Unichain Documentation](https://docs.unichain.org)
- [Unichain Blockscout](https://unichain.blockscout.com)
- [Unichain Faucet (Sepolia)](https://faucet.unichain.org)

---

## 🛠️ Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Unichain Mainnet
UNICHAIN_MAINNET_RPC_URL=https://mainnet.unichain.org
POOL_MANAGER_ADDRESS_UNICHAIN=0x1F98400000000000000000000000000000000004
USDC_ADDRESS_UNICHAIN=0x078D782b760474a361dDA0AF3839290b0EF57AD6

# Unichain Sepolia
UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.unichain.org
POOL_MANAGER_ADDRESS_UNICHAINSEPOLIA=0x00B036B58a818B1BC34d502D3fE730Db729e62AC
USDC_ADDRESS_UNICHAINSEPOLIA=0x31d0220469e10c4E71834a79b1f276d740d3768F
ECOP_ADDRESS_UNICHAINSEPOLIA=0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260
```

---

## 📝 Notes

### Admin Configuration (Both Networks)
- **Admin Address**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`
- **Minter Address**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`
- **Protocol Fee Collector**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`

### Compiler Settings
- Solidity: 0.8.27
- Optimizer: Enabled (200 runs)
- EVM Version: Prague
- Via IR: Enabled

### Verification Status
✅ All 12 contracts verified on Blockscout (Both networks)

---

*Last updated: January 7, 2026 - v2.1*

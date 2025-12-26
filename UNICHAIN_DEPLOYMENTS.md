# 🦄 Unichain Deployments

Complete deployment guide for all Unichain networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Unichain Mainnet** | 130 | ✅ Complete | 10/10 | [Blockscout](https://unichain.blockscout.com) |
| **Unichain Sepolia** | 1301 | ✅ Complete | 10/10 | [Blockscout](https://unichain-sepolia.blockscout.com) |

---

# 🚀 Unichain Mainnet

## Network Information
- **Chain ID**: 130
- **Network Name**: Unichain Mainnet
- **RPC URL**: https://sepolia.unichain.org
- **Block Explorer**: https://unichain.blockscout.com
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 10 contracts deployed and verified**  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)  
**Block Range**: 35816776-35816778  
**Total Gas Paid**: 0.000000046931112488 ETH

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x64fd5631ffe78e907da7b48542abfb402680891a` | [View on Blockscout](https://unichain.blockscout.com/address/0x64fd5631ffe78e907da7b48542abfb402680891a) |
| **Convexo_Vaults** | `0x1917aac9c182454b3ab80aa8703734d2831adf08` | [View on Blockscout](https://unichain.blockscout.com/address/0x1917aac9c182454b3ab80aa8703734d2831adf08) |
| **Convexo_Passport** | `0x3933f0018fc7d21756b86557640d66b97f514bae` | [View on Blockscout](https://unichain.blockscout.com/address/0x3933f0018fc7d21756b86557640d66b97f514bae) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02` | [View on Blockscout](https://unichain.blockscout.com/address/0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02) |
| **CompliantLPHook** | `0x7c22db98a3f8da11f8c79d60a78d12df4a18516b` | [View on Blockscout](https://unichain.blockscout.com/address/0x7c22db98a3f8da11f8c79d60a78d12df4a18516b) |
| **PoolRegistry** | `0x8b346a47413991077f6ad38bfa4bfd3693187e6e` | [View on Blockscout](https://unichain.blockscout.com/address/0x8b346a47413991077f6ad38bfa4bfd3693187e6e) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8` | [View on Blockscout](https://unichain.blockscout.com/address/0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8) |
| **PriceFeedManager** | `0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841` | [View on Blockscout](https://unichain.blockscout.com/address/0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71` | [View on Blockscout](https://unichain.blockscout.com/address/0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71) |
| **VaultFactory** | `0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710` | [View on Blockscout](https://unichain.blockscout.com/address/0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710) |

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
    convexoLPs: "0x64fd5631ffe78e907da7b48542abfb402680891a",
    convexoVaults: "0x1917aac9c182454b3ab80aa8703734d2831adf08",
    convexoPassport: "0x3933f0018fc7d21756b86557640d66b97f514bae",
    hookDeployer: "0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02",
    compliantLPHook: "0x7c22db98a3f8da11f8c79d60a78d12df4a18516b",
    poolRegistry: "0x8b346a47413991077f6ad38bfa4bfd3693187e6e",
    reputationManager: "0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8",
    priceFeedManager: "0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841",
    contractSigner: "0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71",
    vaultFactory: "0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710"
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
**Status**: ✅ Complete - All 10 contracts deployed and verified  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x3beccf56c87ee913e0c9e271b03daaf9fc4dcdea` | [View](https://unichain-sepolia.blockscout.com/address/0x3beccf56c87ee913e0c9e271b03daaf9fc4dcdea) |
| **Convexo_Vaults** | `0x29a5a2d316c70d9ab55dd9750ee543016cd0de08` | [View](https://unichain-sepolia.blockscout.com/address/0x29a5a2d316c70d9ab55dd9750ee543016cd0de08) |
| **Convexo_Passport** | `0xa5eeefc180999981aa356d1cbedbff6f91f6ca7e` | [View](https://unichain-sepolia.blockscout.com/address/0xa5eeefc180999981aa356d1cbedbff6f91f6ca7e) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x4882fd7ba2441410684c447ff6e24f0f5a7f9874` | [View](https://unichain-sepolia.blockscout.com/address/0x4882fd7ba2441410684c447ff6e24f0f5a7f9874) |
| **CompliantLPHook** | `0x0b788fbc303f9b62b9012a3e551aedd7f7ede9e4` | [View](https://unichain-sepolia.blockscout.com/address/0x0b788fbc303f9b62b9012a3e551aedd7f7ede9e4) |
| **PoolRegistry** | `0x3d8e5f30c83e1f5decac6c70bc3d1782043b2628` | [View](https://unichain-sepolia.blockscout.com/address/0x3d8e5f30c83e1f5decac6c70bc3d1782043b2628) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xaf5a98aa5208a2bb19ba91f75f10a76358d911a0` | [View](https://unichain-sepolia.blockscout.com/address/0xaf5a98aa5208a2bb19ba91f75f10a76358d911a0) |
| **PriceFeedManager** | `0xa0eff2c7e0569fcb9c70131d7abc25b33a8689e7` | [View](https://unichain-sepolia.blockscout.com/address/0xa0eff2c7e0569fcb9c70131d7abc25b33a8689e7) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xdb2a87f9b7b40eb279007fd7eb23bd2bfa74ed33` | [View](https://unichain-sepolia.blockscout.com/address/0xdb2a87f9b7b40eb279007fd7eb23bd2bfa74ed33) |
| **VaultFactory** | `0xd05df511dbe7d793d82b7344a955f15485ff0787` | [View](https://unichain-sepolia.blockscout.com/address/0xd05df511dbe7d793d82b7344a955f15485ff0787) |

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
    convexoLPs: "0x3beccf56c87ee913e0c9e271b03daaf9fc4dcdea",
    convexoVaults: "0x29a5a2d316c70d9ab55dd9750ee543016cd0de08",
    convexoPassport: "0xa5eeefc180999981aa356d1cbedbff6f91f6ca7e",
    hookDeployer: "0x4882fd7ba2441410684c447ff6e24f0f5a7f9874",
    compliantLPHook: "0x0b788fbc303f9b62b9012a3e551aedd7f7ede9e4",
    poolRegistry: "0x3d8e5f30c83e1f5decac6c70bc3d1782043b2628",
    reputationManager: "0xaf5a98aa5208a2bb19ba91f75f10a76358d911a0",
    priceFeedManager: "0xa0eff2c7e0569fcb9c70131d7abc25b33a8689e7",
    contractSigner: "0xdb2a87f9b7b40eb279007fd7eb23bd2bfa74ed33",
    vaultFactory: "0xd05df511dbe7d793d82b7344a955f15485ff0787"
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

## 💡 Unichain Benefits

### Why Unichain?
- **Uniswap native**: Built by Uniswap team for optimal DEX performance
- **Ultra-low gas**: Cheapest network for DeFi operations
- **Instant finality**: Fast transaction confirmations
- **MEV protection**: Built-in MEV resistance for fair trading

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 10 Contracts |
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
- Solidity: 0.8.30
- Optimizer: Enabled (200 runs)
- EVM Version: Prague
- Via IR: Enabled

### Verification Status
✅ All contracts verified on Blockscout (Both networks)

---

*Last updated: December 26, 2025*

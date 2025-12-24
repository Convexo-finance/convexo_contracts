# 🦄 Unichain Deployments

Complete deployment guide for all Unichain networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Unichain Mainnet** | 130 | ✅ Complete | 9/9 | [Blockscout](https://unichain.blockscout.com) |
| **Unichain Sepolia** | 1301 | ✅ Complete | 9/9 | [Blockscout](https://unichain-sepolia.blockscout.com) |

---

# 🚀 Unichain Mainnet

## Network Information
- **Chain ID**: 130
- **Network Name**: Unichain Mainnet
- **RPC URL**: Configure via `.env`
- **Block Explorer**: https://unichain.blockscout.com
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 9 contracts deployed and verified**  
**Date**: December 24, 2024  
**Total Gas Paid**: 0.000000046931112488 ETH  
**Block Range**: 35816776-35816778  
**Average Gas Price**: 0.000003867 gwei

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xbc4023284D789D7EB8512c1EDe245C77591a5D96` | [View](https://unichain.blockscout.com/address/0xbc4023284D789D7EB8512c1EDe245C77591a5D96) |
| **Convexo_Vaults** | `0xC058588A8D82B2E2129119B209c80af8bF3d4961` | [View](https://unichain.blockscout.com/address/0xC058588A8D82B2E2129119B209c80af8bF3d4961) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x7356bf8000dE3CA7518a363b954D67cc54F7c84d` | [View](https://unichain.blockscout.com/address/0x7356bf8000dE3CA7518a363b954D67cc54F7c84d) |
| **CompliantLPHook** | `0x282a52f7607Ef04415c6567d18f1BF9acD043f42` | [View](https://unichain.blockscout.com/address/0x282a52f7607Ef04415c6567d18f1BF9acD043f42) |
| **PoolRegistry** | `0x292EF88A7199916899fC296Ff6b522306FA2B19a` | [View](https://unichain.blockscout.com/address/0x292EF88A7199916899fC296Ff6b522306FA2B19a) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x4DbCCff8730398a35D517ab8A1E8413A45d686C4` | [View](https://unichain.blockscout.com/address/0x4DbCCff8730398a35D517ab8A1E8413A45d686C4) |
| **PriceFeedManager** | `0xbB13194B2792E291109402369cb4Fc0358aed132` | [View](https://unichain.blockscout.com/address/0xbB13194B2792E291109402369cb4Fc0358aed132) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xec02A78F2e6Db438EB9b75aA173AC0F0D1D3126A` | [View](https://unichain.blockscout.com/address/0xec02A78F2e6Db438EB9b75aA173AC0F0D1D3126A) |
| **VaultFactory** | `0xC98BCE4617f9708dD1363F21177Be5Ef21fB4993` | [View](https://unichain.blockscout.com/address/0xC98BCE4617f9708dD1363F21177Be5Ef21fB4993) |

## Network Dependencies

### Uniswap V4 PoolManager
- **Address**: `0x1F98400000000000000000000000000000000004`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0x078D782b760474a361dDA0AF3839290b0EF57AD6`
- **Purpose**: Stablecoin used in VaultFactory for vault operations

## Frontend Integration (Mainnet)

```javascript
const UNICHAIN_MAINNET_CONFIG = {
  chainId: 130,
  name: "Unichain Mainnet",
  contracts: {
    convexoLPs: "0xbc4023284D789D7EB8512c1EDe245C77591a5D96",
    convexoVaults: "0xC058588A8D82B2E2129119B209c80af8bF3d4961",
    hookDeployer: "0x7356bf8000dE3CA7518a363b954D67cc54F7c84d",
    compliantLPHook: "0x282a52f7607Ef04415c6567d18f1BF9acD043f42",
    poolRegistry: "0x292EF88A7199916899fC296Ff6b522306FA2B19a",
    reputationManager: "0x4DbCCff8730398a35D517ab8A1E8413A45d686C4",
    priceFeedManager: "0xbB13194B2792E291109402369cb4Fc0358aed132",
    contractSigner: "0xec02A78F2e6Db438EB9b75aA173AC0F0D1D3126A",
    vaultFactory: "0xC98BCE4617f9708dD1363F21177Be5Ef21fB4993"
  },
  usdc: "0x078D782b760474a361dDA0AF3839290b0EF57AD6",
  poolManager: "0x1F98400000000000000000000000000000000004"
};
```

---

# 🧪 Unichain Sepolia Testnet

## Network Information
- **Chain ID**: 1301
- **Network Name**: Unichain Sepolia
- **Block Explorer**: https://unichain-sepolia.blockscout.com
- **Currency**: ETH (Testnet)

## Deployment Summary
**Status**: ✅ Complete - All 9 contracts deployed and verified  
**Date**: December 2, 2025  
**Version**: 2.2

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x6ba429488cad3795af1ec65d80be760b70f58e4b` | [View](https://unichain-sepolia.blockscout.com/address/0x6ba429488cad3795af1ec65d80be760b70f58e4b) |
| **Convexo_Vaults** | `0x64fd5631ffe78e907da7b48542abfb402680891a` | [View](https://unichain-sepolia.blockscout.com/address/0x64fd5631ffe78e907da7b48542abfb402680891a) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x1917aac9c182454b3ab80aa8703734d2831adf08` | [View](https://unichain-sepolia.blockscout.com/address/0x1917aac9c182454b3ab80aa8703734d2831adf08) |
| **CompliantLPHook** | `0x3933f0018fc7d21756b86557640d66b97f514bae` | [View](https://unichain-sepolia.blockscout.com/address/0x3933f0018fc7d21756b86557640d66b97f514bae) |
| **PoolRegistry** | `0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02` | [View](https://unichain-sepolia.blockscout.com/address/0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x7c22db98a3f8da11f8c79d60a78d12df4a18516b` | [View](https://unichain-sepolia.blockscout.com/address/0x7c22db98a3f8da11f8c79d60a78d12df4a18516b) |
| **PriceFeedManager** | `0x8b346a47413991077f6ad38bfa4bfd3693187e6e` | [View](https://unichain-sepolia.blockscout.com/address/0x8b346a47413991077f6ad38bfa4bfd3693187e6e) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8` | [View](https://unichain-sepolia.blockscout.com/address/0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8) |
| **VaultFactory** | `0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841` | [View](https://unichain-sepolia.blockscout.com/address/0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841) |

## Network Dependencies (Sepolia)

- **USDC**: `0x31d0220469e10c4E71834a79b1f276d740d3768F`
- **ECOP Token**: `0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260`
- **PoolManager**: `0x00B036B58a818B1BC34d502D3fE730Db729e62AC`

## Frontend Integration (Sepolia)

```javascript
const UNICHAIN_SEPOLIA_CONFIG = {
  chainId: 1301,
  name: "Unichain Sepolia",
  contracts: {
    convexoLPs: "0x6ba429488cad3795af1ec65d80be760b70f58e4b",
    convexoVaults: "0x64fd5631ffe78e907da7b48542abfb402680891a",
    hookDeployer: "0x1917aac9c182454b3ab80aa8703734d2831adf08",
    compliantLPHook: "0x3933f0018fc7d21756b86557640d66b97f514bae",
    poolRegistry: "0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02",
    reputationManager: "0x7c22db98a3f8da11f8c79d60a78d12df4a18516b",
    priceFeedManager: "0x8b346a47413991077f6ad38bfa4bfd3693187e6e",
    contractSigner: "0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8",
    vaultFactory: "0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841"
  },
  usdc: "0x31d0220469e10c4E71834a79b1f276d740d3768F",
  ecop: "0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260",
  poolManager: "0x00B036B58a818B1BC34d502D3fE730Db729e62AC"
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
- **Ultra-low gas costs**: ~12,600x cheaper than Ethereum
- **Fast confirmations**: Sub-second block times
- **Native Uniswap integration**: Built for DeFi
- **EVM compatible**: Same tooling as Ethereum

### Gas Cost Comparison
| Network | Average Gas Price | Cost for 9 Contracts |
|---------|------------------|---------------------|
| Ethereum Mainnet | ~50 gwei | ~0.0008 ETH |
| Base Mainnet | ~0.0009 gwei | ~0.000011 ETH |
| **Unichain Mainnet** | **~0.000004 gwei** | **~0.000000047 ETH** |

**Unichain is the most cost-effective network for Convexo Protocol!**

---

## 📚 Additional Resources

### Documentation
- [Contract Reference](./CONTRACTS_REFERENCE.md)
- [Security Audit](./SECURITY_AUDIT.md)
- [Frontend Integration Guide](./FRONTEND_INTEGRATION.md)

### Unichain Resources
- [Unichain Documentation](https://docs.unichain.org)
- [Block Explorer](https://unichain.blockscout.com)
- [Unichain Bridge](https://bridge.unichain.org)

---

## 🛠️ Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Unichain Mainnet
UNICHAIN_MAINNET_RPC_URL=https://sepolia.unichain.org
POOL_MANAGER_ADDRESS_UNIMAINNET=0x1F98400000000000000000000000000000000004
USDC_ADDRESS_UNIMAINNET=0x078D782b760474a361dDA0AF3839290b0EF57AD6

# Unichain Sepolia
UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.unichain.org
POOL_MANAGER_ADDRESS_UNISEPOLIA=0x00B036B58a818B1BC34d502D3fE730Db729e62AC
USDC_ADDRESS_UNISEPOLIA=0x31d0220469e10c4E71834a79b1f276d740d3768F
ECOP_ADDRESS_UNISEPOLIA=0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260
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

*Last updated: December 24, 2025*


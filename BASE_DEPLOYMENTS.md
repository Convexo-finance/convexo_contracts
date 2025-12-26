# 🔵 Base Deployments

Complete deployment guide for all Base networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Base Mainnet** | 8453 | ✅ Complete | 10/10 | [Basescan](https://basescan.org) |
| **Base Sepolia** | 84532 | ✅ Complete | 10/10 | [Basescan](https://sepolia.basescan.org) |

---

# 🚀 Base Mainnet

## Network Information
- **Chain ID**: 8453
- **Network Name**: Base Mainnet
- **RPC URL**: https://mainnet.base.org
- **Block Explorer**: https://basescan.org
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 10 contracts deployed and verified**  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935` | [View on Basescan](https://basescan.org/address/0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935) |
| **Convexo_Vaults** | `0x3770bb3bbeb0102a36f51aa253e69034058e4f84` | [View on Basescan](https://basescan.org/address/0x3770bb3bbeb0102a36f51aa253e69034058e4f84) |
| **Convexo_Passport** | `0x2fa95f79ce8c5c01581f6792acc4181282aaefb0` | [View on Basescan](https://basescan.org/address/0x2fa95f79ce8c5c01581f6792acc4181282aaefb0) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xf8dce148ab008f7ae47a26377252673438801712` | [View on Basescan](https://basescan.org/address/0xf8dce148ab008f7ae47a26377252673438801712) |
| **CompliantLPHook** | `0x3d684ac58f25a95c107565bcffffb219b00557c7` | [View on Basescan](https://basescan.org/address/0x3d684ac58f25a95c107565bcffffb219b00557c7) |
| **PoolRegistry** | `0x8b99bfaae6e24251017eed64536ac7df6f155c96` | [View on Basescan](https://basescan.org/address/0x8b99bfaae6e24251017eed64536ac7df6f155c96) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x6441431e6658ef7aab95f2125055ea6f0c42b06e` | [View on Basescan](https://basescan.org/address/0x6441431e6658ef7aab95f2125055ea6f0c42b06e) |
| **PriceFeedManager** | `0x4995b505d90d59e1688a24705698953f0c460c4d` | [View on Basescan](https://basescan.org/address/0x4995b505d90d59e1688a24705698953f0c460c4d) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x1ad4c60a50d184f16fe3cdab2a80d5fdbee405e2` | [View on Basescan](https://basescan.org/address/0x1ad4c60a50d184f16fe3cdab2a80d5fdbee405e2) |
| **VaultFactory** | `0x7fd91438eacffe828f61737d64926ee44cf6695c` | [View on Basescan](https://basescan.org/address/0x7fd91438eacffe828f61737d64926ee44cf6695c) |

## Network Dependencies

### Uniswap V4 PoolManager
- **Address**: `0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- **Purpose**: Native USDC on Base - stablecoin used in VaultFactory

### ZKPassport Verifier
- **Address**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`
- **Purpose**: Official ZKPassport verifier for identity verification

## Frontend Integration (Mainnet)

```javascript
const BASE_MAINNET_CONFIG = {
  chainId: 8453,
  name: "Base Mainnet",
  contracts: {
    convexoLPs: "0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935",
    convexoVaults: "0x3770bb3bbeb0102a36f51aa253e69034058e4f84",
    convexoPassport: "0x2fa95f79ce8c5c01581f6792acc4181282aaefb0",
    hookDeployer: "0xf8dce148ab008f7ae47a26377252673438801712",
    compliantLPHook: "0x3d684ac58f25a95c107565bcffffb219b00557c7",
    poolRegistry: "0x8b99bfaae6e24251017eed64536ac7df6f155c96",
    reputationManager: "0x6441431e6658ef7aab95f2125055ea6f0c42b06e",
    priceFeedManager: "0x4995b505d90d59e1688a24705698953f0c460c4d",
    contractSigner: "0x1ad4c60a50d184f16fe3cdab2a80d5fdbee405e2",
    vaultFactory: "0x7fd91438eacffe828f61737d64926ee44cf6695c"
  },
  usdc: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  poolManager: "0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

# 🧪 Base Sepolia Testnet

## Network Information
- **Chain ID**: 84532
- **Network Name**: Base Sepolia
- **RPC URL**: https://sepolia.base.org
- **Block Explorer**: https://sepolia.basescan.org
- **Currency**: ETH (Testnet)

## Deployment Summary
**Status**: ✅ Complete - All 10 contracts deployed and verified  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x45723f029ed2bd61c5a34ba17eed92219e867513` | [View](https://sepolia.basescan.org/address/0x45723f029ed2bd61c5a34ba17eed92219e867513) |
| **Convexo_Vaults** | `0x15a2bde93252ab0bbca9eefeb83f1e489f6ac770` | [View](https://sepolia.basescan.org/address/0x15a2bde93252ab0bbca9eefeb83f1e489f6ac770) |
| **Convexo_Passport** | `0xaaf4c852636731005a3d194c3f543a70d9bbcce4` | [View](https://sepolia.basescan.org/address/0xaaf4c852636731005a3d194c3f543a70d9bbcce4) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xb35a6c66aa8f9fb3abd5f85158b98961d07e39d3` | [View](https://sepolia.basescan.org/address/0xb35a6c66aa8f9fb3abd5f85158b98961d07e39d3) |
| **CompliantLPHook** | `0xbceeb5aef8905671846ffd187e482a729b5587de` | [View](https://sepolia.basescan.org/address/0xbceeb5aef8905671846ffd187e482a729b5587de) |
| **PoolRegistry** | `0x3e192a3c3834fbdaef437efef005dadd1f04d8db` | [View](https://sepolia.basescan.org/address/0x3e192a3c3834fbdaef437efef005dadd1f04d8db) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x17fb3ef8ddcd1b1afe64665fed589e8b56a1085f` | [View](https://sepolia.basescan.org/address/0x17fb3ef8ddcd1b1afe64665fed589e8b56a1085f) |
| **PriceFeedManager** | `0x8a28297cb1a778010a571f20d0a5df4450a061c0` | [View](https://sepolia.basescan.org/address/0x8a28297cb1a778010a571f20d0a5df4450a061c0) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x9b300ebf48b9fbf6a1489ae663194d62f2b35525` | [View](https://sepolia.basescan.org/address/0x9b300ebf48b9fbf6a1489ae663194d62f2b35525) |
| **VaultFactory** | `0x87982c6485452efea111b0babb212a604635c94d` | [View](https://sepolia.basescan.org/address/0x87982c6485452efea111b0babb212a604635c94d) |

## Network Dependencies (Sepolia)

- **USDC**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **ECOP Token**: `0xb934dcb57fb0673b7bc0fca590c5508f1cde955d`
- **PoolManager**: `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408`
- **ZKPassport Verifier**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`

## Frontend Integration (Sepolia)

```javascript
const BASE_SEPOLIA_CONFIG = {
  chainId: 84532,
  name: "Base Sepolia",
  contracts: {
    convexoLPs: "0x45723f029ed2bd61c5a34ba17eed92219e867513",
    convexoVaults: "0x15a2bde93252ab0bbca9eefeb83f1e489f6ac770",
    convexoPassport: "0xaaf4c852636731005a3d194c3f543a70d9bbcce4",
    hookDeployer: "0xb35a6c66aa8f9fb3abd5f85158b98961d07e39d3",
    compliantLPHook: "0xbceeb5aef8905671846ffd187e482a729b5587de",
    poolRegistry: "0x3e192a3c3834fbdaef437efef005dadd1f04d8db",
    reputationManager: "0x17fb3ef8ddcd1b1afe64665fed589e8b56a1085f",
    priceFeedManager: "0x8a28297cb1a778010a571f20d0a5df4450a061c0",
    contractSigner: "0x9b300ebf48b9fbf6a1489ae663194d62f2b35525",
    vaultFactory: "0x87982c6485452efea111b0babb212a604635c94d"
  },
  usdc: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
  ecop: "0xb934dcb57fb0673b7bc0fca590c5508f1cde955d",
  poolManager: "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

## 🔧 Deployment Scripts

### Deploy to Base Mainnet
```bash
./scripts/deploy_base_mainnet.sh
```

### Deploy to Base Sepolia
```bash
./scripts/deploy_base_sepolia.sh
```

---

## 💡 Base Benefits

### Why Base?
- **Low-cost L2**: Built on Optimism stack
- **Ethereum security**: Inherits Ethereum's security
- **Coinbase integration**: Easy fiat on/off ramps
- **Growing ecosystem**: Strong developer community

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 10 Contracts |
|---------|------------------|---------------------------|
| Ethereum Mainnet | ~50 gwei | ~0.0008 ETH |
| **Base Mainnet** | **~0.0009 gwei** | **~0.000011 ETH** |
| Unichain Mainnet | ~0.000004 gwei | ~0.000000047 ETH |

**Base is 72x cheaper than Ethereum!**

---

## 📚 Additional Resources

### Documentation
- [Contract Reference](./CONTRACTS_REFERENCE.md)
- [Security Audit](./SECURITY_AUDIT.md)
- [Frontend Integration Guide](./FRONTEND_INTEGRATION.md)
- [ZKPassport Integration](./ZKPASSPORT_FRONTEND_INTEGRATION.md)

### Base Resources
- [Base Documentation](https://docs.base.org)
- [Base Bridge](https://bridge.base.org)
- [Basescan Explorer](https://basescan.org)

---

## 🛠️ Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Base Mainnet
BASE_MAINNET_RPC_URL=https://mainnet.base.org
POOL_MANAGER_ADDRESS_BASEMAINNET=0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829
USDC_ADDRESS_BASEMAINNET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
BASESCAN_API_KEY=your_basescan_api_key

# Base Sepolia
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
POOL_MANAGER_ADDRESS_BASESEPOLIA=0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
USDC_ADDRESS_BASESEPOLIA=0x036CbD53842c5426634e7929541eC2318f3dCF7e
ECOP_ADDRESS_BASESEPOLIA=0xb934dcb57fb0673b7bc0fca590c5508f1cde955d
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
✅ All contracts verified on Basescan (Both networks)

---

*Last updated: December 26, 2025*

# 🔵 Base Deployments

Complete deployment guide for all Base networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Base Mainnet** | 8453 | ✅ Complete | 12/12 | [Basescan](https://basescan.org) |
| **Base Sepolia** | 84532 | ✅ Complete | 12/12 | [Basescan](https://sepolia.basescan.org) |

---

# 🚀 Base Mainnet

## Network Information
- **Chain ID**: 8453
- **Network Name**: Base Mainnet
- **RPC URL**: https://mainnet.base.org
- **Block Explorer**: https://basescan.org
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 12 contracts deployed and verified**  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841` | [View on Basescan](https://basescan.org/address/0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841) |
| **Convexo_Vaults** | `0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71` | [View on Basescan](https://basescan.org/address/0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71) |
| **Convexo_Passport** | `0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710` | [View on Basescan](https://basescan.org/address/0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96` | [View on Basescan](https://basescan.org/address/0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96) |
| **CompliantLPHook** | `0x805b733cc50818dabede4847c4a775a7b1610f96` | [View on Basescan](https://basescan.org/address/0x805b733cc50818dabede4847c4a775a7b1610f96) |
| **PoolRegistry** | `0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76` | [View on Basescan](https://basescan.org/address/0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xfb0157e0f904bfa464d09235a723fc2c462d1e76` | [View on Basescan](https://basescan.org/address/0xfb0157e0f904bfa464d09235a723fc2c462d1e76) |
| **PriceFeedManager** | `0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194` | [View on Basescan](https://basescan.org/address/0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8` | [View on Basescan](https://basescan.org/address/0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8) |
| **VaultFactory** | `0xb2785f4341b5bf26be07f7e2037550769ce830cd` | [View on Basescan](https://basescan.org/address/0xb2785f4341b5bf26be07f7e2037550769ce830cd) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0x3738d60fcb27d719fdd5113b855e1158b93a95b1` | [View on Basescan](https://basescan.org/address/0x3738d60fcb27d719fdd5113b855e1158b93a95b1) |
| **VeriffVerifier** | `0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff` | [View on Basescan](https://basescan.org/address/0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff) |

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
    convexoLPs: "0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841",
    convexoVaults: "0xfe381737efb123a24dc41b0e3eeffc0ccb5eee71",
    convexoPassport: "0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710",
    hookDeployer: "0xa03e2718e0ade2d07bfd9ea5705af9a83bb2db96",
    compliantLPHook: "0x805b733cc50818dabede4847c4a775a7b1610f96",
    poolRegistry: "0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76",
    reputationManager: "0xfb0157e0f904bfa464d09235a723fc2c462d1e76",
    priceFeedManager: "0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194",
    contractSigner: "0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8",
    vaultFactory: "0xb2785f4341b5bf26be07f7e2037550769ce830cd",
    treasuryFactory: "0x3738d60fcb27d719fdd5113b855e1158b93a95b1",
    veriffVerifier: "0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff"
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
**Status**: ✅ Complete - All 12 contracts deployed and verified  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xf048da86da99a76856c02a83fb53e72277acacdf` | [View](https://sepolia.basescan.org/address/0xf048da86da99a76856c02a83fb53e72277acacdf) |
| **Convexo_Vaults** | `0xe9309e75f168b5c98c37a5465e539a0fdbf33eb9` | [View](https://sepolia.basescan.org/address/0xe9309e75f168b5c98c37a5465e539a0fdbf33eb9) |
| **Convexo_Passport** | `0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c` | [View](https://sepolia.basescan.org/address/0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x26379c326108d66734d9265dbbf1c09b20dbd2b9` | [View](https://sepolia.basescan.org/address/0x26379c326108d66734d9265dbbf1c09b20dbd2b9) |
| **CompliantLPHook** | `0x058faa5e95b3deb41e6ecabe4dd870b8e3d90475` | [View](https://sepolia.basescan.org/address/0x058faa5e95b3deb41e6ecabe4dd870b8e3d90475) |
| **PoolRegistry** | `0x6ad2b7bd52d6382bc7ba37687be5533eb2cf4cd2` | [View](https://sepolia.basescan.org/address/0x6ad2b7bd52d6382bc7ba37687be5533eb2cf4cd2) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xc8d1160e2e7719e29b34ab36402aaa0ec24d8c01` | [View](https://sepolia.basescan.org/address/0xc8d1160e2e7719e29b34ab36402aaa0ec24d8c01) |
| **PriceFeedManager** | `0x653bcfc6ea735fb67d73ff537746b804c75cd1f4` | [View](https://sepolia.basescan.org/address/0x653bcfc6ea735fb67d73ff537746b804c75cd1f4) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x437e0a14a515fa5dc5655a11856fe28c7bb78477` | [View](https://sepolia.basescan.org/address/0x437e0a14a515fa5dc5655a11856fe28c7bb78477) |
| **VaultFactory** | `0xb987dd28a350d0d88765ac7310c0895b76fa0828` | [View](https://sepolia.basescan.org/address/0xb987dd28a350d0d88765ac7310c0895b76fa0828) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0x68ec89e0884d05d3b4d2f9b27e4212820b1a56e5` | [View](https://sepolia.basescan.org/address/0x68ec89e0884d05d3b4d2f9b27e4212820b1a56e5) |
| **VeriffVerifier** | `0x6f7413e36ffed4bde41b4521cf240aef0668201f` | [View](https://sepolia.basescan.org/address/0x6f7413e36ffed4bde41b4521cf240aef0668201f) |

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
    convexoLPs: "0xf048da86da99a76856c02a83fb53e72277acacdf",
    convexoVaults: "0xe9309e75f168b5c98c37a5465e539a0fdbf33eb9",
    convexoPassport: "0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c",
    hookDeployer: "0x26379c326108d66734d9265dbbf1c09b20dbd2b9",
    compliantLPHook: "0x058faa5e95b3deb41e6ecabe4dd870b8e3d90475",
    poolRegistry: "0x6ad2b7bd52d6382bc7ba37687be5533eb2cf4cd2",
    reputationManager: "0xc8d1160e2e7719e29b34ab36402aaa0ec24d8c01",
    priceFeedManager: "0x653bcfc6ea735fb67d73ff537746b804c75cd1f4",
    contractSigner: "0x437e0a14a515fa5dc5655a11856fe28c7bb78477",
    vaultFactory: "0xb987dd28a350d0d88765ac7310c0895b76fa0828",
    treasuryFactory: "0x68ec89e0884d05d3b4d2f9b27e4212820b1a56e5",
    veriffVerifier: "0x6f7413e36ffed4bde41b4521cf240aef0668201f"
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

## 🏆 Tier System (v2.1)

| Tier | NFT | User Type | Access |
|------|-----|-----------|--------|
| **Tier 0** | None | Unverified | No access |
| **Tier 1** | Convexo_Passport | Individual | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | Limited Partner | LP pools + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault Creator | All above + Vault creation |

---

## 💡 Base Benefits

### Why Base?
- **Low-cost L2**: Built on Optimism stack
- **Ethereum security**: Inherits Ethereum's security
- **Coinbase integration**: Easy fiat on/off ramps
- **Growing ecosystem**: Strong developer community

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 12 Contracts |
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
- Solidity: 0.8.27
- Optimizer: Enabled (200 runs)
- EVM Version: Prague
- Via IR: Enabled

### Verification Status
✅ All 12 contracts verified on Basescan (Both networks)

---

*Last updated: January 7, 2026 - v2.1*

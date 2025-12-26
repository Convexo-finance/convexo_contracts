# 🔵 Base Deployments

Complete deployment guide for all Base networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Base Mainnet** | 8453 | ✅ Complete | 9/9 (v2.2) | [Basescan](https://basescan.org) |
| **Base Sepolia** | 84532 | ✅ Complete | 10/10 (v2.0) | [Basescan](https://sepolia.basescan.org) |

---

# 🚀 Base Mainnet

## Network Information
- **Chain ID**: 8453
- **Network Name**: Base Mainnet
- **RPC URL**: https://mainnet.base.org
- **Block Explorer**: https://basescan.org
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 9 contracts deployed and verified**  
**Date**: December 24, 2024  
**Total Gas Paid**: 0.000011372772322454 ETH  
**Block Range**: 39887479-39887480  
**Average Gas Price**: 0.000937364 gwei

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x282a52f7607ef04415c6567d18f1bf9acd043f42` | [View on Basescan](https://basescan.org/address/0x282a52f7607ef04415c6567d18f1bf9acd043f42) |
| **Convexo_Vaults** | `0x292ef88a7199916899fc296ff6b522306fa2b19a` | [View on Basescan](https://basescan.org/address/0x292ef88a7199916899fc296ff6b522306fa2b19a) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x4dbccff8730398a35d517ab8a1e8413a45d686c4` | [View on Basescan](https://basescan.org/address/0x4dbccff8730398a35d517ab8a1e8413a45d686c4) |
| **CompliantLPHook** | `0xbb13194b2792e291109402369cb4fc0358aed132` | [View on Basescan](https://basescan.org/address/0xbb13194b2792e291109402369cb4fc0358aed132) |
| **PoolRegistry** | `0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a` | [View on Basescan](https://basescan.org/address/0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xc98bce4617f9708dd1363f21177be5ef21fb4993` | [View on Basescan](https://basescan.org/address/0xc98bce4617f9708dd1363f21177be5ef21fb4993) |
| **PriceFeedManager** | `0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7` | [View on Basescan](https://basescan.org/address/0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x5a1f415986a189d79d19d65cb6e3d6dd7b807268` | [View on Basescan](https://basescan.org/address/0x5a1f415986a189d79d19d65cb6e3d6dd7b807268) |
| **VaultFactory** | `0x6b51adc34a503b23db99444048ac7c2dc735a12e` | [View on Basescan](https://basescan.org/address/0x6b51adc34a503b23db99444048ac7c2dc735a12e) |

## Network Dependencies

### Uniswap V4 PoolManager
- **Address**: `0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- **Purpose**: Native USDC on Base - stablecoin used in VaultFactory

## Gas Statistics (Mainnet)

### Transaction Hashes
- Convexo_LPs: `0x234745363890799f95fc88cbc1ca557d3a31a9ae6b39443e1cd0db0a1ce699a5`
- Convexo_Vaults: `0x57eb0514e06c466957228320290bc52ede2ae877b49236eedc309049468b8ced`
- HookDeployer: `0x14f41e3239152ec6933a12dd47c78c1da3dde468097440e39141c4e915b68985`
- CompliantLPHook: `0x58e01440e2cbc83a207b47abcec30bb65ca6302c6f0c6687c48184c68fc7a5e9`
- PoolRegistry: `0x48a71ff080721a1fd72dc8780fe10ecae25aaf7bfedb9bfec01ea92cbf7947fe`
- ReputationManager: `0x7692ca5c568ffbfad533dfa67da00d50e796c618d0f9edba5cc988e453bf9071`
- PriceFeedManager: `0x04c3659c41634a8c65e59f2f71096d6fc3abf133a68920cb3fc04c5f99c1351e`
- ContractSigner: `0x6c35abb96a0244cdb12d4e404aac524ce6c86c79eb09ea4502cf2977b8f56bab`
- VaultFactory: `0xbf7efc90ba86c36dc928728d88d164f1af42e3c960b2f859b4dd22e75cad0e67`

### Gas Usage per Contract
| Contract | Gas Used | ETH Paid |
|----------|----------|----------|
| Convexo_LPs | 1,282,406 | 0.000001205828408116 |
| Convexo_Vaults | 1,282,502 | 0.000001205918675572 |
| HookDeployer | 876,729 | 0.000000824376004494 |
| CompliantLPHook | 569,040 | 0.00000053256681216 |
| PoolRegistry | 1,067,485 | 0.00000099906348144 |
| ReputationManager | 571,766 | 0.000000535118086464 |
| PriceFeedManager | 992,789 | 0.000000929155196256 |
| ContractSigner | 1,732,371 | 0.000001621332948384 |
| VaultFactory | 3,760,442 | 0.000003519412709568 |
| **Total** | **12,135,530** | **0.000011372772322454** |

## Frontend Integration (Mainnet)

```javascript
const BASE_MAINNET_CONFIG = {
  chainId: 8453,
  name: "Base Mainnet",
  contracts: {
    convexoLPs: "0x282a52f7607ef04415c6567d18f1bf9acd043f42",
    convexoVaults: "0x292ef88a7199916899fc296ff6b522306fa2b19a",
    hookDeployer: "0x4dbccff8730398a35d517ab8a1e8413a45d686c4",
    compliantLPHook: "0xbb13194b2792e291109402369cb4fc0358aed132",
    poolRegistry: "0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a",
    reputationManager: "0xc98bce4617f9708dd1363f21177be5ef21fb4993",
    priceFeedManager: "0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7",
    contractSigner: "0x5a1f415986a189d79d19d65cb6e3d6dd7b807268",
    vaultFactory: "0x6b51adc34a503b23db99444048ac7c2dc735a12e"
  },
  usdc: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  poolManager: "0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829"
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
**Date**: December 26, 2024  
**Version**: 2.0 (with ZKPassport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x90caec19973DB5c39373d1f3072a7ED096aBAD84` | [View](https://sepolia.basescan.org/address/0x90caec19973DB5c39373d1f3072a7ED096aBAD84) |
| **Convexo_Vaults** | `0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE` | [View](https://sepolia.basescan.org/address/0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE) |
| **Convexo_Passport** | `0x4A164470586B7e80eEf2734d24f5F784e4f88ad0` | [View](https://sepolia.basescan.org/address/0x4A164470586B7e80eEf2734d24f5F784e4f88ad0) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB` | [View](https://sepolia.basescan.org/address/0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB) |
| **CompliantLPHook** | `0x331C35ba44FE83183eEd913D647F4f18E9BCf785` | [View](https://sepolia.basescan.org/address/0x331C35ba44FE83183eEd913D647F4f18E9BCf785) |
| **PoolRegistry** | `0xA59C12e996C7224B925A98C35c6dd82464CA1e0d` | [View](https://sepolia.basescan.org/address/0xA59C12e996C7224B925A98C35c6dd82464CA1e0d) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x340Fd03C88297A5B0caFD5877FC1faecEffaf159` | [View](https://sepolia.basescan.org/address/0x340Fd03C88297A5B0caFD5877FC1faecEffaf159) |
| **PriceFeedManager** | `0xD6cfde6525703b625ba1acB5645e2584eb7a702f` | [View](https://sepolia.basescan.org/address/0xD6cfde6525703b625ba1acB5645e2584eb7a702f) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5` | [View](https://sepolia.basescan.org/address/0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5) |
| **VaultFactory** | `0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139` | [View](https://sepolia.basescan.org/address/0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139) |

## Network Dependencies (Sepolia)

- **USDC**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **ECOP Token**: `0xb934dcb57fb0673b7bc0fca590c5508f1cde955d`
- **PoolManager**: `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408`

## Frontend Integration (Sepolia)

```javascript
const BASE_SEPOLIA_CONFIG = {
  chainId: 84532,
  name: "Base Sepolia",
  contracts: {
    convexoLPs: "0x90caec19973DB5c39373d1f3072a7ED096aBAD84",
    convexoVaults: "0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE",
    convexoPassport: "0x4A164470586B7e80eEf2734d24f5F784e4f88ad0",
    hookDeployer: "0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB",
    compliantLPHook: "0x331C35ba44FE83183eEd913D647F4f18E9BCf785",
    poolRegistry: "0xA59C12e996C7224B925A98C35c6dd82464CA1e0d",
    reputationManager: "0x340Fd03C88297A5B0caFD5877FC1faecEffaf159",
    priceFeedManager: "0xD6cfde6525703b625ba1acB5645e2584eb7a702f",
    contractSigner: "0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5",
    vaultFactory: "0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139"
  },
  usdc: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
  ecop: "0xb934dcb57fb0673b7bc0fca590c5508f1cde955d",
  poolManager: "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408",
  zkpassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
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
| Network | Average Gas Price | Cost for 9 Contracts |
|---------|------------------|---------------------|
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

*Last updated: December 26, 2024*


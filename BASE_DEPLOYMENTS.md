# 🔵 Base Deployments

Complete deployment guide for all Base networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Base Mainnet** | 8453 | ✅ Complete | 9/9 | [Basescan](https://basescan.org) |
| **Base Sepolia** | 84532 | ✅ Complete | 9/9 | [Basescan](https://sepolia.basescan.org) |

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
| **Convexo_LPs** | `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5` | [View on Basescan](https://basescan.org/address/0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5) |
| **Convexo_Vaults** | `0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50` | [View on Basescan](https://basescan.org/address/0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2` | [View on Basescan](https://basescan.org/address/0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2) |
| **CompliantLPHook** | `0x87af0C8203C84192dBf07f4B6D934fD00eB3F723` | [View on Basescan](https://basescan.org/address/0x87af0C8203C84192dBf07f4B6D934fD00eB3F723) |
| **PoolRegistry** | `0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1` | [View on Basescan](https://basescan.org/address/0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xDe8daB3182426234ACf68E4197A1eDF5172450dD` | [View on Basescan](https://basescan.org/address/0xDe8daB3182426234ACf68E4197A1eDF5172450dD) |
| **PriceFeedManager** | `0xbc4023284D789D7EB8512c1EDe245C77591a5D96` | [View on Basescan](https://basescan.org/address/0xbc4023284D789D7EB8512c1EDe245C77591a5D96) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xC058588A8D82B2E2129119B209c80af8bF3d4961` | [View on Basescan](https://basescan.org/address/0xC058588A8D82B2E2129119B209c80af8bF3d4961) |
| **VaultFactory** | `0x7356bf8000dE3CA7518a363b954D67cc54F7c84d` | [View on Basescan](https://basescan.org/address/0x7356bf8000dE3CA7518a363b954D67cc54F7c84d) |

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
    convexoLPs: "0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5",
    convexoVaults: "0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50",
    hookDeployer: "0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2",
    compliantLPHook: "0x87af0C8203C84192dBf07f4B6D934fD00eB3F723",
    poolRegistry: "0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1",
    reputationManager: "0xDe8daB3182426234ACf68E4197A1eDF5172450dD",
    priceFeedManager: "0xbc4023284D789D7EB8512c1EDe245C77591a5D96",
    contractSigner: "0xC058588A8D82B2E2129119B209c80af8bF3d4961",
    vaultFactory: "0x7356bf8000dE3CA7518a363b954D67cc54F7c84d"
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
**Status**: ✅ Complete - All 9 contracts deployed and verified  
**Date**: December 2, 2025  
**Version**: 2.2

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xd05df511dbe7d793d82b7344a955f15485ff0787` | [View](https://sepolia.basescan.org/address/0xd05df511dbe7d793d82b7344a955f15485ff0787) |
| **Convexo_Vaults** | `0xfb965542aa0b58538a9b50fe020314dd687eb128` | [View](https://sepolia.basescan.org/address/0xfb965542aa0b58538a9b50fe020314dd687eb128) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x503f203ce6d6462f433cd04c7ad2b05d61b56548` | [View](https://sepolia.basescan.org/address/0x503f203ce6d6462f433cd04c7ad2b05d61b56548) |
| **CompliantLPHook** | `0xab83ce760054c1d048d5a9de5194b05398a09d41` | [View](https://sepolia.basescan.org/address/0xab83ce760054c1d048d5a9de5194b05398a09d41) |
| **PoolRegistry** | `0x18fb358bc74054b0c2530c48ef23f8a8d464cb18` | [View](https://sepolia.basescan.org/address/0x18fb358bc74054b0c2530c48ef23f8a8d464cb18) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x50ace0dce54df668477adee4e9d6a6c0df4fedee` | [View](https://sepolia.basescan.org/address/0x50ace0dce54df668477adee4e9d6a6c0df4fedee) |
| **PriceFeedManager** | `0xa46629011e0b8561a45ea03b822d28c0b2432c3a` | [View](https://sepolia.basescan.org/address/0xa46629011e0b8561a45ea03b822d28c0b2432c3a) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x62227ff7ccbdb4d72c3511290b28c3424f1500ef` | [View](https://sepolia.basescan.org/address/0x62227ff7ccbdb4d72c3511290b28c3424f1500ef) |
| **VaultFactory** | `0x8efc7e25c12a815329331da5f0e96affb4014472` | [View](https://sepolia.basescan.org/address/0x8efc7e25c12a815329331da5f0e96affb4014472) |

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
    convexoLPs: "0xd05df511dbe7d793d82b7344a955f15485ff0787",
    convexoVaults: "0xfb965542aa0b58538a9b50fe020314dd687eb128",
    hookDeployer: "0x503f203ce6d6462f433cd04c7ad2b05d61b56548",
    compliantLPHook: "0xab83ce760054c1d048d5a9de5194b05398a09d41",
    poolRegistry: "0x18fb358bc74054b0c2530c48ef23f8a8d464cb18",
    reputationManager: "0x50ace0dce54df668477adee4e9d6a6c0df4fedee",
    priceFeedManager: "0xa46629011e0b8561a45ea03b822d28c0b2432c3a",
    contractSigner: "0x62227ff7ccbdb4d72c3511290b28c3424f1500ef",
    vaultFactory: "0x8efc7e25c12a815329331da5f0e96affb4014472"
  },
  usdc: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
  ecop: "0xb934dcb57fb0673b7bc0fca590c5508f1cde955d",
  poolManager: "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
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

*Last updated: December 24, 2025*


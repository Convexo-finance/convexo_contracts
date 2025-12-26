# ⟠ Ethereum Deployments

Complete deployment guide for all Ethereum networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Mainnet** | 1 | ⏳ Pending | 0/10 | [Etherscan](https://etherscan.io) |
| **Ethereum Sepolia** | 11155111 | ✅ Complete | 10/10 (v2.0) | [Etherscan](https://sepolia.etherscan.io) |

---

# 🚀 Ethereum Mainnet

## Network Information
- **Chain ID**: 1
- **Network Name**: Ethereum Mainnet
- **RPC URL**: https://mainnet.infura.io
- **Block Explorer**: https://etherscan.io
- **Currency**: ETH

## Deployment Summary
**Status**: ⏳ **Pending Deployment**  
**Estimated Gas Cost**: ~0.00082 ETH  
**Estimated Gas Price**: ~0.05217 gwei

## Planned Contracts

All 10 contracts will be deployed once funded (v2.0 with ZKPassport):

### NFT Contracts
- Convexo_LPs
- Convexo_Vaults
- Convexo_Passport (ZKPassport integration)

### Hook System
- HookDeployer
- CompliantLPHook
- PoolRegistry

### Core Infrastructure
- ReputationManager
- PriceFeedManager

### Vault System
- ContractSigner
- VaultFactory

## Network Dependencies (Mainnet)

### Uniswap V4 PoolManager
- **Address**: `0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- **Purpose**: Official USDC on Ethereum - most liquid stablecoin

## How to Deploy

### 1. Fund Deployer Wallet
Send at least **0.001 ETH** to your deployer address to cover gas costs.

### 2. Run Deployment Script
```bash
./scripts/deploy_ethereum_mainnet.sh
```

### 3. Automatic Verification
All contracts will be automatically verified on Etherscan upon deployment.

## Frontend Integration (Mainnet) - After Deployment

```javascript
const ETHEREUM_MAINNET_CONFIG = {
  chainId: 1,
  name: "Ethereum Mainnet",
  contracts: {
    convexoLPs: "TBD",
    convexoVaults: "TBD",
    convexoPassport: "TBD",
    hookDeployer: "TBD",
    compliantLPHook: "TBD",
    poolRegistry: "TBD",
    reputationManager: "TBD",
    priceFeedManager: "TBD",
    contractSigner: "TBD",
    vaultFactory: "TBD"
  },
  usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  poolManager: "0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A",
  zkpassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

# 🧪 Ethereum Sepolia Testnet

## Network Information
- **Chain ID**: 11155111
- **Network Name**: Ethereum Sepolia
- **RPC URL**: https://sepolia.infura.io
- **Block Explorer**: https://sepolia.etherscan.io
- **Currency**: ETH (Testnet)

## Deployment Summary
**Status**: ✅ Complete - All 10 contracts deployed and verified  
**Date**: December 26, 2024  
**Version**: 2.0 (with ZKPassport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x8EFC7e25C12A815329331DA5f0e96AFfB4014472` | [View](https://sepolia.etherscan.io/address/0x8EFC7e25C12A815329331DA5f0e96AFfB4014472) |
| **Convexo_Vaults** | `0xa932e3EAa0a5e5e65f0567405207603266937618` | [View](https://sepolia.etherscan.io/address/0xa932e3EAa0a5e5e65f0567405207603266937618) |
| **Convexo_Passport** | `0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8` | [View](https://sepolia.etherscan.io/address/0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6` | [View](https://sepolia.etherscan.io/address/0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6) |
| **CompliantLPHook** | `0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776` | [View](https://sepolia.etherscan.io/address/0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776) |
| **PoolRegistry** | `0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E` | [View](https://sepolia.etherscan.io/address/0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a` | [View](https://sepolia.etherscan.io/address/0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a) |
| **PriceFeedManager** | `0x6A9af3B1da3fC07C78c37c380368773b1E830Fac` | [View](https://sepolia.etherscan.io/address/0x6A9af3B1da3fC07C78c37c380368773b1E830Fac) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985` | [View](https://sepolia.etherscan.io/address/0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985) |
| **VaultFactory** | `0x8c2D66210A43201bae2a7BF924ecA0f53364967f` | [View](https://sepolia.etherscan.io/address/0x8c2D66210A43201bae2a7BF924ecA0f53364967f) |

## Network Dependencies (Sepolia)

- **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **ECOP Token**: `0x19ac2612e560b2bbedf88660a2566ef53c0a15a1`
- **PoolManager**: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`

## Frontend Integration (Sepolia)

```javascript
const ETHEREUM_SEPOLIA_CONFIG = {
  chainId: 11155111,
  name: "Ethereum Sepolia",
  contracts: {
    convexoLPs: "0x8EFC7e25C12A815329331DA5f0e96AFfB4014472",
    convexoVaults: "0xa932e3EAa0a5e5e65f0567405207603266937618",
    convexoPassport: "0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8",
    hookDeployer: "0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6",
    compliantLPHook: "0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776",
    poolRegistry: "0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E",
    reputationManager: "0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a",
    priceFeedManager: "0x6A9af3B1da3fC07C78c37c380368773b1E830Fac",
    contractSigner: "0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985",
    vaultFactory: "0x8c2D66210A43201bae2a7BF924ecA0f53364967f"
  },
  usdc: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
  ecop: "0x19ac2612e560b2bbedf88660a2566ef53c0a15a1",
  poolManager: "0xE03A1074c86CFeDd5C142C4F04F1a1536e203543",
  zkpassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

## 🔧 Deployment Scripts

### Deploy to Ethereum Mainnet
```bash
./scripts/deploy_ethereum_mainnet.sh
```

### Deploy to Ethereum Sepolia
```bash
./scripts/deploy_ethereum_sepolia.sh
```

---

## 💡 Ethereum Benefits

### Why Ethereum?
- **Maximum security**: Most secure blockchain
- **Largest liquidity**: Deepest DeFi liquidity
- **Highest decentralization**: Most validators
- **Institutional trust**: Preferred by institutions

### Gas Cost Comparison
| Network | Average Gas Price | Cost for 9 Contracts |
|---------|------------------|---------------------|
| **Ethereum Mainnet** | **~50 gwei** | **~0.0008 ETH** |
| Base Mainnet | ~0.0009 gwei | ~0.000011 ETH |
| Unichain Mainnet | ~0.000004 gwei | ~0.000000047 ETH |

**Note**: Ethereum has the highest security but also highest gas costs. Consider using Base or Unichain for cost-sensitive operations, and Ethereum for high-value transactions requiring maximum security.

---

## 📚 Additional Resources

### Documentation
- [Contract Reference](./CONTRACTS_REFERENCE.md)
- [Security Audit](./SECURITY_AUDIT.md)
- [Frontend Integration Guide](./FRONTEND_INTEGRATION.md)

### Ethereum Resources
- [Ethereum Documentation](https://ethereum.org/developers)
- [Etherscan Explorer](https://etherscan.io)
- [Ethereum Gas Tracker](https://etherscan.io/gastracker)

---

## 🛠️ Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Ethereum Mainnet
ETHEREUM_MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
POOL_MANAGER_ADDRESS_ETHMAINNET=0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A
USDC_ADDRESS_ETHMAINNET=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
ETHERSCAN_API_KEY=your_etherscan_api_key

# Ethereum Sepolia
ETHEREUM_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
POOL_MANAGER_ADDRESS_ETHSEPOLIA=0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
USDC_ADDRESS_ETHSEPOLIA=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
ECOP_ADDRESS_ETHSEPOLIA=0x19ac2612e560b2bbedf88660a2566ef53c0a15a1
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
- **Mainnet**: Pending deployment (v2.0 with ZKPassport)
- **Sepolia**: ✅ All 10 contracts verified on Etherscan (v2.0)

### Mainnet Deployment Status

**Ready to deploy once wallet is funded!**

The deployment will:
1. ✅ Deploy all 10 contracts in correct order (including Convexo_Passport)
2. ✅ Handle all dependencies automatically
3. ✅ Verify all contracts on Etherscan
4. ✅ Save addresses to `addresses.json`
5. ✅ Generate transaction receipts

**Estimated time**: ~10-15 minutes  
**Estimated cost**: ~0.00082 ETH (~$2.50 USD at current prices)

---

## 🎯 Mainnet Deployment Checklist

Before deploying to Ethereum Mainnet:

- [ ] Confirm deployer wallet has at least 0.001 ETH
- [ ] Verify `.env` file has correct RPC URL
- [ ] Verify `.env` file has valid Etherscan API key
- [ ] Confirm PoolManager and USDC addresses are correct
- [ ] Review security audit
- [ ] Backup deployment keys
- [ ] Test deployment script on Sepolia first (already done ✅)

Once ready:
```bash
./scripts/deploy_ethereum_mainnet.sh
```

---

*Last updated: December 26, 2024*


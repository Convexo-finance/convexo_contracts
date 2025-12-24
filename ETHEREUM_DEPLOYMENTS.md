# ⟠ Ethereum Deployments

Complete deployment guide for all Ethereum networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Mainnet** | 1 | ⏳ Pending | 0/9 | [Etherscan](https://etherscan.io) |
| **Ethereum Sepolia** | 11155111 | ✅ Complete | 9/9 | [Etherscan](https://sepolia.etherscan.io) |

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

All 9 contracts will be deployed once funded:

### NFT Contracts
- Convexo_LPs
- Convexo_Vaults

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
    hookDeployer: "TBD",
    compliantLPHook: "TBD",
    poolRegistry: "TBD",
    reputationManager: "TBD",
    priceFeedManager: "TBD",
    contractSigner: "TBD",
    vaultFactory: "TBD"
  },
  usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  poolManager: "0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A"
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
**Status**: ✅ Complete - All 9 contracts deployed and verified  
**Date**: December 24, 2024  
**Version**: 2.2

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x1c391574c6a3f0a044fa972583442c7c00d2f727` | [View](https://sepolia.etherscan.io/address/0x1c391574c6a3f0a044fa972583442c7c00d2f727) |
| **Convexo_Vaults** | `0xa9a98fdccbf164fbca6b0688a634775cd59177a6` | [View](https://sepolia.etherscan.io/address/0xa9a98fdccbf164fbca6b0688a634775cd59177a6) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x76da1b31497bbd1093f9226dcad505518cf62ca1` | [View](https://sepolia.etherscan.io/address/0x76da1b31497bbd1093f9226dcad505518cf62ca1) |
| **CompliantLPHook** | `0xe542857f76dba4a53ef7d244cadc227b454b1502` | [View](https://sepolia.etherscan.io/address/0xe542857f76dba4a53ef7d244cadc227b454b1502) |
| **PoolRegistry** | `0xb612db1fe343c4b5ffa9e8c3f4dde37769f7c5b6` | [View](https://sepolia.etherscan.io/address/0xb612db1fe343c4b5ffa9e8c3f4dde37769f7c5b6) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xbfba31d3f7b36a78abd7c7905dacdecbe6bb97ad` | [View](https://sepolia.etherscan.io/address/0xbfba31d3f7b36a78abd7c7905dacdecbe6bb97ad) |
| **PriceFeedManager** | `0x2b09a55380e9023b85886005dc53b600cf6e3f17` | [View](https://sepolia.etherscan.io/address/0x2b09a55380e9023b85886005dc53b600cf6e3f17) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xf75af6f9d586f9c16c5789b2c310dd7a98df97ae` | [View](https://sepolia.etherscan.io/address/0xf75af6f9d586f9c16c5789b2c310dd7a98df97ae) |
| **VaultFactory** | `0xb286824b6f5789ba6a6710a5e9fe487a4cb21f06` | [View](https://sepolia.etherscan.io/address/0xb286824b6f5789ba6a6710a5e9fe487a4cb21f06) |

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
    convexoLPs: "0x1c391574c6a3f0a044fa972583442c7c00d2f727",
    convexoVaults: "0xa9a98fdccbf164fbca6b0688a634775cd59177a6",
    hookDeployer: "0x76da1b31497bbd1093f9226dcad505518cf62ca1",
    compliantLPHook: "0xe542857f76dba4a53ef7d244cadc227b454b1502",
    poolRegistry: "0xb612db1fe343c4b5ffa9e8c3f4dde37769f7c5b6",
    reputationManager: "0xbfba31d3f7b36a78abd7c7905dacdecbe6bb97ad",
    priceFeedManager: "0x2b09a55380e9023b85886005dc53b600cf6e3f17",
    contractSigner: "0xf75af6f9d586f9c16c5789b2c310dd7a98df97ae",
    vaultFactory: "0xb286824b6f5789ba6a6710a5e9fe487a4cb21f06"
  },
  usdc: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
  ecop: "0x19ac2612e560b2bbedf88660a2566ef53c0a15a1",
  poolManager: "0xE03A1074c86CFeDd5C142C4F04F1a1536e203543"
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
- **Mainnet**: Pending deployment
- **Sepolia**: ✅ All contracts verified on Etherscan

### Mainnet Deployment Status

**Ready to deploy once wallet is funded!**

The deployment will:
1. ✅ Deploy all 9 contracts in correct order
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

*Last updated: December 24, 2025*


# ⟠ Ethereum Deployments

Complete deployment guide for all Ethereum networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Mainnet** | 1 | ✅ Complete | 10/10 | [Etherscan](https://etherscan.io) |
| **Ethereum Sepolia** | 11155111 | ✅ Complete | 10/10 | [Etherscan](https://sepolia.etherscan.io) |

---

# 🚀 Ethereum Mainnet

## Network Information
- **Chain ID**: 1
- **Network Name**: Ethereum Mainnet
- **RPC URL**: https://eth.llamarpc.com
- **Block Explorer**: https://etherscan.io
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 10 contracts deployed and verified**  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x7356bf8000de3ca7518a363b954d67cc54f7c84d` | [View on Etherscan](https://etherscan.io/address/0x7356bf8000de3ca7518a363b954d67cc54f7c84d) |
| **Convexo_Vaults** | `0x282a52f7607ef04415c6567d18f1bf9acd043f42` | [View on Etherscan](https://etherscan.io/address/0x282a52f7607ef04415c6567d18f1bf9acd043f42) |
| **Convexo_Passport** | `0x292ef88a7199916899fc296ff6b522306fa2b19a` | [View on Etherscan](https://etherscan.io/address/0x292ef88a7199916899fc296ff6b522306fa2b19a) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x4dbccff8730398a35d517ab8a1e8413a45d686c4` | [View on Etherscan](https://etherscan.io/address/0x4dbccff8730398a35d517ab8a1e8413a45d686c4) |
| **CompliantLPHook** | `0xbb13194b2792e291109402369cb4fc0358aed132` | [View on Etherscan](https://etherscan.io/address/0xbb13194b2792e291109402369cb4fc0358aed132) |
| **PoolRegistry** | `0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a` | [View on Etherscan](https://etherscan.io/address/0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xc98bce4617f9708dd1363f21177be5ef21fb4993` | [View on Etherscan](https://etherscan.io/address/0xc98bce4617f9708dd1363f21177be5ef21fb4993) |
| **PriceFeedManager** | `0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7` | [View on Etherscan](https://etherscan.io/address/0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x5a1f415986a189d79d19d65cb6e3d6dd7b807268` | [View on Etherscan](https://etherscan.io/address/0x5a1f415986a189d79d19d65cb6e3d6dd7b807268) |
| **VaultFactory** | `0x6b51adc34a503b23db99444048ac7c2dc735a12e` | [View on Etherscan](https://etherscan.io/address/0x6b51adc34a503b23db99444048ac7c2dc735a12e) |

## Network Dependencies

### Uniswap V4 PoolManager
- **Address**: `0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A`
- **Purpose**: Used by CompliantLPHook for Uniswap V4 integration

### USDC Token
- **Address**: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- **Purpose**: Circle's USDC on Ethereum - stablecoin used in VaultFactory

### ZKPassport Verifier
- **Address**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`
- **Purpose**: Official ZKPassport verifier for identity verification

## Frontend Integration (Mainnet)

```javascript
const ETHEREUM_MAINNET_CONFIG = {
  chainId: 1,
  name: "Ethereum Mainnet",
  contracts: {
    convexoLPs: "0x7356bf8000de3ca7518a363b954d67cc54f7c84d",
    convexoVaults: "0x282a52f7607ef04415c6567d18f1bf9acd043f42",
    convexoPassport: "0x292ef88a7199916899fc296ff6b522306fa2b19a",
    hookDeployer: "0x4dbccff8730398a35d517ab8a1e8413a45d686c4",
    compliantLPHook: "0xbb13194b2792e291109402369cb4fc0358aed132",
    poolRegistry: "0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a",
    reputationManager: "0xc98bce4617f9708dd1363f21177be5ef21fb4993",
    priceFeedManager: "0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7",
    contractSigner: "0x5a1f415986a189d79d19d65cb6e3d6dd7b807268",
    vaultFactory: "0x6b51adc34a503b23db99444048ac7c2dc735a12e"
  },
  usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  poolManager: "0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
};
```

---

# 🧪 Ethereum Sepolia Testnet

## Network Information
- **Chain ID**: 11155111
- **Network Name**: Ethereum Sepolia
- **RPC URL**: https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
- **Block Explorer**: https://sepolia.etherscan.io
- **Currency**: ETH (Testnet)

## Deployment Summary
**Status**: ✅ Complete - All 10 contracts deployed and verified  
**Date**: December 26, 2025  
**Version**: 2.0 (with Convexo_Passport)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x2f781b3fffd6853a3d8ffca338d33b1d61ffab0e` | [View](https://sepolia.etherscan.io/address/0x2f781b3fffd6853a3d8ffca338d33b1d61ffab0e) |
| **Convexo_Vaults** | `0xefa4e787c96df9df08de5230ec6cf6126a211edc` | [View](https://sepolia.etherscan.io/address/0xefa4e787c96df9df08de5230ec6cf6126a211edc) |
| **Convexo_Passport** | `0x19d9fc7c6c3e62c1c7358504f47e629333b10627` | [View](https://sepolia.etherscan.io/address/0x19d9fc7c6c3e62c1c7358504f47e629333b10627) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xda82a962e5671cfa97663e25495028c313a524e8` | [View](https://sepolia.etherscan.io/address/0xda82a962e5671cfa97663e25495028c313a524e8) |
| **CompliantLPHook** | `0x7fcc3c235cbd5bd6059e4744c3a005c68a2d4da4` | [View](https://sepolia.etherscan.io/address/0x7fcc3c235cbd5bd6059e4744c3a005c68a2d4da4) |
| **PoolRegistry** | `0x43d5c9507f399e689ddf4c05ba542a3ad5dbe53e` | [View](https://sepolia.etherscan.io/address/0x43d5c9507f399e689ddf4c05ba542a3ad5dbe53e) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x549858f0f85ecce1f9713dc3ba5b61c7f9cca69d` | [View](https://sepolia.etherscan.io/address/0x549858f0f85ecce1f9713dc3ba5b61c7f9cca69d) |
| **PriceFeedManager** | `0xd34de952cec3af29abab321e68d7e51c098dc063` | [View](https://sepolia.etherscan.io/address/0xd34de952cec3af29abab321e68d7e51c098dc063) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xa2dfbe7252fcf7dd1b7760342ba126483d3b0548` | [View](https://sepolia.etherscan.io/address/0xa2dfbe7252fcf7dd1b7760342ba126483d3b0548) |
| **VaultFactory** | `0xe48f35fd0e00af2059f18cf67268cce6e87f4ea4` | [View](https://sepolia.etherscan.io/address/0xe48f35fd0e00af2059f18cf67268cce6e87f4ea4) |

## Network Dependencies (Sepolia)

- **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **ECOP Token**: `0x19ac2612e560b2bbedf88660a2566ef53c0a15a1`
- **PoolManager**: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- **ZKPassport Verifier**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`

## Frontend Integration (Sepolia)

```javascript
const ETHEREUM_SEPOLIA_CONFIG = {
  chainId: 11155111,
  name: "Ethereum Sepolia",
  contracts: {
    convexoLPs: "0x2f781b3fffd6853a3d8ffca338d33b1d61ffab0e",
    convexoVaults: "0xefa4e787c96df9df08de5230ec6cf6126a211edc",
    convexoPassport: "0x19d9fc7c6c3e62c1c7358504f47e629333b10627",
    hookDeployer: "0xda82a962e5671cfa97663e25495028c313a524e8",
    compliantLPHook: "0x7fcc3c235cbd5bd6059e4744c3a005c68a2d4da4",
    poolRegistry: "0x43d5c9507f399e689ddf4c05ba542a3ad5dbe53e",
    reputationManager: "0x549858f0f85ecce1f9713dc3ba5b61c7f9cca69d",
    priceFeedManager: "0xd34de952cec3af29abab321e68d7e51c098dc063",
    contractSigner: "0xa2dfbe7252fcf7dd1b7760342ba126483d3b0548",
    vaultFactory: "0xe48f35fd0e00af2059f18cf67268cce6e87f4ea4"
  },
  usdc: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
  ecop: "0x19ac2612e560b2bbedf88660a2566ef53c0a15a1",
  poolManager: "0xE03A1074c86CFeDd5C142C4F04F1a1536e203543",
  zkPassportVerifier: "0x1D000001000EFD9a6371f4d90bB8920D5431c0D8"
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
- **Maximum security**: Most decentralized and secure blockchain
- **Largest ecosystem**: Broadest DeFi integration and liquidity
- **Network effects**: Largest user base and developer community
- **Battle-tested**: Proven track record since 2015

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 10 Contracts |
|---------|------------------|---------------------------|
| **Ethereum Mainnet** | **~30 gwei** | **~0.0005 ETH (~$2)** |
| Base Mainnet | ~0.0009 gwei | ~0.000011 ETH (~$0.04) |
| Unichain Mainnet | ~0.000004 gwei | ~0.000047 ETH (~$0.0002) |

---

## 📚 Additional Resources

### Documentation
- [Contract Reference](./CONTRACTS_REFERENCE.md)
- [Security Audit](./SECURITY_AUDIT.md)
- [Frontend Integration Guide](./FRONTEND_INTEGRATION.md)
- [ZKPassport Integration](./ZKPASSPORT_FRONTEND_INTEGRATION.md)

### Ethereum Resources
- [Ethereum Documentation](https://ethereum.org/developers)
- [Etherscan](https://etherscan.io)
- [Ethereum Faucet (Sepolia)](https://sepoliafaucet.com)

---

## 🛠️ Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Ethereum Mainnet
ETHEREUM_MAINNET_RPC_URL=https://eth.llamarpc.com
POOL_MANAGER_ADDRESS_ETHEREUM=0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A
USDC_ADDRESS_ETHEREUM=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
ETHERSCAN_API_KEY=your_etherscan_api_key

# Ethereum Sepolia
ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
POOL_MANAGER_ADDRESS_SEPOLIA=0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
USDC_ADDRESS_SEPOLIA=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
ECOP_ADDRESS_SEPOLIA=0x19ac2612e560b2bbedf88660a2566ef53c0a15a1
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
✅ All contracts verified on Etherscan (Both networks)

---

*Last updated: December 26, 2025*

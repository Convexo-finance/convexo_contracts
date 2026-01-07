# ⟠ Ethereum Deployments

Complete deployment guide for all Ethereum networks (Mainnet & Sepolia Testnet).

---

## 📋 Networks Overview

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Mainnet** | 1 | ✅ Complete | 12/12 | [Etherscan](https://etherscan.io) |
| **Ethereum Sepolia** | 11155111 | ✅ Complete | 12/12 | [Etherscan](https://sepolia.etherscan.io) |

---

# 🚀 Ethereum Mainnet

## Network Information
- **Chain ID**: 1
- **Network Name**: Ethereum Mainnet
- **RPC URL**: https://eth.llamarpc.com
- **Block Explorer**: https://etherscan.io
- **Currency**: ETH

## Deployment Summary
**Status**: ✅ **Complete - All 12 contracts deployed and verified**  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7` | [View on Etherscan](https://etherscan.io/address/0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7) |
| **Convexo_Vaults** | `0x5a1f415986a189d79d19d65cb6e3d6dd7b807268` | [View on Etherscan](https://etherscan.io/address/0x5a1f415986a189d79d19d65cb6e3d6dd7b807268) |
| **Convexo_Passport** | `0x6b51adc34a503b23db99444048ac7c2dc735a12e` | [View on Etherscan](https://etherscan.io/address/0x6b51adc34a503b23db99444048ac7c2dc735a12e) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x5d88bcf0d62f17846d41e161e92e497d4224764d` | [View on Etherscan](https://etherscan.io/address/0x5d88bcf0d62f17846d41e161e92e497d4224764d) |
| **CompliantLPHook** | `0x6a6357c387331e75d6eeb4d4abc0f0200cd32830` | [View on Etherscan](https://etherscan.io/address/0x6a6357c387331e75d6eeb4d4abc0f0200cd32830) |
| **PoolRegistry** | `0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3` | [View on Etherscan](https://etherscan.io/address/0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0xc5e04ab886025b3fe3d99249d1db069e0b599d8e` | [View on Etherscan](https://etherscan.io/address/0xc5e04ab886025b3fe3d99249d1db069e0b599d8e) |
| **PriceFeedManager** | `0xd09e7252c6402155f9d13653de24ae4f0a220fec` | [View on Etherscan](https://etherscan.io/address/0xd09e7252c6402155f9d13653de24ae4f0a220fec) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x74577d6e9140944db7ae2f1e103a39962c80c235` | [View on Etherscan](https://etherscan.io/address/0x74577d6e9140944db7ae2f1e103a39962c80c235) |
| **VaultFactory** | `0xbabee8acecc117c1295f8950f51db59f7a881646` | [View on Etherscan](https://etherscan.io/address/0xbabee8acecc117c1295f8950f51db59f7a881646) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2` | [View on Etherscan](https://etherscan.io/address/0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2) |
| **VeriffVerifier** | `0xe0c0d95701558ef10768a13a944f56311ead4649` | [View on Etherscan](https://etherscan.io/address/0xe0c0d95701558ef10768a13a944f56311ead4649) |

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
    convexoLPs: "0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7",
    convexoVaults: "0x5a1f415986a189d79d19d65cb6e3d6dd7b807268",
    convexoPassport: "0x6b51adc34a503b23db99444048ac7c2dc735a12e",
    hookDeployer: "0x5d88bcf0d62f17846d41e161e92e497d4224764d",
    compliantLPHook: "0x6a6357c387331e75d6eeb4d4abc0f0200cd32830",
    poolRegistry: "0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3",
    reputationManager: "0xc5e04ab886025b3fe3d99249d1db069e0b599d8e",
    priceFeedManager: "0xd09e7252c6402155f9d13653de24ae4f0a220fec",
    contractSigner: "0x74577d6e9140944db7ae2f1e103a39962c80c235",
    vaultFactory: "0xbabee8acecc117c1295f8950f51db59f7a881646",
    treasuryFactory: "0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2",
    veriffVerifier: "0xe0c0d95701558ef10768a13a944f56311ead4649"
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
**Status**: ✅ Complete - All 12 contracts deployed and verified  
**Date**: January 7, 2026  
**Version**: 2.1 (with Treasury & Veriff)

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0x6d2101b853e80ea873d2c7c0ec6138c837779c6a` | [View](https://sepolia.etherscan.io/address/0x6d2101b853e80ea873d2c7c0ec6138c837779c6a) |
| **Convexo_Vaults** | `0xd1ff2d103a864ccb150602dedc09804037b8ce85` | [View](https://sepolia.etherscan.io/address/0xd1ff2d103a864ccb150602dedc09804037b8ce85) |
| **Convexo_Passport** | `0x259adc4917c442dd9a509cb8333a9bed88fe5c70` | [View](https://sepolia.etherscan.io/address/0x259adc4917c442dd9a509cb8333a9bed88fe5c70) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xec97706ca992d571c17c3ac895e9317656d29a25` | [View](https://sepolia.etherscan.io/address/0xec97706ca992d571c17c3ac895e9317656d29a25) |
| **CompliantLPHook** | `0xb1697c34cc15cb1fba579f94693e9ab53292b51b` | [View](https://sepolia.etherscan.io/address/0xb1697c34cc15cb1fba579f94693e9ab53292b51b) |
| **PoolRegistry** | `0x710299e39b130db198dd2a6973c2ccd7bcc2d093` | [View](https://sepolia.etherscan.io/address/0x710299e39b130db198dd2a6973c2ccd7bcc2d093) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x82e856e70a0057fc6e26c17793a890ec38194cfc` | [View](https://sepolia.etherscan.io/address/0x82e856e70a0057fc6e26c17793a890ec38194cfc) |
| **PriceFeedManager** | `0xebb59c7e14ea002924bf34eedf548836c25a3440` | [View](https://sepolia.etherscan.io/address/0xebb59c7e14ea002924bf34eedf548836c25a3440) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0x59b0f14ac23cd3b0a6a926a302ac01e4221785bf` | [View](https://sepolia.etherscan.io/address/0x59b0f14ac23cd3b0a6a926a302ac01e4221785bf) |
| **VaultFactory** | `0x4fc5ca49812b0c312046b000d234a96e9084effb` | [View](https://sepolia.etherscan.io/address/0x4fc5ca49812b0c312046b000d234a96e9084effb) |

### Treasury & Verification (NEW in v2.1)
| Contract | Address | Explorer |
|----------|---------|----------|
| **TreasuryFactory** | `0x53d38e2ca13d085d14a44b0deadc47995a82eca3` | [View](https://sepolia.etherscan.io/address/0x53d38e2ca13d085d14a44b0deadc47995a82eca3) |
| **VeriffVerifier** | `0xb11f1c681b8719e6d82098e1316d2573477834ab` | [View](https://sepolia.etherscan.io/address/0xb11f1c681b8719e6d82098e1316d2573477834ab) |

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
    convexoLPs: "0x6d2101b853e80ea873d2c7c0ec6138c837779c6a",
    convexoVaults: "0xd1ff2d103a864ccb150602dedc09804037b8ce85",
    convexoPassport: "0x259adc4917c442dd9a509cb8333a9bed88fe5c70",
    hookDeployer: "0xec97706ca992d571c17c3ac895e9317656d29a25",
    compliantLPHook: "0xb1697c34cc15cb1fba579f94693e9ab53292b51b",
    poolRegistry: "0x710299e39b130db198dd2a6973c2ccd7bcc2d093",
    reputationManager: "0x82e856e70a0057fc6e26c17793a890ec38194cfc",
    priceFeedManager: "0xebb59c7e14ea002924bf34eedf548836c25a3440",
    contractSigner: "0x59b0f14ac23cd3b0a6a926a302ac01e4221785bf",
    vaultFactory: "0x4fc5ca49812b0c312046b000d234a96e9084effb",
    treasuryFactory: "0x53d38e2ca13d085d14a44b0deadc47995a82eca3",
    veriffVerifier: "0xb11f1c681b8719e6d82098e1316d2573477834ab"
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

## 🏆 Tier System (v2.1)

| Tier | NFT | User Type | Access |
|------|-----|-----------|--------|
| **Tier 0** | None | Unverified | No access |
| **Tier 1** | Convexo_Passport | Individual | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | Limited Partner | LP pools + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault Creator | All above + Vault creation |

---

## 💡 Ethereum Benefits

### Why Ethereum?
- **Maximum security**: Most decentralized and secure blockchain
- **Largest ecosystem**: Broadest DeFi integration and liquidity
- **Network effects**: Largest user base and developer community
- **Battle-tested**: Proven track record since 2015

### Gas Cost Comparison
| Network | Average Gas Price | Est. Cost for 12 Contracts |
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
- Solidity: 0.8.27
- Optimizer: Enabled (200 runs)
- EVM Version: Prague
- Via IR: Enabled

### Verification Status
✅ All 12 contracts verified on Etherscan (Both networks)

---

*Last updated: January 7, 2026 - v2.1*

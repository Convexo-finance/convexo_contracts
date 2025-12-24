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
| **Convexo_LPs** | `0xbabee8acecc117c1295f8950f51db59f7a881646` | [View](https://unichain.blockscout.com/address/0xbabee8acecc117c1295f8950f51db59f7a881646) |
| **Convexo_Vaults** | `0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2` | [View](https://unichain.blockscout.com/address/0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0xe0c0d95701558ef10768a13a944f56311ead4649` | [View](https://unichain.blockscout.com/address/0xe0c0d95701558ef10768a13a944f56311ead4649) |
| **CompliantLPHook** | `0xdd973ce09ba55260e217d10f9dec6d7945d73e79` | [View](https://unichain.blockscout.com/address/0xdd973ce09ba55260e217d10f9dec6d7945d73e79) |
| **PoolRegistry** | `0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935` | [View](https://unichain.blockscout.com/address/0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x3770bb3bbeb0102a36f51aa253e69034058e4f84` | [View](https://unichain.blockscout.com/address/0x3770bb3bbeb0102a36f51aa253e69034058e4f84) |
| **PriceFeedManager** | `0x2fa95f79ce8c5c01581f6792acc4181282aaefb0` | [View](https://unichain.blockscout.com/address/0x2fa95f79ce8c5c01581f6792acc4181282aaefb0) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xf8dce148ab008f7ae47a26377252673438801712` | [View](https://unichain.blockscout.com/address/0xf8dce148ab008f7ae47a26377252673438801712) |
| **VaultFactory** | `0x3d684ac58f25a95c107565bcffffb219b00557c7` | [View](https://unichain.blockscout.com/address/0x3d684ac58f25a95c107565bcffffb219b00557c7) |

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
    convexoLPs: "0xbabee8acecc117c1295f8950f51db59f7a881646",
    convexoVaults: "0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2",
    hookDeployer: "0xe0c0d95701558ef10768a13a944f56311ead4649",
    compliantLPHook: "0xdd973ce09ba55260e217d10f9dec6d7945d73e79",
    poolRegistry: "0x24d91b11b0dd12d6520e58c72f8fcc9dc1c5b935",
    reputationManager: "0x3770bb3bbeb0102a36f51aa253e69034058e4f84",
    priceFeedManager: "0x2fa95f79ce8c5c01581f6792acc4181282aaefb0",
    contractSigner: "0xf8dce148ab008f7ae47a26377252673438801712",
    vaultFactory: "0x3d684ac58f25a95c107565bcffffb219b00557c7"
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
**Date**: December 24, 2024  
**Version**: 2.2

## Deployed Contracts

### NFT Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **Convexo_LPs** | `0xe4a58592171cd0770e6792600ea3098060a42d46` | [View](https://unichain-sepolia.blockscout.com/address/0xe4a58592171cd0770e6792600ea3098060a42d46) |
| **Convexo_Vaults** | `0xd7cf4aba5b9b4877419ab8af3979da637493afb1` | [View](https://unichain-sepolia.blockscout.com/address/0xd7cf4aba5b9b4877419ab8af3979da637493afb1) |

### Hook System
| Contract | Address | Explorer |
|----------|---------|----------|
| **HookDeployer** | `0x99e9880a08e14112a18c091bd49a2b1713133687` | [View](https://unichain-sepolia.blockscout.com/address/0x99e9880a08e14112a18c091bd49a2b1713133687) |
| **CompliantLPHook** | `0xf54e26527bec4847f66afb5166a7a5c3d1fd6304` | [View](https://unichain-sepolia.blockscout.com/address/0xf54e26527bec4847f66afb5166a7a5c3d1fd6304) |
| **PoolRegistry** | `0x54141c25535c851d0dba00a1bad6f788dbdd0397` | [View](https://unichain-sepolia.blockscout.com/address/0x54141c25535c851d0dba00a1bad6f788dbdd0397) |

### Core Infrastructure
| Contract | Address | Explorer |
|----------|---------|----------|
| **ReputationManager** | `0x4c43d9c8388f2055e0b1185724e77036065a9b18` | [View](https://unichain-sepolia.blockscout.com/address/0x4c43d9c8388f2055e0b1185724e77036065a9b18) |
| **PriceFeedManager** | `0x7ebda99a0dea755b2ae85e966e74a247aca0384a` | [View](https://unichain-sepolia.blockscout.com/address/0x7ebda99a0dea755b2ae85e966e74a247aca0384a) |

### Vault System
| Contract | Address | Explorer |
|----------|---------|----------|
| **ContractSigner** | `0xd1680b5859d28a0440a00e4dcb7545949c54602a` | [View](https://unichain-sepolia.blockscout.com/address/0xd1680b5859d28a0440a00e4dcb7545949c54602a) |
| **VaultFactory** | `0x984a6bd48d8a91758e3ac967ef5c804ba03935ad` | [View](https://unichain-sepolia.blockscout.com/address/0x984a6bd48d8a91758e3ac967ef5c804ba03935ad) |

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
    convexoLPs: "0xe4a58592171cd0770e6792600ea3098060a42d46",
    convexoVaults: "0xd7cf4aba5b9b4877419ab8af3979da637493afb1",
    hookDeployer: "0x99e9880a08e14112a18c091bd49a2b1713133687",
    compliantLPHook: "0xf54e26527bec4847f66afb5166a7a5c3d1fd6304",
    poolRegistry: "0x54141c25535c851d0dba00a1bad6f788dbdd0397",
    reputationManager: "0x4c43d9c8388f2055e0b1185724e77036065a9b18",
    priceFeedManager: "0x7ebda99a0dea755b2ae85e966e74a247aca0384a",
    contractSigner: "0xd1680b5859d28a0440a00e4dcb7545949c54602a",
    vaultFactory: "0x984a6bd48d8a91758e3ac967ef5c804ba03935ad"
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


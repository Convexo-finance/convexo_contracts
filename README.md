# Convexo Protocol

**Decentralized Lending Infrastructure for Latin American SMEs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.27-363636?logo=solidity)](https://soliditylang.org/)
[![Version](https://img.shields.io/badge/Version-2.2-purple)](./CONTRACTS_REFERENCE.md)

---

## Overview

Convexo bridges international investors with Latin American SMEs through compliant, on-chain lending using stablecoins, NFT-permissioned liquidity pools, and tokenized bond vaults.

### Key Features
- **4-NFT Verification System** - Progressive KYC/KYB with ZKPassport, Veriff, Sumsub, and AI Credit Scoring
- **Tokenized Bond Vaults** - 12% APY for investors, flexible repayment for borrowers
- **Compliant LP Pools** - Uniswap V4 hooks with NFT-gated access
- **Personal Treasuries** - Multi-sig USDC management for verified users

---

## Tier System

| Tier | NFT | Verification | Access |
|------|-----|--------------|--------|
| **0** | None | - | No access |
| **1** | Convexo_Passport | ZKPassport | Treasury + Vault investments |
| **2** | LP_Individuals / LP_Business | Veriff / Sumsub | LP pools + Vault investments |
| **3** | Ecreditscoring | AI Credit Score | All above + Vault creation |

---

## Deployed Networks

| Network | Status | Documentation |
|---------|--------|---------------|
| **⟠ Ethereum Mainnet** | ✅ 12/12 contracts | [ETHEREUM_DEPLOYMENTS.md](./ETHEREUM_DEPLOYMENTS.md) |
| **🔵 Base Mainnet** | ✅ 12/12 contracts | [BASE_DEPLOYMENTS.md](./BASE_DEPLOYMENTS.md) |
| **🦄 Unichain Mainnet** | ✅ 12/12 contracts | [UNICHAIN_DEPLOYMENTS.md](./UNICHAIN_DEPLOYMENTS.md) |
| Ethereum Sepolia | ✅ Testnet | [ETHEREUM_DEPLOYMENTS.md](./ETHEREUM_DEPLOYMENTS.md) |
| Base Sepolia | ✅ Testnet | [BASE_DEPLOYMENTS.md](./BASE_DEPLOYMENTS.md) |
| Unichain Sepolia | ✅ Testnet | [UNICHAIN_DEPLOYMENTS.md](./UNICHAIN_DEPLOYMENTS.md) |

> **📍 Contract addresses:** See chain-specific deployment docs above or [addresses.json](./addresses.json)

---

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Clone and build
git clone https://github.com/convexo-finance/convexo_contracts.git
cd convexo_contracts
forge install && forge build

# Run tests
forge test -vvv
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md) | Contract functions & architecture |
| [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md) | React/Wagmi integration guide |
| [ZKPASSPORT_FRONTEND_INTEGRATION.md](./ZKPASSPORT_FRONTEND_INTEGRATION.md) | ZKPassport verification flow |
| [SECURITY_AUDIT.md](./SECURITY_AUDIT.md) | Security features & audit info |
| [addresses.json](./addresses.json) | All contract addresses (JSON) |

---

## Contracts (12)

| # | Contract | Purpose |
|---|----------|---------|
| 1 | **Convexo_Passport** | Soulbound NFT for individuals (Tier 1) |
| 2 | **Limited_Partners_Individuals** | NFT for verified individuals (Tier 2) |
| 3 | **Limited_Partners_Business** | NFT for verified businesses (Tier 2) |
| 4 | **Ecreditscoring** | NFT for credit-scored borrowers (Tier 3) |
| 5 | **ReputationManager** | Tier calculation & access control |
| 6 | **VaultFactory** | Creates tokenized bond vaults |
| 7 | **TreasuryFactory** | Creates personal treasuries |
| 8 | **ContractSigner** | Multi-party contract signing |
| 9 | **VeriffVerifier** | Human-approved KYC verification |
| 10 | **CompliantLPHook** | Uniswap V4 access control hook |
| 11 | **PoolRegistry** | Compliant pool tracking |
| 12 | **PriceFeedManager** | Chainlink price feeds |

---

## ABIs

All ABIs in `abis/` directory:

```
abis/
├── Convexo_Passport.json
├── ReputationManager.json
├── TokenizedBondVault.json
├── VaultFactory.json
├── TreasuryFactory.json
├── ContractSigner.json
├── VeriffVerifier.json
├── CompliantLPHook.json
├── PoolRegistry.json
├── PriceFeedManager.json
└── combined.json
```

---

## Links

- **Website**: [convexo.finance](https://convexo.finance)
- **Docs**: [docs.convexo.finance](https://docs.convexo.finance)
- **Twitter**: [@ConvexoFinance](https://twitter.com/ConvexoFinance)

---

<p align="center">Made with ❤️ for Latin American SMEs</p>

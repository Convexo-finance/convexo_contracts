# Convexo Protocol

**Reducing the Gap funding for SMEs in Latin America using stablecoins, NFT-permissioned liquidity pools and vaults.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-87%2F87%20Passing-brightgreen)](./test)
[![Deployed](https://img.shields.io/badge/Deployed-Base%20Mainnet-blue)](https://basescan.org)
[![Deployed](https://img.shields.io/badge/Deployed-Unichain%20Mainnet-success)](https://unichain.blockscout.com)
[![Deployed](https://img.shields.io/badge/Deployed-Arbitrum%20One-red)](https://arbiscan.io)
[![Version](https://img.shields.io/badge/Version-3.17-purple)](./CONTRACTS_REFERENCE.md)

---

## 🌎 Overview

Convexo Protocol bridges the gap between international investors and Latin American SMEs through compliant, on-chain lending infrastructure.

### The Problem
SMEs in LATAM struggle to access international capital due to:
- Complex compliance requirements
- Limited credit history
- Currency conversion challenges
- High transaction costs

### Our Solution
Convexo creates a compliant, efficient lending protocol using:
- **Local Stablecoins** paired with USDC via Uniswap V4 Hooks
- **Cross-chain tokens** powered by Chainlink CCIP
- **NFT-gated access** for compliance and credit verification
- **AI Credit Scoring** for automated risk assessment
- **Tokenized vaults** for transparent lending

---

## 🔑 Key Features

### 1. Compliant Liquidity Pools
- **Uniswap V4 Hooks** gate pool access to verified users
- Pairs: USDC/ECOP (Colombian Peso), USDC/ARS (Argentine Peso), USDC/MXN (Mexican Peso)
- Only holders of Convexo_LPs NFT (Tier 2+) can trade
- Seamless currency conversion for SMEs

### 2. NFT-Permissioned Vaults
- **AI-powered credit scoring** (threshold: 70+)
- Create tokenized bond vaults to request funding
- Investors earn 10-12% APY in USDC
- Real-time tracking of investments and returns

### 3. Tokenized Bond Vaults
- **Borrower-initiated**: SMEs with Tier 2 NFT create vaults for financing
- **Flexible repayment**: Pay anytime, any amount before maturity
- **Proportional withdrawals**: Each party withdraws independently
  - Protocol collector: 2% fee (proportional to repayments)
  - Investors: Principal + 12% returns (proportional to repayments)
- **Transparent tracking**: Real-time on-chain state

---

## 👥 User Journeys

### For Individual Investors (ZKPassport Verified)

**Privacy-first verification for individual investors!**

```
1. Connect wallet
2. Verify identity using ZKPassport (passport or ID card)
   - Privacy-preserving: Only verification traits stored (no PII)
   - Instant on-chain verification
3. Receive Convexo_Passport NFT (Tier 1)
4. Browse and invest in available vaults
5. Earn returns (10-12% APY)
6. Redeem shares after full repayment
```

**Benefits:**
- ✅ No business KYB required
- ✅ Privacy-first verification
- ✅ Instant on-chain minting
- ✅ Access to vault investments
- ✅ Access to Uniswap V4 LP Pools
- ✅ Soulbound NFT (non-transferable)

**Flow:**
```
Connect Wallet → ZKPassport Verification → Self-Mint Passport NFT →
Invest in Vaults → Earn Returns → Redeem
```

### For SMEs (Borrowers)

#### Step 1: Compliance Verification
```
1. Submit KYB via Veriff/Sumsub
2. Pass compliance checks
3. Admin approves via VeriffVerifier (NEW!)
4. Receive Convexo_LPs NFT (Tier 2)
5. Can now use liquidity pools to convert USDC ↔ Local Stables
```

**Benefits:**
- Exchange USDC (from funded vaults) → Local stablecoins (ECOP, ARS, MXN)
- Top up account with local stables → Get USDC for operations

#### Step 2: Credit Scoring & Vault Creation
```
1. Submit financial statements & business model to AI
2. AI analyzes creditworthiness
3. If score > 70: Receive Convexo_Vaults NFT (Tier 3)
4. Create vault to request funding
5. Investors fund the vault
6. Sign contract with investors
7. Withdraw funds and use for business
8. Repay anytime (principal + 12% interest + 2% protocol fee)
9. Each party withdraws independently
```

**Flow:**
```
Apply → AI Score → NFT (if > 70) → Create Vault → Get Funded → 
Sign Contract → Withdraw → Repay → Protocol & Investors Withdraw
```

### For Business Investors (Lenders)

```
1. Submit KYB via Veriff/Sumsub (business verification)
2. Admin approves via VeriffVerifier
3. Receive Convexo_LPs NFT (Tier 2)
4. Browse available vaults
5. Review: APY (12%), risk level, maturity date
6. Invest USDC in vault (purchase shares)
7. Track returns in real-time
8. Redeem shares after borrower fully repays
9. Receive principal + 12% returns proportionally
```

**Returns:**
- 12% APY on USDC investments
- Withdrawal after full repayment
- Transparent, on-chain tracking
- Proportional to repayments made

---

## 🏗️ Architecture

### Reputation Tiers (v3.17)

| Tier | NFT Contract | User Type | Access | Verification Method |
|------|--------------|-----------|--------|---------------------|
| **Tier 0** | None | Unverified | No access | N/A |
| **Tier 1** | Convexo_Passport | Individual Investor | **LP Pool Swaps** (Uniswap V4) + Vault investments | Self-mint via ZKPassport |
| **Tier 2** | Limited_Partners_Individuals | Limited Partner (Individual) | Credit Score Request + Monetization + OTC + Vaults | KYC via VeriffVerifier (admin approval) |
| **Tier 2** | Limited_Partners_Business | Limited Partner (Business) | Credit Score Request + Monetization + OTC + Vaults | KYB via SumsubVerifier (admin approval) |
| **Tier 3** | Ecreditscoring | Vault Creator | All above + **Vault creation** | AI Credit Score (backend mints) |

**Note:** 
- Highest tier wins (progressive KYC). Users can upgrade from Tier 1 to Tier 2/3.
- **Tier 2 NFTs grant identical permissions** - only difference is identity marker (individual vs business)

### NFT Metadata & Images

| NFT Contract | IPFS URI | CID | Auto-Applied? |
|--------------|----------|-----|---------------|
| Convexo_Passport | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4) | `bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4` | ✅ Yes (hardcoded) |
| Limited_Partners_Individuals | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em) | `bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em` | ✅ Yes (via VeriffVerifier) |
| Limited_Partners_Business | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m) | `bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m` | ✅ Yes (via SumsubVerifier) |
| Ecreditscoring | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e) | `bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e` | ⚠️ No (backend must pass URI) |

**Important:** All NFTs are soulbound (non-transferable) and limited to **one per address**.


### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│            Verification Layer (3-Path System)                │
│                                                              │
│  PATH 1 - Individual Self-Verification (Tier 1):            │
│  ZKPassport → Self-Mint → Convexo_Passport NFT              │
│  ✅ LP Pool Swaps (Uniswap V4) + Vault investments          │
│                                                              │
│  PATH 2A - Individual KYC (Tier 2):                         │
│  Veriff KYC → VeriffVerifier (Registry) →                   │
│  → Admin Approval → Limited_Partners_Individuals NFT         │
│  ✅ Request Credit Score + Monetization + OTC + Vaults      │
│                                                              │
│  PATH 2B - Business KYB (Tier 2):                           │
│  Sumsub KYB → SumsubVerifier (Registry) →                   │
│  → Admin Approval → Limited_Partners_Business NFT            │
│  ✅ Request Credit Score + Monetization + OTC + Vaults      │
│  (Same permissions as PATH 2A)                               │
│                                                              │
│  PATH 3 - Vault Creators (Tier 3):                          │
│  AI Credit Score → Backend → Ecreditscoring NFT              │
│  ✅ All above + Vault creation                              │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│          Liquidity Pools (Tier 1+ Access) ★                 │
│  Uniswap V4 + CompliantLPHook                               │
│  USDC/ECOP, USDC/ARS, USDC/MXN                              │
│  ★ Convexo_Passport holders can swap here                   │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Tokenized Bond Vaults                           │
│  • VaultFactory: Create funding vaults (Tier 3 only)        │
│  • TokenizedBondVault: ERC20 share-based vaults             │
│  • Investors: Tier 1+ can invest                            │
│  • Flexible repayment & independent withdrawals             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Deployed Contracts

View contract addresses by network in **[addresses.json](./addresses.json)**

Supported Networks:
- **⟠ Ethereum**: Mainnet (1) + Sepolia (11155111)
- **🔵 Base**: Mainnet (8453) + Sepolia (84532)
- **🦄 Unichain**: Mainnet (130) + Sepolia (1301)- **🔴 Arbitrum**: One (42161) + Sepolia (421614)
---

## 🚀 Quick Start

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
```

### Installation
```bash
git clone https://github.com/convexo-finance/convexo-protocol.git
forge install
```

### Configuration
```bash
# Copy environment template
cp .env.example .env

# Add your keys
PRIVATE_KEY=your_deployer_private_key
ETHERSCAN_API_KEY=your_api_key
```

### Testing
```bash
# Run all tests
forge test

# With gas report
forge test --gas-report

# Verbose output
forge test -vvv
```

**Test Results:** ✅ 87/87 tests passing (100% coverage)

---

## 🌐 Deployment Status

### 🚀 Mainnet Deployments

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Mainnet** | 1 | ✅ Complete | 12/12 (v3.17) | [Etherscan](https://etherscan.io) |
| **Base Mainnet** | 8453 | ✅ Complete | 12/12 (v3.17) | [BaseScan](https://basescan.org) |
| **Unichain Mainnet** | 130 | ✅ Complete | 12/12 (v3.17) | [Blockscout](https://unichain.blockscout.com) |
| **Arbitrum One** | 42161 | 🔧 Ready | 12/12 (v3.17) | [Arbiscan](https://arbiscan.io) |

### 🧪 Testnet Deployments

| Network | Chain ID | Status | Contracts | Explorer |
|---------|----------|--------|-----------|----------|
| **Ethereum Sepolia** | 11155111 | ✅ Complete | 12/12 (v3.17) | [Etherscan](https://sepolia.etherscan.io) |
| **Base Sepolia** | 84532 | ✅ Complete | 12/12 (v3.17) | [BaseScan](https://sepolia.basescan.org) |
| **Unichain Sepolia** | 1301 | ✅ Complete | 12/12 (v3.17) | [Blockscout](https://unichain-sepolia.blockscout.com) |
| **Arbitrum Sepolia** | 421614 | 🔧 Ready | 12/12 (v3.17) | [Arbiscan](https://sepolia.arbiscan.io) |

**Note**: All networks on v3.17 with 12 contracts. ZKPassport verifier: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8` (same address on all chains).

### 📦 Deployed Contracts (12 Total)

| # | Contract | Purpose |
|---|----------|---------|
| 1 | **Convexo_Passport** | NFT for individual investors (Tier 1 - ZKPassport) |
| 2 | **Limited_Partners_Individuals** | NFT for individual LP access (Tier 2 - Veriff KYC) |
| 3 | **Limited_Partners_Business** | NFT for business LP access (Tier 2 - Sumsub KYB) |
| 4 | **Ecreditscoring** | NFT for vault creators (Tier 3 - AI Credit Score) |
| 5 | **VeriffVerifier** | Privacy-enhanced individual KYC verification |
| 6 | **SumsubVerifier** | Privacy-enhanced business KYB verification |
| 7 | **ReputationManager** | User tier calculation system |
| 8 | **HookDeployer** | Helper for deploying hooks with correct addresses |
| 9 | **PassportGatedHook** | Uniswap V4 hook for gated pool access |
| 10 | **PoolRegistry** | Registry for compliant pools |
| 11 | **PriceFeedManager** | Chainlink price feed integration |
| 12 | **ContractSigner** | Multi-signature contract system |

---

## 🧪 Development

### Build
```bash
forge build
```

### Test
```bash
# Run all tests
forge test

# Verbose output
forge test -vvv

# With gas report
forge test --gas-report
```

**Test Results:** ✅ 87/87 tests passing (100% coverage)

### Available Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy.sh <network>` | Deploy contracts to any network |
| `scripts/update-addresses.sh <chain_id>` | Update addresses.json from broadcast |
| `scripts/verify-all.sh <chain_id>` | Verify all contracts on explorer |
| `scripts/extract-abis.sh` | Extract ABIs for frontend |

### Solidity Scripts

| Script | Purpose |
|--------|---------|
| `script/DeployDeterministic.s.sol` | Main deployment script (CREATE2) |
| `script/PredictAddresses.s.sol` | Preview addresses before deployment |

---

## 🚀 Deployment Guide

### Understanding Deterministic Deployment

Convexo uses **Deterministic Deployment** via [Safe Singleton Factory](https://github.com/safe-fndn/safe-singleton-factory) (CREATE2).

```
┌─────────────────────────────────────────────────────────────────┐
│  Q: Do I deploy once and it goes to all chains?                 │
│  A: NO. You must deploy SEPARATELY on EACH chain.               │
│                                                                  │
│  Q: Then why is it called "deterministic"?                      │
│  A: The ADDRESSES are deterministic (same on all chains)        │
│     because CREATE2 computes address from:                      │
│     • Factory address (same everywhere)                         │
│     • Salt (we use "convexo.v3.17")                             │
│     • Bytecode + constructor args                               │
│                                                                  │
│  Q: What's the benefit?                                         │
│  A: Frontend/backend can use ONE set of addresses for           │
│     core contracts across all chains.                           │
└─────────────────────────────────────────────────────────────────┘
```

**Contract Types:**

| Type | Addresses | Examples |
|------|-----------|----------|
| **Core (CREATE2)** | SAME on all chains | Convexo_Passport, LP_Individuals, ReputationManager |
| **Chain-Specific** | DIFFERENT per chain | VaultFactory, PassportGatedHook |

---

### Prerequisites

1. **Environment Setup**
   ```bash
   cp .env.example .env
   ```

2. **Configure `.env`**
   ```bash
   # Required
   PRIVATE_KEY=your_deployer_private_key
   MINTER_ADDRESS=your_minter_address

   # API Keys for verification
   ETHERSCAN_API_KEY=your_etherscan_api_key
   BASESCAN_API_KEY=your_basescan_api_key
   UNISCAN_API_KEY=your_uniscan_api_key
   ARBISCAN_API_KEY=your_arbiscan_api_key

   # RPC URLs (optional - has public fallbacks)
   ETHEREUM_SEPOLIA_RPC_URL=https://...
   BASE_SEPOLIA_RPC_URL=https://...
   UNICHAIN_SEPOLIA_RPC_URL=https://...
   ARBITRUM_SEPOLIA_RPC_URL=https://...
   ```

---

### Deployment Workflow

**Two-Step Process: Deploy First, Then Verify Separately**

```
  DEPLOY  ──▶  UPDATE ADDRESSES  ──▶  VERIFY  ──▶  EXTRACT ABIs
```

#### Step 0: Predict Addresses (Optional)

```bash
forge script script/PredictAddresses.s.sol -vvv
```

#### Step 1: Deploy to Each Chain

```bash
# Unified deploy script: ./scripts/deploy.sh <network>

# ═══════════════════ TESTNETS ═══════════════════
./scripts/deploy.sh ethereum-sepolia
./scripts/deploy.sh base-sepolia
./scripts/deploy.sh unichain-sepolia
./scripts/deploy.sh arbitrum-sepolia

# ═══════════════════ MAINNETS ═══════════════════
./scripts/deploy.sh ethereum
./scripts/deploy.sh base
./scripts/deploy.sh unichain
./scripts/deploy.sh arbitrum
```

**Note:** If contracts already exist at the computed addresses, they will be skipped automatically.

#### Redeploying After Contract Changes

If you modify contract code and need new addresses, bump the version:

```bash
# Option 1: Use environment variable (recommended)
DEPLOY_VERSION=convexo.v3.15 ./scripts/deploy.sh ethereum-sepolia

# Option 2: Edit default version in script/DeployDeterministic.s.sol
# Change: string public constant DEFAULT_VERSION = "convexo.v3.1";
```

Preview new addresses before deploying:
```bash
DEPLOY_VERSION=convexo.v3.1 forge script script/PredictAddresses.s.sol -vvv
```

#### Step 2: Update Addresses

```bash
./scripts/update-addresses.sh 11155111  # Ethereum Sepolia
./scripts/update-addresses.sh 84532     # Base Sepolia
./scripts/update-addresses.sh 1301      # Unichain Sepolia
./scripts/update-addresses.sh 421614    # Arbitrum Sepolia
```

#### Step 3: Verify Contracts

```bash
./scripts/verify-all.sh 11155111  # Ethereum Sepolia
./scripts/verify-all.sh 84532     # Base Sepolia
./scripts/verify-all.sh 1301      # Unichain Sepolia
./scripts/verify-all.sh 421614    # Arbitrum Sepolia

./scripts/verify-all.sh 1         # Ethereum Mainnet
./scripts/verify-all.sh 8453      # Base Mainnet
./scripts/verify-all.sh 130       # Unichain Mainnet
./scripts/verify-all.sh 42161     # Arbitrum One
```

#### Step 4: Extract ABIs

```bash
./scripts/extract-abis.sh
```

---

### Chain IDs Reference

| Network | Chain ID | Explorer |
|---------|----------|----------|
| Ethereum Sepolia | 11155111 | sepolia.etherscan.io |
| Base Sepolia | 84532 | sepolia.basescan.org |
| Unichain Sepolia | 1301 | unichain-sepolia.blockscout.com |
| Arbitrum Sepolia | 421614 | sepolia.arbiscan.io |
| Ethereum Mainnet | 1 | etherscan.io |
| Base Mainnet | 8453 | basescan.org |
| Unichain Mainnet | 130 | unichain.blockscout.com |
| Arbitrum One | 42161 | arbiscan.io |

---

### Deployment Checklist

#### Pre-Deployment
- [ ] Tests passing (`forge test`)
- [ ] `.env` configured (PRIVATE_KEY, MINTER_ADDRESS, API keys)
- [ ] Sufficient gas in deployer wallet

#### Post-Deployment (per chain)
- [ ] Deploy: `./scripts/deploy.sh <network>`
- [ ] Update: `./scripts/update-addresses.sh <chain_id>`
- [ ] Verify: `./scripts/verify-all.sh <chain_id>`
- [ ] Extract: `./scripts/extract-abis.sh`

---

## 📚 Documentation

### Core Documentation

| Document | Description |
|----------|-------------|
| **[CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md)** | 📖 Complete contract reference with all functions |
| **[FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)** | 💻 Frontend integration guide with code examples |
| **[ZKPASSPORT_FRONTEND_INTEGRATION.md](./ZKPASSPORT_FRONTEND_INTEGRATION.md)** | 🔐 ZKPassport integration guide |
| **[SECURITY_AUDIT.md](./SECURITY_AUDIT.md)** | 🛡️ Security features and audit information |

### Contract Resources
- **[addresses.json](./addresses.json)** - All deployed contract addresses in JSON format
- **[abis/](./abis/)** - Contract ABIs for frontend integration (12 ABIs)

---

## 💻 Frontend Integration

### Install Dependencies
```bash
npm install viem wagmi @rainbow-me/rainbowkit
```

### Check User Reputation
```typescript
import { useContractRead } from 'wagmi';
import ReputationManagerABI from './abis/ReputationManager.json';

function useUserTier(address: `0x${string}`) {
  const { data: tier } = useContractRead({
    address: REPUTATION_MANAGER_ADDRESS,
    abi: ReputationManagerABI,
    functionName: 'getReputationTier',
    args: [address],
  });

  return {
    tier, // 0, 1, 2, or 3
    canInvestInVaults: tier >= 1,
    canAccessLPPools: tier >= 2,
    canCreateVaults: tier === 3,
  };
}
```

**See [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md) for complete examples.**

---

## 🔐 Security

- ✅ **OpenZeppelin v5.5.0** audited contracts
- ✅ **Role-based access control** for admin functions
- ✅ **Soulbound NFTs** (non-transferable)
- ✅ **Uniswap V4 Hooks** for compliant pool access
- ✅ **Chainlink price feeds** for accurate conversions
- ✅ **Multi-signature** contract signing
- ✅ **Privacy-compliant** verification (no PII stored)
- ✅ **All contracts verified** on block explorers

---

## ✨ What's New in v3.17

### Breaking Changes
- **`faceMatchPassed` removed** from `safeMintWithVerification()` (was the 5th param) - now 5 params
- **`faceMatchPassed` removed** from `VerifiedIdentity` struct
- **Treasury deprecated** - TreasuryFactory and TreasuryVault contracts removed
- All addresses changed (version salt: `convexo.v3.17`)

### New in v3.17
1. **Arbitrum Support** - Added Arbitrum One (42161) + Arbitrum Sepolia (421614)
2. **Simplified Minting** - `safeMintWithVerification` now 5 params (no faceMatchPassed)
3. **Cleaner Architecture** - 12 contracts instead of 14 (Treasury removed)
4. **Organized src layout** - `src/contracts/identity/`, `credits/`, `trading/`

### 🏆 Tier System

| Tier | NFT Contract | User Type | Access Level | Minting Method |
|------|--------------|-----------|--------------|----------------|
| **Tier 0** | None | Unverified | No access | N/A |
| **Tier 1** | Convexo_Passport | Individual Investor | LP Pool Swaps + Vault investments | Self-mint via ZKPassport |
| **Tier 2** | Limited_Partners_Individuals | Limited Partner (Individual) | Monetization + Vault investments | Admin-mint via VeriffVerifier |
| **Tier 2** | Limited_Partners_Business | Limited Partner (Business) | Monetization + Vault investments | Admin-mint via SumsubVerifier |
| **Tier 3** | Ecreditscoring | Vault Creator | All above + Vault creation | Backend-mint with AI credit score |

**Note:** Highest tier wins (progressive KYC). Users can upgrade from Tier 1 to Tier 2/3.

### NFT Metadata & Images

| NFT Contract | IPFS URI | CID | Auto-Applied? |
|--------------|----------|-----|---------------|
| Convexo_Passport | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4) | `bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4` | ✅ Yes (hardcoded in contract) |
| Limited_Partners_Individuals | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em) | `bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em` | ✅ Yes (via VeriffVerifier) |
| Limited_Partners_Business | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m) | `bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m` | ✅ Yes (via SumsubVerifier) |
| Ecreditscoring | [View Image](https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e) | `bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e) | ⚠️ No (backend must pass URI) |

**Important:** All NFTs are soulbound (non-transferable) and limited to **one per address**.

### 🔒 Privacy-Compliant Verification

- Only verification **traits** stored on-chain (no PII)
- Stored traits: `kycVerified`, `sanctionsPassed`, `isOver18`
- No name, address, birthdate, face match, or biometric data stored

### 📊 Updated ReputationManager

Access control functions:
- `canInvestInVaults()` - Tier 1+
- `canAccessLPPools()` - Tier 2+
- `canCreateVaults()` - Tier 3

### 🔄 Progressive KYC

- Highest tier wins (no mutual exclusivity)
- Users can upgrade from individual to business verification
- Passport holders can later get LPs/Vaults NFTs

### ⚡ Vault Redemption

- Redemption requires **full repayment** when in Repaying state
- Early exit allowed when vault is Funded/Active (before borrower withdrawal)

---

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| **Version** | 3.17 (Arbitrum + simplified minting) |
| **Test Coverage** | 87/87 tests passing (100%) |
| **Contracts** | 12 contracts per network |
| **Networks Supported** | 4 mainnets, 4 testnets |
| **Verification Methods** | 3 paths (ZKPassport + Veriff + Sumsub) |
| **Investor Returns** | 12% APY |
| **Min Credit Score** | 70 (for vault creation) |
| **Protocol Fee** | 2% of principal (protected) |
| **Repayment** | Flexible (anytime before maturity) |
| **Privacy** | All verification data private (admin-only) ✅ |
| **Deterministic Deploy** | Same addresses on all chains ✅ |

---

## 🛠️ Technical Stack

- **Smart Contracts**: Solidity ^0.8.27
- **Development**: Foundry
- **Standards**: ERC-721, ERC-20
- **DEX Integration**: Uniswap V4 Hooks
- **Oracles**: Chainlink Price Feeds & CCIP
- **KYB/KYC**: Veriff + ZKPassport
- **AI Scoring**: Custom credit scoring engine

---

## 📖 How It Works

### 1. Compliance & NFT Issuance
```solidity
// Individual: ZKPassport verification
convexoPassport.safeMintWithIdentifier(uniqueIdentifier);

// Business: Veriff verification
veriffVerifier.approveVerification(businessAddress);
// → Automatically mints Convexo_LPs NFT
```

### 2. Reputation Check
```solidity
// System checks user tier
reputationManager.getReputationTier(user);
// Returns: None (0), Passport (1), LimitedPartner (2), VaultCreator (3)
```

### 3. Vault Creation (Tier 3)
```solidity
// Create funding vault after credit scoring
vaultFactory.createVault(
  principalAmount,
  interestRate,
  maturityDate,
  ...
);
```

### 4. Investment & Returns (Tier 1+)
```solidity
// Investor stakes USDC
vault.purchaseShares(1000e6); // 1000 USDC

// Check returns
vault.getInvestorReturn(investor);
// Returns: invested, currentValue, profit, apy
```

---

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines.

```bash
# Create a branch
git checkout -b feature/your-feature

# Make changes and test
forge test

# Commit and push
git commit -m "Add feature"
git push origin feature/your-feature
```

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) file for details.

---

## 🔗 Links

- **Website**: [convexo.finance](https://convexo.finance)
- **Documentation**: [docs.convexo.finance](https://docs.convexo.finance)
- **Twitter**: [@ConvexoFinance](https://twitter.com/ConvexoFinance)
- **Discord**: [Join Community](https://discord.gg/convexo)
- **GitHub**: [github.com/convexo-finance](https://github.com/convexo-finance)

---

## 📞 Support

- **Technical Issues**: Open an issue on GitHub
- **Contract Reference**: See [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md)
- **Frontend Integration**: See [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)
- **ZKPassport Integration**: See [ZKPASSPORT_FRONTEND_INTEGRATION.md](./ZKPASSPORT_FRONTEND_INTEGRATION.md)
- **Security**: See [SECURITY_AUDIT.md](./SECURITY_AUDIT.md)
- **General Questions**: Join our Discord

---

## 🎉 Status

**🆕 VERSION 3.17 - ARBITRUM SUPPORT + SIMPLIFIED MINTING COMPLETE**

All 12 contracts deployed, verified, and ready for production.

**Development Status:**
- ✅ 12 smart contracts implemented
- ✅ Comprehensive testing (87 tests, 100% coverage)
- ✅ Deployment scripts unified (deterministic via CREATE2)
- ✅ Documentation complete
- ✅ Security review complete
- ✅ Deployed on all 8 networks (4 mainnet + 4 testnet)

**Version 3.17 Features:**
- 🆕 **Arbitrum One + Sepolia** - 2 new networks added
- 🆕 **Simplified minting** - faceMatchPassed removed from passport flow
- 🆕 **Cleaner architecture** - Treasury deprecated, 12 contracts
- ✅ Privacy-Enhanced Verification - All data private (admin-only)
- ✅ SumsubVerifier - Separate KYB for businesses
- ✅ Multi-Admin Support - Multiple compliance officers
- ✅ Deterministic Deployment - Same addresses on all chains
- ✅ Minted Status - Track NFT minting after approval
- ✅ Progressive KYC - Upgrade from individual to business
- ✅ Borrower-initiated vault creation (Tier 3)
- ✅ Flexible repayment system

**Test Results:**
- ✅ NFT Tests: 37/37 passing
- ✅ Verifier Tests: 30/30 passing  
- ✅ Integration Tests: 20/20 passing
- ✅ Total: 87/87 tests passing (100% coverage)

---

<p align="center">Made with ❤️ for Latin American SMEs</p>

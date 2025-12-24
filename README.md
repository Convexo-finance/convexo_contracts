# Convexo Protocol

**Reducing the Gap funding for SMEs in Latin America using stablecoins, NFT-permissioned  liquidity pools and vaults.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-14%2F14%20Passing-brightgreen)](./test)
[![Deployed](https://img.shields.io/badge/Deployed-Base%20Mainnet-blue)](https://basescan.org)
[![Deployed](https://img.shields.io/badge/Deployed-Unichain%20Mainnet-success)](https://unichain.blockscout.com)

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
- Only holders of Convexo_LPs NFT can trade
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

### For SMEs (Borrowers)

#### Step 1: Compliance Verification
```
1. Submit KYB via Sumsub.com
2. Pass compliance checks
3. Receive Convexo_LPs NFT (Tier 1)
4. Can now use liquidity pools to convert USDC ↔ Local Stables
```

**Benefits:**
- Exchange USDC (from funded vaults) → Local stablecoins (ECOP, ARS, MXN)
- Top up account with local stables → Get USDC for operations

#### Step 2: Credit Scoring & Vault Creation
```
1. Submit financial statements & business model to AI
2. AI analyzes creditworthiness
3. If score > 70: Receive Convexo_Vaults NFT (Tier 2)
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

### For Investors (Lenders)

```
1. Connect wallet to testnet
2. Browse available vaults
3. Review: APY (12%), risk level, maturity date
4. Invest USDC in vault (purchase shares)
5. Track returns in real-time
6. Redeem shares anytime after borrower starts repaying
7. Receive principal + 12% returns proportionally
```

**Returns:**
- 12% APY on USDC investments
- Flexible withdrawal (anytime after repayments start)
- Transparent, on-chain tracking
- Proportional to repayments made

---

## 🏗️ Architecture

### Reputation Tiers

| Tier | NFTs Required | Access |
|------|---------------|--------|
| **Tier 0** | None | No access |
| **Tier 1** | Convexo_LPs | Liquidity pools access |
| **Tier 2** | Convexo_LPs + Convexo_Vaults | Full access (Create vaults) |

### Core Components

```
┌─────────────────────────────────────────────────────┐
│                  Compliance Layer                    │
│  Sumsub KYB → Admin → Convexo_LPs NFT (Tier 1)     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                 Liquidity Pools                      │
│  Uniswap V4 + CompliantLPHook                       │
│  USDC/ECOP, USDC/ARS, USDC/MXN                     │
│  (Only Tier 1+ can trade)                           │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│              AI Credit Scoring                       │
│  Financial Analysis → Score > 70 →                  │
│  Convexo_Vaults NFT (Tier 2)                        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│              Tokenized Bond Vaults                   │
│  • VaultFactory: Create funding vaults              │
│  • TokenizedBondVault: ERC20 share-based vaults     │
│  • Flexible repayment & independent withdrawals     │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Deployed Contracts

View contract addresses and verification links by network:

- **⟠ Ethereum**: [Ethereum Deployments](./ETHEREUM_DEPLOYMENTS.md) (Mainnet + Sepolia)
- **🔵 Base**: [Base Deployments](./BASE_DEPLOYMENTS.md) (Mainnet + Sepolia)
- **🦄 Unichain**: [Unichain Deployments](./UNICHAIN_DEPLOYMENTS.md) (Mainnet + Sepolia)

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

**Test Results:** ✅ 14/14 tests passing (VaultFlow complete)

---

## 🌐 Deployment Status

### 🚀 Mainnet Deployments

| Network | Chain ID | Contracts | Status | Explorer |
|---------|----------|-----------|--------|----------|
| **Base Mainnet** | 8453 | 9/9 | ✅ Complete | [BaseScan](https://basescan.org) |
| **Unichain Mainnet** | 130 | 9/9 | ✅ Complete | [Blockscout](https://unichain.blockscout.com) |
| **Ethereum Mainnet** | 1 | 0/9 | ⏳ Pending | [Etherscan](https://etherscan.io) |

### 🧪 Testnet Deployments

| Network | Chain ID | Contracts | Status | Explorer |
|---------|----------|-----------|--------|----------|
| **Ethereum Sepolia** | 11155111 | 9/9 | ✅ Verified | [Etherscan](https://sepolia.etherscan.io) |
| **Base Sepolia** | 84532 | 9/9 | ✅ Verified | [BaseScan](https://sepolia.basescan.org) |
| **Unichain Sepolia** | 1301 | 9/9 | ✅ Verified | [Blockscout](https://unichain-sepolia.blockscout.com) |

### 📦 Deployed Contracts (All Networks)

1. ✅ **Convexo_LPs** - NFT for liquidity pool access (Tier 1)
2. ✅ **Convexo_Vaults** - NFT for vault creation (Tier 2)
3. ✅ **HookDeployer** - Helper for deploying hooks with correct addresses
4. ✅ **CompliantLPHook** - Uniswap V4 hook for gated pool access
5. ✅ **PoolRegistry** - Registry for compliant pools
6. ✅ **ReputationManager** - User tier calculation system
7. ✅ **PriceFeedManager** - Chainlink price feed integration
8. ✅ **ContractSigner** - Multi-signature contract system
9. ✅ **VaultFactory** - Factory for creating tokenized bond vaults

**Total: 9 Smart Contracts | All Verified ✅**

---

## 🧪 Development

### Build
```bash
forge build
```

### Test
```bash
forge test -vvv
```

### Deploy
```bash
# Ethereum Sepolia
./scripts/deploy_ethereum_sepolia.sh

# Base Sepolia
./scripts/deploy_base_sepolia.sh

# Unichain Sepolia
./scripts/deploy_unichain_sepolia.sh
```

### Verify Contracts 
```bash
# Verify all contracts on a network
./scripts/verify_all.sh sepolia
./scripts/verify_all.sh base-sepolia
./scripts/verify_all.sh unichain-sepolia
```

### Extract ABIs
```bash
./scripts/extract-abis.sh
```

ABIs saved to `abis/` directory for frontend integration.

---

## 📚 Documentation

### Core Documentation
| Document | Description |
|----------|-------------|
| **[CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md)** | 📖 Complete contract reference with all functions and usage |
| **[FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)** | 💻 Frontend integration guide with code examples |
| **[SECURITY_AUDIT.md](./SECURITY_AUDIT.md)** | 🔐 Security features and audit information |

### Deployment Documentation by Chain
| Network | Documentation |
|---------|---------------|
| **⟠ Ethereum** | [ETHEREUM_DEPLOYMENTS.md](./ETHEREUM_DEPLOYMENTS.md) |
| **🔵 Base** | [BASE_DEPLOYMENTS.md](./BASE_DEPLOYMENTS.md) |
| **🦄 Unichain** | [UNICHAIN_DEPLOYMENTS.md](./UNICHAIN_DEPLOYMENTS.md) |

### Contract Resources
- **[addresses.json](./addresses.json)** - All deployed contract addresses in JSON format
- **[abis/](./abis/)** - Contract ABIs for frontend integration (10 ABIs)

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
    address: '0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1',
    abi: ReputationManagerABI,
    functionName: 'getReputationTier',
    args: [address],
  });

  return {
    tier, // 0, 1, or 2
    canUsePools: tier >= 1,
    canCreateVaults: tier >= 2,
  };
}
```

### Browse Vaults
```typescript
import VaultFactoryABI from './abis/VaultFactory.json';

function useVaults() {
  const { data: count } = useContractRead({
    address: '0xDe8daB3182426234ACf68E4197A1eDF5172450dD',
    abi: VaultFactoryABI,
    functionName: 'getVaultCount',
  });

  // Get each vault address...
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
- ✅ **All contracts verified** on block explorers

---

## 🌐 Networks

### Testnet (Current)

#### Ethereum Sepolia (Chain ID: 11155111)
- RPC: https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
- Explorer: https://sepolia.etherscan.io
- Faucet: https://sepoliafaucet.com
- **Uniswap V4:** ✅ Available
- **USDC:** `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **ECOP:** `0x19ac2612e560b2bbedf88660a2566ef53c0a15a1`

#### Base Sepolia (Chain ID: 84532)
- RPC: https://sepolia.base.org
- Explorer: https://sepolia.basescan.org
- Faucet: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
- **Uniswap V4:** ✅ Available
- **USDC:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **ECOP:** `0xb934dcb57fb0673b7bc0fca590c5508f1cde955d`

#### Unichain Sepolia (Chain ID: 1301)
- RPC: https://sepolia.unichain.org
- Explorer: https://sepolia.uniscan.xyz
- **Uniswap V4:** ✅ Available
- **USDC:** `0x31d0220469e10c4E71834a79b1f276d740d3768F`
- **ECOP:** `0xbb0d7c4141ee1fed53db766e1ffcb9c618df8260`

### Mainnet (Future)
- Base Mainnet
- Optimism
- Arbitrum

---

## 🎯 Use Cases

### 1. Currency Conversion
```
SME receives $50,000 USDC from vault
→ Swap USDC for ECOP in compliant pool (Uniswap V4)
→ Use local currency (ECOP, ARS, MXN) for operations
→ Only Tier 1+ users can access pools
```

### 2. Working Capital Loan (Tokenized Bond Vault)
```
SME needs $50k for inventory
→ AI scores credit (>70) → Receives Tier 2 NFT
→ Creates vault via VaultFactory
→ Investors fund vault (purchase shares)
→ Contract created and signed by all parties
→ SME withdraws $50k
→ SME repays gradually: $50k + $6k (12%) + $1k (2% fee) = $57k total
→ Protocol collector withdraws $1k fee (anytime)
→ Investors redeem shares for $56k total (anytime after repayments start)
→ Each party withdraws independently
```

---

## ✨ What's New in v2.2

### 🔒 Critical Security Fix: Protocol Fee Protection
- **FIXED**: Investors can no longer withdraw protocol fees
- **NEW**: `_calculateReservedProtocolFees()` - Internal function to calculate reserved fees
- **NEW**: `getAvailableForInvestors()` - Public view function showing funds available for investors
- **CHANGED**: `redeemShares()` now excludes protocol fees from available balance
- **BENEFIT**: Protocol fees are protected and guaranteed for the protocol

### 📊 Vault Timeline Tracking (v2.1)
- **NEW**: Complete timestamp tracking for all vault milestones
- `getVaultCreatedAt()` - When vault was created
- `getVaultFundedAt()` - When vault reached full funding
- `getVaultContractAttachedAt()` - When contract was attached
- `getVaultFundsWithdrawnAt()` - When borrower withdrew funds
- `getActualDueDate()` - Calculated due date based on withdrawal time

### ✅ Improved Vault Completion Logic (v2.1)
- **CHANGED**: Vault state now changes to `Completed` only when:
  - ✅ All debt is repaid (principal + interest + protocol fee)
  - ✅ **AND** all funds withdrawn by protocol collector & investors
  - ✅ Vault balance < 0.0001 USDC (dust)
- **BENEFIT**: More accurate vault lifecycle tracking

### 🧪 Enhanced Testing
- **NEW**: `testProtocolFeesAreProtectedFromInvestorRedemption()` - Comprehensive test
- **RESULT**: 15/15 tests passing (100% coverage)

---

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| **Version** | 2.2 (Security Enhanced) |
| **Test Coverage** | 15/15 tests passing (100%) |
| **Contracts Deployed** | 9 contracts per network |
| **Networks Supported** | 2 mainnets, 3 testnets (Base, Unichain, Ethereum/Base/Unichain Sepolia) |
| **Investor Returns** | 12% APY |
| **Min Credit Score** | 70 (for vault creation) |
| **Protocol Fee** | 2% of principal (protected) |
| **Repayment** | Flexible (anytime before maturity) |
| **Security** | Protocol fees protected from investor withdrawals ✅ |

---

## 🛠️ Technical Stack

- **Smart Contracts**: Solidity ^0.8.27
- **Development**: Foundry
- **Standards**: ERC-721, ERC-20, ERC-4626
- **DEX Integration**: Uniswap V4 Hooks
- **Oracles**: Chainlink Price Feeds & CCIP
- **Compliance**: Sumsub KYB
- **AI Scoring**: Custom credit scoring engine

---

## 📖 How It Works

### 1. Compliance & NFT Issuance
```solidity
// Admin mints NFT after KYB verification
convexoLPs.safeMint(smeAddress, companyId, "ipfs://...");
```

### 2. Reputation Check
```solidity
// System checks user tier
reputationManager.getReputationTier(user);
// Returns: 0 (None), 1 (Compliant), 2 (Creditscore)
```

### 3. Liquidity Pool Access
```solidity
// Hook verifies NFT before swap
if (convexoLPs.balanceOf(user) == 0) revert Unauthorized();
// Only holders can trade
```

### 4. Vault Creation
```solidity
// Create funding vault after credit scoring
vaultFactory.createVault(
  borrower,
  principalAmount,
  interestRate,
  maturityDate,
  ...
);
```

### 5. Investment & Returns
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
- **Security**: See [SECURITY_AUDIT.md](./SECURITY_AUDIT.md)
- **General Questions**: Join our Discord

---

## 🎉 Status

**✅ FULLY DEPLOYED & VERIFIED ON ALL NETWORKS**

All 9 contracts successfully deployed and verified across 3 testnets with the new vault flow.

**Deployment Status:**

**Mainnets:**
- 🚀 Base Mainnet: 9/9 contracts verified ✅
- 🚀 Unichain Mainnet: 9/9 contracts verified ✅
- ⏳ Ethereum Mainnet: Ready to deploy (pending funding)

**Testnets:**
- ✅ Ethereum Sepolia: 9/9 contracts verified
- ✅ Base Sepolia: 9/9 contracts verified  
- ✅ Unichain Sepolia: 9/9 contracts verified
- ✅ All tests passing (14/14 VaultFlow tests)
- ✅ ABIs extracted and ready for frontend

**Version 2.0 Features:**
- ✅ Borrower-initiated vault creation (requires Tier 2 NFT)
- ✅ Flexible repayment system (pay anytime, any amount)
- ✅ Independent withdrawals for all parties
- ✅ Protocol fees locked in vault until withdrawn
- ✅ Investors can redeem anytime after repayments start
- ✅ Contract signing flow integrated

**Ready for:** Frontend integration and user testing 🚀

---

<p align="center">Made with ❤️ for Latin American SMEs</p>

# Convexo Protocol

**Reducing the Gap funding for SMEs in Latin America using stablecoins, NFT-permissioned  liquidity pools and vaults.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-49%2F49%20Passing-brightgreen)](./test)
[![Deployed](https://img.shields.io/badge/Deployed-Base%20Sepolia-blue)](https://sepolia.basescan.org)

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

### 3. Two Product Lines

#### Product 1: Invoice Factoring
- SMEs sell unpaid invoices for immediate liquidity
- Investors buy at discount, earn on maturity
- **Requirement**: Tier 1 (Compliant NFT)

#### Product 2: Tokenized Bond Credits
- SMEs get loans backed by daily cash flow
- Repay gradually with business revenue
- **Requirement**: Tier 2 (Both NFTs: Compliant + Creditscore)

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
4. Create vault to represent loan request
5. Get funded by international investors
6. Repay with business cash flow
```

**Flow:**
```
Apply → AI Score → NFT (if > 70) → Create Vault → Get Funded → Repay → Complete
```

### For Investors (Lenders)

```
1. Connect wallet to Base Sepolia
2. Browse available vaults
3. Review: APY, risk level, maturity date
4. Invest USDC in vault
5. Track returns in real-time
6. Redeem with profit at maturity
```

**Returns:**
- 10-12% APY on USDC investments
- Transparent, on-chain tracking
- Automated distribution

---

## 🏗️ Architecture

### Reputation Tiers

| Tier | NFTs Required | Access |
|------|---------------|--------|
| **Tier 0** | None | No access |
| **Tier 1** | Convexo_LPs | Liquidity pools + Invoice factoring |
| **Tier 2** | Convexo_LPs + Convexo_Vaults | Full access (Bonds + Credits) |

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
│                Vault & Products                      │
│  • VaultFactory: Create funding vaults              │
│  • InvoiceFactoring: Sell unpaid invoices           │
│  • TokenizedBondCredits: Cash flow-backed loans     │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Deployed Contracts

### Base Sepolia (Chain ID: 84532)

| Contract | Address | Purpose |
|----------|---------|---------|
| **Convexo_LPs** | [`0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d`](https://sepolia.basescan.org/address/0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d) | Tier 1 NFT (Compliant) |
| **Convexo_Vaults** | [`0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5`](https://sepolia.basescan.org/address/0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5) | Tier 2 NFT (Creditscore) |
| **ReputationManager** | [`0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1`](https://sepolia.basescan.org/address/0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1) | Calculate user tier |
| **VaultFactory** | [`0xDe8daB3182426234ACf68E4197A1eDF5172450dD`](https://sepolia.basescan.org/address/0xDe8daB3182426234ACf68E4197A1eDF5172450dD) | Create funding vaults |
| **InvoiceFactoring** | [`0xbc4023284D789D7EB8512c1EDe245C77591a5D96`](https://sepolia.basescan.org/address/0xbc4023284D789D7EB8512c1EDe245C77591a5D96) | Invoice liquidation |
| **TokenizedBondCredits** | [`0xC058588A8D82B2E2129119B209c80af8bF3d4961`](https://sepolia.basescan.org/address/0xC058588A8D82B2E2129119B209c80af8bF3d4961) | Bond credit loans |
| **PoolRegistry** | [`0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50`](https://sepolia.basescan.org/address/0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50) | Track compliant pools |
| **PriceFeedManager** | [`0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2`](https://sepolia.basescan.org/address/0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2) | Chainlink price feeds |
| **ContractSigner** | [`0x87af0C8203C84192dBf07f4B6D934fD00eB3F723`](https://sepolia.basescan.org/address/0x87af0C8203C84192dBf07f4B6D934fD00eB3F723) | Multi-sig agreements |

**✅ All contracts verified on BaseScan**

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
cd convexo-protocol/Counter
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

**Test Results:** ✅ 49/49 tests passing

---

## 🧪 Development

### Build
```bash
forge build
```

### Deploy
```bash
# Deploy to Base Sepolia
forge script script/DeployAll.s.sol \
  --rpc-url base_sepolia \
  --broadcast \
  --verify \
  --legacy
```

### Extract ABIs
```bash
./scripts/extract-abis.sh
```

ABIs saved to `abis/` directory for frontend integration.

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)** | Complete guide for frontend developers with code examples |
| **[CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md)** | Detailed reference for all contract functions |
| **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** | Step-by-step deployment to any network |
| **[addresses.json](./addresses.json)** | All deployed contract addresses |

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
- **Base Sepolia** (Chain ID: 84532)
- RPC: https://sepolia.base.org
- Explorer: https://sepolia.basescan.org
- Faucet: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

### Mainnet (Future)
- Base Mainnet
- Optimism
- Arbitrum

---

## 🎯 Use Cases

### 1. Currency Conversion
```
SME receives $50,000 USDC from investors
→ Swap USDC for ECOP in compliant pool
→ Use local currency for operations
```

### 2. Invoice Factoring
```
SME has $100k invoice due in 60 days
→ List on InvoiceFactoring
→ Sell to investors for $95k immediately
→ Investors earn $5k profit after 60 days
```

### 3. Working Capital Loan
```
SME needs $50k for inventory
→ AI scores credit (>70)
→ Creates vault via VaultFactory
→ Investors fund vault
→ SME repays gradually with revenue
→ Investors earn 12% APY
```

---

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| **Test Coverage** | 49/49 tests passing (100%) |
| **Contracts Deployed** | 9 contracts |
| **Networks Supported** | Base Sepolia (+ 2 others for NFTs) |
| **Target APY** | 10-12% for investors |
| **Min Credit Score** | 70 (for vault creation) |
| **Protocol Fee** | 2% |

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
- **Frontend Integration**: See [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md)
- **Deployment Help**: See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- **General Questions**: Join our Discord

---

## 🎉 Status

**✅ READY FOR FRONTEND DEVELOPMENT**

All contracts are deployed, tested (49/49 passing), verified on BaseScan, and ready for integration.

**Start building**: Check [FRONTEND_INTEGRATION.md](./FRONTEND_INTEGRATION.md) for complete code examples!

---

<p align="center">Made with ❤️ for Latin American SMEs</p>

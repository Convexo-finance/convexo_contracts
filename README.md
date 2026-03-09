# Convexo Protocol

Compliant on-chain lending infrastructure connecting international investors with Latin American SMEs via stablecoins, NFT-permissioned liquidity pools, and tokenized bond vaults.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-122%2F122%20Passing-brightgreen)](./test)
[![Version](https://img.shields.io/badge/Version-3.17-purple)](./docs/CONTRACTS_REFERENCE.md)

---

## Tier System

| Tier | NFT | Verification | Access |
|------|-----|--------------|--------|
| **0** | None | — | No access |
| **1** | Convexo_Passport | ZKPassport (self-mint) | LP pool swaps + vault investments |
| **2** | LP_Individuals | Veriff KYC (admin-mint) | Tier 1 + credit score request + OTC |
| **2** | LP_Business | Sumsub KYB (admin-mint) | Tier 1 + credit score request + OTC |
| **3** | Ecreditscoring | AI credit score (backend-mint) | All above + vault creation |

Highest tier wins. Users upgrade progressively (1 → 2 → 3).

---

## Contract Structure

```
src/contracts/
  identity/    Convexo_Passport, LP_Individuals, LP_Business, Ecreditscoring,
               ReputationManager, VeriffVerifier, SumsubVerifier
  credits/     VaultFactory, TokenizedBondVault (ERC-7540), ContractSigner, Ecreditscoring
  hooks/       PassportGatedHook, BaseHook, HookDeployer, PoolRegistry, PriceFeedManager
src/interfaces/  All interfaces (flat)
script/          DeployDeterministic.s.sol, PredictAddresses.s.sol
scripts/         deploy.sh, verify-all.sh, update-addresses.sh, extract-abis.sh
test/            122 tests across 9 suites
```

**Supported networks:** Ethereum (1, 11155111) · Base (8453, 84532) · Unichain (130, 1301) · Arbitrum (42161, 421614)

**Deployment:** Deterministic via CREATE2 — same addresses on all chains (salt `convexo.v3.17`). VaultFactory and hook contracts are chain-specific.

---

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Install dependencies
forge install

# Configure
cp .env.example .env   # add PRIVATE_KEY, MINTER_ADDRESS, API keys

# Build & test
forge build
forge test
```

---

## Deployment Workflow

```
forge build → forge test → deploy → update-addresses → verify → extract-abis
```

```bash
# 1. Deploy (repeat for each network)
./scripts/deploy.sh ethereum-sepolia
./scripts/deploy.sh base-sepolia
./scripts/deploy.sh unichain-sepolia
./scripts/deploy.sh arbitrum-sepolia
# mainnets: ethereum | base | unichain | arbitrum

# 2. Update addresses.json
./scripts/update-addresses.sh 11155111   # ethereum-sepolia
./scripts/update-addresses.sh 84532      # base-sepolia

# 3. Verify on explorer
./scripts/verify-all.sh 11155111
./scripts/verify-all.sh 84532

# 4. Extract ABIs for frontend
./scripts/extract-abis.sh
```

To redeploy after code changes, bump the version salt in `script/DeployDeterministic.s.sol` or pass `DEPLOY_VERSION=convexo.vX.XX ./scripts/deploy.sh <network>`.

---

## Documentation

| Doc | Contents |
|-----|----------|
| [CONTRACTS_REFERENCE.md](./docs/CONTRACTS_REFERENCE.md) | All contract functions, events, structs, access roles |
| [FRONTEND_INTEGRATION.md](./docs/FRONTEND_INTEGRATION.md) | ABIs, wagmi hooks, ZKPassport flow, vault ERC-7540 integration |
| [SECURITY_AUDIT.md](./docs/SECURITY_AUDIT.md) | Security model, access control, audit notes |
| [PINATA_NFT_METADATA.md](./docs/PINATA_NFT_METADATA.md) | IPFS metadata format for each NFT type |
| [uniswapv4/deployments.md](./docs/uniswapv4/deployments.md) | Hook deployment addresses and pool setup |
| [addresses.json](./addresses.json) | All deployed contract addresses by chain |
| [abis/](./abis/) | Contract ABIs (15 files) |

---

## Security

- OpenZeppelin v5.5 audited contracts
- Role-based access control on all admin functions
- Soulbound NFTs (ERC-721, non-transferable)
- Privacy-compliant: no PII stored on-chain (only verification traits)
- ERC-7540 async redemption — proportional burn prevents stranded funds
- ReentrancyGuard on all vault state-changing functions

---

*MIT License · [convexo.finance](https://convexo.finance)*

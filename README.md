# Convexo Protocol

Compliant on-chain lending infrastructure connecting international investors with Latin American SMEs via stablecoins, NFT-permissioned liquidity pools, and tokenized bond vaults.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-172%2F172%20Passing-brightgreen)](./test)
[![Version](https://img.shields.io/badge/Version-3.21-purple)](./CHANGELOG.md)

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
  hooks/       PassportGatedHook, HookDeployer, PoolRegistry, PriceFeedManager
               BaseHook (abstract base — not deployed, inherited by PassportGatedHook)
src/interfaces/  All interfaces (flat)
script/          DeployDeterministic.s.sol, PredictAddresses.s.sol
scripts/         deploy.sh, verify-all.sh, update-addresses.sh, extract-abis.sh
test/            122 tests across 9 suites
```

**Supported networks:** Ethereum (1, 11155111) · Base (8453, 84532) · Unichain (130, 1301) · Arbitrum (42161, 421614)

**Deployment:** Deterministic via CREATE2 — same addresses on all chains (salt `convexo.v3.18`). VaultFactory and hook contracts are chain-specific (hooks must have correct Uniswap permission bits in their address).

### Live Pools (Phase 1)

| Network | Hook | Status |
|---------|------|--------|
| ETH Sepolia (11155111) — **PRIMARY TESTNET** | `0xd3f980f48638783a8324ff99301028f08bda8a80` | ✅ LIVE — 6,250 USDC + 500 USDC backstop (LP tokenId 26391) |
| Base Sepolia (84532) | `0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80` | ✅ Seeded (no ZKPassport verifier — secondary) |
| Base Mainnet (8453) | `0x04E3281B87321aD1dCF9ed9edB9BeE6268EB12f3` | Pool pending |

ETH Sepolia is the primary testnet because the ZKPassport verifier (`0x1D000001000EFD9a6371f4d90bB8920D5431c0D8`) is deployed on ETH Mainnet, ETH Sepolia, and Base Mainnet — but NOT Base Sepolia.

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
forge test --gas-report
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

### Pool setup scripts (after Phase 1 deploy)

```bash
# Mint test NFT (deployer needs NFT to pass hook KYC check when adding liquidity)
LP_INDIVIDUALS_ADDRESS=0xE244e4B2B37EA6f6453d3154da548e7f2e1e5Df3 \
  forge script script/MintTestNFT.s.sol --rpc-url $RPC --broadcast

# If hook has wrong address bits: redeploy with correct 0x0A80 bits
forge script script/RedeployPassportGatedHook.s.sol --rpc-url $RPC --broadcast

# Initialize USDC/ECOP pool at rate 3650
HOOK_ADDRESS=<hook> TOKEN0=<usdc> TOKEN1=<ecop> RATE=3650 \
  forge script script/InitializePool.s.sol --rpc-url $RPC --broadcast

# Add concentrated liquidity ±5%
HOOK_ADDRESS=<hook> TOKEN0=<usdc> TOKEN1=<ecop> RATE=3650 AMOUNT0=6250000000 \
  forge script script/AddLiquidity.s.sol --rpc-url $RPC --broadcast

# Add full-range backstop (500 USDC)
HOOK_ADDRESS=<hook> TOKEN0=<usdc> TOKEN1=<ecop> RATE=3650 AMOUNT0=500000000 \
  FULL_RANGE=true SKIP_ALLOW_ROUTER=true \
  forge script script/AddLiquidity.s.sol --rpc-url $RPC --broadcast

# Allow Universal Router for swaps
HOOK=<hook> UNIVERSAL_ROUTER=<router> RPC=<rpc> bash scripts/allow-router.sh
```

---

## Hook Redeploy Guide (ETH Sepolia)

Run this whenever the hook needs to be redeployed — for example, after the `ReputationManager` address changes.

**Why the hook must be redeployed:** The `ReputationManager` address is baked in at construction time (`immutable`). There is no upgrade path — a new hook contract must be deployed and a new pool initialized.

### Prerequisites

Your `.env` must have:
```
PRIVATE_KEY=0x...
ETHEREUM_SEPOLIA_RPC_URL=https://...
USDC_ADDRESS_ETHSEPOLIA=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
ECOP_ADDRESS_ETHSEPOLIA=0x19ac2612e560b2bbedf88660a2566ef53c0a15a1
```

The deployer EOA must hold the **LP_Individuals NFT** (`0xE244e4B2B37EA6f6453d3154da548e7f2e1e5Df3`) — this is required to pass the hook's own KYC gate when adding liquidity.

### Step 1 — Deploy the new hook

```bash
./scripts/redeploy-hook.sh
```

The script iterates CREATE2 salts until it finds an address whose lower 14 bits equal `0x0A80` (Uniswap V4 permission requirement). Copy the address printed on the line:

```
[SUCCESS] PassportGatedHook deployed at: 0x...
```

Export it for the remaining steps:

```bash
export NEW_HOOK=0x<address from above>
```

### Step 2 — Allow the Universal Router

The Universal Router (`0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b`) handles swaps. The Position Manager (`0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4`) handles liquidity. Both must be whitelisted on the new hook.

```bash
# Universal Router (swaps)
NEW_HOOK=$NEW_HOOK ./scripts/allow-router.sh

# Position Manager (add/remove liquidity)
NEW_HOOK=$NEW_HOOK ROUTER=0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4 \
  ./scripts/allow-router.sh
```

Each command prints `true` at the end to confirm the router is now allowed.

### Step 3 — Initialize the pool

```bash
NEW_HOOK=$NEW_HOOK ./scripts/pool-init.sh
```

This creates the USDC/ECOP pool at **rate 3650 COP/USDC** using the new hook. The pool is identified by `(currency0, currency1, fee=500, tickSpacing=10, hook)` — changing the hook means a completely new pool.

> Note: V4 automatically orders `currency0 < currency1` by address. On ETH Sepolia, ECOP (`0x19ac...`) < USDC (`0x1c7D...`), so ECOP is `currency0` and USDC is `currency1`. The script handles this automatically.

### Step 4 — Seed liquidity

```bash
# Concentrated ±5% range — 6,250 USDC (main depth)
NEW_HOOK=$NEW_HOOK ./scripts/pool-add-liquidity.sh 6250000000

# Full-range backstop — 500 USDC (prevents breakdown if price moves outside band)
NEW_HOOK=$NEW_HOOK FULL_RANGE=true ./scripts/pool-add-liquidity.sh 500000000
```

### Step 5 — Update addresses.json

After liquidity is added, update `addresses.json` for chain `11155111`:

1. Move the current `passport_gated_hook.address` into `passport_gated_hook.deprecated`
2. Set `passport_gated_hook.address` to `$NEW_HOOK`
3. Update `usdc_ecop_pool.hook` to `$NEW_HOOK`
4. Set `usdc_ecop_pool.status` to `"LIVE — concentrated 6250 USDC + full-range backstop 500 USDC"`

### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `HookAddressNotValid` on pool init | Hook address bits don't match permissions | The redeploy script always finds a valid address — this shouldn't happen |
| `RouterNotAllowed` on add liquidity | Position Manager not yet whitelisted | Run Step 2 for `0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4` |
| `MustHaveKYCVerification` on add liquidity | Deployer EOA has no NFT | Mint LP_Individuals NFT first: `forge script script/MintTestNFT.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast` |
| `Pool already initialized` on pool init | Pool with this hook already exists | Skip Step 3, go straight to Step 4 |
| `NEW_HOOK not set` | Forgot to export after Step 1 | `export NEW_HOOK=0x...` |

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

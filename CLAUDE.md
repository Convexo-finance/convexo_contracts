# Convexo Contracts — AI Context (CLAUDE.md)

This file is the single source of truth for AI agents working on `convexo_contracts/`.
Read this before touching any contract. Update it when you change architecture.

---

## Repository layout

```
convexo_contracts/
├── src/contracts/
│   ├── identity/          — Soulbound NFTs, verifiers, reputation
│   ├── credits/           — VaultFactory, TokenizedBondVault
│   ├── hooks/             — Uniswap V4 hooks
│   │   ├── libraries/     — OracleMath (sqrtPrice ↔ oracle conversions)
│   ├── oracles/           — PriceFeedManager, ManualPriceAggregator
│   └── interfaces/        — Shared interfaces
├── script/
│   ├── DeployDeterministic.s.sol        — Phase 1 deploy (all 13 core contracts)
│   ├── RedeployPassportGatedHook.s.sol  — Redeploy hook with correct v4-core bits
│   ├── InitializePool.s.sol             — Pool init (RATE env var, computes sqrtPriceX96)
│   ├── AddLiquidity.s.sol               — Add liquidity (MINT_POSITION + LiquidityAmounts)
│   ├── MintTestNFT.s.sol                — Mint LP_Individuals NFT on testnet
│   └── PredictAddresses.s.sol           — Predict CREATE2 addresses before deploy
├── test/                  — Foundry tests (run: forge test)
├── broadcast/             — Forge broadcast artifacts (auto-generated on deploy)
├── addresses.json         — Canonical deployed addresses per chain
└── CHANGELOG.md           — Version history
```

---

## Deploy phases

### Phase 1 — DEPLOYED (all 7 chains, version convexo.v3.18)
Script: `script/DeployDeterministic.s.sol`
All chains: 8453 (Base), 130 (Unichain), 84532 (Base Sepolia), 11155111 (Eth Sepolia), 1301 (Uni Sepolia), 421614 (Arb Sepolia), 1 (ETH Mainnet)

| Contract | Address (all chains same via CREATE2) |
|---|---|
| Convexo_Passport | `0x648D128c117bC83aEAAd408ab69F0E5cb6291790` |
| LP_Individuals | `0xE244e4B2B37EA6f6453d3154da548e7f2e1e5Df3` |
| LP_Business | `0x70cFe52560Dc2DD981d2374bB6b01c2170E5597B` |
| Ecreditscoring | `0xa448Aa6bfd5bA16BBd756cAF8E2cd68b31b51D88` |
| VeriffVerifier | `0x5B9808554B793923ba6C6470910373ac307CeB8E` |
| SumsubVerifier | `0x51056F2F2aa64b439E3b9e46C1AcaAE70C5B7EFA` |
| ReputationManager | `0x50b81F36a95E1363288Ef44aD7E48A8CaCDFa349` |
| ContractSigner | `0x5ece4eE045Ff2115fE5d89e7fe277e676EDABD78` |
| PoolRegistry | `0xbab36fC5d44d95d57F378e40C538352FfEe2c5A2` |
| PriceFeedManager | `0xc1CE80A34C9d4B171a0B9873b296c95a7189De66` |
| HookDeployer | `0x69068b03dDb9Ca72B532dB694F075D91e08fB402` |
| PassportGatedHook | per-chain (see addresses.json) — Base Sepolia redeployed 2026-04-10, ETH Sepolia redeployed 2026-04-11 |
| VaultFactory | per-chain (see addresses.json) |

**ETH Sepolia PassportGatedHook (current — PRIMARY TESTNET):** `0xA4c7d0f1bb255460C7b3CBE9910318CB57Cb8A80`
Note: old hook `0x6B5659...` had extra `afterInitialize` bit set in address but not implemented → `InvalidHookResponse()` on pool init. Redeployed via `RedeployPassportGatedHook.s.sol`.

**Base Sepolia PassportGatedHook (secondary testnet):** `0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80`
Note: ZKPassport verifier is NOT deployed on Base Sepolia — cannot run full KYC flow there.

### USDC/ECOP Pool — ETH Sepolia LIVE (2026-04-11) — PRIMARY TESTNET
Pool initialized at rate 3650 COP/USDC. Two positions seeded:
- Concentrated ±5%: 6,250 USDC (main depth — captures all swaps within band)
- Full-range backstop: 500 USDC (prevents breakdown if price moves beyond main range)
Universal Router `0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b` is on the allowlist ✅
Access: Tier >= 1 (Convexo Passport) can swap.

### USDC/ECOP Pool — Base Sepolia (2026-04-10) — secondary testnet
Pool initialized and seeded identically. No ZKPassport verifier → use ETH Sepolia for full KYC+swap flow.

### Phase 2 — NOT DEPLOYED (ConvexoPoolHook with oracle price band)
Script: `script/DeployPhase2.s.sol` — **DOES NOT EXIST YET, needs to be written**
Current testnet uses PassportGatedHook (no oracle price band). ConvexoPoolHook adds that.

| Contract | Status |
|---|---|
| ManualPriceAggregator | Built, tested, not deployed |
| ConvexoHookDeployer | Built, tested, not deployed |
| ConvexoPoolHook | Built, tested, not deployed |

Phase 2 deploy sequence:
1. Write `script/DeployPhase2.s.sol`
2. Deploy `ManualPriceAggregator(admin, 8, "USDC / COP")`
3. Deploy `ConvexoHookDeployer`
4. Call `priceFeedManager.setPriceFeed(USDC_COP, manualAggregator, 26 hours)`
5. Call `convexoHookDeployer.findSalt(...)` off-chain to get valid CREATE2 salt (bits must be 0x1A80)
6. Call `convexoHookDeployer.deploy(...)` with that salt → `ConvexoPoolHook`
7. Call `manualAggregator.setPrice(420000000000)` (4200.00000000 COP/USDC, 8 decimals)
8. `depositReserve(USDC, 500e6)` + `depositReserve(ECOP, 2_100_000e18)` on hook
9. Run `InitializePool.s.sol` to create the USDC/ECOP pool
10. `grantRole(KEEPER_ROLE, keeperEOA)` on ConvexoPoolHook

Pool config: USDC(6dec)/ECOP(18dec), fee=500, tickSpacing=10, bandBps=200, cooldown=1h

---

## Contract architecture

### Identity layer (Phase 1)

```
Convexo_Passport   — Soulbound NFT. Only minted via claimPassport() with ZKPassport ZK proof.
                     Domain: "protocol.convexo.xyz", Scope: "convexo-passport-identity"
                     No admin mint. Proof binds msg.sender + chainId. Age>=18, sanctions, nationality.
                     REVOKER_ROLE can revoke.

LP_Individuals     — Soulbound NFT for KYC'd individuals. Minted by VeriffVerifier webhook.
LP_Business        — Soulbound NFT for KYB'd businesses. Minted by SumsubVerifier webhook.
Ecreditscoring     — Soulbound NFT for credit-scored businesses. Minted by backend (n8n AI).

VeriffVerifier     — Webhook from Veriff → mints LP_Individuals.
SumsubVerifier     — Webhook from Sumsub → mints LP_Business.

ReputationManager  — Aggregates NFT holdings into a tier:
                     None=0, Tier1=Passport only, Tier2=LP_Individuals or LP_Business, Tier3=Ecreditscoring
                     canAccessLPPools(user) = tier >= Tier1
                     canAccessTreasury(user) = tier >= Tier2
                     canInvestInVaults(user) = tier >= Tier2
                     canAccessFunding(user) = tier >= Tier3 AND businessNFT held
```

### Hook layer (Phase 1 + 2)

```
BaseHook           — Custom V4 base (not from v4-periphery). Validates address permission bits
                     in constructor. Exposes internal virtual _beforeSwap, _afterInitialize, etc.
                     Override only what you enable. All others revert HookNotImplemented().

PassportGatedHook  — DEPLOYED. KYC gate for any V4 pool.
                     beforeSwap + beforeAddLiquidity + beforeRemoveLiquidity.
                     sender = router (must be in allowedRouters mapping).
                     user = abi.decode(hookData, (address)) — router passes real user.
                     reputationManager.getReputationTier(user) must be >= Tier1.
                     ROUTER_ADMIN_ROLE manages router allowlist.

ConvexoPoolHook    — NOT DEPLOYED. Extends PassportGatedHook + adds oracle price band.
                     Additional: afterInitialize — validates pool init price is within bandBps of oracle.
                     Additional: _beforeSwap — also checks sqrtPriceLimitX96 doesn't exceed band.
                     rebalance(key) — KEEPER_ROLE calls to snap pool back to oracle price.
                     Uses PriceFeedManager.getLatestPrice(USDC_COP) via unlockCallback pattern.
                     Permission bits: 0x1A80 (afterInit + beforeAddLiq + beforeRemoveLiq + beforeSwap)
                     Must be deployed at address where lower 14 bits == 0x1A80 (Uniswap requirement).

ConvexoHookDeployer — NOT DEPLOYED. Deploys ConvexoPoolHook via CREATE2 for correct address bits.
                     findSalt() iterates off-chain to find salt giving 0x1A80 bits.
                     deploy() deploys with that salt.
```

### Oracle layer (Phase 1 + 2)

```
PriceFeedManager   — DEPLOYED. Manages Chainlink-compatible price feeds.
                     setPriceFeed(pair, aggregatorAddress, heartbeat) to register a feed.
                     getLatestPrice(CurrencyPair) validates staleness (heartbeat), round completeness.
                     Supports: USDC_COP, USDC_CHF, USDC_ARS, USDC_MXN.

ManualPriceAggregator — NOT DEPLOYED. IAggregatorV3-compatible. Admin sets price manually.
                        Phase 1 MVP: setPrice(420000000000) = 4200.00000000 COP/USDC (8 decimals).
                        Phase 2 plan: replace with real Chainlink aggregator address in PriceFeedManager.
                        No changes to ConvexoPoolHook needed for that upgrade.
```

### Credits layer (Phase 1)

```
VaultFactory       — Factory for TokenizedBondVault (investment vaults). Per-chain.
TokenizedBondVault — ERC4626-style vault. Access gated by VaultFactory → ReputationManager (tier >= 2).
```

---

## Hook address constraint (CRITICAL)

Uniswap V4 encodes hook permissions in the contract address's lower 14 bits.
The hook contract must be deployed at an address where those bits match `getHookPermissions()`.

- PassportGatedHook bits: beforeAddLiq(11) + beforeRemoveLiq(9) + beforeSwap(7) = `0x0A80`
- ConvexoPoolHook bits: afterInit(12) + beforeAddLiq(11) + beforeRemoveLiq(9) + beforeSwap(7) = `0x1A80`

`BaseHook` constructor calls `Hooks.validateHookPermissions()` — deploy will revert if address bits are wrong.

Use `HookDeployer.findPassportGatedHookSalt()` for PassportGatedHook.
Use `ConvexoHookDeployer.findSalt()` for ConvexoPoolHook.
These iterate CREATE2 salts until the predicted address has the correct bits.

---

## Workflow: how to update and redeploy

### Changing a Phase 1 contract

1. Edit contract in `src/contracts/`
2. Run `forge test` — all tests must pass
3. The Phase 1 contracts use CREATE2 with salt `convexo.v3.XX` — bump the version in `DeployDeterministic.s.sol`
4. Update `addresses.json` after deploy (script writes this automatically)
5. Update `CHANGELOG.md`

### Adding a Phase 2 contract (pool)

1. Write `script/DeployPhase2.s.sol`
2. Run `forge test` on pool-related tests first
3. Deploy to Base Sepolia first: `DEPLOY_VERSION=convexo.v3.18 forge script script/DeployPhase2.s.sol --rpc-url base-sepolia --broadcast`
4. Set price: call `manualAggregator.setPrice()`
5. Fund hook: `depositReserve(USDC, 500e6)` + `depositReserve(ECOP, 2_100_000e18)`
6. Init pool: run `InitializePool.s.sol`
7. Update `addresses.json` with new addresses
8. Update Railway env vars (backend keeper)
9. Update `CHANGELOG.md`

### Running tests

```bash
cd convexo_contracts
forge test                    # all tests
forge test --match-contract ConvexoPassport -vvv   # single contract
forge test --match-test testRebalance -vvv          # single test
forge coverage                # coverage report
```

---

## Environment variables for deploy scripts

```
PRIVATE_KEY=<deployer EOA>
BASESCAN_API_KEY=<for verification>
ETHERSCAN_API_KEY=<for ETH mainnet>
ARBISCAN_API_KEY=<for Arbitrum>
RPC_BASE=<base mainnet RPC>
RPC_BASE_SEPOLIA=<base sepolia RPC>
# etc.
```

---

## Key design decisions

- **No admin mint on Passport**: `claimPassport()` is the only mint path. ZKPassport proof is verified on-chain — admin cannot bypass.
- **Soulbound everywhere**: identity NFTs use `_update()` override that blocks transfers.
- **Router pattern in hooks**: V4 `sender` is the router, not the user. Hooks gate on router allowlist + decode user from hookData.
- **Single hook per pool**: V4 only allows one hook. `ConvexoPoolHook` inherits `PassportGatedHook` so both KYC gate and price band are in one contract.
- **ManualPriceAggregator is temporary**: It's Chainlink IAggregatorV3 compatible. Phase 2 upgrade is just calling `priceFeedManager.setPriceFeed(pair, chainlinkAddress, heartbeat)` — zero contract changes.
- **CREATE2 determinism**: Core identity contracts are same address on all chains (using same salt). Hook addresses differ per chain because they must match permission bits AND deployment order matters.

---

## What the backend needs from contracts

The backend (`convexo-backend/`) interacts with:
- `ReputationManager.getReputationTier(address)` — gating middleware
- `ManualPriceAggregator.setPrice(int256)` — rates.service syncs on-chain via keeper
- `ConvexoPoolHook.rebalance(PoolKey)` — pool keeper cron (5min)
- Webhook verifiers (VeriffVerifier, SumsubVerifier) — called via HMAC-signed webhooks

Backend env vars needed for Phase 2:
- `KEEPER_PRIVATE_KEY`
- `CONVEXO_HOOK_ADDRESS`
- `USDC_ADDRESS`
- `ECOP_ADDRESS`
- `MANUAL_PRICE_AGGREGATOR_ADDRESS`
- `POOL_KEEPER_CHAIN_ID`

---

## What the frontend needs from contracts

The frontend uses:
- `Convexo_Passport.claimPassport(zkParams, isIDCard, ipfsHash)` — ZKPassport flow
- `ReputationManager.getReputationTier(address)` — UI gating
- `PassportGatedHook` / `ConvexoPoolHook` as the hook address in Uniswap V4 pool interactions
- `ECOP` token addresses (per chain, see addresses.json)

All ABIs are in `abis/` and auto-exported on `forge build`.

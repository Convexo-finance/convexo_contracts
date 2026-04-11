# Convexo Contracts — Changelog

Format: version tag → what changed → deploy status.

---

## v3.18.1 — 2026-04-10 (Base Sepolia pool live)

### USDC/ECOP Pool — Base Sepolia LIVE

**Problem fixed:** Original PassportGatedHook (`0x6aCd36...`) was deployed against old v4-core with
different permission bit positions → PoolManager rejected it with `HookAddressNotValid`.

**Solution:**
- Added `script/RedeployPassportGatedHook.s.sol` — finds valid CREATE2 salt using current v4-core
  bit layout (0x0A80 = beforeAddLiq + beforeRemoveLiq + beforeSwap), deploys via Safe Singleton Factory.
- Fixed `script/AddLiquidity.s.sol` — replaced `MINT_POSITION_FROM_DELTAS` (only works when
  existing credits are present, e.g. after a decrease_liquidity) with `MINT_POSITION` + explicit
  liquidity computed via `LiquidityAmounts.getLiquidityForAmounts`.

**New PassportGatedHook (Base Sepolia 84532):** `0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80`

**USDC/ECOP pool deployed:**
- Hook: `0xdCfF77e89904e9Bead3f456D04629Ca8Eb7e8a80`
- Token0 (USDC): `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- Token1 (ECOP): `0xb934dCB57fB0673B7BC0Fca590c5508f1CDE955D`
- fee=500, tickSpacing=10, init rate=3650 COP/USDC
- Main position: 6,250 USDC concentrated ±5%
- Backstop: 500 USDC full-range

**Access:** Any user with Tier >= 1 (Convexo Passport NFT) can swap + add/remove liquidity.
Router must be allowed on hook (`allowRouter(positionManager)` — done at deploy).

**New/updated scripts:**
- `scripts/redeploy-hook.sh` + `script/RedeployPassportGatedHook.s.sol` (new)
- `scripts/pool-init.sh` — updated HOOK_ADDRESS
- `scripts/pool-add-liquidity.sh` — updated HOOK_ADDRESS
- `script/AddLiquidity.s.sol` — fixed MINT_POSITION + LiquidityAmounts import

---

## v3.18 (current) — 2026-03

### Deployed (Phase 1) — all 7 chains
All 13 core contracts deployed at deterministic CREATE2 addresses via `DeployDeterministic.s.sol`.
Chains: Base (8453), Unichain (130), Base Sepolia (84532), Eth Sepolia (11155111), Uni Sepolia (1301), Arb Sepolia (421614), ETH Mainnet (1).

**Identity contracts** (same address on all chains):
- `Convexo_Passport` — upgraded to trustless ZKPassport self-claim only. No admin mint path. `claimPassport()` verifies ZK proof on-chain: domain + scope binding, msg.sender binding, chainId binding, age ≥ 18, sanctions (US/UK/EU/CH), nationality exclusion, document expiry, sybil resistance (uniqueIdentifier). Stores enriched `VerifiedIdentity` struct with boolean privacy traits only.
- `LP_Individuals` — KYC NFT for individuals (Veriff). Soulbound.
- `LP_Business` — KYB NFT for businesses (Sumsub). Soulbound.
- `Ecreditscoring` — Credit score NFT for businesses (n8n AI). Soulbound.
- `VeriffVerifier` — Veriff webhook verifier, mints LP_Individuals.
- `SumsubVerifier` — Sumsub webhook verifier, mints LP_Business.
- `ReputationManager` — Aggregates NFT tiers. Exposes canAccessTreasury, canInvestInVaults, canAccessFunding.
- `ContractSigner` — Document signing registry.

**Infrastructure contracts** (same address on all chains except hook/vault which need address-bit matching):
- `PoolRegistry` — Registry of Uniswap V4 pools.
- `PriceFeedManager` — Chainlink-compatible price feed manager (USDC_COP, USDC_CHF, USDC_ARS, USDC_MXN).
- `HookDeployer` — CREATE2 deployer for PassportGatedHook (finds valid salt for 0x0A80 bits).
- `PassportGatedHook` — Uniswap V4 hook: gates swap + add/remove liquidity to verified users. beforeSwap + beforeAddLiquidity + beforeRemoveLiquidity. Router allowlist + ReputationManager tier check. Per-chain (address bits must match 0x0A80).
- `VaultFactory` — Factory for investment vaults. Per-chain.

### Built but NOT YET deployed (Phase 2 — USDC/ECOP Pool MVP)
Pending `script/DeployPhase2.s.sol` (script not written yet).

- `ManualPriceAggregator` (`src/contracts/oracles/ManualPriceAggregator.sol`) — IAggregatorV3-compatible manual price feed. Admin sets USDC/COP rate. Temporary until Chainlink feed available for USDC/COP.
- `ConvexoHookDeployer` (`src/contracts/hooks/ConvexoHookDeployer.sol`) — CREATE2 deployer for ConvexoPoolHook. Finds salt giving address bits 0x1A80.
- `ConvexoPoolHook` (`src/contracts/hooks/ConvexoPoolHook.sol`) — Uniswap V4 hook for USDC/ECOP pool. Inherits PassportGatedHook (KYC gate) + adds oracle price band (±bandBps from PriceFeedManager). afterInitialize validates pool init price. Keeper rebalance via unlockCallback pattern. USDC(6dec)/ECOP(18dec), fee=500, tickSpacing=10, bandBps=200, cooldown=1h.

Supporting library (deployed as part of hooks):
- `OracleMath` (`src/contracts/hooks/libraries/OracleMath.sol`) — Converts oracle price (int256, decimals) → sqrtPriceX96. Computes deviation in bps between two sqrtPrices.

---

## v3.11 — 2025

- Refactored contract structure
- Added Arbitrum chain support (421614 Arb Sepolia)
- Upgraded ZKPassport integration

---

## v3.0 — 2025

- Initial multi-chain deployment
- Base, Unichain, Eth, Uni testnets
- Core identity + reputation system

---

## Upcoming

### Phase 2 deploy (next step)
1. Write `script/DeployPhase2.s.sol`
2. Deploy ManualPriceAggregator + ConvexoHookDeployer + ConvexoPoolHook on Base Sepolia
3. Wire: `priceFeedManager.setPriceFeed(USDC_COP, manualAggregator, 26 hours)`
4. Set initial price: `manualAggregator.setPrice(420000000000)` (4200 COP/USDC)
5. Fund hook reserve: USDC + ECOP
6. Init pool via `InitializePool.s.sol`
7. Grant KEEPER_ROLE to backend keeper EOA
8. Add Railway env vars

### Phase 2 oracle upgrade (future)
- Replace ManualPriceAggregator with real Chainlink feed when available
- `priceFeedManager.setPriceFeed(USDC_COP, chainlinkAddress, 3600)`
- Zero changes to ConvexoPoolHook

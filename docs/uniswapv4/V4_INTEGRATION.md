# Convexo — Uniswap V4 Integration

**What we're building:** A KYC-gated USDC/ECOP liquidity pool on Uniswap V4 that stays anchored to the real Colombian Peso FX rate.

---

## The Problem We're Solving

In a normal Uniswap pool, arbitrageurs keep the price aligned with the market.
In a KYC-gated pool, **there are no external arbitrageurs** — only verified Convexo users.

Without intervention:
- Directional flow (users buying ECOP) causes the pool price to drift
- LPs suffer impermanent loss against the real FX rate
- The pool becomes unusable at extreme drift

**Solution:** KYC gate (Phase 1) → oracle-anchored price band + keeper rebalance (Phase 2)

---

## Pool Configuration

| Parameter | Value |
|-----------|-------|
| Token 0 | USDC (6 decimals) — must be lower address |
| Token 1 | ECOP (18 decimals) |
| Fee tier | `500` (0.05%) — low fee for a stable forex pair |
| Tick spacing | `10` |
| Hook | PassportGatedHook (Phase 1) → ConvexoPoolHook (Phase 2) |
| Price band | ±2% from oracle (Phase 2 only) |

---

## Hook Architecture

### Phase 1 — MVP (current)

`PassportGatedHook` — KYC gate only. No price oracle.

```
User / Router
     │  hookData = abi.encode(userAddress)
     ▼
PassportGatedHook
  ├─ beforeSwap:          check router allowlist + user NFT tier
  ├─ beforeAddLiquidity:  check router allowlist + user NFT tier
  └─ beforeRemoveLiquidity: check router allowlist + user NFT tier
```

Permission bits: `0x0A80` (beforeAddLiquidity + beforeRemoveLiquidity + beforeSwap)

### Phase 2 — Oracle-Anchored (next)

`ConvexoPoolHook` — inherits PassportGatedHook, adds price band + rebalance.

```
User / Router
     │
     ▼
ConvexoPoolHook
  ├─ afterInitialize:       validate pool initialized within band of oracle
  ├─ beforeSwap:            KYC check + price band guard (reject if >2% off oracle)
  ├─ beforeAddLiquidity:    KYC check
  ├─ beforeRemoveLiquidity: KYC check
  └─ rebalance(poolKey):    KEEPER_ROLE → corrective swap via poolManager.unlock()

PriceFeedManager
  ├─ Phase 1: ManualPriceAggregator (admin sets price daily)
  └─ Phase 2: Chainlink Aggregator (trustless, automatic)
```

Permission bits: `0x1A80` (afterInitialize + above 3)

---

## How V4 Hook Permissions Work

Uniswap V4 encodes permissions in the bottom 14 bits of the hook contract address.
PoolManager validates at pool initialization — address bits must match `getHookPermissions()`.

```
bit 13 = beforeInitialize    bit 12 = afterInitialize
bit 11 = beforeAddLiquidity  bit 10 = afterAddLiquidity
bit  9 = beforeRemoveLiquidity  bit  8 = afterRemoveLiquidity
bit  7 = beforeSwap          bit  6 = afterSwap
...
```

This is why hooks use CREATE2 — you mine a salt that produces an address with the correct bits.

---

## Deployment (Phase 1)

### 1. Deploy contracts
```bash
DEPLOY_VERSION=convexo.v3.18 ./scripts/deploy.sh base-sepolia
# or: ./scripts/deploy.sh base (mainnet)
```

Note the deployed addresses — specifically `passport_gated_hook`.

### 2. Allow your router
```bash
cast send <PASSPORT_GATED_HOOK> \
  "allowRouter(address)" <ROUTER_ADDRESS> \
  --rpc-url $RPC_URL --private-key $ADMIN_PRIVATE_KEY
```

### 3. Initialize the pool
```bash
HOOK_ADDRESS=<passport_gated_hook> \
TOKEN0=<usdc_address> \
TOKEN1=<ecop_address> \
forge script script/InitializePool.s.sol \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### 4. Add initial liquidity
Use Uniswap V4 PositionManager. Always pass `hookData = abi.encode(adminAddress)` — the hook checks KYC on the encoded address.

PositionManager addresses: see `Univ4_deployments.md`

### 5. Update addresses + sync
```bash
./scripts/verify-all.sh <chainId>
./scripts/update-addresses.sh <chainId>
cp addresses.json ../convexo_frontend/addresses.json
./scripts/extract-abis.sh
```

---

## Router Integration

### Why routers need allowlisting

In V4, `msg.sender` in hook callbacks is **always the PoolManager** — never the end user.
The `sender` parameter identifies the router (whoever called `poolManager.unlock()`).

PassportGatedHook maintains `allowedRouters`. Any router must be explicitly allowlisted by admin.

### What routers must include

```solidity
// Every swap / addLiquidity / removeLiquidity call must include:
bytes memory hookData = abi.encode(userAddress);
```

The hook decodes this and checks the user's NFT tier. Without a valid Convexo NFT, it reverts with `MustHaveKYCVerification`.

### Router management

```solidity
passportGatedHook.allowRouter(routerAddress);   // admin only
passportGatedHook.revokeRouter(routerAddress);  // admin only
passportGatedHook.allowedRouters(addr);         // view: returns bool
```

---

## KYC Access

```solidity
// Check pool access
passportGatedHook.hasLPPoolAccess(userAddress); // bool

// Get tier
passportGatedHook.getUserTier(userAddress);
// None(0), Passport(1), LimitedPartner(2), VaultCreator(3)
```

Any tier > 0 grants pool access. Both PassportGatedHook and ConvexoPoolHook use the same logic via ReputationManager.

---

## Phase 2 Price Flow

```
Real world: 1 USDC = 4,200 COP

ManualPriceAggregator (Phase 1) / Chainlink (Phase 2)
       │
       ▼
PriceFeedManager.getLatestPrice(USDC_COP)
  → (420000000000, 8)   // 4200.00000000 with 8 decimals
       │
       ▼
OracleMath.oracleToSqrtPriceX96(price, 8, 6, 18, true)
  → uint160 sqrtPriceX96   // V4 pool price format
       │
       ▼
ConvexoPoolHook._beforeSwap()
  → compare pool sqrtPrice vs oracle sqrtPrice
  → if deviation > 2%: revert SwapExceedsPriceBand
  → otherwise: allow swap
```

---

## Events

```solidity
event AccessGranted(address indexed user, string operation, ReputationTier tier);
event RouterAllowed(address indexed router);
event RouterRevoked(address indexed router);
// Phase 2:
event ConvexoPoolHookDeployed(address indexed hook, address poolManager, address reputationManager, bytes32 salt);
```

---

## Security Notes

- **Never use `msg.sender` for user identity in hooks** — it's always PoolManager
- User identity comes from `hookData` — routers are trusted to encode the correct address
- Only allowlisted routers can interact with the pool
- Hook address bits are validated at deploy time — `validateHookPermissions()` in BaseHook
- `beforeSwapReturnDelta` is NOT enabled — no NoOp attack vector
- `beforeRemoveLiquidity` enabled — can block withdrawals if KYC lapses (by design)

---

## Roadmap

| Phase | Hook | Oracle | Status |
|-------|------|--------|--------|
| 1 — MVP | PassportGatedHook | None (manual LP management) | Code done, deploy pending |
| 2 — Oracle | ConvexoPoolHook | ManualPriceAggregator (admin sets daily) | Code done, deploy after Phase 1 stable |
| 3 — Chainlink | ConvexoPoolHook | Chainlink USDC/COP feed | 1 tx: setPriceFeed() — no new contracts |
| 4 — PoR | ConvexoPoolHook | + Chainlink Proof of Reserves | ECOP backing verifiable on-chain |

See `docs/upgrades/` for execution plans.

---

## Contract Addresses

V4 infrastructure per chain: `Univ4_deployments.md`

Convexo contract addresses: `addresses.json` (generated after deploy)

Permit2 (same all chains): `0x000000000022D473030F116dDEE9F6B43aC78BA3`

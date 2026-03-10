---

# Convexo Oracles — Developer Reference

## Overview

Convexo uses oracle price feeds to anchor the USDC/ECOP pool price to real-world USDC/COP exchange rates. The oracle layer is designed for a staged rollout:

| Phase | Oracle | Who sets price | Automation |
|---|---|---|---|
| 1 (MVP) | ManualPriceAggregator | Admin daily | None |
| 2 | ManualPriceAggregator + keeper | Admin daily | Backend auto-rebalances pool |
| 3 | Chainlink USDC/COP feed | Nobody | Fully automatic |
| 4 | Chainlink + Proof of Reserves | Nobody | Automatic + reserve verification |

The key design: `PriceFeedManager` accepts any `IAggregatorV3`-compatible feed. Upgrading from manual to Chainlink requires zero contract changes — just one `setPriceFeed()` call.

---

## Contracts

### PriceFeedManager

Deployed contract. Registry of price feeds per currency pair.

```solidity
// Supported pairs
enum CurrencyPair { USDC_COP, USDC_EUR, USDC_MXN }

// Register a feed (admin only)
function setPriceFeed(CurrencyPair pair, address feed, uint256 heartbeat) external

// Deactivate a feed
function deactivatePriceFeed(CurrencyPair pair) external

// Read price
function getLatestPrice(CurrencyPair pair) returns (int256 price, uint8 decimals)
function getPriceWithTimestamp(CurrencyPair pair) returns (int256 price, uint8 decimals, uint256 updatedAt)
function isPriceFeedActive(CurrencyPair pair) returns (bool)

// Conversion helpers (used by backend + frontend)
function convertUSDCToLocal(CurrencyPair pair, uint256 usdcAmount) returns (uint256)
function convertLocalToUSDC(CurrencyPair pair, uint256 localAmount) returns (uint256)
```

**Staleness check:** `getLatestPrice` reverts `StalePriceData` if `block.timestamp - updatedAt > heartbeat`. For ManualPriceAggregator use 26-hour heartbeat (gives admin buffer for weekends/holidays).

---

### ManualPriceAggregator

IAggregatorV3-compatible. Admin sets the price manually. Swap for Chainlink in Phase 3.

```solidity
// Set price (PRICE_SETTER_ROLE)
// Example: 4200 COP/USDC with 8 decimals = 420000000000
function setPrice(int256 price) external

// IAggregatorV3 reads
function decimals() returns (uint8)          // 8
function description() returns (string)      // "USDC / COP"
function latestRoundData() returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
```

**Price format:** `price = humanReadableRate * 10^decimals`
- 4200 COP/USDC → `4200 * 10^8 = 420000000000`
- 4250 COP/USDC → `4250 * 10^8 = 425000000000`

---

## Phase 1 Setup (Manual)

```bash
# 1. Deploy (included in main deploy script)
forge script script/DeployDeterministic.s.sol --broadcast
# ManualPriceAggregator and PriceFeedManager are NOT deployed in MVP
# They are deployed via script/DeployPhase2.s.sol

# 2. Link aggregator to PriceFeedManager
cast send <PRICE_FEED_MANAGER> \
  "setPriceFeed(uint8,address,uint256)" 0 <MANUAL_AGGREGATOR> 93600 \
  --rpc-url $RPC_URL --private-key $ADMIN_PRIVATE_KEY
# 93600 = 26 hours in seconds, pair 0 = USDC_COP

# 3. Set initial price (4200 COP/USDC)
cast send <MANUAL_AGGREGATOR> \
  "setPrice(int256)" 420000000000 \
  --rpc-url $RPC_URL --private-key $ADMIN_PRIVATE_KEY

# 4. Grant PRICE_SETTER_ROLE to backend service wallet
cast send <MANUAL_AGGREGATOR> \
  "grantRole(bytes32,address)" \
  $(cast keccak "PRICE_SETTER_ROLE") <BACKEND_WALLET> \
  --rpc-url $RPC_URL --private-key $ADMIN_PRIVATE_KEY
```

Backend also calls `setPrice()` automatically whenever admin updates the rate via `POST /admin/rates` with pair `USDC-COP`.

---

## Phase 3 Upgrade — Chainlink

When a Chainlink USDC/COP feed is available:

```bash
# Single call — no contract redeployment needed
cast send <PRICE_FEED_MANAGER> \
  "setPriceFeed(uint8,address,uint256)" 0 <CHAINLINK_FEED_ADDRESS> 3600 \
  --rpc-url $RPC_URL --private-key $ADMIN_PRIVATE_KEY
# 3600 = 1 hour heartbeat (Chainlink standard)
```

`ManualPriceAggregator` can be deactivated or left deployed (it holds no funds).

### Finding Chainlink USDC/COP
- Chainlink Data Feeds: https://docs.chain.link/data-feeds/price-feeds/addresses
- Search for "COP" or "Colombian Peso"
- If not available: use a Chainlink Any API job or a decentralized oracle network (Band Protocol, Pyth)

---

## Phase 4 — Proof of Reserves

Proof of Reserves (PoR) verifies that ECOP tokens are backed 1:1 by real Colombian Pesos held in a bank account or regulated custodian.

### Why it matters
- ECOP is a COP-pegged token. Users need assurance that 1 ECOP = 1 COP is genuinely backed.
- Without PoR, users must trust the issuer's word. With PoR, the blockchain verifies reserves.

### Chainlink Proof of Reserves

Chainlink provides PoR feeds that attest to off-chain or cross-chain asset reserves:
- An authorized reporter (bank, auditor, or automated bridge) attests to the reserve balance
- The on-chain feed is updated regularly (e.g., daily)
- Smart contracts can read the reserve and compare it to total ECOP supply

### Integration Plan (Phase 4)

```solidity
// New contract: src/contracts/oracles/ProofOfReservesGuard.sol
contract ProofOfReservesGuard {
    IAggregatorV3 public immutable reserveFeed;   // Chainlink PoR feed
    IERC20 public immutable ecop;                  // ECOP token

    // Returns true if reserves >= total supply
    function isFullyBacked() external view returns (bool) {
        (, int256 reserveBalance,,,) = reserveFeed.latestRoundData();
        uint256 totalSupply = ecop.totalSupply();
        // reserveBalance is in COP cents (e.g. 8 decimals)
        // totalSupply is in ECOP (18 decimals)
        // Convert and compare
        return uint256(reserveBalance) >= totalSupply / 1e10;
    }
}
```

The `ConvexoPoolHook` can optionally gate swaps behind `isFullyBacked()` — if reserves drop below supply, swaps pause automatically until the issuer tops up.

### PoR Reporter options
1. **Chainlink External Adapter** — custom adapter reads bank balance via API, posts on-chain
2. **Chainlink DECO** — privacy-preserving TLS proof of bank statement (no third party)
3. **Manual attestation** — auditor posts signed reserve report on-chain quarterly

### Resources
- Chainlink PoR: https://docs.chain.link/data-feeds/proof-of-reserve
- Chainlink Any API: https://docs.chain.link/any-api/introduction
- Pyth Network (alternative): https://pyth.network

---

## OracleMath Library

Used internally by `ConvexoPoolHook` to convert between Chainlink prices and Uniswap V4 sqrtPriceX96 format.

```solidity
// Convert Chainlink price to Uniswap sqrtPriceX96
OracleMath.oracleToSqrtPriceX96(
    chainlinkPrice,   // e.g. 420000000000
    chainlinkDec,     // 8
    token0Dec,        // 6 (USDC)
    token1Dec,        // 18 (ECOP)
    token0IsBase      // true (Chainlink gives COP per USDC)
) returns (uint160 sqrtPriceX96)

// Deviation in basis points between pool and oracle
OracleMath.deviationBps(poolSqrtPrice, oracleSqrtPrice) returns (uint256 bps)

// True if pool has drifted more than bandBps from oracle
OracleMath.exceedsBand(poolSqrtPrice, oracleSqrtPrice, bandBps) returns (bool)
```

**Concrete example — USDC/ECOP pool:**
- Chainlink price: `420000000000` (4200 COP/USDC, 8 decimals)
- token0 = USDC (6 dec), token1 = ECOP (18 dec)
- priceRatio = 4200 * 10^12 = 4.2e15 ECOP units per USDC unit
- sqrtPriceX96 = sqrt(4.2e15) * 2^96 ≈ 5.13e36 (fits in uint160)

---

## Related Docs
- `docs/hooks/HOOKS_REFERENCE.md` — V4 hook integration
- `docs/hooks/HOOKS_ARCHITECTURE.md` — price band design and math
- `docs/hooks/POOL_MVP_PLAN.md` — MVP execution plan

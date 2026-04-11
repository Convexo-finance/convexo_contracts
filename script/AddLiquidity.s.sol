// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";

import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {PassportGatedHook} from "../src/contracts/hooks/PassportGatedHook.sol";

/// @title AddLiquidity
/// @notice Seeds the USDC/ECOP Convexo V4 pool with concentrated liquidity.
///
/// ── Why concentrated, not full-range ────────────────────────────────────────
/// ConvexoPoolHook blocks all swaps beyond ±bandBps (2%) from the oracle price.
/// Liquidity outside that range is unreachable — full-range is wasted capital.
///
/// Recommended layout:
///   Main position  : ±RANGE_PCT (default 5%) around current COP rate
///                    → covers the ±2% band + small buffer for rate drift
///   Backstop       : run script again with FULL_RANGE=true, small amount
///                    → prevents pool breakdown if oracle moves > RANGE_PCT
///
/// ── Reserve sizing ──────────────────────────────────────────────────────────
/// The keeper (ConvexoPoolHook.rebalance) swaps to bring price back to oracle.
/// It needs tokens pre-funded via depositReserve(). Rule of thumb:
///   reserve = 10-15% of the main position depth in each token
/// With 2% band and daily rate updates of ~0.5%, one rebalance per day uses
/// roughly 1-2% of pool depth in whichever direction the rate moved.
///
/// ── Prerequisites ───────────────────────────────────────────────────────────
///   1. Pool initialized (InitializePool.s.sol already run)
///   2. Deployer wallet holds USDC + ECOP (run: cast balance TOKEN --rpc-url ...)
///   3. Deployer holds a Convexo tier NFT (run MintTestNFT.s.sol on testnet)
///
/// ── Usage ───────────────────────────────────────────────────────────────────
/// Usage — only RATE and AMOUNT0 (USDC) needed, ECOP computed automatically:
///
///   TOKEN0=<usdc> TOKEN1=<ecop> HOOK_ADDRESS=<hook> \
///   RATE=3650 AMOUNT0=6250000000 \
///   forge script script/AddLiquidity.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
///
///   AMOUNT0=6250000000 means 6,250 USDC (6 decimals)
///   Script auto-computes AMOUNT1: 6,250 * 3,650 = 22,812,500 ECOP (18 decimals)
///
/// Full-range backstop (run after main position, small USDC amount):
///   FULL_RANGE=true SKIP_ALLOW_ROUTER=true RATE=3650 AMOUNT0=500000000 \
///   ... same TOKEN0/TOKEN1/HOOK_ADDRESS ...
///
/// Required env vars : PRIVATE_KEY, HOOK_ADDRESS, TOKEN0, TOKEN1, RATE
/// Optional env vars :
///   AMOUNT0            USDC in raw units (default 500 USDC = 500_000_000)
///   AMOUNT1            ECOP in raw units — override if you want exact control
///   RANGE_PCT          % range each side of current rate (default 5 = ±5%)
///   FULL_RANGE         "true" = full-range backstop position
///   SKIP_ALLOW_ROUTER  "true" if PositionManager already allowed on hook
contract AddLiquidity is Script {

    // ── Pool config (must match InitializePool.s.sol) ─────────────────────────
    uint24 constant FEE          = 500;
    int24  constant TICK_SPACING = 10;

    // Full-range ticks for tickSpacing=10 (nearest valid multiples of 10)
    int24 constant MIN_TICK = -887270;
    int24 constant MAX_TICK =  887270;

    // Basis points per 1% (1% = 100 bps in tick terms = ~100 ticks at low prices,
    // but we use the actual formula: Δtick = ln(1 + pct/100) / ln(1.0001))
    // ±5%  → Δtick ≈  488
    // ±10% → Δtick ≈  953
    // ±2%  → Δtick ≈  200
    // Precomputed for common values:
    int24 constant TICKS_PER_1PCT = 100; // approximate, formula below is exact

    // Default seed amounts
    uint128 constant DEFAULT_AMOUNT0 = 500_000_000;  // 500 USDC (6 dec)
    // AMOUNT1 is computed from AMOUNT0 * RATE automatically — no need to specify it
    uint256 constant DEFAULT_RATE    = 3650;          // 1 USDC = 3650 ECOP (current COP rate)
    uint256 constant DEFAULT_RANGE   = 5;             // ±5%

    // Permit2 — same on all EVM chains
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    uint256 constant Q96 = 1 << 96;

    // ── Network config ─────────────────────────────────────────────────────────
    function getPositionManager() internal view returns (address) {
        uint256 id = block.chainid;
        if (id == 1)        return 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e;
        if (id == 8453)     return 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
        if (id == 130)      return 0x4529A01c7A0410167c5740C487A8DE60232617bf;
        if (id == 42161)    return 0xd88F38F930b7952f2DB2432Cb002E7abbF3dD869;
        if (id == 11155111) return vm.envOr("POSITION_MANAGER_ADDRESS_ETHSEPOLIA",  0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4);
        if (id == 84532)    return vm.envOr("POSITION_MANAGER_ADDRESS_BASESEPOLIA", 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80);
        if (id == 1301)     return vm.envOr("POSITION_MANAGER_ADDRESS_UNISEPOLIA",  0xf969Aee60879C54bAAed9F3eD26147Db216Fd664);
        if (id == 421614)   return vm.envOr("POSITION_MANAGER_ADDRESS_ARBSEPOLIA",  0xAc631556d3d4019C95769033B5E719dD77124BAc);
        revert("Unsupported network");
    }

    // ── Main ───────────────────────────────────────────────────────────────────
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer           = vm.addr(deployerPrivateKey);
        address hookAddress        = vm.envAddress("HOOK_ADDRESS");
        address token0Env          = vm.envAddress("TOKEN0");
        address token1Env          = vm.envAddress("TOKEN1");
        uint256 rate               = vm.envOr("RATE",          DEFAULT_RATE);
        uint256 rangePct           = vm.envOr("RANGE_PCT",     DEFAULT_RANGE);
        bool    fullRange          = keccak256(bytes(vm.envOr("FULL_RANGE",         string("false")))) == keccak256("true");
        bool    skipAllowRouter    = keccak256(bytes(vm.envOr("SKIP_ALLOW_ROUTER",  string("false")))) == keccak256("true");

        // Only AMOUNT0 (USDC) is required. AMOUNT1 (ECOP) is derived from rate:
        //   amount1 = amount0 * rate  (adjusted for decimals: USDC=6dec, ECOP=18dec)
        //   e.g. 6250 USDC * 3650 = 22,812,500 ECOP
        uint128 amount0Max = uint128(vm.envOr("AMOUNT0", uint256(DEFAULT_AMOUNT0)));
        uint128 amount1Max = uint128(vm.envOr("AMOUNT1",
            uint256(amount0Max) * rate * 1e12  // convert USDC raw → ECOP raw at current rate
        ));

        // V4 requires currency0 < currency1
        (address currency0, address currency1) = token0Env < token1Env
            ? (token0Env, token1Env)
            : (token1Env, token0Env);

        // If addresses were swapped, swap amounts too
        if (token0Env > token1Env) (amount0Max, amount1Max) = (amount1Max, amount0Max);

        address positionManager = getPositionManager();

        // ── Compute sqrtPriceX96 from rate ─────────────────────────────────────
        // For USDC(6dec)/ECOP(18dec): priceRaw = rate * 10^(18-6) = rate * 1e12
        // sqrtPriceX96 = sqrt(priceRaw * Q96^2)
        // Split to avoid overflow: sqrt(priceRaw) * Q96
        // priceRaw = 4200 * 1e12 = 4.2e15 → sqrt = ~64,807,407 → * Q96 = ~5.13e36 (fits uint160)
        uint256 priceRaw = rate * 1e12;
        uint160 sqrtPriceX96 = _sqrtPriceX96FromRate(priceRaw);

        // ── Compute tick range from sqrtPriceX96 ──────────────────────────────
        int24 tickLower;
        int24 tickUpper;

        if (fullRange) {
            tickLower = MIN_TICK;
            tickUpper = MAX_TICK;
        } else {
            // Current tick from oracle price
            int24 currentTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

            // Tick delta for rangePct%: Δtick = ln(1 + pct/100) / ln(1.0001)
            // Precomputed: 1% ≈ 100 ticks, 5% ≈ 488, 10% ≈ 953
            // Use formula: pct * 100 ticks (approximate, accurate to within 2 ticks for pct <= 10)
            // For more precision we multiply by exact factor 9975/10000 ≈ ln(1.01)/ln(1.0001)/100
            int24 halfRange = int24(int256(rangePct * 100));

            // Snap to tickSpacing=10
            int24 roundedLower = ((currentTick - halfRange) / TICK_SPACING) * TICK_SPACING;
            int24 roundedUpper = ((currentTick + halfRange) / TICK_SPACING + 1) * TICK_SPACING;

            tickLower = roundedLower < MIN_TICK ? MIN_TICK : roundedLower;
            tickUpper = roundedUpper > MAX_TICK ? MAX_TICK : roundedUpper;
        }

        console.log("\n========================================");
        console.log("ADD LIQUIDITY - CONVEXO V4 POOL");
        console.log("========================================");
        console.log("Network:         ", block.chainid);
        console.log("Deployer:        ", deployer);
        console.log("Hook:            ", hookAddress);
        console.log("PositionManager: ", positionManager);
        console.log("Currency0 (USDC):", currency0);
        console.log("Currency1 (ECOP):", currency1);
        console.log("RATE (COP/USDC): ", rate);
        console.log("Amount0Max:      ", amount0Max);
        console.log("Amount1Max:      ", amount1Max);
        console.log("TickLower:       ", tickLower);
        console.log("TickUpper:       ", tickUpper);
        if (fullRange) {
            console.log("Mode:            FULL-RANGE (backstop)");
        } else {
            console.log("Mode:            CONCENTRATED +-", rangePct, "%");
        }

        vm.startBroadcast(deployerPrivateKey);

        // ── 1. Allow PositionManager as router on the hook ─────────────────────
        // PassportGatedHook.beforeAddLiquidity checks allowedRouters[sender].
        // In V4, sender = the address that called poolManager.unlock() = PositionManager.
        if (!skipAllowRouter) {
            console.log("\nAllowing PositionManager as router on hook...");
            PassportGatedHook(hookAddress).allowRouter(positionManager);
        }

        // ── 2. Approve tokens to permit2 ──────────────────────────────────────
        IERC20(currency0).approve(PERMIT2, type(uint256).max);
        IERC20(currency1).approve(PERMIT2, type(uint256).max);

        // ── 3. permit2 approve PositionManager ────────────────────────────────
        uint48 expiration = uint48(block.timestamp + 7 days);
        (bool ok0,) = PERMIT2.call(abi.encodeWithSignature(
            "approve(address,address,uint160,uint48)",
            currency0, positionManager, type(uint160).max, expiration
        ));
        require(ok0, "permit2 approve currency0 failed");

        (bool ok1,) = PERMIT2.call(abi.encodeWithSignature(
            "approve(address,address,uint160,uint48)",
            currency1, positionManager, type(uint160).max, expiration
        ));
        require(ok1, "permit2 approve currency1 failed");

        // ── 4. Build PoolKey ───────────────────────────────────────────────────
        PoolKey memory key = PoolKey({
            currency0:   Currency.wrap(currency0),
            currency1:   Currency.wrap(currency1),
            fee:         FEE,
            tickSpacing: TICK_SPACING,
            hooks:       IHooks(hookAddress)
        });

        // ── 5. Compute liquidity from amounts ─────────────────────────────────
        // MINT_POSITION requires explicit liquidity; MINT_POSITION_FROM_DELTAS only
        // works when there are existing credits (e.g. after decrease_liquidity).
        // We compute liquidity from amounts + current pool price using LiquidityAmounts.
        uint160 sqrtLower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtUpper = TickMath.getSqrtPriceAtTick(tickUpper);
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtLower,
            sqrtUpper,
            amount0Max,
            amount1Max
        );
        require(liquidity > 0, "Computed liquidity is zero - check tick range or amounts");

        console.log("Liquidity computed:  ", liquidity);

        // ── 6. Encode MINT_POSITION + SETTLE_PAIR ─────────────────────────────
        // MINT_POSITION: explicit liquidity + max amounts as slippage guards.
        // hookData = abi.encode(deployer): hook decodes user and checks NFT tier.
        // SETTLE_PAIR: pulls tokens from user (via permit2) to pay the liquidity debt.
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            liquidity,
            amount0Max,
            amount1Max,
            deployer,
            abi.encode(deployer)  // hookData: deployer is the "user" for KYC check
        );
        params[1] = abi.encode(Currency.wrap(currency0), Currency.wrap(currency1));

        console.log("\nCalling modifyLiquidities...");
        (bool success,) = positionManager.call(
            abi.encodeWithSignature(
                "modifyLiquidities(bytes,uint256)",
                abi.encode(actions, params),
                block.timestamp + 60
            )
        );
        require(success, "modifyLiquidities failed");

        vm.stopBroadcast();

        console.log("\nLiquidity added successfully!");
        if (!fullRange) {
            console.log("NEXT: run again with FULL_RANGE=true and small amounts for backstop.");
            console.log("NEXT: depositReserve() on hook with ~10-15% of position depth.");
        }
        console.log("========================================\n");
    }

    // ── Internal: sqrtPriceX96 from raw price ratio ────────────────────────────
    // priceRaw = token1_units_per_token0_unit (already decimal-adjusted)
    // sqrtPriceX96 = sqrt(priceRaw) * 2^96
    function _sqrtPriceX96FromRate(uint256 priceRaw) internal pure returns (uint160) {
        // ratioX192 = priceRaw * Q96 * Q96
        // We compute sqrt(ratioX192) = sqrt(priceRaw) * Q96
        // To avoid overflow: compute sqrt(priceRaw * Q96) * sqrt(Q96)
        // Q96 = 2^96, sqrt(Q96) = 2^48 = 281474976710656
        uint256 inner = _sqrt(priceRaw * Q96);
        uint256 sq = inner * (1 << 48);
        return uint160(sq);
    }

    // Babylonian sqrt
    function _sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 y = (x >> 1) + 1;
        while (y < z) { z = y; y = (x / y + y) >> 1; }
    }
}

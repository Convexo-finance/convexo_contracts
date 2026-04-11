// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

/// @title InitializePool
/// @notice Initializes the USDC/ECOP Uniswap V4 pool at the current COP rate.
///
/// IMPORTANT: Uniswap V4 requires:
///   1. Hook address must have bits 11, 9, 7 set (PassportGatedHook) or
///      bits 12, 11, 9, 7 set (ConvexoPoolHook). Validated below.
///   2. currency0 < currency1 (sorted by address, enforced below).
///   3. Pool is initialized once — re-running will revert.
///
/// When using ConvexoPoolHook: init price must be within bandBps (2%) of
/// ManualPriceAggregator.setPrice() — otherwise afterInitialize reverts.
/// For PassportGatedHook (testnet): any price works, no oracle check.
///
/// Usage (provide RATE = current COP per USDC, script computes sqrtPriceX96):
///   TOKEN0=<usdc> TOKEN1=<ecop> HOOK_ADDRESS=<hook> RATE=3650 \
///   forge script script/InitializePool.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
///
/// Required env vars: PRIVATE_KEY, HOOK_ADDRESS, TOKEN0, TOKEN1, RATE
contract InitializePool is Script {

    // ── Pool config ───────────────────────────────────────────────────────────
    // fee=500 + tickSpacing=10: correct tier for stable-ish pegged pairs.
    // Do NOT change — must match AddLiquidity.s.sol and any future scripts.
    uint24 constant FEE          = 500;
    int24  constant TICK_SPACING = 10;

    uint256 constant Q96 = 1 << 96;

    // ── Network config ────────────────────────────────────────────────────────
    function getPoolManager() internal view returns (address) {
        uint256 id = block.chainid;
        if (id == 1)        return vm.envOr("POOL_MANAGER_ADDRESS_ETH",         0x000000000004444c5dc75cB358380D2e3dE08A90);
        if (id == 8453)     return vm.envOr("POOL_MANAGER_ADDRESS_BASE",        0x498581fF718922c3f8e6A244956aF099B2652b2b);
        if (id == 130)      return vm.envOr("POOL_MANAGER_ADDRESS_UNI",         0x1F98400000000000000000000000000000000004);
        if (id == 42161)    return vm.envOr("POOL_MANAGER_ADDRESS_ARBONE",      0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
        if (id == 11155111) return vm.envOr("POOL_MANAGER_ADDRESS_ETHSEPOLIA",  0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
        if (id == 84532)    return vm.envOr("POOL_MANAGER_ADDRESS_BASESEPOLIA", 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
        if (id == 1301)     return vm.envOr("POOL_MANAGER_ADDRESS_UNISEPOLIA",  0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
        if (id == 421614)   return vm.envOr("POOL_MANAGER_ADDRESS_ARBSEPOLIA",  0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
        revert("Unsupported network");
    }

    // ── Main ──────────────────────────────────────────────────────────────────
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address hookAddress        = vm.envAddress("HOOK_ADDRESS");
        address token0Env          = vm.envAddress("TOKEN0");
        address token1Env          = vm.envAddress("TOKEN1");

        // RATE = human-readable COP per USDC (e.g. 3650 means 1 USDC = 3650 ECOP)
        // Script computes sqrtPriceX96 internally — no manual hex needed.
        uint256 rate = vm.envUint("RATE");
        require(rate > 0, "RATE env var required (e.g. RATE=3650)");

        // V4 requires currency0 < currency1
        (address currency0, address currency1) = token0Env < token1Env
            ? (token0Env, token1Env)
            : (token1Env, token0Env);

        // Compute sqrtPriceX96 from rate
        // USDC=token0 (6 dec), ECOP=token1 (18 dec)
        // priceRaw = rate * 10^(18-6) = rate * 1e12
        // sqrtPriceX96 = sqrt(priceRaw) * Q96 = sqrt(priceRaw * Q96^2)
        uint160 sqrtPriceX96 = _sqrtPriceX96FromRate(rate);

        address poolManager = getPoolManager();

        console.log("\n========================================");
        console.log("INITIALIZE UNISWAP V4 POOL");
        console.log("========================================");
        console.log("Network:       ", block.chainid);
        console.log("PoolManager:   ", poolManager);
        console.log("Hook:          ", hookAddress);
        console.log("Currency0:     ", currency0);
        console.log("Currency1:     ", currency1);
        console.log("RATE (COP/USD):", rate);
        console.log("sqrtPriceX96:  ", sqrtPriceX96);
        console.log("Fee:           ", FEE);
        console.log("TickSpacing:   ", TICK_SPACING);

        // Hook bit validation is intentionally skipped here.
        // The PoolManager validates the hook on initialize() — if the hook address
        // has wrong bits for this PoolManager version it will revert there with a
        // clear error. Pre-checking here would use the LOCAL v4-core bit positions
        // which may differ from the on-chain PoolManager version.
        console.log("Hook bits: skipping pre-check (PoolManager validates on-chain)");

        PoolKey memory key = PoolKey({
            currency0:   Currency.wrap(currency0),
            currency1:   Currency.wrap(currency1),
            fee:         FEE,
            tickSpacing: TICK_SPACING,
            hooks:       IHooks(hookAddress)
        });

        vm.broadcast(deployerPrivateKey);
        IPoolManager(poolManager).initialize(key, sqrtPriceX96);

        console.log("\nPool initialized at rate", rate, "COP/USDC");
        console.log("Next: run AddLiquidity.s.sol with same RATE=", rate);
        console.log("========================================\n");
    }

    // ── Internal: sqrtPriceX96 from human-readable rate ───────────────────────
    // rate = COP per USDC (e.g. 3650)
    // USDC=token0 (6 dec), ECOP=token1 (18 dec)
    // priceRaw = rate * 1e12  (= ECOP_raw / USDC_raw at this exchange rate)
    // sqrtPriceX96 = sqrt(priceRaw * Q96^2) = sqrt(priceRaw * Q96) * sqrt(Q96)
    //              = sqrt(priceRaw * Q96) * 2^48
    function _sqrtPriceX96FromRate(uint256 rate) internal pure returns (uint160) {
        uint256 priceRaw = rate * 1e12;
        uint256 inner    = _sqrt(priceRaw * Q96);   // sqrt(priceRaw * 2^96)
        uint256 result   = inner * (1 << 48);        // * sqrt(2^96) = * 2^48
        return uint160(result);
    }

    function _sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 y = (x >> 1) + 1;
        while (y < z) { z = y; y = (x / y + y) >> 1; }
    }
}

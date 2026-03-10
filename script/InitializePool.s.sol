// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {HookDeployer} from "../src/contracts/hooks/HookDeployer.sol";

/// @title InitializePool
/// @notice Initializes Uniswap V4 pools with PassportGatedHook for Convexo protocol
/// @dev Run after deploying contracts. Creates USDC/ECOP and EURC/ECOP pools.
///
/// IMPORTANT: Uniswap V4 requires:
///   1. Hook address must have bits 11, 9, 7 set (deployed via HookDeployer)
///   2. currency0 < currency1 (addresses sorted, lower address = currency0)
///   3. Pool is initialized once — re-running will revert (already initialized)
///
/// Usage:
///   forge script script/InitializePool.s.sol --rpc-url $RPC_URL --broadcast
///
/// Required env vars:
///   PRIVATE_KEY, POOL_MANAGER_ADDRESS_*, HOOK_ADDRESS, TOKEN0, TOKEN1,
///   INITIAL_SQRT_PRICE_X96 (optional, defaults to 1:1 price)
///
/// Example — initialize USDC/ECOP pool on Base Sepolia:
///   TOKEN0=0x036CbD...  (USDC, lower addr)
///   TOKEN1=0xb934dc...  (ECOP, higher addr)
///   HOOK_ADDRESS=<passport_gated_hook from addresses.json>
///   forge script script/InitializePool.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
contract InitializePool is Script {

    // ── Pool configuration ──────────────────────────────────────────────────

    /// @dev Fee tier: 0.3% (3000) is standard for volatile pairs, 0.05% (500) for stablecoins
    uint24 public constant FEE = 3000;

    /// @dev Tick spacing must match fee tier: 500→10, 3000→60, 10000→200
    int24 public constant TICK_SPACING = 60;

    /// @dev sqrt(1) * 2^96 — 1:1 initial price (USDC and ECOP are priced separately,
    ///      set this to reflect the actual ECOP/USDC market price at initialization)
    ///      Formula: sqrtPriceX96 = sqrt(price) * 2^96
    ///      For 1 USDC = 1 ECOP: sqrt(1) * 2^96 = 79228162514264337593543950336
    ///      For 1 USDC = 0.01 ECOP (100 ECOP/USDC): sqrt(100) * 2^96 = 792281625142643375935439503360
    uint160 public constant DEFAULT_SQRT_PRICE_X96 = 79228162514264337593543950336; // 1:1

    // ── Network configuration ───────────────────────────────────────────────

    function getPoolManager() internal view returns (address) {
        uint256 chainId = block.chainid;
        if (chainId == 1)        return vm.envOr("POOL_MANAGER_ADDRESS_ETH",        0x000000000004444c5dc75cB358380D2e3dE08A90);
        if (chainId == 8453)     return vm.envOr("POOL_MANAGER_ADDRESS_BASE",       0x498581fF718922c3f8e6A244956aF099B2652b2b);
        if (chainId == 130)      return vm.envOr("POOL_MANAGER_ADDRESS_UNI",        0x1F98400000000000000000000000000000000004);
        if (chainId == 42161)    return vm.envOr("POOL_MANAGER_ADDRESS_ARBONE",     0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
        if (chainId == 11155111) return vm.envOr("POOL_MANAGER_ADDRESS_ETHSEPOLIA", 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
        if (chainId == 84532)    return vm.envOr("POOL_MANAGER_ADDRESS_BASESEPOLIA",0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
        if (chainId == 1301)     return vm.envOr("POOL_MANAGER_ADDRESS_UNISEPOLIA", 0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
        if (chainId == 421614)   return vm.envOr("POOL_MANAGER_ADDRESS_ARBSEPOLIA", 0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
        revert("Unsupported network");
    }

    // ── Main ────────────────────────────────────────────────────────────────

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        address token0Env = vm.envAddress("TOKEN0");
        address token1Env = vm.envAddress("TOKEN1");
        uint160 sqrtPriceX96 = uint160(vm.envOr("INITIAL_SQRT_PRICE_X96", uint256(DEFAULT_SQRT_PRICE_X96)));

        // Uniswap V4 requires currency0 < currency1 (sort by address)
        (address currency0, address currency1) = token0Env < token1Env
            ? (token0Env, token1Env)
            : (token1Env, token0Env);

        address poolManager = getPoolManager();

        console.log("\n========================================");
        console.log("INITIALIZE UNISWAP V4 POOL");
        console.log("========================================");
        console.log("Network Chain ID:", block.chainid);
        console.log("PoolManager:", poolManager);
        console.log("Hook:", hookAddress);
        console.log("Currency0:", currency0);
        console.log("Currency1:", currency1);
        console.log("Fee:", FEE);
        console.log("TickSpacing:", TICK_SPACING);
        console.log("SqrtPriceX96:", sqrtPriceX96);

        // Validate hook has correct permission bits (11, 9, 7)
        uint160 hookBits = uint160(hookAddress);
        bool hasBeforeAddLiquidity = (hookBits & (1 << 11)) != 0;
        bool hasBeforeRemoveLiquidity = (hookBits & (1 << 9)) != 0;
        bool hasBeforeSwap = (hookBits & (1 << 7)) != 0;

        require(hasBeforeAddLiquidity && hasBeforeRemoveLiquidity && hasBeforeSwap,
            "Hook address missing required permission bits (11, 9, 7). Redeploy via HookDeployer.");

        console.log("Hook permission bits: OK (bits 11, 9, 7 set)");

        // Build PoolKey using official v4-core types
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(hookAddress)
        });

        // Initialize the pool
        vm.broadcast(deployerPrivateKey);
        IPoolManager(poolManager).initialize(key, sqrtPriceX96);

        console.log("\n Pool initialized successfully!");
        console.log("========================================");
        console.log("Pool ID can be computed off-chain via:");
        console.log("  keccak256(abi.encode(currency0, currency1, fee, tickSpacing, hooks))");
        console.log("========================================\n");
    }
}

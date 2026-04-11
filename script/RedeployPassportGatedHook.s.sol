// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/SafeSingletonDeployer.sol";
import {PassportGatedHook} from "../src/contracts/hooks/PassportGatedHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";

/// @title RedeployPassportGatedHook
/// @notice Finds a valid CREATE2 salt and redeploys PassportGatedHook via the
///         Safe Singleton Factory (0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7).
///
/// WHY THIS IS NEEDED:
///   The previously deployed PassportGatedHook was compiled against an older
///   v4-core with different Hooks permission bit positions. The on-chain
///   PoolManager rejects it with HookAddressNotValid.
///
///   This script uses the CURRENT v4-core bytecode + Safe Singleton Factory
///   to find and deploy a hook at a new address whose lower 14 bits are exactly
///   0x0A80 (beforeAddLiquidity + beforeRemoveLiquidity + beforeSwap).
///
/// REQUIRED ENV VARS:
///   PRIVATE_KEY             deployer private key
///   POOL_MANAGER_ADDRESS    PoolManager address (or uses chain default)
///   REPUTATION_MANAGER      ReputationManager address (0x50b81F36a95E1363288Ef44aD7E48A8CaCDFa349)
///   ADMIN                   Admin address for hook router management
///
/// USAGE:
///   forge script script/RedeployPassportGatedHook.s.sol \
///     --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
///
/// After running: update HOOK_ADDRESS in scripts/pool-init.sh and scripts/pool-add-liquidity.sh
contract RedeployPassportGatedHook is Script {

    // PassportGatedHook required permission bits (v4-core 1.0.x layout):
    //   beforeAddLiquidity    bit 11 = 0x800
    //   beforeRemoveLiquidity bit 9  = 0x200
    //   beforeSwap            bit 7  = 0x080
    //   total                       = 0xA80
    uint160 constant REQUIRED_MASK =
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.BEFORE_SWAP_FLAG;

    // All other hook bits in the lower 14 bits must be zero
    uint160 constant FORBIDDEN_MASK = uint160((1 << 14) - 1) & ~REQUIRED_MASK;

    // Known addresses
    address constant REPUTATION_MANAGER_DEFAULT = 0x50b81F36a95E1363288Ef44aD7E48A8CaCDFa349;
    address constant ADMIN_DEFAULT              = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    // Safe Singleton Factory — same address on all EVM chains
    address constant FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    uint256 constant MAX_ITERATIONS = 1_000_000;

    function getPoolManager() internal view returns (address) {
        uint256 id = block.chainid;
        if (id == 1)        return vm.envOr("POOL_MANAGER_ADDRESS", 0x000000000004444c5dc75cB358380D2e3dE08A90);
        if (id == 8453)     return vm.envOr("POOL_MANAGER_ADDRESS", 0x498581fF718922c3f8e6A244956aF099B2652b2b);
        if (id == 130)      return vm.envOr("POOL_MANAGER_ADDRESS", 0x1F98400000000000000000000000000000000004);
        if (id == 42161)    return vm.envOr("POOL_MANAGER_ADDRESS", 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
        if (id == 11155111) return vm.envOr("POOL_MANAGER_ADDRESS", 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
        if (id == 84532)    return vm.envOr("POOL_MANAGER_ADDRESS", 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
        if (id == 1301)     return vm.envOr("POOL_MANAGER_ADDRESS", 0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
        if (id == 421614)   return vm.envOr("POOL_MANAGER_ADDRESS", 0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
        revert("Unsupported network");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager        = getPoolManager();
        address reputationManager  = vm.envOr("REPUTATION_MANAGER", REPUTATION_MANAGER_DEFAULT);
        address admin              = vm.envOr("ADMIN", ADMIN_DEFAULT);

        bytes memory creationCode = type(PassportGatedHook).creationCode;
        bytes memory args         = abi.encode(IPoolManager(poolManager), ReputationManager(reputationManager), admin);

        console.log("\n========================================");
        console.log("REDEPLOY PassportGatedHook");
        console.log("========================================");
        console.log("Network chain ID:  ", block.chainid);
        console.log("PoolManager:       ", poolManager);
        console.log("ReputationManager: ", reputationManager);
        console.log("Admin:             ", admin);
        console.log("Required bits:     0x0A80");
        console.log("Searching for valid salt (up to", MAX_ITERATIONS, "iterations)...\n");

        // ── Find valid salt (off-chain, no tx needed) ──────────────────────────
        // We compute CREATE2 addresses inline (raw keccak256) to avoid the overhead
        // of calling vm.computeCreate2Address in a hot loop.
        //
        // CREATE2 address = keccak256(0xff ++ factory ++ salt ++ initcodeHash)[12:]
        // initcodeHash    = keccak256(creationCode ++ args)
        bytes32 initcodeHash = keccak256(abi.encodePacked(creationCode, args));

        // Starting salt: chain-specific to avoid reuse across networks
        bytes32 startingSalt = keccak256(abi.encodePacked("PassportGatedHook-v2", block.chainid));

        bytes32 foundSalt;
        address predictedAddress;
        bool found = false;

        for (uint256 i = 0; i < MAX_ITERATIONS; i++) {
            bytes32 candidate = bytes32(uint256(startingSalt) + i);
            address predicted = address(uint160(uint256(keccak256(
                abi.encodePacked(bytes1(0xff), FACTORY, candidate, initcodeHash)
            ))));

            if (_hasValidPermissions(predicted)) {
                foundSalt        = candidate;
                predictedAddress = predicted;
                found            = true;
                console.log("Found valid salt after", i + 1, "iterations");
                console.log("Salt:              ", vm.toString(foundSalt));
                console.log("Predicted address: ", predictedAddress);
                break;
            }
        }

        require(found, "No valid salt found within iteration limit");

        // ── Check if already deployed ──────────────────────────────────────────
        uint256 existingCode;
        assembly { existingCode := extcodesize(predictedAddress) }

        if (existingCode > 0) {
            console.log("\n[SKIP] PassportGatedHook already deployed at:", predictedAddress);
            console.log("Update pool-init.sh HOOK_ADDRESS to:", predictedAddress);
            return;
        }

        // ── Deploy ─────────────────────────────────────────────────────────────
        console.log("\nDeploying PassportGatedHook...");
        address deployed = SafeSingletonDeployer.broadcastDeploy(
            deployerPrivateKey,
            creationCode,
            args,
            foundSalt
        );

        require(deployed == predictedAddress, "Deployed address mismatch");

        console.log("\n========================================");
        console.log("[SUCCESS] PassportGatedHook deployed at:", deployed);
        console.log("========================================");
        console.log("\nNEXT STEPS:");
        console.log("1. Update scripts/pool-init.sh:         HOOK_ADDRESS=", deployed);
        console.log("2. Update scripts/pool-add-liquidity.sh HOOK_ADDRESS=", deployed);
        console.log("3. Run: ./scripts/mint-test-nft.sh (if not already done)");
        console.log("4. Run: ./scripts/pool-init.sh");
        console.log("5. Run: ./scripts/pool-add-liquidity.sh");
        console.log("========================================\n");
    }

    function _hasValidPermissions(address addr) internal pure returns (bool) {
        uint160 bits = uint160(addr);
        return (bits & REQUIRED_MASK) == REQUIRED_MASK && (bits & FORBIDDEN_MASK) == 0;
    }
}

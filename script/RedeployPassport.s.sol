// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/SafeSingletonDeployer.sol";

import {Convexo_Passport} from "../src/contracts/identity/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/identity/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/identity/Limited_Partners_Business.sol";
import {Ecreditscoring} from "../src/contracts/credits/Ecreditscoring.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";
import {HookDeployer} from "../src/contracts/hooks/HookDeployer.sol";

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title RedeployPassport
/// @notice Targeted redeploy: Convexo_Passport → ReputationManager → PassportGatedHook
///         for a single chain, without touching LP contracts or other infrastructure.
///
/// Use when Convexo_Passport bytecode changes (e.g. devMode expiry guard) and the
/// chain-specific passport + downstream contracts need to be refreshed.
///
/// Usage (ETH Sepolia):
///   PRIVATE_KEY=... \
///   PASSPORT_VERSION=convexo.v3.19 \
///   HOOK_DEPLOYER=0x69068b03dDb9Ca72B532dB694F075D91e08fB402 \
///   LP_INDIVIDUALS=0xE244e4B2B37EA6f6453d3154da548e7f2e1e5Df3 \
///   LP_BUSINESS=0x70cFe52560Dc2DD981d2374bB6b01c2170E5597B \
///   ECREDITSCORING=0xa448Aa6bfd5bA16BBd756cAF8E2cd68b31b51D88 \
///   POOL_MANAGER=0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
///   forge script script/RedeployPassport.s.sol \
///     --rpc-url https://eth-sepolia.g.alchemy.com/v2/<key> \
///     --broadcast -vv
contract RedeployPassport is Script {
    address public constant ADMIN       = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;
    address public constant ZKPASSPORT  = 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8;
    string  public constant METADATA    = "https://metadata.convexo.finance/passport";

    // Results (logged at end)
    address public newPassport;
    address public newReputationManager;
    address public newHook;

    function isDeployed(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory version   = vm.envOr("PASSPORT_VERSION", string("convexo.v3.19"));
        bytes32 saltPrefix      = keccak256(abi.encodePacked(version));

        address hookDeployerAddr = vm.envAddress("HOOK_DEPLOYER");
        address lpIndividuals    = vm.envAddress("LP_INDIVIDUALS");
        address lpBusiness       = vm.envAddress("LP_BUSINESS");
        address ecreditscoring   = vm.envAddress("ECREDITSCORING");
        address poolManager      = vm.envAddress("POOL_MANAGER");

        console.log("=== RedeployPassport ===");
        console.log("Version:", version);
        console.log("Chain:", block.chainid);
        console.log("ADMIN:", ADMIN);

        // ── 1. Convexo_Passport ──────────────────────────────────────────────
        bytes32 passportSalt = keccak256(abi.encodePacked(saltPrefix, "ConvexoPassport"));
        bytes memory passportArgs = abi.encode(ADMIN, METADATA, ZKPASSPORT);

        newPassport = SafeSingletonDeployer.computeAddress(
            type(Convexo_Passport).creationCode,
            passportArgs,
            passportSalt
        );

        if (isDeployed(newPassport)) {
            console.log("[SKIP] Convexo_Passport already at:", newPassport);
        } else {
            newPassport = SafeSingletonDeployer.broadcastDeploy(
                deployerPrivateKey,
                type(Convexo_Passport).creationCode,
                passportArgs,
                passportSalt
            );
            console.log("[NEW]  Convexo_Passport:", newPassport);
        }

        // ── 2. ReputationManager ─────────────────────────────────────────────
        bytes32 repSalt = keccak256(abi.encodePacked(saltPrefix, "ReputationManager"));
        bytes memory repArgs = abi.encode(newPassport, lpIndividuals, lpBusiness, ecreditscoring);

        newReputationManager = SafeSingletonDeployer.computeAddress(
            type(ReputationManager).creationCode,
            repArgs,
            repSalt
        );

        if (isDeployed(newReputationManager)) {
            console.log("[SKIP] ReputationManager already at:", newReputationManager);
        } else {
            newReputationManager = SafeSingletonDeployer.broadcastDeploy(
                deployerPrivateKey,
                type(ReputationManager).creationCode,
                repArgs,
                repSalt
            );
            console.log("[NEW]  ReputationManager:", newReputationManager);
        }

        // ── 3. PassportGatedHook (address bits must be 0x0A80) ───────────────
        bytes32 hookStartingSalt = keccak256(abi.encodePacked(saltPrefix, "chain", block.chainid, "PassportGatedHook"));

        (bytes32 hookSalt, address predictedHook) = HookDeployer(hookDeployerAddr).findSalt(
            IPoolManager(poolManager),
            ReputationManager(newReputationManager),
            ADMIN,
            hookStartingSalt,
            500000
        );

        if (isDeployed(predictedHook)) {
            console.log("[SKIP] PassportGatedHook already at:", predictedHook);
            newHook = predictedHook;
        } else {
            vm.broadcast(deployerPrivateKey);
            newHook = address(
                HookDeployer(hookDeployerAddr).deploy(
                    IPoolManager(poolManager),
                    ReputationManager(newReputationManager),
                    ADMIN,
                    hookSalt
                )
            );
            console.log("[NEW]  PassportGatedHook:", newHook);
            console.log("       Hook salt:", vm.toString(hookSalt));
        }

        // ── Summary ──────────────────────────────────────────────────────────
        console.log("\n=== RESULTS (update addresses.json + frontend addresses.ts) ===");
        console.log("convexo_passport:    ", newPassport);
        console.log("reputation_manager:  ", newReputationManager);
        console.log("passport_gated_hook: ", newHook);
        console.log("\nNext steps:");
        console.log("1. allow-router on new hook");
        console.log("2. forge script InitializePool.s.sol with new hook + RATE env var");
        console.log("3. forge script AddLiquidity.s.sol");
        console.log("4. Update addresses.json for chain", block.chainid);
        console.log("5. Update convexo_frontend/lib/contracts/addresses.ts");
        console.log("6. Re-extract ABIs: bash scripts/extract-abis.sh");
    }
}

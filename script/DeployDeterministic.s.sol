// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/SafeSingletonDeployer.sol";

// identity/
import {Convexo_Passport} from "../src/contracts/identity/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/identity/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/identity/Limited_Partners_Business.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";
import {VeriffVerifier} from "../src/contracts/identity/VeriffVerifier.sol";
import {SumsubVerifier} from "../src/contracts/identity/SumsubVerifier.sol";

// credits/
import {Ecreditscoring} from "../src/contracts/credits/Ecreditscoring.sol";
import {ContractSigner} from "../src/contracts/credits/ContractSigner.sol";
import {VaultFactory} from "../src/contracts/credits/VaultFactory.sol";

// hooks/
import {PoolRegistry} from "../src/contracts/hooks/PoolRegistry.sol";
import {HookDeployer} from "../src/contracts/hooks/HookDeployer.sol";
import {PassportGatedHook} from "../src/contracts/hooks/PassportGatedHook.sol";

// Interfaces
import {ILimitedPartnersIndividuals} from "../src/interfaces/ILimitedPartnersIndividuals.sol";
import {ILimitedPartnersBusiness} from "../src/interfaces/ILimitedPartnersBusiness.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title DeployDeterministic
/// @notice Deploys all Convexo MVP contracts to deterministic addresses using Safe Singleton Factory.
///
/// Phase 2 contracts (PriceFeedManager, ManualPriceAggregator, ConvexoHookDeployer,
/// ConvexoPoolHook) are implemented in src/contracts/oracles/ and src/contracts/hooks/
/// but NOT deployed here — they will be added in a future script when the oracle
/// price-band feature is enabled.
///
/// ===============================================================================
/// DETERMINISTIC DEPLOYMENT STRATEGY:
/// ===============================================================================
/// 1. All addresses are computed BEFORE deployment using CREATE2
/// 2. Contracts can reference each other because addresses are predictable
/// 3. Same salt + same bytecode = same address on ANY chain
/// 4. Safe Singleton Factory (0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7) is pre-deployed
///    on all major EVM chains
/// 5. If a contract already exists at the computed address, deployment is SKIPPED
/// ===============================================================================
contract DeployDeterministic is Script {
    // ========================================================================
    // CONFIGURATION
    // ========================================================================

    /// @notice Salt version — bump to get new addresses after ABI-breaking changes.
    ///         Example: DEPLOY_VERSION=convexo.v3.18 ./scripts/deploy.sh base-sepolia
    string public constant DEFAULT_VERSION = "convexo.v3.18";

    /// @notice Admin address — MUST be same across all chains for same addresses.
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    string public constant CONVEXO_PASSPORT_METADATA_URI = "https://metadata.convexo.finance/passport";

    function getSaltPrefix() internal view returns (bytes32) {
        string memory version = vm.envOr("DEPLOY_VERSION", DEFAULT_VERSION);
        return keccak256(abi.encodePacked(version));
    }

    // ========================================================================
    // DEPLOYED CONTRACT ADDRESSES
    // ========================================================================

    // NFTs
    address public convexoPassport;
    address public lpIndividuals;
    address public lpBusiness;
    address public ecreditscoring;

    // Verifiers
    address public veriffVerifier;
    address public sumsubVerifier;

    // Infrastructure
    address public reputationManager;
    address public contractSigner;
    address public poolRegistry;
    address public hookDeployer;
    address public vaultFactory;

    // Chain-specific
    address public passportGatedHook;

    // ========================================================================
    // HELPERS
    // ========================================================================

    function getSalt(string memory contractName) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(getSaltPrefix(), contractName));
    }

    function isDeployed(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function deployIfNeeded(
        uint256 deployerPrivateKey,
        bytes memory creationCode,
        bytes memory args,
        bytes32 salt,
        string memory name
    ) internal returns (address) {
        address predicted = SafeSingletonDeployer.computeAddress(creationCode, args, salt);
        if (isDeployed(predicted)) {
            console.log(string.concat("[SKIP] ", name, " already deployed:"), predicted);
            return predicted;
        }
        address deployed = SafeSingletonDeployer.broadcastDeploy(deployerPrivateKey, creationCode, args, salt);
        console.log(string.concat("[NEW] Deployed ", name, ":"), deployed);
        return deployed;
    }

    // ========================================================================
    // NETWORK CONFIGURATION
    // ========================================================================

    function getZKPassportVerifier() internal pure returns (address) {
        return 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8;
    }

    function getNetworkConfig(uint256 chainId)
        internal
        view
        returns (string memory networkName, address poolManager, address usdc)
    {
        if (chainId == 11155111) {
            networkName = "Ethereum Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ETHSEPOLIA", 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
            usdc = vm.envOr("USDC_ADDRESS_ETHSEPOLIA", 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);
        } else if (chainId == 84532) {
            networkName = "Base Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_BASESEPOLIA", 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
            usdc = vm.envOr("USDC_ADDRESS_BASESEPOLIA", 0x036CbD53842c5426634e7929541eC2318f3dCF7e);
        } else if (chainId == 1301) {
            networkName = "Unichain Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_UNISEPOLIA", 0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
            usdc = vm.envOr("USDC_ADDRESS_UNISEPOLIA", 0x31d0220469e10c4E71834a79b1f276d740d3768F);
        } else if (chainId == 1) {
            networkName = "Ethereum Mainnet";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ETHMAINNET", 0x000000000004444c5dc75cB358380D2e3dE08A90);
            usdc = vm.envOr("USDC_ADDRESS_ETHMAINNET", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        } else if (chainId == 8453) {
            networkName = "Base Mainnet";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_BASEMAINNET", 0x498581fF718922c3f8e6A244956aF099B2652b2b);
            usdc = vm.envOr("USDC_ADDRESS_BASEMAINNET", 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        } else if (chainId == 130) {
            networkName = "Unichain Mainnet";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_UNIMAINNET", 0x1F98400000000000000000000000000000000004);
            usdc = vm.envOr("USDC_ADDRESS_UNIMAINNET", 0x078D782b760474a361dDA0AF3839290b0EF57AD6);
        } else if (chainId == 421614) {
            networkName = "Arbitrum Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ARBSEPOLIA", 0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
            usdc = vm.envOr("USDC_ADDRESS_ARBSEPOLIA", 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d);
        } else if (chainId == 42161) {
            networkName = "Arbitrum One";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ARBONE", 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
            usdc = vm.envOr("USDC_ADDRESS_ARBONE", 0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        } else {
            revert("Unsupported network");
        }
    }

    // ========================================================================
    // ADDRESS PREDICTION
    // ========================================================================

    function predictAllAddresses(address minter) public view {
        console.log("\n========================================");
        console.log("PREDICTED ADDRESSES (Same on All Chains)");
        console.log("========================================\n");

        address predictedPassport = SafeSingletonDeployer.computeAddress(
            type(Convexo_Passport).creationCode,
            abi.encode(ADMIN, CONVEXO_PASSPORT_METADATA_URI, getZKPassportVerifier()),
            getSalt("ConvexoPassport")
        );
        console.log("Convexo_Passport:", predictedPassport);

        address predictedLpIndividuals = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Individuals).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPIndividuals")
        );
        address predictedVeriffVerifier = SafeSingletonDeployer.computeAddress(
            type(VeriffVerifier).creationCode,
            abi.encode(ADMIN, predictedLpIndividuals),
            getSalt("VeriffVerifier")
        );
        console.log("VeriffVerifier:", predictedVeriffVerifier);

        address predictedLpBusiness = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Business).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPBusiness")
        );
        address predictedSumsubVerifier = SafeSingletonDeployer.computeAddress(
            type(SumsubVerifier).creationCode,
            abi.encode(ADMIN, predictedLpBusiness),
            getSalt("SumsubVerifier")
        );
        console.log("SumsubVerifier:", predictedSumsubVerifier);
        console.log("Limited_Partners_Individuals:", predictedLpIndividuals);
        console.log("Limited_Partners_Business:", predictedLpBusiness);

        address predictedEcreditscoring = SafeSingletonDeployer.computeAddress(
            type(Ecreditscoring).creationCode,
            abi.encode(ADMIN, minter, predictedLpIndividuals, predictedLpBusiness),
            getSalt("Ecreditscoring")
        );
        console.log("Ecreditscoring:", predictedEcreditscoring);

        address predictedReputationManager = SafeSingletonDeployer.computeAddress(
            type(ReputationManager).creationCode,
            abi.encode(predictedPassport, predictedLpIndividuals, predictedLpBusiness, predictedEcreditscoring),
            getSalt("ReputationManager")
        );
        console.log("ReputationManager:", predictedReputationManager);

        address predictedContractSigner = SafeSingletonDeployer.computeAddress(
            type(ContractSigner).creationCode, abi.encode(ADMIN), getSalt("ContractSigner")
        );
        console.log("ContractSigner:", predictedContractSigner);

        address predictedPoolRegistry = SafeSingletonDeployer.computeAddress(
            type(PoolRegistry).creationCode, abi.encode(ADMIN), getSalt("PoolRegistry")
        );
        console.log("PoolRegistry:", predictedPoolRegistry);

        address predictedHookDeployer =
            SafeSingletonDeployer.computeAddress(type(HookDeployer).creationCode, "", getSalt("HookDeployer"));
        console.log("HookDeployer:", predictedHookDeployer);

        console.log("\n========================================\n");
    }

    // ========================================================================
    // MAIN DEPLOYMENT
    // ========================================================================

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.envAddress("MINTER_ADDRESS");
        address protocolFeeCollector = vm.envOr("PROTOCOL_FEE_COLLECTOR", ADMIN);

        uint256 chainId = block.chainid;
        (string memory networkName, address poolManager, address usdc) = getNetworkConfig(chainId);

        console.log("\n========================================");
        console.log("DETERMINISTIC DEPLOYMENT - MVP");
        console.log("========================================");
        console.log("Network:", networkName);
        console.log("Chain ID:", chainId);
        console.log("Admin:", ADMIN);
        console.log("Minter:", minter);
        console.log("Salt Prefix:", vm.toString(getSaltPrefix()));
        console.log("========================================\n");

        predictAllAddresses(minter);

        // ====================================================================
        // Phase 1: Core NFTs + Verifiers
        // ====================================================================
        console.log("Phase 1: Core Contracts...\n");

        convexoPassport = deployIfNeeded(
            deployerPrivateKey,
            type(Convexo_Passport).creationCode,
            abi.encode(ADMIN, CONVEXO_PASSPORT_METADATA_URI, getZKPassportVerifier()),
            getSalt("ConvexoPassport"),
            "Convexo_Passport"
        );

        lpIndividuals = deployIfNeeded(
            deployerPrivateKey,
            type(Limited_Partners_Individuals).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPIndividuals"),
            "Limited_Partners_Individuals"
        );

        lpBusiness = deployIfNeeded(
            deployerPrivateKey,
            type(Limited_Partners_Business).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPBusiness"),
            "Limited_Partners_Business"
        );

        veriffVerifier = deployIfNeeded(
            deployerPrivateKey,
            type(VeriffVerifier).creationCode,
            abi.encode(ADMIN, lpIndividuals),
            getSalt("VeriffVerifier"),
            "VeriffVerifier"
        );

        sumsubVerifier = deployIfNeeded(
            deployerPrivateKey,
            type(SumsubVerifier).creationCode,
            abi.encode(ADMIN, lpBusiness),
            getSalt("SumsubVerifier"),
            "SumsubVerifier"
        );

        ecreditscoring = deployIfNeeded(
            deployerPrivateKey,
            type(Ecreditscoring).creationCode,
            abi.encode(ADMIN, minter, lpIndividuals, lpBusiness),
            getSalt("Ecreditscoring"),
            "Ecreditscoring"
        );

        // ====================================================================
        // Phase 2: Infrastructure
        // ====================================================================
        console.log("\nPhase 2: Infrastructure...\n");

        reputationManager = deployIfNeeded(
            deployerPrivateKey,
            type(ReputationManager).creationCode,
            abi.encode(convexoPassport, lpIndividuals, lpBusiness, ecreditscoring),
            getSalt("ReputationManager"),
            "ReputationManager"
        );

        contractSigner = deployIfNeeded(
            deployerPrivateKey,
            type(ContractSigner).creationCode,
            abi.encode(ADMIN),
            getSalt("ContractSigner"),
            "ContractSigner"
        );

        poolRegistry = deployIfNeeded(
            deployerPrivateKey,
            type(PoolRegistry).creationCode,
            abi.encode(ADMIN),
            getSalt("PoolRegistry"),
            "PoolRegistry"
        );

        hookDeployer = deployIfNeeded(
            deployerPrivateKey,
            type(HookDeployer).creationCode,
            "",
            getSalt("HookDeployer"),
            "HookDeployer"
        );

        // ====================================================================
        // Phase 3: Chain-Specific (PassportGatedHook + VaultFactory)
        // ====================================================================
        console.log("\nPhase 3: Chain-Specific Contracts...\n");

        bytes32 chainSalt = keccak256(abi.encodePacked(getSaltPrefix(), "chain", chainId));

        // PassportGatedHook — deployed via HookDeployer so address bits == 0x0A80
        // (beforeAddLiquidity + beforeRemoveLiquidity + beforeSwap)
        if (poolManager != address(0)) {
            bytes32 hookStartingSalt = keccak256(abi.encodePacked(chainSalt, "PassportGatedHook"));
            (bytes32 hookSalt, address predictedHook) = HookDeployer(hookDeployer).findSalt(
                IPoolManager(poolManager),
                ReputationManager(reputationManager),
                ADMIN,
                hookStartingSalt,
                500000
            );

            if (isDeployed(predictedHook)) {
                console.log("[SKIP] PassportGatedHook already deployed:", predictedHook);
                passportGatedHook = predictedHook;
            } else {
                vm.broadcast(deployerPrivateKey);
                passportGatedHook = address(
                    HookDeployer(hookDeployer).deploy(
                        IPoolManager(poolManager),
                        ReputationManager(reputationManager),
                        ADMIN,
                        hookSalt
                    )
                );
                console.log("[NEW] Deployed PassportGatedHook:", passportGatedHook);
                console.log("      Hook salt used:", vm.toString(hookSalt));
            }
        }

        if (usdc != address(0)) {
            vaultFactory = deployIfNeeded(
                deployerPrivateKey,
                type(VaultFactory).creationCode,
                abi.encode(ADMIN, usdc, protocolFeeCollector, contractSigner, reputationManager),
                keccak256(abi.encodePacked(chainSalt, "VaultFactory")),
                "VaultFactory"
            );
        }

        // ====================================================================
        // Phase 4: Role Setup
        // ====================================================================
        console.log("\nPhase 4: Roles...\n");

        bytes32 MINTER_CALLBACK_ROLE = keccak256("MINTER_CALLBACK_ROLE");

        if (!VeriffVerifier(veriffVerifier).hasRole(MINTER_CALLBACK_ROLE, lpIndividuals)) {
            vm.broadcast(deployerPrivateKey);
            VeriffVerifier(veriffVerifier).addMinterCallback(lpIndividuals);
            console.log("[NEW] Granted MINTER_CALLBACK_ROLE to LP_Individuals on VeriffVerifier");
        } else {
            console.log("[SKIP] MINTER_CALLBACK_ROLE already granted to LP_Individuals");
        }

        if (!SumsubVerifier(sumsubVerifier).hasRole(MINTER_CALLBACK_ROLE, lpBusiness)) {
            vm.broadcast(deployerPrivateKey);
            SumsubVerifier(sumsubVerifier).addMinterCallback(lpBusiness);
            console.log("[NEW] Granted MINTER_CALLBACK_ROLE to LP_Business on SumsubVerifier");
        } else {
            console.log("[SKIP] MINTER_CALLBACK_ROLE already granted to LP_Business");
        }

        // ====================================================================
        // SUMMARY
        // ====================================================================
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("\n--- DETERMINISTIC (Same on All Chains) ---");
        console.log("Convexo_Passport:              ", convexoPassport);
        console.log("Limited_Partners_Individuals:  ", lpIndividuals);
        console.log("Limited_Partners_Business:     ", lpBusiness);
        console.log("Ecreditscoring:                ", ecreditscoring);
        console.log("VeriffVerifier:                ", veriffVerifier);
        console.log("SumsubVerifier:                ", sumsubVerifier);
        console.log("ReputationManager:             ", reputationManager);
        console.log("ContractSigner:                ", contractSigner);
        console.log("PoolRegistry:                  ", poolRegistry);
        console.log("HookDeployer:                  ", hookDeployer);
        console.log("\n--- CHAIN-SPECIFIC ---");
        console.log("PassportGatedHook:             ", passportGatedHook);
        console.log("VaultFactory:                  ", vaultFactory);
        console.log("\n========================================");
        console.log("Phase 2 (oracle + ConvexoPoolHook): script/DeployPhase2.s.sol");
        console.log("Next: Initialize pool via script/InitializePool.s.sol");
        console.log("========================================\n");
    }
}

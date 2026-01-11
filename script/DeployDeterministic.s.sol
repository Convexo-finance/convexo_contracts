// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/SafeSingletonDeployer.sol";

// Import all contracts
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {Ecreditscoring} from "../src/contracts/Ecreditscoring.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";
import {VeriffVerifier} from "../src/contracts/VeriffVerifier.sol";
import {SumsubVerifier} from "../src/contracts/SumsubVerifier.sol";
import {PoolRegistry} from "../src/contracts/PoolRegistry.sol";
import {PriceFeedManager} from "../src/contracts/PriceFeedManager.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {TreasuryFactory} from "../src/contracts/TreasuryFactory.sol";
import {HookDeployer} from "../src/hooks/HookDeployer.sol";
import {PassportGatedHook} from "../src/hooks/PassportGatedHook.sol";

// Interfaces
import {ILimitedPartnersIndividuals} from "../src/interfaces/ILimitedPartnersIndividuals.sol";
import {ILimitedPartnersBusiness} from "../src/interfaces/ILimitedPartnersBusiness.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title DeployDeterministic
/// @notice Deploys all Convexo contracts to deterministic addresses using Safe Singleton Factory
/// @dev Uses CREATE2 via Safe Singleton Factory for same addresses across all chains
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

    /// @notice Default salt version - can be overridden via DEPLOY_VERSION env var
    /// @dev Change version to get new addresses after contract changes
    ///      Example: DEPLOY_VERSION=v3.1 ./scripts/deploy.sh ethereum-sepolia
    string public constant DEFAULT_VERSION = "convexo.v3.15";

    /// @notice Admin address - MUST be same across all chains for same addresses
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    /// @notice Get salt prefix (from env or default)
    function getSaltPrefix() internal view returns (bytes32) {
        string memory version = vm.envOr("DEPLOY_VERSION", DEFAULT_VERSION);
        return keccak256(abi.encodePacked(version));
    }

    /// @notice Metadata URI for Convexo Passport
    string public constant CONVEXO_PASSPORT_METADATA_URI = "https://metadata.convexo.finance/passport";

    // ========================================================================
    // DEPLOYED CONTRACT ADDRESSES (will be same on all chains)
    // ========================================================================

    // NFT Contracts
    address public convexoPassport;
    address public lpIndividuals;
    address public lpBusiness;
    address public ecreditscoring;

    // Verifiers
    address public veriffVerifier;
    address public sumsubVerifier;

    // Infrastructure
    address public reputationManager;
    address public poolRegistry;
    address public priceFeedManager;
    address public contractSigner;
    address public vaultFactory;
    address public treasuryFactory;
    address public hookDeployer;
    address public passportGatedHook;

    // ========================================================================
    // SALT GENERATORS
    // ========================================================================

    function getSalt(string memory contractName) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(getSaltPrefix(), contractName));
    }

    /// @notice Check if a contract already exists at an address
    function isDeployed(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /// @notice Deploy via CREATE2 only if not already deployed
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

        address deployed = SafeSingletonDeployer.broadcastDeploy(
            deployerPrivateKey,
            creationCode,
            args,
            salt
        );
        console.log(string.concat("[NEW] Deployed ", name, ":"), deployed);
        return deployed;
    }

    // ========================================================================
    // NETWORK CONFIGURATION
    // ========================================================================

    function getZKPassportVerifier() internal pure returns (address) {
        // Same verifier address on all networks
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
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ETHMAINNET", 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A);
            usdc = vm.envOr("USDC_ADDRESS_ETHMAINNET", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        } else if (chainId == 8453) {
            networkName = "Base Mainnet";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_BASEMAINNET", 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829);
            usdc = vm.envOr("USDC_ADDRESS_BASEMAINNET", 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        } else if (chainId == 130) {
            networkName = "Unichain Mainnet";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_UNIMAINNET", 0x1F98400000000000000000000000000000000004);
            usdc = vm.envOr("USDC_ADDRESS_UNIMAINNET", 0x078D782b760474a361dDA0AF3839290b0EF57AD6);
        } else {
            revert("Unsupported network");
        }
    }

    // ========================================================================
    // ADDRESS PREDICTION (Call before deployment to get addresses)
    // ========================================================================

    function predictAllAddresses(address minter) public view {
        console.log("\n========================================");
        console.log("PREDICTED ADDRESSES (Same on All Chains)");
        console.log("========================================\n");

        // Predict addresses in deployment order

        // 1. Convexo Passport (constructor takes: admin, initialBaseURI)
        address predictedPassport = SafeSingletonDeployer.computeAddress(
            type(Convexo_Passport).creationCode,
            abi.encode(ADMIN, CONVEXO_PASSPORT_METADATA_URI),
            getSalt("ConvexoPassport")
        );
        console.log("Convexo_Passport:", predictedPassport);

        // 2. Veriff Verifier (needs LP Individuals address - predict it first)
        address predictedLpIndividuals = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Individuals).creationCode,
            abi.encode(ADMIN, minter, address(0)), // verifier will be set separately
            getSalt("LPIndividuals")
        );

        address predictedVeriffVerifier = SafeSingletonDeployer.computeAddress(
            type(VeriffVerifier).creationCode,
            abi.encode(ADMIN, predictedLpIndividuals),
            getSalt("VeriffVerifier")
        );
        console.log("VeriffVerifier:", predictedVeriffVerifier);

        // 3. Sumsub Verifier (needs LP Business address - predict it first)
        address predictedLpBusiness = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Business).creationCode,
            abi.encode(ADMIN, minter, address(0)), // verifier will be set separately
            getSalt("LPBusiness")
        );

        address predictedSumsubVerifier = SafeSingletonDeployer.computeAddress(
            type(SumsubVerifier).creationCode,
            abi.encode(ADMIN, predictedLpBusiness),
            getSalt("SumsubVerifier")
        );
        console.log("SumsubVerifier:", predictedSumsubVerifier);

        // Note: LP contracts with verifier callback would have different addresses
        // For deterministic deployment, we deploy without callback and set it up post-deployment
        console.log("Limited_Partners_Individuals:", predictedLpIndividuals);
        console.log("Limited_Partners_Business:", predictedLpBusiness);

        // 4. Ecreditscoring
        address predictedEcreditscoring = SafeSingletonDeployer.computeAddress(
            type(Ecreditscoring).creationCode,
            abi.encode(ADMIN, minter, predictedLpIndividuals, predictedLpBusiness),
            getSalt("Ecreditscoring")
        );
        console.log("Ecreditscoring:", predictedEcreditscoring);

        // 5. Reputation Manager
        address predictedReputationManager = SafeSingletonDeployer.computeAddress(
            type(ReputationManager).creationCode,
            abi.encode(predictedPassport, predictedLpIndividuals, predictedLpBusiness, predictedEcreditscoring),
            getSalt("ReputationManager")
        );
        console.log("ReputationManager:", predictedReputationManager);

        // 6. Contract Signer
        address predictedContractSigner = SafeSingletonDeployer.computeAddress(
            type(ContractSigner).creationCode, abi.encode(ADMIN), getSalt("ContractSigner")
        );
        console.log("ContractSigner:", predictedContractSigner);

        // 7. Pool Registry
        address predictedPoolRegistry = SafeSingletonDeployer.computeAddress(
            type(PoolRegistry).creationCode, abi.encode(ADMIN), getSalt("PoolRegistry")
        );
        console.log("PoolRegistry:", predictedPoolRegistry);

        // 8. Price Feed Manager
        address predictedPriceFeedManager = SafeSingletonDeployer.computeAddress(
            type(PriceFeedManager).creationCode, abi.encode(ADMIN), getSalt("PriceFeedManager")
        );
        console.log("PriceFeedManager:", predictedPriceFeedManager);

        // 9. Hook Deployer
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
        console.log("DETERMINISTIC DEPLOYMENT");
        console.log("========================================");
        console.log("Network:", networkName);
        console.log("Chain ID:", chainId);
        console.log("Admin:", ADMIN);
        console.log("Minter:", minter);
        console.log("Salt Prefix:", vm.toString(getSaltPrefix()));
        console.log("========================================\n");

        // Show predicted addresses first
        predictAllAddresses(minter);

        // ========================================================================
        // Phase 1: Deploy Core NFTs and Verifiers
        // ========================================================================
        console.log("Phase 1: Deploying Core Contracts...\n");

        // 1. Convexo Passport (constructor takes: admin, initialBaseURI)
        convexoPassport = deployIfNeeded(
            deployerPrivateKey,
            type(Convexo_Passport).creationCode,
            abi.encode(ADMIN, CONVEXO_PASSPORT_METADATA_URI),
            getSalt("ConvexoPassport"),
            "Convexo_Passport"
        );

        // 2. LP Individuals (without verifier callback for deterministic address)
        lpIndividuals = deployIfNeeded(
            deployerPrivateKey,
            type(Limited_Partners_Individuals).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPIndividuals"),
            "Limited_Partners_Individuals"
        );

        // 3. LP Business (without verifier callback for deterministic address)
        lpBusiness = deployIfNeeded(
            deployerPrivateKey,
            type(Limited_Partners_Business).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPBusiness"),
            "Limited_Partners_Business"
        );

        // 4. Veriff Verifier (references LP Individuals)
        veriffVerifier = deployIfNeeded(
            deployerPrivateKey,
            type(VeriffVerifier).creationCode,
            abi.encode(ADMIN, lpIndividuals),
            getSalt("VeriffVerifier"),
            "VeriffVerifier"
        );

        // 5. Sumsub Verifier (references LP Business)
        sumsubVerifier = deployIfNeeded(
            deployerPrivateKey,
            type(SumsubVerifier).creationCode,
            abi.encode(ADMIN, lpBusiness),
            getSalt("SumsubVerifier"),
            "SumsubVerifier"
        );

        // 6. Ecreditscoring
        ecreditscoring = deployIfNeeded(
            deployerPrivateKey,
            type(Ecreditscoring).creationCode,
            abi.encode(ADMIN, minter, lpIndividuals, lpBusiness),
            getSalt("Ecreditscoring"),
            "Ecreditscoring"
        );

        // ========================================================================
        // Phase 2: Deploy Infrastructure
        // ========================================================================
        console.log("\nPhase 2: Deploying Infrastructure...\n");

        // 7. Reputation Manager
        reputationManager = deployIfNeeded(
            deployerPrivateKey,
            type(ReputationManager).creationCode,
            abi.encode(convexoPassport, lpIndividuals, lpBusiness, ecreditscoring),
            getSalt("ReputationManager"),
            "ReputationManager"
        );

        // 8. Contract Signer
        contractSigner = deployIfNeeded(
            deployerPrivateKey,
            type(ContractSigner).creationCode,
            abi.encode(ADMIN),
            getSalt("ContractSigner"),
            "ContractSigner"
        );

        // 9. Pool Registry
        poolRegistry = deployIfNeeded(
            deployerPrivateKey,
            type(PoolRegistry).creationCode,
            abi.encode(ADMIN),
            getSalt("PoolRegistry"),
            "PoolRegistry"
        );

        // 10. Price Feed Manager
        priceFeedManager = deployIfNeeded(
            deployerPrivateKey,
            type(PriceFeedManager).creationCode,
            abi.encode(ADMIN),
            getSalt("PriceFeedManager"),
            "PriceFeedManager"
        );

        // 11. Hook Deployer
        hookDeployer = deployIfNeeded(
            deployerPrivateKey,
            type(HookDeployer).creationCode,
            "",
            getSalt("HookDeployer"),
            "HookDeployer"
        );

        // ========================================================================
        // Phase 3: Deploy Network-Specific Contracts (different per chain)
        // ========================================================================
        console.log("\nPhase 3: Deploying Network-Specific Contracts...\n");

        // These contracts have chain-specific dependencies (poolManager, usdc)
        // so they will have different addresses per chain
        // Using chain-specific salt to make them deterministic per chain

        bytes32 chainSalt = keccak256(abi.encodePacked(getSaltPrefix(), "chain", chainId));

        if (poolManager != address(0)) {
            passportGatedHook = deployIfNeeded(
                deployerPrivateKey,
                type(PassportGatedHook).creationCode,
                abi.encode(poolManager, reputationManager),
                keccak256(abi.encodePacked(chainSalt, "PassportGatedHook")),
                "PassportGatedHook"
            );
        }

        if (usdc != address(0)) {
            vaultFactory = deployIfNeeded(
                deployerPrivateKey,
                type(VaultFactory).creationCode,
                abi.encode(ADMIN, usdc, protocolFeeCollector, contractSigner, reputationManager),
                keccak256(abi.encodePacked(chainSalt, "VaultFactory")),
                "VaultFactory"
            );

            treasuryFactory = deployIfNeeded(
                deployerPrivateKey,
                type(TreasuryFactory).creationCode,
                abi.encode(usdc, reputationManager),
                keccak256(abi.encodePacked(chainSalt, "TreasuryFactory")),
                "TreasuryFactory"
            );
        }

        // ========================================================================
        // Phase 4: Setup Roles (skip if already configured)
        // ========================================================================
        console.log("\nPhase 4: Setting up Roles...\n");

        // Grant MINTER_CALLBACK_ROLE to LP contracts (skip if already granted)
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

        // ========================================================================
        // DEPLOYMENT SUMMARY
        // ========================================================================
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("========================================");

        console.log("\n--- DETERMINISTIC ADDRESSES (Same on All Chains) ---");
        console.log("Convexo_Passport:", convexoPassport);
        console.log("Limited_Partners_Individuals:", lpIndividuals);
        console.log("Limited_Partners_Business:", lpBusiness);
        console.log("Ecreditscoring:", ecreditscoring);
        console.log("VeriffVerifier:", veriffVerifier);
        console.log("SumsubVerifier:", sumsubVerifier);
        console.log("ReputationManager:", reputationManager);
        console.log("ContractSigner:", contractSigner);
        console.log("PoolRegistry:", poolRegistry);
        console.log("PriceFeedManager:", priceFeedManager);
        console.log("HookDeployer:", hookDeployer);

        console.log("\n--- CHAIN-SPECIFIC ADDRESSES ---");
        console.log("PassportGatedHook:", passportGatedHook);
        console.log("VaultFactory:", vaultFactory);
        console.log("TreasuryFactory:", treasuryFactory);

        console.log("\n========================================");
        console.log("NOTE: LP contracts deployed without verifier callback");
        console.log("The markAsMinted callback requires manual status update");
        console.log("or use the non-deterministic DeployAll.s.sol for full callback support");
        console.log("========================================\n");
    }
}

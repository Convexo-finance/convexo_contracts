// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {Ecreditscoring} from "../src/contracts/Ecreditscoring.sol";
import {HookDeployer} from "../src/hooks/HookDeployer.sol";
import {PassportGatedHook} from "../src/hooks/PassportGatedHook.sol";
import {PoolRegistry} from "../src/contracts/PoolRegistry.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {PriceFeedManager} from "../src/contracts/PriceFeedManager.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {TreasuryFactory} from "../src/contracts/TreasuryFactory.sol";
import {VeriffVerifier} from "../src/contracts/VeriffVerifier.sol";
import {SumsubVerifier} from "../src/contracts/SumsubVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {ILimitedPartnersIndividuals} from "../src/interfaces/ILimitedPartnersIndividuals.sol";
import {ILimitedPartnersBusiness} from "../src/interfaces/ILimitedPartnersBusiness.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title DeployAll
/// @notice Deploys all Convexo contracts in the correct order
/// @dev
/// ===============================================================================
/// NFT SYSTEM (4 NFTs):
/// ===============================================================================
/// 1. Convexo_Passport - ZKPassport (International KYC) - Tier 1
/// 2. Limited_Partners_Individuals - Veriff (Individual KYC) - Tier 2
/// 3. Limited_Partners_Business - Sumsub (Business KYB) - Tier 2
/// 4. Ecreditscoring - AI Credit Score (Vault Creation) - Tier 3
/// ===============================================================================
contract DeployAll is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    // NFT Contracts
    Convexo_Passport public convexoPassport;
    Limited_Partners_Individuals public lpIndividuals;
    Limited_Partners_Business public lpBusiness;
    Ecreditscoring public ecreditscoring;
    
    // Infrastructure
    HookDeployer public hookDeployer;
    PassportGatedHook public passportGatedHook;
    PoolRegistry public poolRegistry;
    ReputationManager public reputationManager;
    PriceFeedManager public priceFeedManager;
    ContractSigner public contractSigner;
    VaultFactory public vaultFactory;
    TreasuryFactory public treasuryFactory;
    
    // Verifiers
    VeriffVerifier public veriffVerifier;
    SumsubVerifier public sumsubVerifier;
    
    string public constant CONVEXO_PASSPORT_METADATA_URI = "https://metadata.convexo.finance/passport";
    
    /// @notice Get ZKPassport verifier address for the current network
    function getZKPassportVerifier(uint256 chainId) internal pure returns (address) {
        address verifier = 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8;
        
        if (chainId == 11155111 ||  // Ethereum Sepolia
            chainId == 84532 ||      // Base Sepolia
            chainId == 1301 ||       // Unichain Sepolia
            chainId == 1 ||          // Ethereum Mainnet
            chainId == 8453 ||       // Base Mainnet
            chainId == 130) {        // Unichain Mainnet
            return verifier;
        } else {
            revert("ZKPassport verifier not configured for this network");
        }
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.envAddress("MINTER_ADDRESS");

        uint256 chainId = block.chainid;
        address poolManager;
        address usdc;
        string memory networkName;
        
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
        
        console.log("Deploying to:", networkName);
        console.log("Chain ID:", chainId);
        console.log("PoolManager:", poolManager);
        console.log("USDC:", usdc);
        
        address protocolFeeCollector = vm.envOr("PROTOCOL_FEE_COLLECTOR", ADMIN);

        vm.startBroadcast(deployerPrivateKey);

        // ========================================================================
        // Phase 1: Deploy NFT Contracts (Tier 1-3)
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 1: Deploying NFT Contracts...");
        console.log("========================================");

        // Tier 1: Convexo Passport (ZKPassport - International KYC)
        address zkPassportVerifier = getZKPassportVerifier(chainId);
        convexoPassport = new Convexo_Passport(ADMIN, zkPassportVerifier, CONVEXO_PASSPORT_METADATA_URI);
        console.log("Convexo_Passport (Tier 1 - ZKPassport):", address(convexoPassport));

        // Tier 2: Limited Partners Individuals (Veriff - Individual KYC)
        lpIndividuals = new Limited_Partners_Individuals(ADMIN, minter);
        console.log("Limited_Partners_Individuals (Tier 2 - Veriff):", address(lpIndividuals));

        // Tier 2: Limited Partners Business (Sumsub - Business KYB)
        lpBusiness = new Limited_Partners_Business(ADMIN, minter);
        console.log("Limited_Partners_Business (Tier 2 - Sumsub):", address(lpBusiness));

        // Tier 3: Ecreditscoring (AI Credit Score - requires LP NFT)
        ecreditscoring = new Ecreditscoring(
            ADMIN,
            minter,
            IERC721(address(lpIndividuals)),
            IERC721(address(lpBusiness))
        );
        console.log("Ecreditscoring (Tier 3 - Credit Score):", address(ecreditscoring));

        // ========================================================================
        // Phase 2: Deploy Core Infrastructure
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 2: Deploying Core Infrastructure...");
        console.log("========================================");

        reputationManager = new ReputationManager(
            IERC721(address(convexoPassport)),
            IERC721(address(lpIndividuals)),
            IERC721(address(lpBusiness)),
            IERC721(address(ecreditscoring))
        );
        console.log("ReputationManager:", address(reputationManager));

        // ========================================================================
        // Phase 3: Deploy Hook System
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 3: Deploying Hook System...");
        console.log("========================================");

        hookDeployer = new HookDeployer();
        console.log("HookDeployer:", address(hookDeployer));

        if (poolManager != address(0)) {
            passportGatedHook = new PassportGatedHook(IPoolManager(poolManager), reputationManager);
            console.log("PassportGatedHook:", address(passportGatedHook));
        }

        poolRegistry = new PoolRegistry(ADMIN);
        console.log("PoolRegistry:", address(poolRegistry));

        priceFeedManager = new PriceFeedManager(ADMIN);
        console.log("PriceFeedManager:", address(priceFeedManager));

        // ========================================================================
        // Phase 4: Deploy Vault System
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 4: Deploying Vault System...");
        console.log("========================================");

        contractSigner = new ContractSigner(ADMIN);
        console.log("ContractSigner:", address(contractSigner));

        if (usdc != address(0)) {
            vaultFactory = new VaultFactory(ADMIN, usdc, protocolFeeCollector, contractSigner, reputationManager);
            console.log("VaultFactory:", address(vaultFactory));
        }

        // ========================================================================
        // Phase 5: Deploy Treasury System
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 5: Deploying Treasury System...");
        console.log("========================================");

        if (usdc != address(0)) {
            treasuryFactory = new TreasuryFactory(usdc, reputationManager);
            console.log("TreasuryFactory:", address(treasuryFactory));
        }

        // ========================================================================
        // Phase 6: Deploy Verification System
        // ========================================================================
        console.log("\n========================================");
        console.log("Phase 6: Deploying Verification System...");
        console.log("========================================");

        // VeriffVerifier - for INDIVIDUAL KYC → mints Limited_Partners_Individuals
        veriffVerifier = new VeriffVerifier(ADMIN, ILimitedPartnersIndividuals(address(lpIndividuals)));
        console.log("VeriffVerifier (Individual KYC):", address(veriffVerifier));

        // SumsubVerifier - for BUSINESS KYB → mints Limited_Partners_Business
        sumsubVerifier = new SumsubVerifier(ADMIN, ILimitedPartnersBusiness(address(lpBusiness)));
        console.log("SumsubVerifier (Business KYB):", address(sumsubVerifier));

        vm.stopBroadcast();

        // Summary
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("\nNFT Contracts (4 NFTs):");
        console.log("  [Tier 1] Convexo_Passport (ZKPassport):", address(convexoPassport));
        console.log("  [Tier 2] Limited_Partners_Individuals (Veriff):", address(lpIndividuals));
        console.log("  [Tier 2] Limited_Partners_Business (Sumsub):", address(lpBusiness));
        console.log("  [Tier 3] Ecreditscoring (Credit Score):", address(ecreditscoring));
        console.log("\nVerification System:");
        console.log("  VeriffVerifier (Individual KYC):", address(veriffVerifier));
        console.log("  SumsubVerifier (Business KYB):", address(sumsubVerifier));
        console.log("\nCore Infrastructure:");
        console.log("  ReputationManager:", address(reputationManager));
        console.log("  PriceFeedManager:", address(priceFeedManager));
        console.log("\nHook System:");
        console.log("  HookDeployer:", address(hookDeployer));
        if (address(passportGatedHook) != address(0)) {
            console.log("  PassportGatedHook:", address(passportGatedHook));
        }
        console.log("  PoolRegistry:", address(poolRegistry));
        console.log("\nVault System:");
        console.log("  ContractSigner:", address(contractSigner));
        if (address(vaultFactory) != address(0)) {
            console.log("  VaultFactory:", address(vaultFactory));
        }
        console.log("\nTreasury System:");
        if (address(treasuryFactory) != address(0)) {
            console.log("  TreasuryFactory:", address(treasuryFactory));
        }
        console.log("========================================\n");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {Convexo_Vaults} from "../src/convexovaults.sol";
import {HookDeployer} from "../src/hooks/HookDeployer.sol";
import {CompliantLPHook} from "../src/hooks/CompliantLPHook.sol";
import {PoolRegistry} from "../src/contracts/PoolRegistry.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {PriceFeedManager} from "../src/contracts/PriceFeedManager.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";

/// @title DeployAll
/// @notice Deploys all Convexo contracts in the correct order
/// @dev This script handles dependencies and saves addresses to addresses.json
contract DeployAll is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    // Deployed contract addresses
    Convexo_LPs public convexoLPs;
    Convexo_Vaults public convexoVaults;
    HookDeployer public hookDeployer;
    CompliantLPHook public compliantLPHook;
    PoolRegistry public poolRegistry;
    ReputationManager public reputationManager;
    PriceFeedManager public priceFeedManager;
    ContractSigner public contractSigner;
    VaultFactory public vaultFactory;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.envAddress("MINTER_ADDRESS");

        // Try to get network-specific variables first, fallback to generic ones
        uint256 chainId = block.chainid;
        address poolManager;
        address usdc;
        string memory networkName;
        
        if (chainId == 11155111) {
            // Ethereum Sepolia
            networkName = "Ethereum Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_ETHSEPOLIA", 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
            usdc = vm.envOr("USDC_ADDRESS_ETHSEPOLIA", 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);
        } else if (chainId == 84532) {
            // Base Sepolia
            networkName = "Base Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_BASESEPOLIA", 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
            usdc = vm.envOr("USDC_ADDRESS_BASESEPOLIA", 0x036CbD53842c5426634e7929541eC2318f3dCF7e);
        } else if (chainId == 1301) {
            // Unichain Sepolia
            networkName = "Unichain Sepolia";
            poolManager = vm.envOr("POOL_MANAGER_ADDRESS_UNISEPOLIA", 0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
            usdc = vm.envOr("USDC_ADDRESS_UNISEPOLIA", 0x31d0220469e10c4E71834a79b1f276d740d3768F);
        } else {
            revert("Unsupported network");
        }
        
        console.log("Deploying to:", networkName);
        console.log("Chain ID:", chainId);
        console.log("PoolManager:", poolManager);
        console.log("USDC:", usdc);
        
        address protocolFeeCollector = vm.envOr("PROTOCOL_FEE_COLLECTOR", ADMIN);

        vm.startBroadcast(deployerPrivateKey);

        // ============================================================
        // Phase 1: Deploy NFTs
        // ============================================================
        console.log("Phase 1: Deploying NFTs...");

        convexoLPs = new Convexo_LPs(ADMIN, minter);
        console.log("Convexo_LPs deployed at:", address(convexoLPs));

        convexoVaults = new Convexo_Vaults(ADMIN, minter);
        console.log("Convexo_Vaults deployed at:", address(convexoVaults));

        // ============================================================
        // Phase 2: Deploy Hook System
        // ============================================================
        console.log("\nPhase 2: Deploying Hook System...");

        hookDeployer = new HookDeployer();
        console.log("HookDeployer deployed at:", address(hookDeployer));

        // Only deploy hook if PoolManager is provided
        if (poolManager != address(0)) {
            compliantLPHook = new CompliantLPHook(IPoolManager(poolManager), IConvexoLPs(address(convexoLPs)));
            console.log("CompliantLPHook deployed at:", address(compliantLPHook));
        } else {
            console.log("Skipping CompliantLPHook deployment (no POOL_MANAGER_ADDRESS set)");
        }

        poolRegistry = new PoolRegistry(ADMIN);
        console.log("PoolRegistry deployed at:", address(poolRegistry));

        // ============================================================
        // Phase 3: Deploy Core Infrastructure
        // ============================================================
        console.log("\nPhase 3: Deploying Core Infrastructure...");

        reputationManager =
            new ReputationManager(IConvexoLPs(address(convexoLPs)), IConvexoVaults(address(convexoVaults)));
        console.log("ReputationManager deployed at:", address(reputationManager));

        priceFeedManager = new PriceFeedManager(ADMIN);
        console.log("PriceFeedManager deployed at:", address(priceFeedManager));

        // ============================================================
        // Phase 4: Deploy Vault System
        // ============================================================
        console.log("\nPhase 4: Deploying Vault System...");

        contractSigner = new ContractSigner(ADMIN);
        console.log("ContractSigner deployed at:", address(contractSigner));

        // Only deploy VaultFactory if USDC is provided
        if (usdc != address(0)) {
            vaultFactory = new VaultFactory(ADMIN, usdc, protocolFeeCollector, contractSigner, reputationManager);
            console.log("VaultFactory deployed at:", address(vaultFactory));
        } else {
            console.log("Skipping VaultFactory deployment (no USDC_ADDRESS set)");
        }

        vm.stopBroadcast();

        // ============================================================
        // Summary
        // ============================================================
        console.log("\n========================================");
        console.log("Deployment Complete!");
        console.log("========================================");
        console.log("\nNFTs:");
        console.log("  Convexo_LPs:", address(convexoLPs));
        console.log("  Convexo_Vaults:", address(convexoVaults));
        console.log("\nHook System:");
        console.log("  HookDeployer:", address(hookDeployer));
        if (address(compliantLPHook) != address(0)) {
            console.log("  CompliantLPHook:", address(compliantLPHook));
        }
        console.log("  PoolRegistry:", address(poolRegistry));
        console.log("\nCore Infrastructure:");
        console.log("  ReputationManager:", address(reputationManager));
        console.log("  PriceFeedManager:", address(priceFeedManager));
        console.log("\nVault System:");
        console.log("  ContractSigner:", address(contractSigner));
        if (address(vaultFactory) != address(0)) {
            console.log("  VaultFactory:", address(vaultFactory));
        }
        console.log("========================================\n");
    }
}

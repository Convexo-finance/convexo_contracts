// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/SafeSingletonDeployer.sol";

// Import all contracts for bytecode
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
import {HookDeployer} from "../src/hooks/HookDeployer.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {TreasuryFactory} from "../src/contracts/TreasuryFactory.sol";
import {PassportGatedHook} from "../src/hooks/PassportGatedHook.sol";

/// @title PredictAddresses
/// @notice Predicts all contract addresses before deployment using Safe Singleton Factory
/// @dev Run this script to see what addresses your contracts will have on ANY chain
///
/// Usage:
///   forge script script/PredictAddresses.s.sol -vvv
///   DEPLOY_VERSION=convexo.v3.1 forge script script/PredictAddresses.s.sol -vvv
///
contract PredictAddresses is Script {
    /// @notice Default version - can be overridden via DEPLOY_VERSION env var
    string public constant DEFAULT_VERSION = "convexo.v3.16";

    /// @notice Admin address - MUST be same across all chains
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    /// @notice Metadata URI for Convexo Passport
    string public constant CONVEXO_PASSPORT_METADATA_URI = "https://metadata.convexo.finance/passport";

    function getSaltPrefix() internal view returns (bytes32) {
        string memory version = vm.envOr("DEPLOY_VERSION", DEFAULT_VERSION);
        return keccak256(abi.encodePacked(version));
    }

    function getVersion() internal view returns (string memory) {
        return vm.envOr("DEPLOY_VERSION", DEFAULT_VERSION);
    }

    function getSalt(string memory contractName) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(getSaltPrefix(), contractName));
    }

    function run() external view {
        address minter = vm.envOr("MINTER_ADDRESS", ADMIN);

        console.log("\n");
        console.log("================================================================");
        console.log("    CONVEXO DETERMINISTIC ADDRESS PREDICTION");
        console.log("================================================================");
        console.log("");
        console.log("These addresses will be THE SAME on all EVM chains:");
        console.log("  - Ethereum (Mainnet & Sepolia)");
        console.log("  - Base (Mainnet & Sepolia)");
        console.log("  - Unichain (Mainnet & Sepolia)");
        console.log("  - And 240+ other chains with Safe Singleton Factory");
        console.log("");
        console.log("Configuration:");
        console.log("  Admin:", ADMIN);
        console.log("  Minter:", minter);
        console.log("  Version:", getVersion());
        console.log("");
        console.log("================================================================");
        console.log("    NFT CONTRACTS");
        console.log("================================================================");

        // 1. Convexo Passport (constructor takes: admin, initialBaseURI)
        address convexoPassport = SafeSingletonDeployer.computeAddress(
            type(Convexo_Passport).creationCode,
            abi.encode(ADMIN, CONVEXO_PASSPORT_METADATA_URI),
            getSalt("ConvexoPassport")
        );
        console.log("");
        console.log("Convexo_Passport (Tier 1 - ZKPassport)");
        console.log("  Address:", convexoPassport);

        // 2. LP Individuals
        address lpIndividuals = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Individuals).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPIndividuals")
        );
        console.log("");
        console.log("Limited_Partners_Individuals (Tier 2 - Veriff KYC)");
        console.log("  Address:", lpIndividuals);

        // 3. LP Business
        address lpBusiness = SafeSingletonDeployer.computeAddress(
            type(Limited_Partners_Business).creationCode,
            abi.encode(ADMIN, minter, address(0)),
            getSalt("LPBusiness")
        );
        console.log("");
        console.log("Limited_Partners_Business (Tier 2 - Sumsub KYB)");
        console.log("  Address:", lpBusiness);

        // 4. Ecreditscoring
        address ecreditscoring = SafeSingletonDeployer.computeAddress(
            type(Ecreditscoring).creationCode,
            abi.encode(ADMIN, minter, lpIndividuals, lpBusiness),
            getSalt("Ecreditscoring")
        );
        console.log("");
        console.log("Ecreditscoring (Tier 3 - AI Credit Score)");
        console.log("  Address:", ecreditscoring);

        console.log("");
        console.log("================================================================");
        console.log("    VERIFICATION SYSTEM");
        console.log("================================================================");

        // 5. Veriff Verifier
        address veriffVerifier = SafeSingletonDeployer.computeAddress(
            type(VeriffVerifier).creationCode, abi.encode(ADMIN, lpIndividuals), getSalt("VeriffVerifier")
        );
        console.log("");
        console.log("VeriffVerifier (Individual KYC)");
        console.log("  Address:", veriffVerifier);

        // 6. Sumsub Verifier
        address sumsubVerifier = SafeSingletonDeployer.computeAddress(
            type(SumsubVerifier).creationCode, abi.encode(ADMIN, lpBusiness), getSalt("SumsubVerifier")
        );
        console.log("");
        console.log("SumsubVerifier (Business KYB)");
        console.log("  Address:", sumsubVerifier);

        console.log("");
        console.log("================================================================");
        console.log("    INFRASTRUCTURE");
        console.log("================================================================");

        // 7. Reputation Manager
        address reputationManager = SafeSingletonDeployer.computeAddress(
            type(ReputationManager).creationCode,
            abi.encode(convexoPassport, lpIndividuals, lpBusiness, ecreditscoring),
            getSalt("ReputationManager")
        );
        console.log("");
        console.log("ReputationManager");
        console.log("  Address:", reputationManager);

        // 8. Contract Signer
        address contractSigner = SafeSingletonDeployer.computeAddress(
            type(ContractSigner).creationCode, abi.encode(ADMIN), getSalt("ContractSigner")
        );
        console.log("");
        console.log("ContractSigner");
        console.log("  Address:", contractSigner);

        // 9. Pool Registry
        address poolRegistry =
            SafeSingletonDeployer.computeAddress(type(PoolRegistry).creationCode, abi.encode(ADMIN), getSalt("PoolRegistry"));
        console.log("");
        console.log("PoolRegistry");
        console.log("  Address:", poolRegistry);

        // 10. Price Feed Manager
        address priceFeedManager = SafeSingletonDeployer.computeAddress(
            type(PriceFeedManager).creationCode, abi.encode(ADMIN), getSalt("PriceFeedManager")
        );
        console.log("");
        console.log("PriceFeedManager");
        console.log("  Address:", priceFeedManager);

        // 11. Hook Deployer
        address hookDeployer =
            SafeSingletonDeployer.computeAddress(type(HookDeployer).creationCode, "", getSalt("HookDeployer"));
        console.log("");
        console.log("HookDeployer");
        console.log("  Address:", hookDeployer);

        console.log("");
        console.log("================================================================");
        console.log("    CHAIN-SPECIFIC CONTRACTS");
        console.log("================================================================");

        // Compute chain-specific addresses for all supported chains
        _printChainSpecificAddresses(11155111, "Ethereum Sepolia", reputationManager, contractSigner);
        _printChainSpecificAddresses(84532, "Base Sepolia", reputationManager, contractSigner);
        _printChainSpecificAddresses(1301, "Unichain Sepolia", reputationManager, contractSigner);
        _printChainSpecificAddresses(1, "Ethereum Mainnet", reputationManager, contractSigner);
        _printChainSpecificAddresses(8453, "Base Mainnet", reputationManager, contractSigner);
        _printChainSpecificAddresses(130, "Unichain Mainnet", reputationManager, contractSigner);

        console.log("");
        console.log("================================================================");
        console.log("    NOTES");
        console.log("================================================================");
        console.log("");
        console.log("1. Core contracts (above) have the SAME address on all chains.");
        console.log("2. Chain-specific contracts have DIFFERENT addresses per chain.");
        console.log("3. To deploy a new version, use:");
        console.log("   DEPLOY_VERSION=convexo.v3.2 ./scripts/deploy.sh <network>");
        console.log("");
        console.log("================================================================");
        console.log("");
    }

    function _printChainSpecificAddresses(
        uint256 chainId,
        string memory chainName,
        address reputationManager,
        address contractSigner
    ) internal view {
        (address usdc, address poolManager) = _getChainConfig(chainId);
        address protocolFeeCollector = ADMIN;

        bytes32 chainSalt = keccak256(abi.encodePacked(getSaltPrefix(), "chain", chainId));

        address passportGatedHook = SafeSingletonDeployer.computeAddress(
            type(PassportGatedHook).creationCode,
            abi.encode(poolManager, reputationManager),
            keccak256(abi.encodePacked(chainSalt, "PassportGatedHook"))
        );

        address vaultFactory = SafeSingletonDeployer.computeAddress(
            type(VaultFactory).creationCode,
            abi.encode(ADMIN, usdc, protocolFeeCollector, contractSigner, reputationManager),
            keccak256(abi.encodePacked(chainSalt, "VaultFactory"))
        );

        address treasuryFactory = SafeSingletonDeployer.computeAddress(
            type(TreasuryFactory).creationCode,
            abi.encode(usdc, reputationManager),
            keccak256(abi.encodePacked(chainSalt, "TreasuryFactory"))
        );

        console.log("");
        console.log(chainName, "(Chain ID:", chainId, ")");
        console.log("  PassportGatedHook:");
        console.log("    Address:", passportGatedHook);
        console.log("  VaultFactory:");
        console.log("    Address:", vaultFactory);
        console.log("  TreasuryFactory:");
        console.log("    Address:", treasuryFactory);
    }

    function _getChainConfig(uint256 chainId) internal pure returns (address usdc, address poolManager) {
        if (chainId == 11155111) {
            usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
            poolManager = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
        } else if (chainId == 84532) {
            usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
            poolManager = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
        } else if (chainId == 1301) {
            usdc = 0x31d0220469e10c4E71834a79b1f276d740d3768F;
            poolManager = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
        } else if (chainId == 1) {
            usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            poolManager = 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A;
        } else if (chainId == 8453) {
            usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
            poolManager = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829;
        } else if (chainId == 130) {
            usdc = 0x078D782b760474a361dDA0AF3839290b0EF57AD6;
            poolManager = 0x1F98400000000000000000000000000000000004;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {TreasuryFactory} from "../src/contracts/TreasuryFactory.sol";
import {TreasuryVault} from "../src/contracts/TreasuryVault.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {Convexo_Vaults} from "../src/convexovaults.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, ProofVerificationParams, DisclosedData} from "../src/interfaces/IZKPassportVerifier.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/// @notice Mock ZKPassport Verifier for testing
contract MockZKPassportVerifier is IZKPassportVerifier {
    function verifyProof(
        ProofVerificationParams calldata,
        bool
    ) external view returns (bool success, DisclosedData memory disclosedData) {
        success = true;
        disclosedData = DisclosedData({
            kycVerified: true,
            faceMatchPassed: true,
            sanctionsPassed: true,
            isOver18: true,
            verifiedAt: block.timestamp
        });
    }
}

contract TreasuryFactoryTest is Test {
    TreasuryFactory public treasuryFactory;
    ReputationManager public reputationManager;
    Convexo_LPs public convexoLPs;
    Convexo_Vaults public convexoVaults;
    Convexo_Passport public convexoPassport;
    MockZKPassportVerifier public mockVerifier;
    ERC20Mock public usdc;

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public passportHolder = address(0x3);
    address public lpHolder = address(0x4);
    address public vaultHolder = address(0x5);
    address public noNFTUser = address(0x6);
    address public signer1 = address(0x7);
    address public signer2 = address(0x8);
    address public signer3 = address(0x9);

    function setUp() public {
        // Deploy USDC mock
        usdc = new ERC20Mock();

        // Deploy NFT contracts
        vm.startPrank(admin);
        convexoLPs = new Convexo_LPs(admin, minter);
        convexoVaults = new Convexo_Vaults(admin, minter);

        mockVerifier = new MockZKPassportVerifier();
        convexoPassport = new Convexo_Passport(admin, address(mockVerifier), "https://metadata.convexo.finance/passport");
        vm.stopPrank();

        // Deploy ReputationManager
        reputationManager = new ReputationManager(
            IConvexoLPs(address(convexoLPs)),
            IConvexoVaults(address(convexoVaults)),
            IConvexoPassport(address(convexoPassport))
        );

        // Deploy TreasuryFactory
        treasuryFactory = new TreasuryFactory(address(usdc), reputationManager);

        // Mint some USDC to users for testing
        usdc.mint(passportHolder, 10000e6);
        usdc.mint(lpHolder, 10000e6);
        usdc.mint(vaultHolder, 10000e6);
    }

    function test_CreateTreasury_PassportHolder_SingleSig() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(passportHolder);
        convexoPassport.safeMintWithZKPassport(params, false);

        // Create single-sig treasury (empty signers array)
        address[] memory signers = new address[](0);

        vm.prank(passportHolder);
        vm.expectEmit(true, false, false, true);
        emit TreasuryCreated(0, address(0), passportHolder, 1, 1);

        (uint256 treasuryId, address treasuryAddress) = treasuryFactory.createTreasury(signers, 1);

        assertEq(treasuryId, 0);
        assertEq(treasuryFactory.getTreasury(0), treasuryAddress);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);
        assertEq(treasury.owner(), passportHolder);
        assertEq(treasury.signaturesRequired(), 1);
        assertEq(treasury.getSignerCount(), 1);
        assertTrue(treasury.isAuthorizedSigner(passportHolder));
    }

    function test_CreateTreasury_LPHolder_MultiSig() public {
        // Mint LPs NFT
        vm.prank(minter);
        convexoLPs.safeMint(lpHolder, "COMPANY123", "ipfs://test");

        // Create multi-sig treasury (3 signers, 2 required)
        address[] memory signers = new address[](3);
        signers[0] = lpHolder;
        signers[1] = signer1;
        signers[2] = signer2;

        vm.prank(lpHolder);
        (uint256 treasuryId, address treasuryAddress) = treasuryFactory.createTreasury(signers, 2);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);
        assertEq(treasury.owner(), lpHolder);
        assertEq(treasury.signaturesRequired(), 2);
        assertEq(treasury.getSignerCount(), 3);
        assertTrue(treasury.isAuthorizedSigner(lpHolder));
        assertTrue(treasury.isAuthorizedSigner(signer1));
        assertTrue(treasury.isAuthorizedSigner(signer2));
    }

    function test_CreateTreasury_VaultHolder() public {
        // Mint Vaults NFT
        vm.prank(minter);
        convexoVaults.safeMint(vaultHolder, "COMPANY456", "ipfs://test");

        // Vault holders (Tier 3) can also create treasuries
        address[] memory signers = new address[](0);

        vm.prank(vaultHolder);
        (uint256 treasuryId, address treasuryAddress) = treasuryFactory.createTreasury(signers, 1);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);
        assertEq(treasury.owner(), vaultHolder);
    }

    function test_CreateTreasury_RevertsForNoNFT() public {
        address[] memory signers = new address[](0);

        vm.prank(noNFTUser);
        vm.expectRevert("Must have Tier 1+ (Convexo_Passport or higher)");
        treasuryFactory.createTreasury(signers, 1);
    }

    function test_GetTreasuriesByOwner() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(passportHolder);
        convexoPassport.safeMintWithZKPassport(params, false);

        // Create multiple treasuries
        address[] memory signers = new address[](0);

        vm.startPrank(passportHolder);
        treasuryFactory.createTreasury(signers, 1);
        treasuryFactory.createTreasury(signers, 1);
        treasuryFactory.createTreasury(signers, 1);
        vm.stopPrank();

        uint256[] memory ownerTreasuries = treasuryFactory.getTreasuriesByOwner(passportHolder);
        assertEq(ownerTreasuries.length, 3);
        assertEq(ownerTreasuries[0], 0);
        assertEq(ownerTreasuries[1], 1);
        assertEq(ownerTreasuries[2], 2);
    }

    function test_TreasuryDeposit() public {
        // Create treasury
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(passportHolder);
        convexoPassport.safeMintWithZKPassport(params, false);

        address[] memory signers = new address[](0);

        vm.prank(passportHolder);
        (, address treasuryAddress) = treasuryFactory.createTreasury(signers, 1);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);

        // Deposit USDC
        vm.startPrank(passportHolder);
        usdc.approve(treasuryAddress, 1000e6);
        treasury.deposit(1000e6);
        vm.stopPrank();

        assertEq(treasury.getBalance(), 1000e6);
    }

    function test_TreasurySingleSigWithdrawal() public {
        // Setup treasury with deposit
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(passportHolder);
        convexoPassport.safeMintWithZKPassport(params, false);

        address[] memory signers = new address[](0);

        vm.prank(passportHolder);
        (, address treasuryAddress) = treasuryFactory.createTreasury(signers, 1);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);

        vm.startPrank(passportHolder);
        usdc.approve(treasuryAddress, 1000e6);
        treasury.deposit(1000e6);

        // Propose withdrawal (automatically executes for single-sig)
        treasury.proposeWithdrawal(signer1, 500e6);
        vm.stopPrank();

        assertEq(treasury.getBalance(), 500e6);
        assertEq(usdc.balanceOf(signer1), 500e6);
    }

    function test_TreasuryMultiSigWithdrawal() public {
        // Mint LPs NFT
        vm.prank(minter);
        convexoLPs.safeMint(lpHolder, "COMPANY123", "ipfs://test");

        // Create multi-sig treasury
        address[] memory signers = new address[](3);
        signers[0] = lpHolder;
        signers[1] = signer1;
        signers[2] = signer2;

        vm.prank(lpHolder);
        (, address treasuryAddress) = treasuryFactory.createTreasury(signers, 2);

        TreasuryVault treasury = TreasuryVault(treasuryAddress);

        // Deposit
        vm.startPrank(lpHolder);
        usdc.approve(treasuryAddress, 1000e6);
        treasury.deposit(1000e6);

        // Propose withdrawal
        uint256 withdrawalId = treasury.proposeWithdrawal(signer3, 600e6);
        vm.stopPrank();

        // First signature already applied by proposer
        (,,, bool executed, uint256 signatureCount) = treasury.getWithdrawalProposal(withdrawalId);
        assertEq(signatureCount, 1);
        assertFalse(executed);

        // Second signer signs (should execute automatically)
        vm.prank(signer1);
        treasury.signWithdrawal(withdrawalId);

        (,,, executed, signatureCount) = treasury.getWithdrawalProposal(withdrawalId);
        assertEq(signatureCount, 2);
        assertTrue(executed);

        assertEq(treasury.getBalance(), 400e6);
        assertEq(usdc.balanceOf(signer3), 600e6);
    }

    function test_GetTreasuryCount() public {
        // Mint NFTs
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(passportHolder);
        convexoPassport.safeMintWithZKPassport(params, false);

        vm.prank(minter);
        convexoLPs.safeMint(lpHolder, "COMPANY123", "ipfs://test");

        assertEq(treasuryFactory.getTreasuryCount(), 0);

        address[] memory signers = new address[](0);

        vm.prank(passportHolder);
        treasuryFactory.createTreasury(signers, 1);
        assertEq(treasuryFactory.getTreasuryCount(), 1);

        vm.prank(lpHolder);
        treasuryFactory.createTreasury(signers, 1);
        assertEq(treasuryFactory.getTreasuryCount(), 2);
    }

    event TreasuryCreated(
        uint256 indexed treasuryId,
        address indexed treasuryAddress,
        address indexed owner,
        uint256 signaturesRequired,
        uint256 signerCount
    );
}

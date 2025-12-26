// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {Convexo_Vaults} from "../src/convexovaults.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, ProofVerificationParams, DisclosedData} from "../src/interfaces/IZKPassportVerifier.sol";

/// @notice Mock ZKPassport Verifier for testing
contract MockZKPassportVerifier is IZKPassportVerifier {
    function verifyProof(
        ProofVerificationParams calldata,
        bool
    ) external view returns (bool success, DisclosedData memory disclosedData) {
        success = true;
        disclosedData = DisclosedData({
            nationality: "US",
            isOver18: true,
            verifiedAt: block.timestamp
        });
    }
}

contract ReputationManagerPassportTest is Test {
    ReputationManager public reputationManager;
    Convexo_LPs public convexoLPs;
    Convexo_Vaults public convexoVaults;
    Convexo_Passport public convexoPassport;
    MockZKPassportVerifier public mockVerifier;

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public user3 = address(0x5);
    address public user4 = address(0x6);

    function setUp() public {
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
    }

    function test_TierNone_NoNFTs() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.None));
        assertFalse(reputationManager.hasCompliantAccess(user1));
        assertFalse(reputationManager.hasCreditscoreAccess(user1));
        assertFalse(reputationManager.hasPassportAccess(user1));
    }

    function test_TierCompliant_OnlyLPs() public {
        // Mint LPs NFT
        vm.prank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");

        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Compliant));
        assertTrue(reputationManager.hasCompliantAccess(user1));
        assertFalse(reputationManager.hasCreditscoreAccess(user1));
        assertFalse(reputationManager.hasPassportAccess(user1));
    }

    function test_TierCreditscore_BothBusinessNFTs() public {
        // Mint both business NFTs
        vm.startPrank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");
        convexoVaults.safeMint(user1, "https://uri.com/2", "");
        vm.stopPrank();

        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Creditscore));
        assertTrue(reputationManager.hasCompliantAccess(user1));
        assertTrue(reputationManager.hasCreditscoreAccess(user1));
        assertFalse(reputationManager.hasPassportAccess(user1));
    }

    function test_TierPassport_OnlyPassportNFT() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Passport));
        assertFalse(reputationManager.hasCompliantAccess(user1));
        assertFalse(reputationManager.hasCreditscoreAccess(user1));
        assertTrue(reputationManager.hasPassportAccess(user1));
        assertTrue(reputationManager.holdsConvexoPassport(user1));
    }

    function test_MutuallyExclusive_PassportAndBusinessNFTs() public {
        // Mint Passport NFT first
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        // Try to mint business NFT
        vm.prank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");

        // Should revert when checking reputation
        vm.expectRevert("Cannot hold both business and individual NFTs");
        reputationManager.getReputationTier(user1);
    }

    function test_GetReputationDetails_WithPassport() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        (
            ReputationManager.ReputationTier tier,
            uint256 lpsBalance,
            uint256 vaultsBalance,
            uint256 passportBalance
        ) = reputationManager.getReputationDetails(user1);

        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Passport));
        assertEq(lpsBalance, 0);
        assertEq(vaultsBalance, 0);
        assertEq(passportBalance, 1);
    }

    function test_GetReputationDetails_WithBusinessNFTs() public {
        // Mint both business NFTs
        vm.startPrank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");
        convexoVaults.safeMint(user1, "https://uri.com/2", "");
        vm.stopPrank();

        (
            ReputationManager.ReputationTier tier,
            uint256 lpsBalance,
            uint256 vaultsBalance,
            uint256 passportBalance
        ) = reputationManager.getReputationDetails(user1);

        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Creditscore));
        assertEq(lpsBalance, 1);
        assertEq(vaultsBalance, 1);
        assertEq(passportBalance, 0);
    }

    function test_CheckReputationWithEvent_Passport() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        vm.expectEmit(true, false, false, true);
        emit ReputationChecked(
            user1,
            ReputationManager.ReputationTier.Passport,
            0,
            0,
            1
        );
        
        ReputationManager.ReputationTier tier = reputationManager.checkReputationWithEvent(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Passport));
    }

    function test_MultipleUsers_DifferentTiers() public {
        // User1: No NFTs (Tier 0)
        assertEq(uint256(reputationManager.getReputationTier(user1)), uint256(ReputationManager.ReputationTier.None));

        // User2: LPs only (Tier 1)
        vm.prank(minter);
        convexoLPs.safeMint(user2, "https://uri.com/1", "");
        assertEq(uint256(reputationManager.getReputationTier(user2)), uint256(ReputationManager.ReputationTier.Compliant));

        // User3: LPs + Vaults (Tier 2)
        vm.startPrank(minter);
        convexoLPs.safeMint(user3, "https://uri.com/2", "");
        convexoVaults.safeMint(user3, "https://uri.com/3", "");
        vm.stopPrank();
        assertEq(uint256(reputationManager.getReputationTier(user3)), uint256(ReputationManager.ReputationTier.Creditscore));

        // User4: Passport (Tier 3)
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });
        vm.prank(user4);
        convexoPassport.safeMintWithZKPassport(params, false);
        assertEq(uint256(reputationManager.getReputationTier(user4)), uint256(ReputationManager.ReputationTier.Passport));
    }

    function test_RequireCompliantAccess_FailsForPassport() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        // Passport tier (3) is not >= Compliant tier (1) in business path
        vm.expectRevert("Must have Compliant tier or higher");
        reputationManager.requireCompliantAccess(user1);
    }

    function test_RequireCreditscoreAccess_FailsForPassport() public {
        // Mint Passport NFT
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        convexoPassport.safeMintWithZKPassport(params, false);

        vm.expectRevert("Must have Creditscore tier");
        reputationManager.requireCreditscoreAccess(user1);
    }

    event ReputationChecked(
        address indexed user,
        ReputationManager.ReputationTier tier,
        uint256 lpsBalance,
        uint256 vaultsBalance,
        uint256 passportBalance
    );
}


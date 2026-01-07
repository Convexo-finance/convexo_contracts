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
            kycVerified: true,
            faceMatchPassed: true,
            sanctionsPassed: true,
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
        assertFalse(reputationManager.canCreateTreasury(user1));
        assertFalse(reputationManager.canInvestInVaults(user1));
        assertFalse(reputationManager.canAccessLPPools(user1));
        assertFalse(reputationManager.canCreateVaults(user1));
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
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.Passport)); // Tier 1
        assertTrue(reputationManager.canCreateTreasury(user1));
        assertTrue(reputationManager.canInvestInVaults(user1));
        assertFalse(reputationManager.canAccessLPPools(user1)); // Cannot access LP pools
        assertFalse(reputationManager.canCreateVaults(user1)); // Cannot create vaults
        assertTrue(reputationManager.hasPassportAccess(user1));
        assertTrue(reputationManager.holdsConvexoPassport(user1));
    }

    function test_TierLimitedPartner_OnlyLPs() public {
        // Mint LPs NFT
        vm.prank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");

        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.LimitedPartner)); // Tier 2
        assertTrue(reputationManager.canCreateTreasury(user1)); // Tier 2 includes Tier 1 benefits
        assertTrue(reputationManager.canInvestInVaults(user1));
        assertTrue(reputationManager.canAccessLPPools(user1));
        assertFalse(reputationManager.canCreateVaults(user1)); // Cannot create vaults yet
        assertTrue(reputationManager.hasLimitedPartnerAccess(user1));
        assertFalse(reputationManager.hasVaultCreatorAccess(user1));
        assertFalse(reputationManager.hasPassportAccess(user1));
    }

    function test_TierVaultCreator_OnlyVaultsNFT() public {
        // Mint Vaults NFT only (highest tier wins, even without LPs)
        vm.prank(minter);
        convexoVaults.safeMint(user1, "https://uri.com/1", "");

        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.VaultCreator)); // Tier 3
        assertTrue(reputationManager.canCreateTreasury(user1));
        assertTrue(reputationManager.canInvestInVaults(user1));
        assertTrue(reputationManager.canAccessLPPools(user1)); // Tier 3 includes Tier 2 benefits
        assertTrue(reputationManager.canCreateVaults(user1));
        assertTrue(reputationManager.hasVaultCreatorAccess(user1));
        assertFalse(reputationManager.hasPassportAccess(user1));
    }

    function test_HighestTierWins_VaultsWithPassport() public {
        // User has both Passport and Vaults NFT - highest tier (Vaults = Tier 3) wins
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

        // Mint Vaults NFT
        vm.prank(minter);
        convexoVaults.safeMint(user1, "https://uri.com/1", "");

        // Should return Tier 3 (VaultCreator) - highest tier wins
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.VaultCreator));
        assertTrue(reputationManager.canCreateVaults(user1));
        assertTrue(reputationManager.hasVaultCreatorAccess(user1));
    }

    function test_HighestTierWins_LPsWithPassport() public {
        // User has both Passport and LPs NFT - highest tier (LPs = Tier 2) wins
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

        // Mint LPs NFT
        vm.prank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/2", "");

        // Should return Tier 2 (LimitedPartner) - highest tier wins
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.LimitedPartner));
        assertTrue(reputationManager.canAccessLPPools(user1));
        assertTrue(reputationManager.hasLimitedPartnerAccess(user1));
    }

    function test_HighestTierWins_AllThreeNFTs() public {
        // User has all three NFTs - highest tier (Vaults = Tier 3) wins
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

        // Mint both business NFTs
        vm.startPrank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");
        convexoVaults.safeMint(user1, "https://uri.com/2", "");
        vm.stopPrank();

        // Should return Tier 3 (VaultCreator) - highest tier wins
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(user1);
        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.VaultCreator));
        assertTrue(reputationManager.canCreateVaults(user1));
        assertTrue(reputationManager.canAccessLPPools(user1));
        assertTrue(reputationManager.canInvestInVaults(user1));
        assertTrue(reputationManager.canCreateTreasury(user1));
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

    function test_GetReputationDetails_WithVaultsNFT() public {
        // Mint Vaults NFT (Tier 3)
        vm.prank(minter);
        convexoVaults.safeMint(user1, "https://uri.com/1", "");

        (
            ReputationManager.ReputationTier tier,
            uint256 lpsBalance,
            uint256 vaultsBalance,
            uint256 passportBalance
        ) = reputationManager.getReputationDetails(user1);

        assertEq(uint256(tier), uint256(ReputationManager.ReputationTier.VaultCreator));
        assertEq(lpsBalance, 0);
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

        // User2: Passport (Tier 1)
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });
        vm.prank(user2);
        convexoPassport.safeMintWithZKPassport(params, false);
        assertEq(uint256(reputationManager.getReputationTier(user2)), uint256(ReputationManager.ReputationTier.Passport));

        // User3: LPs only (Tier 2)
        vm.prank(minter);
        convexoLPs.safeMint(user3, "https://uri.com/1", "");
        assertEq(uint256(reputationManager.getReputationTier(user3)), uint256(ReputationManager.ReputationTier.LimitedPartner));

        // User4: Vaults (Tier 3)
        vm.prank(minter);
        convexoVaults.safeMint(user4, "https://uri.com/2", "");
        assertEq(uint256(reputationManager.getReputationTier(user4)), uint256(ReputationManager.ReputationTier.VaultCreator));
    }

    function test_RequireLimitedPartnerAccess_FailsForPassport() public {
        // Mint Passport NFT (Tier 1)
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

        // Passport tier (1) is not >= LimitedPartner tier (2)
        vm.expectRevert("Must have LimitedPartner tier or higher");
        reputationManager.requireLimitedPartnerAccess(user1);
    }

    function test_RequireVaultCreatorAccess_FailsForPassport() public {
        // Mint Passport NFT (Tier 1)
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

        vm.expectRevert("Must have VaultCreator tier");
        reputationManager.requireVaultCreatorAccess(user1);
    }

    function test_RequireLimitedPartnerAccess_PassesForLPs() public {
        // This test verifies LPs holders can pass LimitedPartner access check
        vm.prank(minter);
        convexoLPs.safeMint(user1, "https://uri.com/1", "");

        // Should not revert
        reputationManager.requireLimitedPartnerAccess(user1);
    }

    function test_RequireVaultCreatorAccess_PassesForVaults() public {
        // This test verifies Vaults holders can pass VaultCreator access check
        vm.prank(minter);
        convexoVaults.safeMint(user1, "https://uri.com/1", "");

        // Should not revert
        reputationManager.requireVaultCreatorAccess(user1);
    }

    event ReputationChecked(
        address indexed user,
        ReputationManager.ReputationTier tier,
        uint256 lpsBalance,
        uint256 vaultsBalance,
        uint256 passportBalance
    );
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {Ecreditscoring} from "../src/contracts/Ecreditscoring.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ReputationManagerTest is Test {
    ReputationManager public reputationManager;
    Convexo_Passport public passport;
    Limited_Partners_Individuals public lpIndividuals;
    Limited_Partners_Business public lpBusiness;
    Ecreditscoring public ecreditscoring;

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public passportHolder = address(0x3);
    address public individualLPHolder = address(0x4);
    address public businessLPHolder = address(0x5);
    address public creditHolder = address(0x6);
    address public noNFTHolder = address(0x7);

    function setUp() public {
        // Deploy NFT contracts - use address(this) as admin for test convenience
        passport = new Convexo_Passport(address(this), "https://metadata");
        lpIndividuals = new Limited_Partners_Individuals(address(this), address(this), address(0));
        lpBusiness = new Limited_Partners_Business(address(this), address(this), address(0));
        ecreditscoring = new Ecreditscoring(
            address(this),
            address(this),
            IERC721(address(lpIndividuals)),
            IERC721(address(lpBusiness))
        );

        // Deploy ReputationManager
        reputationManager = new ReputationManager(
            IERC721(address(passport)),
            IERC721(address(lpIndividuals)),
            IERC721(address(lpBusiness)),
            IERC721(address(ecreditscoring))
        );

        // Setup holders
        // Passport holder (Tier 1) - mint via ZKPassport
        _mintPassportForUser(passportHolder, 1);

        // Individual LP holder (Tier 2)
        lpIndividuals.safeMint(individualLPHolder, "veriff_123", "");

        // Business LP holder (Tier 2)
        lpBusiness.safeMint(
            businessLPHolder,
            "Acme Corp",
            "REG123",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );

        // Credit holder (Tier 3) - needs LP first
        lpIndividuals.safeMint(creditHolder, "veriff_456", "");
        ecreditscoring.safeMint(
            creditHolder,
            80, // score (0-100 scale)
            Ecreditscoring.CreditTier.Gold,
            1000000e6,
            "ref_123",
            ""
        );
    }

    /// @notice Helper to mint passport via ZKPassport for a user
    function _mintPassportForUser(address user, uint256 seed) internal {
        bytes32 uniqueIdentifier = bytes32(seed);
        bytes32 personhoodProof = bytes32(seed + 1000);
        vm.prank(user);
        passport.safeMintWithVerification(
            uniqueIdentifier,
            personhoodProof,
            true, // sanctionsPassed
            true, // isOver18
            true, // faceMatchPassed
            "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4" // Convexo Passport IPFS hash
        );
    }

    function test_TierNone() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(noNFTHolder);
        assertEq(uint(tier), uint(ReputationManager.ReputationTier.None));
        assertFalse(reputationManager.canAccessLPPools(noNFTHolder));
        assertFalse(reputationManager.canCreateVaults(noNFTHolder));
    }

    function test_TierPassport() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(passportHolder);
        assertEq(uint(tier), uint(ReputationManager.ReputationTier.Passport));
        assertTrue(reputationManager.canAccessLPPools(passportHolder));
        assertFalse(reputationManager.canCreateVaults(passportHolder));
        assertFalse(reputationManager.canRequestCreditScore(passportHolder));
    }

    function test_TierLimitedPartner_Individual() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(individualLPHolder);
        assertEq(uint(tier), uint(ReputationManager.ReputationTier.LimitedPartner));
        assertTrue(reputationManager.canAccessLPPools(individualLPHolder));
        assertTrue(reputationManager.canRequestCreditScore(individualLPHolder));
        assertFalse(reputationManager.canCreateVaults(individualLPHolder));
    }

    function test_TierLimitedPartner_Business() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(businessLPHolder);
        assertEq(uint(tier), uint(ReputationManager.ReputationTier.LimitedPartner));
        assertTrue(reputationManager.canAccessLPPools(businessLPHolder));
        assertTrue(reputationManager.canRequestCreditScore(businessLPHolder));
    }

    function test_TierVaultCreator() public view {
        ReputationManager.ReputationTier tier = reputationManager.getReputationTier(creditHolder);
        assertEq(uint(tier), uint(ReputationManager.ReputationTier.VaultCreator));
        assertTrue(reputationManager.canAccessLPPools(creditHolder));
        assertTrue(reputationManager.canCreateVaults(creditHolder));
    }

    function test_HoldsNFT() public view {
        assertTrue(reputationManager.holdsPassport(passportHolder));
        assertTrue(reputationManager.holdsLPIndividuals(individualLPHolder));
        assertTrue(reputationManager.holdsLPBusiness(businessLPHolder));
        assertTrue(reputationManager.holdsEcreditscoring(creditHolder));
        assertTrue(reputationManager.holdsAnyLP(individualLPHolder));
        assertTrue(reputationManager.holdsAnyLP(businessLPHolder));
    }

    function test_GetReputationDetails() public view {
        (
            ReputationManager.ReputationTier tier,
            uint256 passportBal,
            uint256 lpIndBal,
            uint256 lpBusBal,
            uint256 creditBal
        ) = reputationManager.getReputationDetails(creditHolder);

        assertEq(uint(tier), uint(ReputationManager.ReputationTier.VaultCreator));
        assertEq(passportBal, 0);
        assertEq(lpIndBal, 1);
        assertEq(lpBusBal, 0);
        assertEq(creditBal, 1);
    }

    function test_RequireAccess() public view {
        // Should not revert
        reputationManager.requirePassportAccess(passportHolder);
        reputationManager.requireLimitedPartnerAccess(individualLPHolder);
        reputationManager.requireVaultCreatorAccess(creditHolder);
    }

    function test_RequireAccess_Reverts() public {
        vm.expectRevert("Must have Passport tier or higher");
        reputationManager.requirePassportAccess(noNFTHolder);

        vm.expectRevert("Must have LimitedPartner tier or higher");
        reputationManager.requireLimitedPartnerAccess(passportHolder);

        vm.expectRevert("Must have VaultCreator tier");
        reputationManager.requireVaultCreatorAccess(individualLPHolder);
    }
}

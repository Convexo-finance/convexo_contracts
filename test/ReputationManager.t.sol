// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";
import {Convexo_Passport} from "../src/contracts/identity/Convexo_Passport.sol";
import {Limited_Partners_Individuals} from "../src/contracts/identity/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/identity/Limited_Partners_Business.sol";
import {Ecreditscoring} from "../src/contracts/credits/Ecreditscoring.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    IZKPassportVerifier,
    IZKPassportHelper,
    ProofVerificationParams,
    ProofVerificationData,
    ServiceConfig,
    BoundData,
    DisclosedData,
    FaceMatchMode,
    OS
} from "../src/interfaces/IZKPassportVerifier.sol";

// ─── Minimal Mock Helper for ReputationManager tests ─────────────────────────

contract RepMgrMockHelper is IZKPassportHelper {
    address public _sender;

    constructor() {}

    function setSender(address s) external { _sender = s; }

    function verifyScopes(bytes32[] calldata, string calldata, string calldata) external pure override returns (bool) { return true; }
    function getBoundData(bytes calldata) external view override returns (BoundData memory) {
        return BoundData({ senderAddress: _sender, chainId: block.chainid, customData: "" });
    }
    function getDisclosedData(bytes calldata, bool) external pure override returns (DisclosedData memory) {
        return DisclosedData({ name: "", issuingCountry: "", nationality: "", gender: "",
            birthDate: "", expiryDate: "", documentNumber: "", documentType: "passport" });
    }
    function isAgeAboveOrEqual(uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isAgeAbove(uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isAgeBetween(uint8, uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isAgeBelowOrEqual(uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isAgeBelow(uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isAgeEqual(uint8, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateAfterOrEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateAfter(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateBetween(uint256, uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateBeforeOrEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateBefore(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isBirthdateEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateAfterOrEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateAfter(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBetween(uint256, uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBeforeOrEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBefore(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isNationalityIn(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isIssuingCountryIn(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isNationalityOut(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isIssuingCountryOut(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isSanctionsRootValid(uint256, bool, bytes calldata) external pure override returns (bool) { return true; }
    function enforceSanctionsRoot(uint256, bool, bytes calldata) external pure override {}
    function isFaceMatchVerified(FaceMatchMode, OS, bytes calldata) external pure override returns (bool) { return true; }
    function getProofTimestamp(bytes32[] calldata) external pure override returns (uint256) { return 1; }
}

contract RepMgrMockVerifier is IZKPassportVerifier {
    RepMgrMockHelper public helper;
    uint256 private _idCounter;

    constructor() {
        helper = new RepMgrMockHelper();
    }

    function setSender(address s) external { helper.setSender(s); }

    function verify(ProofVerificationParams calldata)
        external
        returns (bool, bytes32, IZKPassportHelper)
    {
        bytes32 uid = keccak256(abi.encodePacked("uid", _idCounter++));
        return (true, uid, IZKPassportHelper(address(helper)));
    }
}

contract ReputationManagerTest is Test {
    ReputationManager public reputationManager;
    Convexo_Passport public passport;
    Limited_Partners_Individuals public lpIndividuals;
    Limited_Partners_Business public lpBusiness;
    Ecreditscoring public ecreditscoring;
    RepMgrMockVerifier public mockVerifier;

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public passportHolder = address(0x3);
    address public individualLPHolder = address(0x4);
    address public businessLPHolder = address(0x5);
    address public creditHolder = address(0x6);
    address public noNFTHolder = address(0x7);

    function setUp() public {
        // Deploy mock verifier
        mockVerifier = new RepMgrMockVerifier();

        // Deploy NFT contracts - use address(this) as admin for test convenience
        passport = new Convexo_Passport(address(this), "https://metadata", address(mockVerifier));
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
        _mintPassportForUser(passportHolder);

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
    function _mintPassportForUser(address user) internal {
        mockVerifier.setSender(user);
        // Build minimal params
        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = bytes32(0);
        ProofVerificationParams memory params = ProofVerificationParams({
            version: bytes32(0),
            proofVerificationData: ProofVerificationData({
                vkeyHash: bytes32(uint256(1)),
                proof: new bytes(0),
                publicInputs: publicInputs
            }),
            committedInputs: new bytes(0),
            serviceConfig: ServiceConfig({
                validityPeriodInSeconds: 3600,
                domain: "protocol.convexo.xyz",
                scope: "convexo-passport-identity",
                devMode: false
            })
        });
        vm.prank(user);
        passport.claimPassport(params, false, "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4");
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

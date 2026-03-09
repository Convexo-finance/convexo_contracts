// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Convexo_Passport} from "../src/contracts/identity/Convexo_Passport.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
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

// ─── Mock Helper ─────────────────────────────────────────────────────────────

contract MockZKPassportHelper is IZKPassportHelper {
    bool public _scopesValid = true;
    bool public _ageAboveOrEqual = true;
    bool public _sanctionsValid = true;
    bool public _nationalityOut = true;
    bool public _expiryValid = true;
    address public _senderAddress;
    uint256 public _chainId;
    uint256 public _proofTimestamp;

    constructor(address sender, uint256 chainId) {
        _senderAddress = sender;
        _chainId = chainId;
        _proofTimestamp = block.timestamp;
    }

    // ── Setters for test control ──────────────────────────────────────────

    function setScopesValid(bool v) external { _scopesValid = v; }
    function setAgeAboveOrEqual(bool v) external { _ageAboveOrEqual = v; }
    function setSanctionsValid(bool v) external { _sanctionsValid = v; }
    function setNationalityOut(bool v) external { _nationalityOut = v; }
    function setExpiryValid(bool v) external { _expiryValid = v; }
    function setSenderAddress(address v) external { _senderAddress = v; }
    function setChainId(uint256 v) external { _chainId = v; }
    function setProofTimestamp(uint256 v) external { _proofTimestamp = v; }

    // ── IZKPassportHelper implementation ─────────────────────────────────

    function verifyScopes(bytes32[] calldata, string calldata, string calldata)
        external view override returns (bool) { return _scopesValid; }

    function getBoundData(bytes calldata) external view override returns (BoundData memory) {
        return BoundData({ senderAddress: _senderAddress, chainId: _chainId, customData: "" });
    }

    function getDisclosedData(bytes calldata, bool) external pure override returns (DisclosedData memory) {
        return DisclosedData({ name: "", issuingCountry: "", nationality: "", gender: "",
            birthDate: "", expiryDate: "", documentNumber: "", documentType: "passport" });
    }

    function isAgeAboveOrEqual(uint8, bytes calldata) external view override returns (bool) { return _ageAboveOrEqual; }
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

    function isExpiryDateAfterOrEqual(uint256, bytes calldata) external view override returns (bool) { return _expiryValid; }
    function isExpiryDateAfter(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBetween(uint256, uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBeforeOrEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateBefore(uint256, bytes calldata) external pure override returns (bool) { return true; }
    function isExpiryDateEqual(uint256, bytes calldata) external pure override returns (bool) { return true; }

    function isNationalityIn(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isIssuingCountryIn(string[] memory, bytes calldata) external pure override returns (bool) { return true; }
    function isNationalityOut(string[] memory, bytes calldata) external view override returns (bool) { return _nationalityOut; }
    function isIssuingCountryOut(string[] memory, bytes calldata) external pure override returns (bool) { return true; }

    function isSanctionsRootValid(uint256, bool, bytes calldata) external view override returns (bool) { return _sanctionsValid; }
    function enforceSanctionsRoot(uint256, bool, bytes calldata) external view override {
        if (!_sanctionsValid) revert("Sanctions failed");
    }

    function isFaceMatchVerified(FaceMatchMode, OS, bytes calldata) external pure override returns (bool) { return true; }

    function getProofTimestamp(bytes32[] calldata) external view override returns (uint256) { return _proofTimestamp; }
}

// ─── Mock Verifier ────────────────────────────────────────────────────────────

contract MockZKPassportVerifier is IZKPassportVerifier {
    bool public _verified = true;
    bytes32 public _uniqueIdentifier;
    MockZKPassportHelper public helper;

    constructor(address defaultSender, uint256 defaultChainId) {
        helper = new MockZKPassportHelper(defaultSender, defaultChainId);
        _uniqueIdentifier = keccak256("default-unique-id");
    }

    function setVerified(bool v) external { _verified = v; }
    function setUniqueIdentifier(bytes32 id) external { _uniqueIdentifier = id; }

    function verify(ProofVerificationParams calldata)
        external
        view
        override
        returns (bool verified, bytes32 uniqueIdentifier, IZKPassportHelper h)
    {
        return (_verified, _uniqueIdentifier, IZKPassportHelper(address(helper)));
    }
}

// ─── Test Contract ────────────────────────────────────────────────────────────

contract ConvexoPassportTest is Test {
    Convexo_Passport public passport;
    MockZKPassportVerifier public mockVerifier;
    MockZKPassportHelper public mockHelper;

    address public admin    = address(0x1);
    address public user1    = address(0x2);
    address public user2    = address(0x3);
    address public user3    = address(0x4);

    string constant PASSPORT_IPFS = "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4";

    function setUp() public {
        // Deploy mock verifier configured for user1 on the test chain
        mockVerifier = new MockZKPassportVerifier(user1, block.chainid);
        mockHelper = mockVerifier.helper();

        vm.prank(admin);
        passport = new Convexo_Passport(admin, "", address(mockVerifier));
    }

    // ─── Helpers ─────────────────────────────────────────────────────────

    function _makeParams() internal pure returns (ProofVerificationParams memory) {
        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = bytes32(0);
        return ProofVerificationParams({
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
    }

    function _claimAs(address user) internal returns (uint256) {
        mockHelper.setSenderAddress(user);
        vm.prank(user);
        return passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    function _claimAsWithId(address user, bytes32 uniqueId) internal returns (uint256) {
        mockVerifier.setUniqueIdentifier(uniqueId);
        mockHelper.setSenderAddress(user);
        vm.prank(user);
        return passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── Deployment ───────────────────────────────────────────────────────

    function test_Deployment() public view {
        assertEq(passport.name(), "Convexo Passport");
        assertEq(passport.symbol(), "CPASS");
        assertTrue(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(passport.hasRole(passport.REVOKER_ROLE(), admin));
        assertEq(address(passport.ZKPASSPORT_VERIFIER()), address(mockVerifier));
        assertEq(passport.APP_DOMAIN(), "protocol.convexo.xyz");
        assertEq(passport.APP_SCOPE(), "convexo-passport-identity");
    }

    // ─── claimPassport — success ──────────────────────────────────────────

    function test_ClaimPassport_Success() public {
        bytes32 expectedId = keccak256("default-unique-id");

        // Set sender first, then expectEmit, then the actual call
        mockHelper.setSenderAddress(user1);

        vm.expectEmit(true, true, false, false);
        emit IConvexoPassport.PassportMinted(user1, 0, expectedId, bytes32(uint256(1)), true, true, true);

        vm.prank(user1);
        uint256 tokenId = passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);

        assertEq(passport.ownerOf(tokenId), user1);
        assertEq(passport.balanceOf(user1), 1);
        assertTrue(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 1);

        IConvexoPassport.VerifiedIdentity memory id = passport.getVerifiedIdentity(user1);
        assertEq(id.identifierHash, expectedId);
        assertTrue(id.isActive);
        assertTrue(id.kycVerified);
        assertTrue(id.sanctionsPassed);
        assertTrue(id.isOver18);
        assertTrue(id.nationalityCompliant);
        assertGt(id.verifiedAt, 0);

        assertTrue(passport.isIdentifierUsed(expectedId));
    }

    // ─── claimPassport — revert: proof invalid ────────────────────────────

    function test_ClaimPassport_RevertIf_ProofInvalid() public {
        mockVerifier.setVerified(false);
        mockHelper.setSenderAddress(user1);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.ProofVerificationFailed.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: wrong scope ─────────────────────────────

    function test_ClaimPassport_RevertIf_InvalidScope() public {
        mockHelper.setScopesValid(false);
        mockHelper.setSenderAddress(user1);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.InvalidScope.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: wrong sender ────────────────────────────

    function test_ClaimPassport_RevertIf_InvalidSender() public {
        // helper says sender is user1, but user2 calls
        mockHelper.setSenderAddress(user1);
        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.InvalidSender.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: wrong chain ─────────────────────────────

    function test_ClaimPassport_RevertIf_InvalidChain() public {
        mockHelper.setSenderAddress(user1);
        mockHelper.setChainId(999); // wrong chain
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.InvalidChain.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: under 18 ────────────────────────────────

    function test_ClaimPassport_RevertIf_AgeVerificationFailed() public {
        mockHelper.setSenderAddress(user1);
        mockHelper.setAgeAboveOrEqual(false);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.AgeVerificationFailed.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: sanctions ───────────────────────────────

    function test_ClaimPassport_RevertIf_SanctionsCheckFailed() public {
        mockHelper.setSenderAddress(user1);
        mockHelper.setSanctionsValid(false);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SanctionsCheckFailed.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: nationality ─────────────────────────────

    function test_ClaimPassport_RevertIf_NationalityNotCompliant() public {
        mockHelper.setSenderAddress(user1);
        mockHelper.setNationalityOut(false);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.NationalityNotCompliant.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: expired passport ────────────────────────

    function test_ClaimPassport_RevertIf_PassportExpired() public {
        mockHelper.setSenderAddress(user1);
        mockHelper.setExpiryValid(false);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.PassportExpired.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: duplicate identifier ────────────────────

    function test_ClaimPassport_RevertIf_IdentifierAlreadyUsed() public {
        bytes32 sharedId = keccak256("shared-id");
        _claimAsWithId(user1, sharedId);

        // user2 tries with same uniqueIdentifier
        mockVerifier.setUniqueIdentifier(sharedId);
        mockHelper.setSenderAddress(user2);
        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.IdentifierAlreadyUsed.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── claimPassport — revert: already has passport ────────────────────

    function test_ClaimPassport_RevertIf_AlreadyHasPassport() public {
        _claimAs(user1);

        // user1 tries to claim again with different uniqueId
        mockVerifier.setUniqueIdentifier(keccak256("second-id"));
        mockHelper.setSenderAddress(user1);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.AlreadyHasPassport.selector);
        passport.claimPassport(_makeParams(), false, PASSPORT_IPFS);
    }

    // ─── Multiple users ───────────────────────────────────────────────────

    function test_MultipleDifferentPassports() public {
        uint256 t1 = _claimAsWithId(user1, keccak256("id-user1"));
        uint256 t2 = _claimAsWithId(user2, keccak256("id-user2"));

        assertEq(t1, 0);
        assertEq(t2, 1);
        assertEq(passport.getActivePassportCount(), 2);
        assertTrue(passport.holdsActivePassport(user1));
        assertTrue(passport.holdsActivePassport(user2));
    }

    // ─── Revoke ───────────────────────────────────────────────────────────

    function test_RevokePassport() public {
        uint256 tokenId = _claimAs(user1);

        vm.prank(admin);
        passport.revokePassport(tokenId);

        assertFalse(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 0);
        assertFalse(passport.getVerifiedIdentity(user1).isActive);
    }

    function test_RevokePassport_RevertIfNotRevoker() public {
        uint256 tokenId = _claimAs(user1);
        vm.prank(user2);
        vm.expectRevert();
        passport.revokePassport(tokenId);
    }

    // ─── Soulbound ────────────────────────────────────────────────────────

    function test_SoulboundToken_CannotTransfer() public {
        uint256 tokenId = _claimAs(user1);

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.transferFrom(user1, user2, tokenId);

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.approve(user2, tokenId);

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.setApprovalForAll(user2, true);
    }

    // ─── Token URI ────────────────────────────────────────────────────────

    function test_TokenURI() public {
        _claimAs(user1);
        string memory uri = passport.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(
            "https://lime-famous-condor-7.mypinata.cloud/ipfs/",
            PASSPORT_IPFS
        )));
    }

    // ─── View helpers ─────────────────────────────────────────────────────

    function test_GetVerifiedIdentity_EmptyForNonHolder() public view {
        IConvexoPassport.VerifiedIdentity memory id = passport.getVerifiedIdentity(user1);
        assertFalse(id.isActive);
        assertEq(id.identifierHash, bytes32(0));
    }

    function test_IsIdentifierUsed_FalseForUnused() public view {
        assertFalse(passport.isIdentifierUsed(keccak256("unused-id")));
    }

    // ─── ID card variant ─────────────────────────────────────────────────

    function test_ClaimPassport_WithIDCard() public {
        mockHelper.setSenderAddress(user1);
        vm.prank(user1);
        uint256 tokenId = passport.claimPassport(_makeParams(), true, PASSPORT_IPFS); // isIDCard = true
        assertEq(passport.ownerOf(tokenId), user1);
    }
}

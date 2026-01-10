// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, ProofVerificationParams, DisclosedData} from "../src/interfaces/IZKPassportVerifier.sol";

/// @notice Mock ZKPassport Verifier for testing
/// @dev Returns verification traits (no PII) matching the updated DisclosedData struct
contract MockZKPassportVerifier is IZKPassportVerifier {
    bool public shouldSucceed = true;
    // Verification traits (boolean results)
    bool public kycVerified = true;
    bool public faceMatchPassed = true;
    bool public sanctionsPassed = true;
    bool public userIsOver18 = true;

    function setShouldSucceed(bool _shouldSucceed) external {
        shouldSucceed = _shouldSucceed;
    }

    function setKycVerified(bool _kycVerified) external {
        kycVerified = _kycVerified;
    }

    function setFaceMatchPassed(bool _faceMatchPassed) external {
        faceMatchPassed = _faceMatchPassed;
    }

    function setSanctionsPassed(bool _sanctionsPassed) external {
        sanctionsPassed = _sanctionsPassed;
    }

    function setUserIsOver18(bool _isOver18) external {
        userIsOver18 = _isOver18;
    }

    function verifyProof(
        ProofVerificationParams calldata,
        bool
    ) external view returns (bool success, DisclosedData memory disclosedData) {
        success = shouldSucceed;
        disclosedData = DisclosedData({
            kycVerified: kycVerified,
            faceMatchPassed: faceMatchPassed,
            sanctionsPassed: sanctionsPassed,
            isOver18: userIsOver18,
            verifiedAt: block.timestamp
        });
    }
}

contract ConvexoPassportTest is Test {
    Convexo_Passport public passport;
    MockZKPassportVerifier public mockVerifier;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    string public constant BASE_URI = "https://metadata.convexo.finance/passport";

    // Privacy-compliant event (only verification traits, no PII)
    event PassportMinted(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier,
        bytes32 personhoodProof,
        bool kycVerified,
        bool faceMatchPassed,
        bool sanctionsPassed,
        bool isOver18
    );

    event PassportRevoked(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier
    );

    function setUp() public {
        // Deploy mock verifier
        mockVerifier = new MockZKPassportVerifier();

        // Deploy Convexo_Passport
        vm.prank(admin);
        passport = new Convexo_Passport(admin, address(mockVerifier), BASE_URI);
    }

    /// @notice Helper to create unique ZKPassport proof params
    function _createZKParams(uint256 seed) internal view returns (ProofVerificationParams memory) {
        return ProofVerificationParams({
            publicKey: bytes32(seed),
            nullifier: bytes32(seed + 1000),
            proof: abi.encodePacked(seed),
            attestationId: seed,
            scope: bytes32(seed + 2000),
            currentDate: block.timestamp
        });
    }

    /// @notice Helper to mint passport via ZKPassport for a user
    function _mintPassportForUser(address user, uint256 seed) internal returns (uint256) {
        ProofVerificationParams memory params = _createZKParams(seed);
        vm.prank(user);
        return passport.safeMintWithZKPassport(params, false);
    }

    function test_Deployment() public view {
        assertEq(passport.name(), "Convexo Passport");
        assertEq(passport.symbol(), "CPASS");
        assertEq(address(passport.zkPassportVerifier()), address(mockVerifier));
        assertTrue(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(passport.hasRole(passport.REVOKER_ROLE(), admin));
    }

    function test_SafeMintWithZKPassport_Success() public {
        // Create proof parameters
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        // Privacy-compliant: emit verification traits (booleans), not PII
        emit PassportMinted(
            user1,
            0,
            keccak256(abi.encodePacked(params.publicKey, params.scope)),
            params.nullifier,
            true,   // kycVerified
            true,   // faceMatchPassed
            true,   // sanctionsPassed
            true    // isOver18
        );

        uint256 tokenId = passport.safeMintWithZKPassport(params, false);

        assertEq(tokenId, 0);
        assertEq(passport.ownerOf(tokenId), user1);
        assertEq(passport.balanceOf(user1), 1);
        assertTrue(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 1);

        // Verify stored traits (no PII)
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertTrue(identity.isActive);
        assertTrue(identity.kycVerified);
        assertTrue(identity.faceMatchPassed);
        assertTrue(identity.sanctionsPassed);
        assertTrue(identity.isOver18);

        // Verify identifier is marked as used
        assertTrue(passport.isIdentifierUsed(keccak256(abi.encodePacked(params.publicKey, params.scope))));
    }

    function test_SafeMintWithZKPassport_RevertIfProofFails() public {
        mockVerifier.setShouldSucceed(false);

        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.ProofVerificationFailed.selector);
        passport.safeMintWithZKPassport(params, false);
    }

    function test_SafeMintWithZKPassport_StoresIsOver18False() public {
        // When ZKPassport returns isOver18=false, we just store it as a trait (no validation)
        mockVerifier.setUserIsOver18(false);

        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        uint256 tokenId = passport.safeMintWithZKPassport(params, false);

        // Verify passport was minted and isOver18=false is stored correctly
        assertEq(tokenId, 0);
        assertEq(passport.balanceOf(user1), 1);

        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertFalse(identity.isOver18); // Stored as false from ZKPassport trait
        assertTrue(identity.isActive);
        assertTrue(identity.kycVerified);  // Other traits still true
    }

    function test_SafeMintWithZKPassport_RevertIfAlreadyHasPassport() public {
        ProofVerificationParams memory params1 = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        passport.safeMintWithZKPassport(params1, false);

        // Try to mint again with different proof
        ProofVerificationParams memory params2 = ProofVerificationParams({
            publicKey: bytes32(uint256(10)),
            nullifier: bytes32(uint256(20)),
            proof: hex"5678",
            attestationId: 2,
            scope: bytes32(uint256(30)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.AlreadyHasPassport.selector);
        passport.safeMintWithZKPassport(params2, false);
    }

    function test_SafeMintWithZKPassport_RevertIfIdentifierUsed() public {
        ProofVerificationParams memory params = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        passport.safeMintWithZKPassport(params, false);

        // Try to use the same identifier (publicKey + scope) with a different user
        // Using same publicKey and scope but different nullifier
        ProofVerificationParams memory params2 = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),    // Same publicKey
            nullifier: bytes32(uint256(999)),  // Different nullifier
            proof: hex"5678",
            attestationId: 2,
            scope: bytes32(uint256(3)),        // Same scope
            currentDate: block.timestamp
        });

        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.IdentifierAlreadyUsed.selector);
        passport.safeMintWithZKPassport(params2, false);
    }

    function test_RevokePassport_Success() public {
        // Mint a passport first via ZKPassport
        uint256 tokenId = _mintPassportForUser(user1, 1);

        IConvexoPassport.VerifiedIdentity memory identityBefore = passport.getVerifiedIdentity(user1);
        bytes32 uniqueIdentifier = identityBefore.uniqueIdentifier;

        // Revoke it
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit PassportRevoked(user1, tokenId, uniqueIdentifier);
        passport.revokePassport(tokenId);

        assertFalse(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 0);

        IConvexoPassport.VerifiedIdentity memory identityAfter = passport.getVerifiedIdentity(user1);
        assertFalse(identityAfter.isActive);
    }

    function test_RevokePassport_RevertIfNotRevoker() public {
        uint256 tokenId = _mintPassportForUser(user1, 1);

        vm.prank(user1);
        vm.expectRevert();
        passport.revokePassport(tokenId);
    }

    function test_RevokePassport_RevertIfAlreadyRevoked() public {
        uint256 tokenId = _mintPassportForUser(user1, 1);

        vm.prank(admin);
        passport.revokePassport(tokenId);

        vm.prank(admin);
        vm.expectRevert(Convexo_Passport.PassportNotActive.selector);
        passport.revokePassport(tokenId);
    }

    function test_Soulbound_CannotTransfer() public {
        uint256 tokenId = _mintPassportForUser(user1, 1);

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.transferFrom(user1, user2, tokenId);
    }

    function test_Soulbound_CanBurn() public {
        uint256 tokenId = _mintPassportForUser(user1, 1);

        vm.prank(user1);
        passport.burn(tokenId);

        assertEq(passport.balanceOf(user1), 0);
    }

    function test_MultipleUsers_CanMintDifferentPassports() public {
        ProofVerificationParams memory params1 = ProofVerificationParams({
            publicKey: bytes32(uint256(1)),
            nullifier: bytes32(uint256(2)),
            proof: hex"1234",
            attestationId: 1,
            scope: bytes32(uint256(3)),
            currentDate: block.timestamp
        });

        ProofVerificationParams memory params2 = ProofVerificationParams({
            publicKey: bytes32(uint256(10)),
            nullifier: bytes32(uint256(20)),
            proof: hex"5678",
            attestationId: 2,
            scope: bytes32(uint256(30)),
            currentDate: block.timestamp
        });

        vm.prank(user1);
        uint256 tokenId1 = passport.safeMintWithZKPassport(params1, false);

        vm.prank(user2);
        uint256 tokenId2 = passport.safeMintWithZKPassport(params2, false);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(passport.balanceOf(user1), 1);
        assertEq(passport.balanceOf(user2), 1);
        assertEq(passport.getActivePassportCount(), 2);
    }

    function test_SetBaseURI_Success() public {
        string memory newBaseURI = "https://new-metadata.convexo.finance/passport";

        vm.prank(admin);
        passport.setBaseURI(newBaseURI);

        uint256 tokenId = _mintPassportForUser(user1, 1);

        // The tokenURI should use the fixed IPFS URI
        string memory uri = passport.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);
    }

    function test_SetBaseURI_RevertIfNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        passport.setBaseURI("https://new-uri.com");
    }

    function test_IsIdentifierUsed() public {
        ProofVerificationParams memory params = _createZKParams(1);
        bytes32 identifier = keccak256(abi.encodePacked(params.publicKey, params.scope));

        // Before mint
        assertFalse(passport.isIdentifierUsed(identifier));

        // After mint
        vm.prank(user1);
        passport.safeMintWithZKPassport(params, false);
        assertTrue(passport.isIdentifierUsed(identifier));
    }

    /// @notice Test the core invariant: 1 human → 1 ZKPassport → 1 NFT → 1 wallet
    function test_CoreInvariant_OneHumanOnePassport() public {
        // User1 mints with their ZKPassport
        ProofVerificationParams memory params = _createZKParams(1);
        vm.prank(user1);
        passport.safeMintWithZKPassport(params, false);

        // Verify invariants:
        // 1. Wallet has exactly 1 passport
        assertEq(passport.balanceOf(user1), 1);

        // 2. Same wallet cannot mint another (AlreadyHasPassport)
        ProofVerificationParams memory params2 = _createZKParams(2);
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.AlreadyHasPassport.selector);
        passport.safeMintWithZKPassport(params2, false);

        // 3. Same identifier cannot be reused by another wallet (IdentifierAlreadyUsed)
        // uniqueIdentifier = hash(publicKey + scope) - this is the SINGLE sybil resistance check
        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.IdentifierAlreadyUsed.selector);
        passport.safeMintWithZKPassport(params, false);
    }

    /// @notice Test that there is only ONE minting path
    function test_OnlyZKPassportMintingPath() public {
        // The only way to mint is via safeMintWithZKPassport
        // There is no safeMint or safeMintWithIdentifier function
        // This test documents the security invariant

        ProofVerificationParams memory params = _createZKParams(1);
        vm.prank(user1);
        uint256 tokenId = passport.safeMintWithZKPassport(params, false);

        assertEq(tokenId, 0);
        assertEq(passport.balanceOf(user1), 1);
        assertTrue(passport.holdsActivePassport(user1));
    }
}

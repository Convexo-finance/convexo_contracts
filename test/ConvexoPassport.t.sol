// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";

/// @title ConvexoPassportSimplifiedTest
/// @notice Tests for the simplified Convexo_Passport contract
/// @dev Tests the new safeMintWithVerification function with direct parameters
contract ConvexoPassportSimplifiedTest is Test {
    Convexo_Passport public passport;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    string constant BASE_URI = "https://api.convexo.io/passport/";

    function setUp() public {
        // Deploy Convexo_Passport with empty base URI (we use individual IPFS URIs)
        vm.prank(admin);
        passport = new Convexo_Passport(admin, "");
    }

    /// @notice Helper to mint passport for a user with verification results
    function _mintPassportForUser(
        address user, 
        uint256 seed,
        bool sanctionsPassed,
        bool isOver18,
        bool faceMatchPassed
    ) internal returns (uint256) {
        string memory uniqueIdentifier = string(abi.encodePacked("zkpassport-id-", vm.toString(seed)));
        bytes32 personhoodProof = bytes32(seed + 1000);
        // Use actual Convexo Passport IPFS hash
        string memory ipfsHash = "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4";
        vm.prank(user);
        return passport.safeMintWithVerification(
            uniqueIdentifier,
            personhoodProof,
            sanctionsPassed,
            isOver18,
            faceMatchPassed,
            ipfsHash
        );
    }

    function test_Deployment() public view {
        assertEq(passport.name(), "Convexo Passport");
        assertEq(passport.symbol(), "CPASS");
        assertTrue(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(passport.hasRole(passport.REVOKER_ROLE(), admin));
    }

    function test_SafeMintWithVerification_Success() public {
        string memory uniqueIdentifier = "zkpassport-unique-id-12345";
        bytes32 identifierHash = keccak256(bytes(uniqueIdentifier));
        bytes32 personhoodProof = bytes32(uint256(2));
        
        // Expect PassportMinted event
        vm.expectEmit(true, true, false, false);
        emit IConvexoPassport.PassportMinted(
            user1,
            0, // tokenId
            identifierHash,
            personhoodProof,
            true, // kycVerified (always true when minted)
            true, // faceMatchPassed
            true, // sanctionsPassed
            true  // isOver18
        );
        
        vm.prank(user1);
        uint256 tokenId = passport.safeMintWithVerification(
            uniqueIdentifier,
            personhoodProof,
            true, // sanctionsPassed
            true, // isOver18
            true, // faceMatchPassed
            "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4" // Actual Convexo Passport IPFS hash
        );
        
        // Verify token was minted
        assertEq(passport.ownerOf(tokenId), user1);
        assertEq(passport.balanceOf(user1), 1);
        assertTrue(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 1);
        
        // Verify identity data
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertEq(identity.identifierHash, identifierHash);
        assertEq(identity.personhoodProof, personhoodProof);
        assertTrue(identity.isActive);
        assertTrue(identity.kycVerified);
        assertTrue(identity.faceMatchPassed);
        assertTrue(identity.sanctionsPassed);
        assertTrue(identity.isOver18);
        assertGt(identity.verifiedAt, 0);
        
        // Verify identifier is marked as used
        assertTrue(passport.isIdentifierUsed(uniqueIdentifier));
    }

    function test_SafeMintWithVerification_RevertIfIdentifierUsed() public {
        string memory uniqueIdentifier = "zkpassport-same-id-used-twice";
        bytes32 personhoodProof1 = bytes32(uint256(2));
        bytes32 personhoodProof2 = bytes32(uint256(3));
        
        // First mint succeeds
        vm.prank(user1);
        passport.safeMintWithVerification(
            uniqueIdentifier,
            personhoodProof1,
            true, // sanctionsPassed
            true, // isOver18
            true, // faceMatchPassed
            "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4"
        );
        
        // Second mint with same identifier should fail
        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.IdentifierAlreadyUsed.selector);
        passport.safeMintWithVerification(
            uniqueIdentifier, // Same identifier
            personhoodProof2, // Different proof
            true, // sanctionsPassed
            true, // isOver18
            true, // faceMatchPassed
            "bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m" // Different IPFS hash (business LP)
        );
    }

    function test_SafeMintWithVerification_RevertIfAlreadyHasPassport() public {
        // User mints first passport
        _mintPassportForUser(user1, 1, true, true, true);
        
        // Try to mint second passport - should fail
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.AlreadyHasPassport.selector);
        passport.safeMintWithVerification(
            "zkpassport-different-id-999", // Different identifier
            bytes32(uint256(3)), // Different proof
            true, // sanctionsPassed
            true, // isOver18
            true, // faceMatchPassed
            "bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em" // Individual LP IPFS hash
        );
    }

    function test_SafeMintWithVerification_StoresVariousTraits() public {
        string memory uniqueIdentifier = "zkpassport-traits-test-id";
        bytes32 personhoodProof = bytes32(uint256(2));
        
        vm.prank(user1);
        uint256 tokenId = passport.safeMintWithVerification(
            uniqueIdentifier,
            personhoodProof,
            false, // sanctionsPassed = false
            false, // isOver18 = false
            true,  // faceMatchPassed
            "bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4" // Convexo Passport IPFS hash
        );
        
        // Verify traits are stored correctly
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertFalse(identity.sanctionsPassed);
        assertFalse(identity.isOver18);
        assertTrue(identity.faceMatchPassed);
        assertTrue(identity.kycVerified); // Always true when minted
    }

    function test_MultipleDifferentPassports() public {
        // Mint passports for different users with different identifiers
        uint256 tokenId1 = _mintPassportForUser(user1, 1, true, true, true);
        uint256 tokenId2 = _mintPassportForUser(user2, 2, true, false, true);
        
        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(passport.getActivePassportCount(), 2);
        
        // Verify each user has their own passport
        assertTrue(passport.holdsActivePassport(user1));
        assertTrue(passport.holdsActivePassport(user2));
        
        // Verify different traits
        IConvexoPassport.VerifiedIdentity memory identity1 = passport.getVerifiedIdentity(user1);
        IConvexoPassport.VerifiedIdentity memory identity2 = passport.getVerifiedIdentity(user2);
        
        assertTrue(identity1.isOver18);
        assertFalse(identity2.isOver18);
    }

    function test_RevokePassport() public {
        // Mint passport
        uint256 tokenId = _mintPassportForUser(user1, 1, true, true, true);
        assertEq(passport.getActivePassportCount(), 1);
        
        // Revoke passport
        vm.prank(admin);
        passport.revokePassport(tokenId);
        
        // Verify passport is revoked
        assertFalse(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 0);
        
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertFalse(identity.isActive);
    }

    function test_RevokePassport_RevertIfNotRevoker() public {
        // Mint passport
        uint256 tokenId = _mintPassportForUser(user1, 1, true, true, true);
        
        // Try to revoke from non-revoker - should fail
        vm.prank(user2);
        vm.expectRevert();
        passport.revokePassport(tokenId);
    }

    function test_SoulboundToken_CannotTransfer() public {
        // Mint passport
        uint256 tokenId = _mintPassportForUser(user1, 1, true, true, true);
        
        // Try to transfer - should fail
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.transferFrom(user1, user2, tokenId);
        
        // Try to approve - should fail
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.approve(user2, tokenId);
        
        // Try to set approval for all - should fail
        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.setApprovalForAll(user2, true);
    }

    function test_TokenURI() public {
        // Mint passport with actual IPFS hash
        uint256 tokenId = _mintPassportForUser(user1, 1, true, true, true);
        
        string memory tokenURI = passport.tokenURI(tokenId);
        // Should return the full IPFS URL via your custom Pinata gateway
        assertEq(tokenURI, "https://lime-famous-condor-7.mypinata.cloud/ipfs/bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4");
    }

    function test_GetVerifiedIdentity_EmptyForNonHolder() public view {
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertFalse(identity.isActive);
        assertEq(identity.identifierHash, bytes32(0));
        assertEq(identity.personhoodProof, bytes32(0));
    }

    function test_IsIdentifierUsed_FalseForUnused() public view {
        string memory unusedIdentifier = "zkpassport-unused-id-999";
        assertFalse(passport.isIdentifierUsed(unusedIdentifier));
    }
}
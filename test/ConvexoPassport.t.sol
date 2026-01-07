// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Convexo_Passport} from "../src/contracts/Convexo_Passport.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, ProofVerificationParams, DisclosedData} from "../src/interfaces/IZKPassportVerifier.sol";

/// @notice Mock ZKPassport Verifier for testing
contract MockZKPassportVerifier is IZKPassportVerifier {
    bool public shouldSucceed = true;
    bool public userIsOver18 = true;
    string public userNationality = "US";

    function setShouldSucceed(bool _shouldSucceed) external {
        shouldSucceed = _shouldSucceed;
    }

    function setUserIsOver18(bool _isOver18) external {
        userIsOver18 = _isOver18;
    }

    function setUserNationality(string memory _nationality) external {
        userNationality = _nationality;
    }

    function verifyProof(
        ProofVerificationParams calldata,
        bool
    ) external view returns (bool success, DisclosedData memory disclosedData) {
        success = shouldSucceed;
        disclosedData = DisclosedData({
            nationality: userNationality,
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

    event PassportMinted(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier,
        bytes32 personhoodProof,
        string nationality,
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

    function test_Deployment() public view {
        assertEq(passport.name(), "Convexo Passport");
        assertEq(passport.symbol(), "CPASS");
        assertEq(address(passport.zkPassportVerifier()), address(mockVerifier));
        assertTrue(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(passport.hasRole(passport.MINTER_ROLE(), admin));
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
        emit PassportMinted(
            user1, 
            0, 
            keccak256(abi.encodePacked(params.publicKey, params.scope)), 
            params.nullifier,
            "US",
            true
        );
        
        uint256 tokenId = passport.safeMintWithZKPassport(params, false);

        assertEq(tokenId, 0);
        assertEq(passport.ownerOf(tokenId), user1);
        assertEq(passport.balanceOf(user1), 1);
        assertTrue(passport.holdsActivePassport(user1));
        assertEq(passport.getActivePassportCount(), 1);

        // Verify all stored ZKPassport data
        IConvexoPassport.VerifiedIdentity memory identity = passport.getVerifiedIdentity(user1);
        assertTrue(identity.isActive);
        assertEq(identity.nationality, "US");
        assertEq(identity.personhoodProof, params.nullifier); // PERSONHOOD
        assertTrue(identity.isOver18); // KYC age verification
        assertGt(identity.zkPassportTimestamp, 0); // ZKPassport timestamp
        assertEq(identity.uniqueIdentifier, keccak256(abi.encodePacked(params.publicKey, params.scope))); // UNIQUE ID
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

    function test_SafeMintWithZKPassport_RevertIfNotOver18() public {
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
        vm.expectRevert(Convexo_Passport.MustBeOver18.selector);
        passport.safeMintWithZKPassport(params, false);
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

        // Try to use the same identifier with a different user
        vm.prank(user2);
        vm.expectRevert(Convexo_Passport.IdentifierAlreadyUsed.selector);
        passport.safeMintWithZKPassport(params, false);
    }

    function test_AdminMint_Success() public {
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "/custom/1");

        assertEq(tokenId, 0);
        assertEq(passport.ownerOf(tokenId), user1);
        assertEq(passport.balanceOf(user1), 1);
        // TokenURI is base URI + passed URI
        assertEq(passport.tokenURI(tokenId), string(abi.encodePacked(BASE_URI, "/custom/1")));
        assertTrue(passport.holdsActivePassport(user1));
    }

    function test_AdminMint_RevertIfNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        passport.safeMint(user2, "https://custom-uri.com/1");
    }

    function test_RevokePassport_Success() public {
        // Mint a passport first
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "https://custom-uri.com/1");

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
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "https://custom-uri.com/1");

        vm.prank(user1);
        vm.expectRevert();
        passport.revokePassport(tokenId);
    }

    function test_RevokePassport_RevertIfAlreadyRevoked() public {
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "https://custom-uri.com/1");

        vm.prank(admin);
        passport.revokePassport(tokenId);

        vm.prank(admin);
        vm.expectRevert(Convexo_Passport.PassportNotActive.selector);
        passport.revokePassport(tokenId);
    }

    function test_Soulbound_CannotTransfer() public {
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "https://custom-uri.com/1");

        vm.prank(user1);
        vm.expectRevert(Convexo_Passport.SoulboundTokenCannotBeTransferred.selector);
        passport.transferFrom(user1, user2, tokenId);
    }

    function test_Soulbound_CanBurn() public {
        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "https://custom-uri.com/1");

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

        vm.prank(admin);
        uint256 tokenId = passport.safeMint(user1, "");

        // The tokenURI should use the new base URI
        string memory uri = passport.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);
    }

    function test_SetBaseURI_RevertIfNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        passport.setBaseURI("https://new-uri.com");
    }
}


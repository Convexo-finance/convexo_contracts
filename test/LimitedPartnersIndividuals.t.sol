// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {VeriffVerifier} from "../src/contracts/VeriffVerifier.sol";
import {ILimitedPartnersIndividuals} from "../src/interfaces/ILimitedPartnersIndividuals.sol";

contract LimitedPartnersIndividualsTest is Test {
    Limited_Partners_Individuals public nft;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    string public constant VERIFF_SESSION = "veriff_session_123";
    string public constant TOKEN_URI = "ipfs://metadata";

    function setUp() public {
        // Deploy NFT without verifier callback for basic tests
        nft = new Limited_Partners_Individuals(admin, minter, address(0));
    }

    function test_Mint() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.tokenURI(tokenId), TOKEN_URI);
        assertTrue(nft.getTokenState(tokenId));
    }

    function test_MintFails_NotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);
    }

    function test_Soulbound_TransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Limited_Partners_Individuals.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_SetTokenState_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        assertTrue(nft.getTokenState(tokenId));

        vm.prank(admin);
        nft.setTokenState(tokenId, false);
        assertFalse(nft.getTokenState(tokenId));
    }

    function test_GetVerificationId_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        vm.prank(admin);
        string memory vId = nft.getVerificationId(tokenId);
        assertEq(vId, VERIFF_SESSION);
    }

    function test_SupportsInterface() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
    }

    function test_OneNFTPerAddress_SecondMintFails() public {
        // Mint first NFT to user1
        vm.prank(minter);
        nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        // Try to mint second NFT to same user1 - should fail
        vm.prank(minter);
        vm.expectRevert(Limited_Partners_Individuals.AlreadyHoldsNFT.selector);
        nft.safeMint(user1, "veriff_session_456", "ipfs://metadata2");
    }

    function test_OneNFTPerAddress_DifferentUsersCanMint() public {
        // Mint NFT to user1
        vm.prank(minter);
        uint256 tokenId1 = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        // Mint NFT to user2 - should succeed
        vm.prank(minter);
        uint256 tokenId2 = nft.safeMint(user2, "veriff_session_456", "ipfs://metadata2");

        assertEq(nft.ownerOf(tokenId1), user1);
        assertEq(nft.ownerOf(tokenId2), user2);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
    }

    function test_OneNFTPerAddress_AfterBurnCanMintAgain() public {
        // Mint first NFT to user1
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        // Burn the NFT
        vm.prank(user1);
        nft.burn(tokenId);

        assertEq(nft.balanceOf(user1), 0);

        // Mint new NFT to user1 - should succeed after burn
        vm.prank(minter);
        uint256 newTokenId = nft.safeMint(user1, "veriff_session_789", "ipfs://metadata3");

        assertEq(nft.ownerOf(newTokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function test_VerifierContractIsImmutable() public view {
        assertEq(nft.verifierContract(), address(0));
    }
}

/// @notice Integration tests for NFT with Verifier callback
contract LimitedPartnersIndividualsIntegrationTest is Test {
    Limited_Partners_Individuals public nft;
    VeriffVerifier public verifier;

    address public user1 = address(0x3);

    string public constant VERIFF_SESSION = "veriff_session_123";
    string public constant TOKEN_URI = "ipfs://metadata";

    function setUp() public {
        // First deploy a placeholder NFT to get the address for verifier
        // In production, this is a circular dependency that requires CREATE2 or two-step deployment

        // Deploy verifier first with a placeholder LP address
        // Use address(this) as admin so we can grant roles
        Limited_Partners_Individuals placeholderNft = new Limited_Partners_Individuals(address(this), address(this), address(0));
        verifier = new VeriffVerifier(address(this), ILimitedPartnersIndividuals(address(placeholderNft)));

        // Deploy the real NFT with verifier address
        nft = new Limited_Partners_Individuals(address(this), address(this), address(verifier));

        // Grant MINTER_CALLBACK_ROLE to the NFT contract so it can call markAsMinted
        verifier.grantRole(verifier.MINTER_CALLBACK_ROLE(), address(nft));
    }

    function test_MintTriggersVerifierCallback() public {
        // First submit and approve verification in the verifier
        verifier.submitVerification(user1, VERIFF_SESSION);
        verifier.approveVerification(user1);

        // Check status is Approved before minting
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Approved));
        assertTrue(verifier.isApproved(user1));
        assertFalse(verifier.isMinted(user1));

        // Mint NFT - should trigger callback
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        // Verify callback updated the verifier status
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Minted));
        assertTrue(verifier.isMinted(user1));
        assertTrue(verifier.isVerified(user1));

        // Verify NFT was minted
        assertEq(nft.ownerOf(tokenId), user1);
    }

    function test_MarkAsMinted_RequiresApprovedStatus() public {
        // Submit but don't approve
        verifier.submitVerification(user1, VERIFF_SESSION);

        // Try to mint without approval - should fail on markAsMinted
        vm.expectRevert("Not approved");
        nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);
    }

    function test_VerifierPrivacy_AdminCanReadRecord() public {
        verifier.submitVerification(user1, VERIFF_SESSION);

        // Admin can read full record
        VeriffVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.user, user1);
        assertEq(record.veriffSessionId, VERIFF_SESSION);
    }

    function test_VerifierPrivacy_NonAdminCannotReadRecord() public {
        verifier.submitVerification(user1, VERIFF_SESSION);

        // Non-admin cannot read full record
        vm.prank(user1);
        vm.expectRevert();
        verifier.getVerificationRecord(user1);
    }

    function test_VerifierPrivacy_PublicCanCheckExistence() public {
        // Before submission
        assertFalse(verifier.hasVerificationRecord(user1));

        verifier.submitVerification(user1, VERIFF_SESSION);

        // After submission - public can check existence
        assertTrue(verifier.hasVerificationRecord(user1));
    }

    function test_VerifierPrivacy_PublicCanCheckStatus() public {
        verifier.submitVerification(user1, VERIFF_SESSION);

        // Public can check status enum (no details)
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Pending));
        assertFalse(verifier.isApproved(user1));
        assertFalse(verifier.isMinted(user1));
    }

    function test_ManualMintWorkflow() public {
        // Step 1: Backend submits verification
        verifier.submitVerification(user1, VERIFF_SESSION);
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Pending));

        // Step 2: Admin reviews private data
        VeriffVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.veriffSessionId, VERIFF_SESSION);

        // Step 3: Admin approves (NO auto-mint)
        verifier.approveVerification(user1);
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Approved));

        // No NFT minted yet
        assertEq(nft.balanceOf(user1), 0);

        // Step 4: Admin manually mints NFT
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        // Step 5: Callback auto-updates verifier status
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Minted));
        assertEq(nft.ownerOf(tokenId), user1);
    }
}

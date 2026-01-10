// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {SumsubVerifier} from "../src/contracts/SumsubVerifier.sol";
import {ILimitedPartnersBusiness} from "../src/interfaces/ILimitedPartnersBusiness.sol";

contract LimitedPartnersBusinessTest is Test {
    Limited_Partners_Business public nft;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    function setUp() public {
        // Deploy NFT without verifier callback for basic tests
        nft = new Limited_Partners_Business(admin, minter, address(0));
    }

    function test_Mint() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            "ipfs://metadata"
        );

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertTrue(nft.getTokenState(tokenId));
        assertEq(nft.getCompanyName(tokenId), "Acme Corp");
    }

    function test_MintFails_NotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );
    }

    function test_Soulbound_TransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );

        vm.prank(user1);
        vm.expectRevert(Limited_Partners_Business.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_GetBusinessInfo_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );

        vm.prank(admin);
        Limited_Partners_Business.BusinessInfo memory info = nft.getBusinessInfo(tokenId);
        assertEq(info.companyName, "Acme Corp");
        assertEq(info.registrationNumber, "REG123456");
    }

    function test_OneNFTPerAddress_SecondMintFails() public {
        // Mint first NFT to user1
        vm.prank(minter);
        nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            "ipfs://metadata"
        );

        // Try to mint second NFT to same user1 - should fail
        vm.prank(minter);
        vm.expectRevert(Limited_Partners_Business.AlreadyHoldsNFT.selector);
        nft.safeMint(
            user1,
            "Beta Corp",
            "REG789012",
            "US-CA",
            Limited_Partners_Business.BusinessType.LLC,
            "sumsub_456",
            "ipfs://metadata2"
        );
    }

    function test_OneNFTPerAddress_DifferentUsersCanMint() public {
        // Mint NFT to user1
        vm.prank(minter);
        uint256 tokenId1 = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            "ipfs://metadata"
        );

        // Mint NFT to user2 - should succeed
        vm.prank(minter);
        uint256 tokenId2 = nft.safeMint(
            user2,
            "Beta Corp",
            "REG789012",
            "US-CA",
            Limited_Partners_Business.BusinessType.LLC,
            "sumsub_456",
            "ipfs://metadata2"
        );

        assertEq(nft.ownerOf(tokenId1), user1);
        assertEq(nft.ownerOf(tokenId2), user2);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
    }

    function test_OneNFTPerAddress_AfterBurnCanMintAgain() public {
        // Mint first NFT to user1
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            "ipfs://metadata"
        );

        // Burn the NFT
        vm.prank(user1);
        nft.burn(tokenId);

        assertEq(nft.balanceOf(user1), 0);

        // Mint new NFT to user1 - should succeed after burn
        vm.prank(minter);
        uint256 newTokenId = nft.safeMint(
            user1,
            "Gamma Corp",
            "REG345678",
            "US-NY",
            Limited_Partners_Business.BusinessType.Partnership,
            "sumsub_789",
            "ipfs://metadata3"
        );

        assertEq(nft.ownerOf(newTokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function test_VerifierContractIsImmutable() public view {
        assertEq(nft.verifierContract(), address(0));
    }
}

/// @notice Integration tests for NFT with Verifier callback
contract LimitedPartnersBusinessIntegrationTest is Test {
    Limited_Partners_Business public nft;
    SumsubVerifier public verifier;

    address public user1 = address(0x3);

    string public constant APPLICANT_ID = "sumsub_applicant_123";
    string public constant COMPANY_NAME = "Acme Corp";
    string public constant REG_NUMBER = "REG123456";
    string public constant JURISDICTION = "US-DE";
    string public constant TOKEN_URI = "ipfs://metadata";

    function setUp() public {
        // First deploy a placeholder NFT to get the address for verifier
        // Use address(this) as admin so we can grant roles
        Limited_Partners_Business placeholderNft = new Limited_Partners_Business(address(this), address(this), address(0));
        verifier = new SumsubVerifier(address(this), ILimitedPartnersBusiness(address(placeholderNft)));

        // Deploy the real NFT with verifier address
        nft = new Limited_Partners_Business(address(this), address(this), address(verifier));

        // Grant MINTER_CALLBACK_ROLE to the NFT contract so it can call markAsMinted
        verifier.grantRole(verifier.MINTER_CALLBACK_ROLE(), address(nft));
    }

    function test_MintTriggersVerifierCallback() public {
        // First submit and approve verification in the verifier
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.approveVerification(user1);

        // Check status is Approved before minting
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Approved));
        assertTrue(verifier.isApproved(user1));
        assertFalse(verifier.isMinted(user1));

        // Mint NFT - should trigger callback
        uint256 tokenId = nft.safeMint(
            user1,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            Limited_Partners_Business.BusinessType.Corporation,
            APPLICANT_ID,
            TOKEN_URI
        );

        // Verify callback updated the verifier status
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Minted));
        assertTrue(verifier.isMinted(user1));
        assertTrue(verifier.isVerified(user1));

        // Verify NFT was minted
        assertEq(nft.ownerOf(tokenId), user1);
    }

    function test_MarkAsMinted_RequiresApprovedStatus() public {
        // Submit but don't approve
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // Try to mint without approval - should fail on markAsMinted
        vm.expectRevert("Not approved");
        nft.safeMint(
            user1,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            Limited_Partners_Business.BusinessType.Corporation,
            APPLICANT_ID,
            TOKEN_URI
        );
    }

    function test_VerifierPrivacy_AdminCanReadRecord() public {
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // Admin can read full record
        SumsubVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.user, user1);
        assertEq(record.sumsubApplicantId, APPLICANT_ID);
        assertEq(record.companyName, COMPANY_NAME);
    }

    function test_VerifierPrivacy_NonAdminCannotReadRecord() public {
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // Non-admin cannot read full record
        vm.prank(user1);
        vm.expectRevert();
        verifier.getVerificationRecord(user1);
    }

    function test_VerifierPrivacy_NonAdminCannotReadCompanyDetails() public {
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // Non-admin cannot read company details
        vm.prank(user1);
        vm.expectRevert();
        verifier.getCompanyDetails(user1);
    }

    function test_VerifierPrivacy_PublicCanCheckExistence() public {
        // Before submission
        assertFalse(verifier.hasVerificationRecord(user1));

        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // After submission - public can check existence
        assertTrue(verifier.hasVerificationRecord(user1));
    }

    function test_VerifierPrivacy_PublicCanCheckStatus() public {
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );

        // Public can check status enum (no details)
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Pending));
        assertFalse(verifier.isApproved(user1));
        assertFalse(verifier.isMinted(user1));
    }

    function test_ManualMintWorkflow() public {
        // Step 1: Backend submits verification
        verifier.submitVerification(
            user1,
            APPLICANT_ID,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            SumsubVerifier.BusinessType.Corporation
        );
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Pending));

        // Step 2: Admin reviews private data
        SumsubVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.companyName, COMPANY_NAME);

        // Step 3: Admin approves (NO auto-mint)
        verifier.approveVerification(user1);
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Approved));

        // No NFT minted yet
        assertEq(nft.balanceOf(user1), 0);

        // Step 4: Admin manually mints NFT
        uint256 tokenId = nft.safeMint(
            user1,
            COMPANY_NAME,
            REG_NUMBER,
            JURISDICTION,
            Limited_Partners_Business.BusinessType.Corporation,
            APPLICANT_ID,
            TOKEN_URI
        );

        // Step 5: Callback auto-updates verifier status
        assertEq(uint256(verifier.getStatus(user1)), uint256(SumsubVerifier.VerificationStatus.Minted));
        assertEq(nft.ownerOf(tokenId), user1);
    }
}

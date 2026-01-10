// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {SumsubVerifier} from "../src/contracts/SumsubVerifier.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {ILimitedPartnersBusiness} from "../src/interfaces/ILimitedPartnersBusiness.sol";

contract SumsubVerifierTest is Test {
    SumsubVerifier public verifier;
    Limited_Partners_Business public lpBusiness;

    address public admin = address(0x1);
    address public business1 = address(0x3);
    address public business2 = address(0x4);

    function setUp() public {
        // Deploy LP Business NFT - use address(this) as admin for test convenience
        // Note: verifier is address(0) since we're testing the verifier directly, not the callback
        lpBusiness = new Limited_Partners_Business(address(this), address(this), address(0));

        // Deploy Sumsub Verifier
        verifier = new SumsubVerifier(address(this), ILimitedPartnersBusiness(address(lpBusiness)));

        // Grant minter role to this contract (for manual minting after approval)
        lpBusiness.grantRole(lpBusiness.MINTER_ROLE(), address(this));
    }

    function test_SubmitVerification() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        // Admin can read the record
        SumsubVerifier.VerificationRecord memory record = verifier.getVerificationRecord(business1);
        assertEq(record.user, business1);
        assertEq(record.companyName, "Acme Corp");
        assertEq(uint256(record.status), uint256(SumsubVerifier.VerificationStatus.Pending));
    }

    function test_ApproveVerification_NoAutoMint() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.approveVerification(business1);

        // Status should be Approved (not Minted)
        assertEq(uint256(verifier.getStatus(business1)), uint256(SumsubVerifier.VerificationStatus.Approved));
        assertTrue(verifier.isApproved(business1));
        assertTrue(verifier.isVerified(business1)); // isVerified returns true for Approved OR Minted

        // NFT should NOT be minted yet (no auto-mint in new model)
        assertEq(lpBusiness.balanceOf(business1), 0);
    }

    function test_ManualMintAfterApproval() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.approveVerification(business1);

        // Admin manually mints NFT
        uint256 tokenId = lpBusiness.safeMint(
            business1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "applicant_123",
            ""
        );

        // NFT should be minted
        assertEq(lpBusiness.balanceOf(business1), 1);
        assertEq(lpBusiness.ownerOf(tokenId), business1);

        // Note: Status won't auto-update to Minted because lpBusiness has address(0) verifier
        // In production with proper callback, status would be Minted
    }

    function test_RejectVerification() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.rejectVerification(business1, "Invalid documents");

        assertFalse(verifier.isVerified(business1));
        assertEq(uint256(verifier.getStatus(business1)), uint256(SumsubVerifier.VerificationStatus.Rejected));
    }

    function test_SubmitVerification_RevertsForDuplicateRegistration() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        vm.expectRevert("Company registration already verified");
        verifier.submitVerification(
            business2,
            "applicant_456",
            "Different Corp",
            "REG123456", // Same registration
            "US-DE",
            SumsubVerifier.BusinessType.LLC
        );
    }

    function test_GetCompanyDetails_AdminOnly() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        // Admin can read company details
        (string memory name, string memory reg, string memory jur, SumsubVerifier.BusinessType bType) =
            verifier.getCompanyDetails(business1);

        assertEq(name, "Acme Corp");
        assertEq(reg, "REG123456");
        assertEq(jur, "US-DE");
        assertEq(uint256(bType), uint256(SumsubVerifier.BusinessType.Corporation));
    }

    function test_GetCompanyDetails_NonAdminReverts() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        // Non-admin cannot read company details
        vm.prank(business1);
        vm.expectRevert();
        verifier.getCompanyDetails(business1);
    }

    function test_PublicCanCheckStatus() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        // Anyone can check status (but not details)
        vm.prank(business2); // Different user
        assertEq(uint256(verifier.getStatus(business1)), uint256(SumsubVerifier.VerificationStatus.Pending));
        assertTrue(verifier.hasVerificationRecord(business1));
        assertFalse(verifier.isApproved(business1));
        assertFalse(verifier.isMinted(business1));
    }

    function test_PublicCannotReadVerificationRecord() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );

        // Non-admin cannot read full record
        vm.prank(business1);
        vm.expectRevert();
        verifier.getVerificationRecord(business1);
    }
}

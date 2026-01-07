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
        lpBusiness = new Limited_Partners_Business(address(this), address(this));
        
        // Deploy Sumsub Verifier
        verifier = new SumsubVerifier(address(this), ILimitedPartnersBusiness(address(lpBusiness)));
        
        // Grant minter role to verifier
        lpBusiness.grantRole(lpBusiness.MINTER_ROLE(), address(verifier));
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
        
        SumsubVerifier.VerificationRecord memory record = verifier.getVerificationStatus(business1);
        assertEq(record.user, business1);
        assertEq(record.companyName, "Acme Corp");
        assertEq(uint(record.status), uint(SumsubVerifier.VerificationStatus.Pending));
    }

    function test_ApproveVerification() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.approveVerification(business1);
        
        assertTrue(verifier.isVerified(business1));
        assertEq(lpBusiness.balanceOf(business1), 1);
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

    function test_GetCompanyDetails() public {
        verifier.submitVerification(
            business1,
            "applicant_123",
            "Acme Corp",
            "REG123456",
            "US-DE",
            SumsubVerifier.BusinessType.Corporation
        );
        verifier.approveVerification(business1);
        
        (string memory name, string memory reg, string memory jur, SumsubVerifier.BusinessType bType) = 
            verifier.getCompanyDetails(business1);
        
        assertEq(name, "Acme Corp");
        assertEq(reg, "REG123456");
        assertEq(jur, "US-DE");
        assertEq(uint(bType), uint(SumsubVerifier.BusinessType.Corporation));
    }
}


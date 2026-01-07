// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {VeriffVerifier} from "../src/contracts/VeriffVerifier.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {ILimitedPartnersIndividuals} from "../src/interfaces/ILimitedPartnersIndividuals.sol";

contract VeriffVerifierTest is Test {
    VeriffVerifier public verifier;
    Limited_Partners_Individuals public lpIndividuals;
    
    address public admin = address(0x1);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    string public constant SESSION_ID = "veriff_session_123";

    function setUp() public {
        // Deploy LP Individuals NFT - use address(this) as admin for test convenience
        lpIndividuals = new Limited_Partners_Individuals(address(this), address(this));
        
        // Deploy Veriff Verifier
        verifier = new VeriffVerifier(address(this), ILimitedPartnersIndividuals(address(lpIndividuals)));
        
        // Grant minter role to verifier
        lpIndividuals.grantRole(lpIndividuals.MINTER_ROLE(), address(verifier));
    }

    function test_SubmitVerification() public {
        verifier.submitVerification(user1, SESSION_ID);
        
        VeriffVerifier.VerificationRecord memory record = verifier.getVerificationStatus(user1);
        assertEq(record.user, user1);
        assertEq(record.veriffSessionId, SESSION_ID);
        assertEq(uint(record.status), uint(VeriffVerifier.VerificationStatus.Pending));
    }

    function test_ApproveVerification() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.approveVerification(user1);
        
        assertTrue(verifier.isVerified(user1));
        assertEq(lpIndividuals.balanceOf(user1), 1);
    }

    function test_RejectVerification() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.rejectVerification(user1, "Invalid documents");
        
        assertFalse(verifier.isVerified(user1));
        assertEq(lpIndividuals.balanceOf(user1), 0);
    }

    function test_SubmitVerification_RevertsForDuplicate() public {
        verifier.submitVerification(user1, SESSION_ID);
        
        vm.expectRevert("User already has a verification");
        verifier.submitVerification(user1, "different_session");
    }

    function test_ResetVerification() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.rejectVerification(user1, "Invalid documents");
        verifier.resetVerification(user1);
        
        // Can submit again after reset
        verifier.submitVerification(user1, "new_session");
    }

    function test_SessionIdUsed() public {
        verifier.submitVerification(user1, SESSION_ID);
        
        assertTrue(verifier.isSessionIdUsed(SESSION_ID));
        assertFalse(verifier.isSessionIdUsed("unused_session"));
    }
}


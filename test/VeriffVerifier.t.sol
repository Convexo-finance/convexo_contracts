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
        // Note: verifier is address(0) since we're testing the verifier directly, not the callback
        lpIndividuals = new Limited_Partners_Individuals(address(this), address(this), address(0));

        // Deploy Veriff Verifier
        verifier = new VeriffVerifier(address(this), ILimitedPartnersIndividuals(address(lpIndividuals)));

        // Grant minter role to this contract (for manual minting after approval)
        lpIndividuals.grantRole(lpIndividuals.MINTER_ROLE(), address(this));
    }

    function test_SubmitVerification() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Admin can read the full record
        VeriffVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.user, user1);
        assertEq(record.veriffSessionId, SESSION_ID);
        assertEq(uint256(record.status), uint256(VeriffVerifier.VerificationStatus.Pending));
    }

    function test_ApproveVerification_NoAutoMint() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.approveVerification(user1);

        // Status should be Approved (not Minted)
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Approved));
        assertTrue(verifier.isApproved(user1));
        assertTrue(verifier.isVerified(user1)); // isVerified returns true for Approved OR Minted

        // NFT should NOT be minted yet (no auto-mint in new model)
        assertEq(lpIndividuals.balanceOf(user1), 0);
    }

    function test_ManualMintAfterApproval() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.approveVerification(user1);

        // Admin manually mints NFT
        uint256 tokenId = lpIndividuals.safeMint(user1, SESSION_ID, "");

        // NFT should be minted
        assertEq(lpIndividuals.balanceOf(user1), 1);
        assertEq(lpIndividuals.ownerOf(tokenId), user1);

        // Note: Status won't auto-update to Minted because lpIndividuals has address(0) verifier
        // In production with proper callback, status would be Minted
    }

    function test_RejectVerification() public {
        verifier.submitVerification(user1, SESSION_ID);
        verifier.rejectVerification(user1, "Invalid documents");

        assertFalse(verifier.isVerified(user1));
        assertEq(lpIndividuals.balanceOf(user1), 0);
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Rejected));
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

        VeriffVerifier.VerificationRecord memory record = verifier.getVerificationRecord(user1);
        assertEq(record.veriffSessionId, "new_session");
    }

    function test_SessionIdUsed_AdminOnly() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Admin can check session ID usage
        assertTrue(verifier.isSessionIdUsed(SESSION_ID));
        assertFalse(verifier.isSessionIdUsed("unused_session"));
    }

    function test_SessionIdUsed_NonAdminReverts() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Non-admin cannot check session ID usage
        vm.prank(user1);
        vm.expectRevert();
        verifier.isSessionIdUsed(SESSION_ID);
    }

    function test_PublicCanCheckStatus() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Anyone can check status (but not details)
        vm.prank(user2); // Different user
        assertEq(uint256(verifier.getStatus(user1)), uint256(VeriffVerifier.VerificationStatus.Pending));
        assertTrue(verifier.hasVerificationRecord(user1));
        assertFalse(verifier.isApproved(user1));
        assertFalse(verifier.isMinted(user1));
    }

    function test_PublicCannotReadVerificationRecord() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Non-admin cannot read full record
        vm.prank(user1);
        vm.expectRevert();
        verifier.getVerificationRecord(user1);
    }

    function test_GetSessionId_AdminOnly() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Admin can get session ID
        string memory sessionId = verifier.getSessionId(user1);
        assertEq(sessionId, SESSION_ID);
    }

    function test_GetSessionId_NonAdminReverts() public {
        verifier.submitVerification(user1, SESSION_ID);

        // Non-admin cannot get session ID
        vm.prank(user1);
        vm.expectRevert();
        verifier.getSessionId(user1);
    }
}

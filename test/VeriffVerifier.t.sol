// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {VeriffVerifier} from "../src/contracts/VeriffVerifier.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";

contract VeriffVerifierTest is Test {
    VeriffVerifier public veriffVerifier;
    Convexo_LPs public convexoLPs;

    address public admin = address(0x1);
    address public verifier = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public unauthorizedUser = address(0x5);

    string constant SESSION_ID_1 = "veriff_session_123456";
    string constant SESSION_ID_2 = "veriff_session_789012";

    function setUp() public {
        // Deploy Convexo_LPs NFT
        vm.startPrank(admin);
        convexoLPs = new Convexo_LPs(admin, admin);

        // Deploy VeriffVerifier
        veriffVerifier = new VeriffVerifier(admin, IConvexoLPs(address(convexoLPs)));

        // Grant MINTER_ROLE to VeriffVerifier so it can mint NFTs
        convexoLPs.grantRole(convexoLPs.MINTER_ROLE(), address(veriffVerifier));

        // Grant VERIFIER_ROLE to verifier address
        veriffVerifier.grantRole(veriffVerifier.VERIFIER_ROLE(), verifier);
        vm.stopPrank();
    }

    function test_SubmitVerification_Success() public {
        vm.prank(verifier);
        vm.expectEmit(true, false, false, true);
        emit VerificationSubmitted(user1, SESSION_ID_1, block.timestamp);

        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        VeriffVerifier.VerificationRecord memory record = veriffVerifier.getVerificationStatus(user1);
        assertEq(record.user, user1);
        assertEq(record.veriffSessionId, SESSION_ID_1);
        assertEq(uint256(record.status), uint256(VeriffVerifier.VerificationStatus.Pending));
        assertEq(record.submittedAt, block.timestamp);
        assertEq(record.processedAt, 0);
        assertEq(record.processor, address(0));
    }

    function test_SubmitVerification_RevertsForUnauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        veriffVerifier.submitVerification(user1, SESSION_ID_1);
    }

    function test_SubmitVerification_RevertsForInvalidAddress() public {
        vm.prank(verifier);
        vm.expectRevert("Invalid user address");
        veriffVerifier.submitVerification(address(0), SESSION_ID_1);
    }

    function test_SubmitVerification_RevertsForEmptySessionId() public {
        vm.prank(verifier);
        vm.expectRevert("Invalid session ID");
        veriffVerifier.submitVerification(user1, "");
    }

    function test_SubmitVerification_RevertsForDuplicateUser() public {
        vm.startPrank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        vm.expectRevert("User already has a verification");
        veriffVerifier.submitVerification(user1, SESSION_ID_2);
        vm.stopPrank();
    }

    function test_SubmitVerification_RevertsForDuplicateSessionId() public {
        vm.startPrank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        vm.expectRevert("Session ID already used");
        veriffVerifier.submitVerification(user2, SESSION_ID_1);
        vm.stopPrank();
    }

    function test_ApproveVerification_Success() public {
        // Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Approve verification
        vm.prank(verifier);
        vm.expectEmit(true, false, false, true);
        emit VerificationApproved(user1, SESSION_ID_1, 0, verifier, block.timestamp);

        veriffVerifier.approveVerification(user1);

        // Check verification record
        VeriffVerifier.VerificationRecord memory record = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(record.status), uint256(VeriffVerifier.VerificationStatus.Approved));
        assertEq(record.processedAt, block.timestamp);
        assertEq(record.processor, verifier);
        assertEq(record.nftTokenId, 0);

        // Check NFT was minted
        assertEq(convexoLPs.balanceOf(user1), 1);
        assertTrue(veriffVerifier.isVerified(user1));
    }

    function test_ApproveVerification_RevertsForNoPending() public {
        vm.prank(verifier);
        vm.expectRevert("No pending verification");
        veriffVerifier.approveVerification(user1);
    }

    function test_ApproveVerification_RevertsForUnauthorized() public {
        // Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Try to approve as unauthorized user
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        veriffVerifier.approveVerification(user1);
    }

    function test_RejectVerification_Success() public {
        // Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Reject verification
        string memory reason = "Insufficient documentation";
        vm.prank(verifier);
        vm.expectEmit(true, false, false, true);
        emit VerificationRejected(user1, SESSION_ID_1, reason, verifier, block.timestamp);

        veriffVerifier.rejectVerification(user1, reason);

        // Check verification record
        VeriffVerifier.VerificationRecord memory record = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(record.status), uint256(VeriffVerifier.VerificationStatus.Rejected));
        assertEq(record.processedAt, block.timestamp);
        assertEq(record.processor, verifier);
        assertEq(record.rejectionReason, reason);

        // Check no NFT was minted
        assertEq(convexoLPs.balanceOf(user1), 0);
        assertFalse(veriffVerifier.isVerified(user1));
    }

    function test_RejectVerification_RevertsForEmptyReason() public {
        // Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Try to reject with empty reason
        vm.prank(verifier);
        vm.expectRevert("Rejection reason required");
        veriffVerifier.rejectVerification(user1, "");
    }

    function test_RejectVerification_RevertsForNoPending() public {
        vm.prank(verifier);
        vm.expectRevert("No pending verification");
        veriffVerifier.rejectVerification(user1, "Some reason");
    }

    function test_IsSessionIdUsed() public {
        assertFalse(veriffVerifier.isSessionIdUsed(SESSION_ID_1));

        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        assertTrue(veriffVerifier.isSessionIdUsed(SESSION_ID_1));
    }

    function test_GetUserBySessionId() public {
        assertEq(veriffVerifier.getUserBySessionId(SESSION_ID_1), address(0));

        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        assertEq(veriffVerifier.getUserBySessionId(SESSION_ID_1), user1);
    }

    function test_ResetVerification_Success() public {
        // Submit and reject verification
        vm.startPrank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);
        veriffVerifier.rejectVerification(user1, "Failed KYC");
        vm.stopPrank();

        // Reset verification as admin
        vm.prank(admin);
        veriffVerifier.resetVerification(user1);

        // Check verification was reset
        VeriffVerifier.VerificationRecord memory record = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(record.status), uint256(VeriffVerifier.VerificationStatus.None));
        assertEq(record.user, address(0));

        // Check session ID is available again
        assertFalse(veriffVerifier.isSessionIdUsed(SESSION_ID_1));

        // User can submit again with same session ID
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        VeriffVerifier.VerificationRecord memory newRecord = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(newRecord.status), uint256(VeriffVerifier.VerificationStatus.Pending));
    }

    function test_ResetVerification_RevertsForNonRejected() public {
        // Submit verification (pending state)
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Try to reset pending verification
        vm.prank(admin);
        vm.expectRevert("Can only reset rejected verifications");
        veriffVerifier.resetVerification(user1);
    }

    function test_ResetVerification_RevertsForUnauthorized() public {
        // Submit and reject verification
        vm.startPrank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);
        veriffVerifier.rejectVerification(user1, "Failed KYC");
        vm.stopPrank();

        // Try to reset as unauthorized user
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        veriffVerifier.resetVerification(user1);
    }

    function test_MultipleUsers_DifferentStatuses() public {
        vm.startPrank(verifier);

        // User1: Approved
        veriffVerifier.submitVerification(user1, SESSION_ID_1);
        veriffVerifier.approveVerification(user1);

        // User2: Rejected
        veriffVerifier.submitVerification(user2, SESSION_ID_2);
        veriffVerifier.rejectVerification(user2, "Failed verification");

        vm.stopPrank();

        // Check user1 is verified with NFT
        assertTrue(veriffVerifier.isVerified(user1));
        assertEq(convexoLPs.balanceOf(user1), 1);

        // Check user2 is not verified without NFT
        assertFalse(veriffVerifier.isVerified(user2));
        assertEq(convexoLPs.balanceOf(user2), 0);
    }

    function test_FullWorkflow_SubmitApprove() public {
        // Step 1: Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        VeriffVerifier.VerificationRecord memory pendingRecord = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(pendingRecord.status), uint256(VeriffVerifier.VerificationStatus.Pending));

        // Step 2: Approve verification
        vm.prank(verifier);
        veriffVerifier.approveVerification(user1);

        VeriffVerifier.VerificationRecord memory approvedRecord = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(approvedRecord.status), uint256(VeriffVerifier.VerificationStatus.Approved));

        // Step 3: Verify NFT was minted
        assertEq(convexoLPs.balanceOf(user1), 1);
        assertEq(convexoLPs.ownerOf(0), user1);
    }

    function test_FullWorkflow_SubmitRejectReset() public {
        // Step 1: Submit verification
        vm.prank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);

        // Step 2: Reject verification
        vm.prank(verifier);
        veriffVerifier.rejectVerification(user1, "Incomplete documents");

        VeriffVerifier.VerificationRecord memory rejectedRecord = veriffVerifier.getVerificationStatus(user1);
        assertEq(uint256(rejectedRecord.status), uint256(VeriffVerifier.VerificationStatus.Rejected));

        // Step 3: Reset verification
        vm.prank(admin);
        veriffVerifier.resetVerification(user1);

        // Step 4: Resubmit and approve
        vm.startPrank(verifier);
        veriffVerifier.submitVerification(user1, SESSION_ID_1);
        veriffVerifier.approveVerification(user1);
        vm.stopPrank();

        // Verify final state
        assertTrue(veriffVerifier.isVerified(user1));
        assertEq(convexoLPs.balanceOf(user1), 1);
    }

    event VerificationSubmitted(
        address indexed user,
        string sessionId,
        uint256 timestamp
    );

    event VerificationApproved(
        address indexed user,
        string sessionId,
        uint256 nftTokenId,
        address indexed approver,
        uint256 timestamp
    );

    event VerificationRejected(
        address indexed user,
        string sessionId,
        string reason,
        address indexed rejector,
        uint256 timestamp
    );
}

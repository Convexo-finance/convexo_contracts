// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IConvexoLPs} from "../interfaces/IConvexoLPs.sol";

/// @title VeriffVerifier
/// @notice Human-approved KYC/KYB verification system for Limited Partner access
/// @dev Admin submits verification results from Veriff platform, then approves/rejects to mint Convexo_LPs NFT
contract VeriffVerifier is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice Verification status states
    enum VerificationStatus {
        None,       // 0 - No verification submitted
        Pending,    // 1 - Submitted, awaiting approval
        Approved,   // 2 - Approved and NFT minted
        Rejected    // 3 - Rejected by admin
    }

    /// @notice Verification record for a user
    struct VerificationRecord {
        address user;
        string veriffSessionId;
        VerificationStatus status;
        uint256 submittedAt;
        uint256 processedAt;
        address processor;
        string rejectionReason;
        uint256 nftTokenId;
    }

    /// @notice The Convexo_LPs NFT contract
    IConvexoLPs public immutable convexoLPs;

    /// @notice Mapping from user address to verification record
    mapping(address => VerificationRecord) public verifications;

    /// @notice Mapping from Veriff session ID to user address (prevent duplicates)
    mapping(string => address) public sessionIdToUser;

    /// @notice Emitted when a verification is submitted
    event VerificationSubmitted(
        address indexed user,
        string sessionId,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is approved
    event VerificationApproved(
        address indexed user,
        string sessionId,
        uint256 nftTokenId,
        address indexed approver,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is rejected
    event VerificationRejected(
        address indexed user,
        string sessionId,
        string reason,
        address indexed rejector,
        uint256 timestamp
    );

    constructor(address admin, IConvexoLPs _convexoLPs) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        convexoLPs = _convexoLPs;
    }

    /// @notice Submit a verification result from Veriff platform
    /// @param user The address of the user being verified
    /// @param sessionId The Veriff session ID
    function submitVerification(
        address user,
        string calldata sessionId
    ) external onlyRole(VERIFIER_ROLE) {
        require(user != address(0), "Invalid user address");
        require(bytes(sessionId).length > 0, "Invalid session ID");
        require(
            verifications[user].status == VerificationStatus.None,
            "User already has a verification"
        );
        require(
            sessionIdToUser[sessionId] == address(0),
            "Session ID already used"
        );

        verifications[user] = VerificationRecord({
            user: user,
            veriffSessionId: sessionId,
            status: VerificationStatus.Pending,
            submittedAt: block.timestamp,
            processedAt: 0,
            processor: address(0),
            rejectionReason: "",
            nftTokenId: 0
        });

        sessionIdToUser[sessionId] = user;

        emit VerificationSubmitted(user, sessionId, block.timestamp);
    }

    /// @notice Approve a pending verification and mint Convexo_LPs NFT
    /// @param user The address of the user to approve
    function approveVerification(address user) external onlyRole(VERIFIER_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Pending, "No pending verification");

        // Mint Convexo_LPs NFT (Tier 2)
        uint256 tokenId = convexoLPs.safeMint(
            user,
            record.veriffSessionId, // Use session ID as companyId
            "" // Empty URI, can be updated later
        );

        record.status = VerificationStatus.Approved;
        record.processedAt = block.timestamp;
        record.processor = msg.sender;
        record.nftTokenId = tokenId;

        emit VerificationApproved(
            user,
            record.veriffSessionId,
            tokenId,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Reject a pending verification
    /// @param user The address of the user to reject
    /// @param reason The reason for rejection
    function rejectVerification(
        address user,
        string calldata reason
    ) external onlyRole(VERIFIER_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Pending, "No pending verification");
        require(bytes(reason).length > 0, "Rejection reason required");

        record.status = VerificationStatus.Rejected;
        record.processedAt = block.timestamp;
        record.processor = msg.sender;
        record.rejectionReason = reason;

        emit VerificationRejected(
            user,
            record.veriffSessionId,
            reason,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Get verification status for a user
    /// @param user The address to check
    /// @return The verification record
    function getVerificationStatus(address user)
        external
        view
        returns (VerificationRecord memory)
    {
        return verifications[user];
    }

    /// @notice Check if a user has an approved verification
    /// @param user The address to check
    /// @return True if user has approved verification
    function isVerified(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Approved;
    }

    /// @notice Check if a session ID has been used
    /// @param sessionId The Veriff session ID to check
    /// @return True if session ID has been used
    function isSessionIdUsed(string calldata sessionId) external view returns (bool) {
        return sessionIdToUser[sessionId] != address(0);
    }

    /// @notice Get user address associated with a session ID
    /// @param sessionId The Veriff session ID
    /// @return The user address (address(0) if not found)
    function getUserBySessionId(string calldata sessionId) external view returns (address) {
        return sessionIdToUser[sessionId];
    }

    /// @notice Allow user to resubmit after rejection (admin only)
    /// @param user The address of the user
    function resetVerification(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(
            record.status == VerificationStatus.Rejected,
            "Can only reset rejected verifications"
        );

        // Clear session ID mapping
        delete sessionIdToUser[record.veriffSessionId];

        // Reset verification record
        delete verifications[user];
    }
}

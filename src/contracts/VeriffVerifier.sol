// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ILimitedPartnersIndividuals} from "../interfaces/ILimitedPartnersIndividuals.sol";

/// @title VeriffVerifier
/// @notice Human-approved KYC verification system for INDIVIDUAL Limited Partners
/// @dev For INDIVIDUALS only - uses Veriff platform for identity verification
///      Upon approval, admin manually mints Limited_Partners_Individuals NFT (Tier 2)
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// VERIFICATION FLOW (PRIVACY-ENHANCED):
/// ═══════════════════════════════════════════════════════════════════════════════
/// 1. Individual completes Veriff identity verification on frontend
/// 2. Backend receives webhook with verification result
/// 3. Backend calls submitVerification() with session details
/// 4. Admin reviews PRIVATE data and calls approveVerification() or rejectVerification()
/// 5. On approval: Status changes to Approved (NO auto-mint)
/// 6. Admin manually calls Limited_Partners_Individuals.safeMint()
/// 7. NFT contract calls markAsMinted() to update status to Minted
/// 8. User becomes Limited Partner → Can access LP pools, Treasury, Invest
///
/// PRIVACY MODEL:
/// - All verification data is PRIVATE (admin-only access)
/// - Public can only check hasVerificationRecord() (existence, not details)
/// - Events are emitted for monitoring but contain no sensitive data
///
/// For BUSINESS KYB, use SumsubVerifier instead
/// ═══════════════════════════════════════════════════════════════════════════════
contract VeriffVerifier is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant MINTER_CALLBACK_ROLE = keccak256("MINTER_CALLBACK_ROLE");

    /// @notice Verification status states
    enum VerificationStatus {
        None,       // 0 - No verification submitted
        Pending,    // 1 - Submitted, awaiting approval
        Approved,   // 2 - Approved but NFT not yet minted
        Rejected,   // 3 - Rejected by admin
        Minted      // 4 - Approved and NFT minted
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
        uint256 mintedAt;
    }

    /// @notice The Limited Partners Individuals NFT contract
    ILimitedPartnersIndividuals public immutable lpIndividuals;

    /// @notice Mapping from user address to verification record (PRIVATE)
    mapping(address => VerificationRecord) private verifications;

    /// @notice Mapping from Veriff session ID to user address (PRIVATE)
    mapping(string => address) private sessionIdToUser;

    /// @notice Emitted when a verification is submitted
    event VerificationSubmitted(
        address indexed user,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is approved
    event VerificationApproved(
        address indexed user,
        address indexed approver,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is rejected
    event VerificationRejected(
        address indexed user,
        address indexed rejector,
        uint256 timestamp
    );

    /// @notice Emitted when an NFT is minted and verification status updated
    event VerificationMinted(
        address indexed user,
        uint256 tokenId,
        uint256 timestamp
    );

    /// @notice Constructor
    /// @param admin Address to receive admin and verifier roles
    /// @param _lpIndividuals Limited Partners Individuals NFT contract address
    constructor(address admin, ILimitedPartnersIndividuals _lpIndividuals) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        lpIndividuals = _lpIndividuals;
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
            nftTokenId: 0,
            mintedAt: 0
        });

        sessionIdToUser[sessionId] = user;

        emit VerificationSubmitted(user, block.timestamp);
    }

    /// @notice Approve a pending verification (NO auto-mint)
    /// @dev After approval, admin must manually mint NFT via LP contract
    /// @param user The address of the user to approve
    function approveVerification(address user) external onlyRole(VERIFIER_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Pending, "No pending verification");

        record.status = VerificationStatus.Approved;
        record.processedAt = block.timestamp;
        record.processor = msg.sender;

        emit VerificationApproved(
            user,
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
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Mark verification as minted (called by NFT contract after minting)
    /// @param user The user whose NFT was minted
    /// @param tokenId The minted token ID
    function markAsMinted(address user, uint256 tokenId) external onlyRole(MINTER_CALLBACK_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Approved, "Not approved");

        record.status = VerificationStatus.Minted;
        record.nftTokenId = tokenId;
        record.mintedAt = block.timestamp;

        emit VerificationMinted(user, tokenId, block.timestamp);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ADMIN-ONLY VIEW FUNCTIONS (Private data access)
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Get full verification record (admin only)
    /// @param user The address to check
    /// @return The verification record
    function getVerificationRecord(address user)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (VerificationRecord memory)
    {
        return verifications[user];
    }

    /// @notice Get verification session ID for a user (admin only)
    /// @param user The address to check
    /// @return The Veriff session ID
    function getSessionId(address user)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (string memory)
    {
        return verifications[user].veriffSessionId;
    }

    /// @notice Check if a session ID has been used (admin only)
    /// @param sessionId The Veriff session ID to check
    /// @return True if session ID has been used
    function isSessionIdUsed(string calldata sessionId)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (bool)
    {
        return sessionIdToUser[sessionId] != address(0);
    }

    /// @notice Get user address associated with a session ID (admin only)
    /// @param sessionId The Veriff session ID
    /// @return The user address (address(0) if not found)
    function getUserBySessionId(string calldata sessionId)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (address)
    {
        return sessionIdToUser[sessionId];
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // PUBLIC VIEW FUNCTIONS (No sensitive data exposed)
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Check if a user has any verification record (public)
    /// @param user The address to check
    /// @return True if user has any verification record
    function hasVerificationRecord(address user) external view returns (bool) {
        return verifications[user].user != address(0);
    }

    /// @notice Check if a user has an approved verification (ready to mint)
    /// @param user The address to check
    /// @return True if user has approved verification
    function isApproved(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Approved;
    }

    /// @notice Check if a user has a minted verification
    /// @param user The address to check
    /// @return True if user has minted verification
    function isMinted(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Minted;
    }

    /// @notice Check if a user is verified (approved or minted)
    /// @param user The address to check
    /// @return True if user is verified
    function isVerified(address user) external view returns (bool) {
        VerificationStatus status = verifications[user].status;
        return status == VerificationStatus.Approved || status == VerificationStatus.Minted;
    }

    /// @notice Get verification status for a user (status only, no details)
    /// @param user The address to check
    /// @return The verification status
    function getStatus(address user) external view returns (VerificationStatus) {
        return verifications[user].status;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

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

    // ═══════════════════════════════════════════════════════════════════════════════
    // ROLE MANAGEMENT (Multi-admin support for compliance teams)
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Add a new verifier (compliance officer)
    /// @dev Multiple compliance officers can have VERIFIER_ROLE
    /// @param account The address to grant VERIFIER_ROLE
    function addVerifier(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        _grantRole(VERIFIER_ROLE, account);
    }

    /// @notice Remove a verifier (compliance officer)
    /// @param account The address to revoke VERIFIER_ROLE from
    function removeVerifier(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VERIFIER_ROLE, account);
    }

    /// @notice Add a new admin
    /// @dev Multiple admins can manage the contract
    /// @param account The address to grant DEFAULT_ADMIN_ROLE
    function addAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Remove an admin (cannot remove self)
    /// @param account The address to revoke DEFAULT_ADMIN_ROLE from
    function removeAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != msg.sender, "Cannot remove self as admin");
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Grant minter callback role to an NFT contract
    /// @param nftContract The NFT contract address that can call markAsMinted
    function addMinterCallback(address nftContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nftContract != address(0), "Invalid address");
        _grantRole(MINTER_CALLBACK_ROLE, nftContract);
    }

    /// @notice Revoke minter callback role from an NFT contract
    /// @param nftContract The NFT contract address
    function removeMinterCallback(address nftContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_CALLBACK_ROLE, nftContract);
    }

    /// @notice Check if an address is a verifier (compliance officer)
    /// @param account The address to check
    /// @return True if the address has VERIFIER_ROLE
    function isVerifier(address account) external view returns (bool) {
        return hasRole(VERIFIER_ROLE, account);
    }

    /// @notice Check if an address is an admin
    /// @param account The address to check
    /// @return True if the address has DEFAULT_ADMIN_ROLE
    function isAdmin(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Check if an address has minter callback role
    /// @param account The address to check
    /// @return True if the address has MINTER_CALLBACK_ROLE
    function hasMinterCallback(address account) external view returns (bool) {
        return hasRole(MINTER_CALLBACK_ROLE, account);
    }
}

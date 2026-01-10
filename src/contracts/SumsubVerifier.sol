// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ILimitedPartnersBusiness} from "../interfaces/ILimitedPartnersBusiness.sol";

/// @title SumsubVerifier
/// @notice Human-approved KYB verification system for BUSINESS Limited Partners
/// @dev For BUSINESSES only - uses Sumsub platform for KYB verification
///      Upon approval, admin manually mints Limited_Partners_Business NFT (Tier 2)
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// VERIFICATION FLOW (PRIVACY-ENHANCED):
/// ═══════════════════════════════════════════════════════════════════════════════
/// 1. Business completes Sumsub KYB verification on frontend
/// 2. Backend receives webhook with verification result and company details
/// 3. Backend calls submitVerification() with applicant and company details
/// 4. Admin reviews PRIVATE data and calls approveVerification() or rejectVerification()
/// 5. On approval: Status changes to Approved (NO auto-mint)
/// 6. Admin manually calls Limited_Partners_Business.safeMint()
/// 7. NFT contract calls markAsMinted() to update status to Minted
/// 8. Business becomes Limited Partner → Can access LP pools, Treasury, Invest
///
/// PRIVACY MODEL:
/// - All verification data is PRIVATE (admin-only access)
/// - Public can only check hasVerificationRecord() (existence, not details)
/// - Events are emitted for monitoring but contain no sensitive data
///
/// For INDIVIDUAL KYC, use VeriffVerifier instead
/// ═══════════════════════════════════════════════════════════════════════════════
contract SumsubVerifier is AccessControl {
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

    /// @notice Business type for KYB (mirrors NFT contract)
    enum BusinessType {
        Corporation,
        LLC,
        Partnership,
        SoleProprietor,
        Other
    }

    /// @notice Verification record for a business
    struct VerificationRecord {
        address user;                   // Wallet address representing the business
        string sumsubApplicantId;       // Sumsub applicant ID
        string companyName;             // Registered company name
        string companyRegistrationNumber; // Company registration number
        string jurisdiction;            // Jurisdiction of incorporation
        BusinessType businessType;      // Type of business entity
        VerificationStatus status;
        uint256 submittedAt;
        uint256 processedAt;
        address processor;
        string rejectionReason;
        uint256 nftTokenId;
        uint256 mintedAt;
    }

    /// @notice The Limited Partners Business NFT contract
    ILimitedPartnersBusiness public immutable lpBusiness;

    /// @notice Mapping from user address to verification record (PRIVATE)
    mapping(address => VerificationRecord) private verifications;

    /// @notice Mapping from Sumsub applicant ID to user address (PRIVATE)
    mapping(string => address) private applicantIdToUser;

    /// @notice Mapping from company registration number to user address (PRIVATE)
    mapping(string => address) private registrationToUser;

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
    /// @param _lpBusiness Limited Partners Business NFT contract address
    constructor(address admin, ILimitedPartnersBusiness _lpBusiness) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        lpBusiness = _lpBusiness;
    }

    /// @notice Submit a KYB verification result from Sumsub platform
    /// @param user The address representing the business
    /// @param applicantId The Sumsub applicant ID
    /// @param companyName The registered company name
    /// @param registrationNumber The company registration number
    /// @param jurisdiction The jurisdiction of incorporation (e.g., "US-DE", "UK", "SG")
    /// @param businessType The type of business entity
    function submitVerification(
        address user,
        string calldata applicantId,
        string calldata companyName,
        string calldata registrationNumber,
        string calldata jurisdiction,
        BusinessType businessType
    ) external onlyRole(VERIFIER_ROLE) {
        require(user != address(0), "Invalid user address");
        require(bytes(applicantId).length > 0, "Invalid applicant ID");
        require(bytes(companyName).length > 0, "Invalid company name");
        require(bytes(registrationNumber).length > 0, "Invalid registration number");
        require(bytes(jurisdiction).length > 0, "Invalid jurisdiction");
        require(
            verifications[user].status == VerificationStatus.None,
            "User already has a verification"
        );
        require(
            applicantIdToUser[applicantId] == address(0),
            "Applicant ID already used"
        );
        require(
            registrationToUser[registrationNumber] == address(0),
            "Company registration already verified"
        );

        verifications[user] = VerificationRecord({
            user: user,
            sumsubApplicantId: applicantId,
            companyName: companyName,
            companyRegistrationNumber: registrationNumber,
            jurisdiction: jurisdiction,
            businessType: businessType,
            status: VerificationStatus.Pending,
            submittedAt: block.timestamp,
            processedAt: 0,
            processor: address(0),
            rejectionReason: "",
            nftTokenId: 0,
            mintedAt: 0
        });

        applicantIdToUser[applicantId] = user;
        registrationToUser[registrationNumber] = user;

        emit VerificationSubmitted(user, block.timestamp);
    }

    /// @notice Approve a pending verification (NO auto-mint)
    /// @dev After approval, admin must manually mint NFT via LP contract
    /// @param user The address of the business to approve
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
    /// @param user The address of the business to reject
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

    /// @notice Get company details for a user (admin only)
    /// @param user The address to check
    /// @return companyName The company name
    /// @return registrationNumber The registration number
    /// @return jurisdiction The jurisdiction
    /// @return businessType The business type
    function getCompanyDetails(address user)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (
            string memory companyName,
            string memory registrationNumber,
            string memory jurisdiction,
            BusinessType businessType
        )
    {
        VerificationRecord storage record = verifications[user];
        return (
            record.companyName,
            record.companyRegistrationNumber,
            record.jurisdiction,
            record.businessType
        );
    }

    /// @notice Check if an applicant ID has been used (admin only)
    /// @param applicantId The Sumsub applicant ID to check
    /// @return True if applicant ID has been used
    function isApplicantIdUsed(string calldata applicantId)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (bool)
    {
        return applicantIdToUser[applicantId] != address(0);
    }

    /// @notice Check if a company registration number has been used (admin only)
    /// @param registrationNumber The registration number to check
    /// @return True if registration number has been used
    function isRegistrationUsed(string calldata registrationNumber)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (bool)
    {
        return registrationToUser[registrationNumber] != address(0);
    }

    /// @notice Get user address associated with an applicant ID (admin only)
    /// @param applicantId The Sumsub applicant ID
    /// @return The user address (address(0) if not found)
    function getUserByApplicantId(string calldata applicantId)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (address)
    {
        return applicantIdToUser[applicantId];
    }

    /// @notice Get user address associated with a registration number (admin only)
    /// @param registrationNumber The company registration number
    /// @return The user address (address(0) if not found)
    function getUserByRegistration(string calldata registrationNumber)
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (address)
    {
        return registrationToUser[registrationNumber];
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // PUBLIC VIEW FUNCTIONS (No sensitive data exposed)
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Check if a business has any verification record (public)
    /// @param user The address to check
    /// @return True if business has any verification record
    function hasVerificationRecord(address user) external view returns (bool) {
        return verifications[user].user != address(0);
    }

    /// @notice Check if a business has an approved verification (ready to mint)
    /// @param user The address to check
    /// @return True if business has approved verification
    function isApproved(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Approved;
    }

    /// @notice Check if a business has a minted verification
    /// @param user The address to check
    /// @return True if business has minted verification
    function isMinted(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Minted;
    }

    /// @notice Check if a business is verified (approved or minted)
    /// @param user The address to check
    /// @return True if business is verified
    function isVerified(address user) external view returns (bool) {
        VerificationStatus status = verifications[user].status;
        return status == VerificationStatus.Approved || status == VerificationStatus.Minted;
    }

    /// @notice Get verification status for a business (status only, no details)
    /// @param user The address to check
    /// @return The verification status
    function getStatus(address user) external view returns (VerificationStatus) {
        return verifications[user].status;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Allow business to resubmit after rejection (admin only)
    /// @param user The address of the business
    function resetVerification(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(
            record.status == VerificationStatus.Rejected,
            "Can only reset rejected verifications"
        );

        // Clear applicant ID mapping
        delete applicantIdToUser[record.sumsubApplicantId];
        // Clear registration mapping
        delete registrationToUser[record.companyRegistrationNumber];

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

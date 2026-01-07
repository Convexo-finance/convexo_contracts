// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ILimitedPartnersBusiness} from "../interfaces/ILimitedPartnersBusiness.sol";

/// @title SumsubVerifier
/// @notice Human-approved KYB verification system for BUSINESS Limited Partners
/// @dev For BUSINESSES only - uses Sumsub platform for KYB verification
///      Upon approval, mints Limited_Partners_Business NFT (Tier 2)
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// VERIFICATION FLOW:
/// ═══════════════════════════════════════════════════════════════════════════════
/// 1. Business completes Sumsub KYB verification on frontend
/// 2. Backend receives webhook with verification result and company details
/// 3. Backend calls submitVerification() with applicant and company details
/// 4. Admin reviews and calls approveVerification() or rejectVerification()
/// 5. On approval: Limited_Partners_Business NFT is minted
/// 6. Business becomes Limited Partner → Can access LP pools, Treasury, Invest
/// 7. Limited Partner can request Credit Score for Ecreditscoring NFT (Tier 3)
///
/// For INDIVIDUAL KYC, use VeriffVerifier instead
/// ═══════════════════════════════════════════════════════════════════════════════
contract SumsubVerifier is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice Verification status states
    enum VerificationStatus {
        None,       // 0 - No verification submitted
        Pending,    // 1 - Submitted, awaiting approval
        Approved,   // 2 - Approved and NFT minted
        Rejected    // 3 - Rejected by admin
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
    }

    /// @notice The Limited Partners Business NFT contract
    ILimitedPartnersBusiness public immutable lpBusiness;

    /// @notice Mapping from user address to verification record
    mapping(address => VerificationRecord) public verifications;

    /// @notice Mapping from Sumsub applicant ID to user address (prevent duplicates)
    mapping(string => address) public applicantIdToUser;

    /// @notice Mapping from company registration number to user address (prevent duplicates)
    mapping(string => address) public registrationToUser;

    /// @notice Emitted when a verification is submitted
    event VerificationSubmitted(
        address indexed user,
        string applicantId,
        string companyName,
        string registrationNumber,
        BusinessType businessType,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is approved
    event VerificationApproved(
        address indexed user,
        string applicantId,
        string companyName,
        uint256 nftTokenId,
        address indexed approver,
        uint256 timestamp
    );

    /// @notice Emitted when a verification is rejected
    event VerificationRejected(
        address indexed user,
        string applicantId,
        string companyName,
        string reason,
        address indexed rejector,
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
            nftTokenId: 0
        });

        applicantIdToUser[applicantId] = user;
        registrationToUser[registrationNumber] = user;

        emit VerificationSubmitted(
            user,
            applicantId,
            companyName,
            registrationNumber,
            businessType,
            block.timestamp
        );
    }

    /// @notice Approve a pending verification and mint Limited Partners Business NFT
    /// @param user The address of the business to approve
    function approveVerification(address user) external onlyRole(VERIFIER_ROLE) {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Pending, "No pending verification");

        // Mint Limited Partners Business NFT (Tier 2)
        uint256 tokenId = lpBusiness.safeMint(
            user,
            record.companyName,
            record.companyRegistrationNumber,
            record.jurisdiction,
            ILimitedPartnersBusiness.BusinessType(uint8(record.businessType)),
            record.sumsubApplicantId,
            "" // Empty URI, can be updated later
        );

        record.status = VerificationStatus.Approved;
        record.processedAt = block.timestamp;
        record.processor = msg.sender;
        record.nftTokenId = tokenId;

        emit VerificationApproved(
            user,
            record.sumsubApplicantId,
            record.companyName,
            tokenId,
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
            record.sumsubApplicantId,
            record.companyName,
            reason,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Get verification status for a business
    /// @param user The address to check
    /// @return The verification record
    function getVerificationStatus(address user)
        external
        view
        returns (VerificationRecord memory)
    {
        return verifications[user];
    }

    /// @notice Check if a business has an approved verification
    /// @param user The address to check
    /// @return True if business has approved verification
    function isVerified(address user) external view returns (bool) {
        return verifications[user].status == VerificationStatus.Approved;
    }

    /// @notice Check if an applicant ID has been used
    /// @param applicantId The Sumsub applicant ID to check
    /// @return True if applicant ID has been used
    function isApplicantIdUsed(string calldata applicantId) external view returns (bool) {
        return applicantIdToUser[applicantId] != address(0);
    }

    /// @notice Check if a company registration number has been used
    /// @param registrationNumber The registration number to check
    /// @return True if registration number has been used
    function isRegistrationUsed(string calldata registrationNumber) external view returns (bool) {
        return registrationToUser[registrationNumber] != address(0);
    }

    /// @notice Get user address associated with an applicant ID
    /// @param applicantId The Sumsub applicant ID
    /// @return The user address (address(0) if not found)
    function getUserByApplicantId(string calldata applicantId) external view returns (address) {
        return applicantIdToUser[applicantId];
    }

    /// @notice Get user address associated with a registration number
    /// @param registrationNumber The company registration number
    /// @return The user address (address(0) if not found)
    function getUserByRegistration(string calldata registrationNumber) external view returns (address) {
        return registrationToUser[registrationNumber];
    }

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

    /// @notice Get company details for a verified business
    /// @param user The address to check
    /// @return companyName The company name
    /// @return registrationNumber The registration number
    /// @return jurisdiction The jurisdiction
    /// @return businessType The business type
    function getCompanyDetails(address user)
        external
        view
        returns (
            string memory companyName,
            string memory registrationNumber,
            string memory jurisdiction,
            BusinessType businessType
        )
    {
        VerificationRecord storage record = verifications[user];
        require(record.status == VerificationStatus.Approved, "Not verified");
        return (
            record.companyName,
            record.companyRegistrationNumber,
            record.jurisdiction,
            record.businessType
        );
    }
}

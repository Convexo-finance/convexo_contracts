// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title Interface for SumsubVerifier
/// @notice Callback interface for NFT contracts to update verification status
/// @dev Used by Limited_Partners_Business to mark verifications as minted
interface ISumsubVerifier {
    /// @notice Verification status states
    enum VerificationStatus {
        None,       // 0 - No verification submitted
        Pending,    // 1 - Submitted, awaiting approval
        Approved,   // 2 - Approved but NFT not yet minted
        Rejected,   // 3 - Rejected by admin
        Minted      // 4 - Approved and NFT minted
    }

    /// @notice Business type for KYB
    enum BusinessType {
        Corporation,
        LLC,
        Partnership,
        SoleProprietor,
        Other
    }

    /// @notice Verification record for a business
    struct VerificationRecord {
        address user;
        string sumsubApplicantId;
        string companyName;
        string companyRegistrationNumber;
        string jurisdiction;
        BusinessType businessType;
        VerificationStatus status;
        uint256 submittedAt;
        uint256 processedAt;
        address processor;
        string rejectionReason;
        uint256 nftTokenId;
        uint256 mintedAt;
    }

    /// @notice Mark verification as minted (called by NFT contract after minting)
    /// @param user The user whose NFT was minted
    /// @param tokenId The minted token ID
    function markAsMinted(address user, uint256 tokenId) external;

    /// @notice Check if a business has an approved (ready to mint) verification
    /// @param user The address to check
    /// @return True if business has approved verification (status = Approved)
    function isApproved(address user) external view returns (bool);

    /// @notice Check if a business has a minted verification
    /// @param user The address to check
    /// @return True if business has minted verification (status = Minted)
    function isMinted(address user) external view returns (bool);

    /// @notice Check if a business has any verification record
    /// @param user The address to check
    /// @return True if business has any verification record
    function hasVerificationRecord(address user) external view returns (bool);
}

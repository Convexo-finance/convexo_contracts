// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title Interface for Limited Partners Business NFT
/// @notice Tier 2 NFT for businesses verified via Sumsub KYB
/// @dev Used by SumsubVerifier to mint NFTs after KYB approval
interface ILimitedPartnersBusiness {
    /// @notice Business type enum
    enum BusinessType {
        Corporation,
        LLC,
        Partnership,
        SoleProprietor,
        Other
    }

    /// @notice Returns the number of tokens owned by an address
    /// @param owner The address to query
    /// @return The number of tokens owned
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Returns the owner of a token
    /// @param tokenId The token ID to query
    /// @return The address of the token owner
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Returns the state of a token (true = Active, false = NonActive)
    /// @param tokenId The token ID to query
    /// @return True if the token is active
    function getTokenState(uint256 tokenId) external view returns (bool);

    /// @notice Get company name for a token
    /// @param tokenId Token ID to query
    /// @return The company name
    function getCompanyName(uint256 tokenId) external view returns (string memory);

    /// @notice Mint a new token
    /// @param to Address to mint to
    /// @param companyName Company name
    /// @param registrationNumber Registration number
    /// @param jurisdiction Jurisdiction
    /// @param businessType Business type
    /// @param sumsubApplicantId Sumsub applicant ID
    /// @param uri Token metadata URI
    /// @return tokenId The minted token ID
    function safeMint(
        address to,
        string memory companyName,
        string memory registrationNumber,
        string memory jurisdiction,
        BusinessType businessType,
        string memory sumsubApplicantId,
        string memory uri
    ) external returns (uint256);
}


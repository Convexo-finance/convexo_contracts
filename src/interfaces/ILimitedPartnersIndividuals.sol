// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title Interface for Limited Partners Individuals NFT
/// @notice Tier 2 NFT for individuals verified via Veriff
/// @dev Used by VeriffVerifier to mint NFTs after KYC approval
interface ILimitedPartnersIndividuals {
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

    /// @notice Mint a new token
    /// @param to Address to mint to
    /// @param verificationId Veriff session ID
    /// @param uri Token metadata URI
    /// @return tokenId The minted token ID
    function safeMint(address to, string memory verificationId, string memory uri) external returns (uint256);
}


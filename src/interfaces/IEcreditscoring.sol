// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title Interface for Ecreditscoring NFT
/// @notice Tier 3 NFT for vault creators with AI Credit Score
/// @dev Required for creating loan vaults and tokenized bonds
interface IEcreditscoring {
    /// @notice Credit tier enum
    enum CreditTier {
        None,       // 0 - Not scored
        Bronze,     // 1 - Basic credit
        Silver,     // 2 - Good credit
        Gold,       // 3 - Excellent credit
        Platinum    // 4 - Premium credit
    }

    /// @notice Credit information struct
    struct CreditInfo {
        CreditTier tier;
        uint256 score;          // 0-1000 scale
        uint256 maxLoanAmount;  // Maximum loan amount in USDC (6 decimals)
        uint256 scoredAt;       // Timestamp of scoring
        string referenceId;     // External reference ID
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

    /// @notice Check if user holds any LP NFT
    /// @param user Address to check
    /// @return True if user has LP status
    function hasLPStatus(address user) external view returns (bool);

    /// @notice Check if user can receive Ecreditscoring NFT
    /// @param user Address to check
    /// @return True if user holds any LP NFT
    function canReceiveEcreditscoringNFT(address user) external view returns (bool);

    /// @notice Get credit information for a token
    /// @param tokenId Token ID to query
    /// @return info The credit information
    function getCreditInfo(uint256 tokenId) external view returns (CreditInfo memory info);

    /// @notice Get credit tier for a token
    /// @param tokenId Token ID to query
    /// @return The credit tier
    function getCreditTier(uint256 tokenId) external view returns (CreditTier);

    /// @notice Get maximum loan amount for a token
    /// @param tokenId Token ID to query
    /// @return The maximum loan amount
    function getMaxLoanAmount(uint256 tokenId) external view returns (uint256);
}


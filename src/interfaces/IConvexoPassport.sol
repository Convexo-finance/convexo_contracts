// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ProofVerificationParams} from "./IZKPassportVerifier.sol";

/// @title IConvexoPassport
/// @notice Interface for Convexo_Passport NFT contract
/// @dev Soulbound NFT for individual investors verified via ZKPassport
interface IConvexoPassport {
    /// @notice Verified identity information stored for each passport holder
    struct VerifiedIdentity {
        bytes32 uniqueIdentifier;
        uint256 verifiedAt;
        bool isActive;
        string nationality;
    }

    /// @notice Emitted when a new passport is minted
    event PassportMinted(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier,
        string nationality
    );

    /// @notice Emitted when a passport is revoked
    event PassportRevoked(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier
    );

    /// @notice Self-mint a passport using ZKPassport verification
    /// @param params The ZKPassport proof parameters
    /// @param isIDCard Whether the proof is from an ID card
    /// @return tokenId The minted token ID
    function safeMintWithZKPassport(
        ProofVerificationParams calldata params,
        bool isIDCard
    ) external returns (uint256 tokenId);

    /// @notice Admin mint a passport (for testing or special cases)
    /// @param to The address to mint to
    /// @param uri The token URI
    /// @return tokenId The minted token ID
    function safeMint(address to, string memory uri) external returns (uint256 tokenId);

    /// @notice Revoke a passport
    /// @param tokenId The token ID to revoke
    function revokePassport(uint256 tokenId) external;

    /// @notice Check if an address holds an active passport
    /// @param holder The address to check
    /// @return hasPassport Whether the address holds an active passport
    function holdsActivePassport(address holder) external view returns (bool hasPassport);

    /// @notice Get verified identity information for an address
    /// @param holder The address to query
    /// @return identity The verified identity information
    function getVerifiedIdentity(address holder) external view returns (VerifiedIdentity memory identity);

    /// @notice Check if a unique identifier has been used
    /// @param uniqueIdentifier The identifier to check
    /// @return used Whether the identifier has been used
    function isIdentifierUsed(bytes32 uniqueIdentifier) external view returns (bool used);

    /// @notice Get the total number of active passports
    /// @return count The number of active passports
    function getActivePassportCount() external view returns (uint256 count);
}


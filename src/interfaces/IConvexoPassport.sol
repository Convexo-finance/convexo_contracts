// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ProofVerificationParams} from "./IZKPassportVerifier.sol";

/// @title IConvexoPassport
/// @notice Interface for Convexo_Passport NFT contract
/// @dev Soulbound NFT for individual investors verified via ZKPassport
///      Privacy-compliant: stores only verification results (traits), no PII
interface IConvexoPassport {
    /// @notice Verified identity information stored for each passport holder
    /// @dev Stores verification results as "traits" - no sensitive PII stored on-chain
    struct VerifiedIdentity {
        // Cryptographic identifiers (sybil resistance)
        bytes32 uniqueIdentifier;       // Hash of publicKey + scope
        bytes32 personhoodProof;        // Nullifier from ZKPassport
        // Timestamps
        uint256 verifiedAt;             // Contract verification timestamp
        uint256 zkPassportTimestamp;    // Original ZKPassport verification time
        // Status
        bool isActive;                  // Whether passport is currently active
        // ZKPassport verification results (boolean traits - no PII)
        bool kycVerified;               // Overall KYC verification passed
        bool faceMatchPassed;           // Face match verification result
        bool sanctionsPassed;           // Sanctions check result
        bool isOver18;                  // Age verification result
    }

    /// @notice Emitted when a new passport is minted
    /// @dev Privacy-compliant: emits only non-PII verification traits
    event PassportMinted(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 uniqueIdentifier,       // Cryptographic identifier (not PII)
        bytes32 personhoodProof,        // Nullifier (not PII)
        bool kycVerified,               // Verification trait
        bool faceMatchPassed,           // Verification trait
        bool sanctionsPassed,           // Verification trait
        bool isOver18                   // Verification trait
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

    /// @notice Self-mint a passport using unique identifier from ZKPassport (simplified)
    /// @param uniqueIdentifier The unique identifier from ZKPassport verification
    /// @return tokenId The minted token ID
    function safeMintWithIdentifier(bytes32 uniqueIdentifier) external returns (uint256 tokenId);

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


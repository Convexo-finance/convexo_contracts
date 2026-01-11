// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IConvexoPassport
/// @notice Interface for Convexo_Passport NFT contract
/// @dev Soulbound NFT for individual investors verified via ZKPassport
///      Privacy-compliant: stores only verification results (traits), no PII
interface IConvexoPassport {
    /// @notice Verified identity information stored for each passport holder
    /// @dev Stores verification results as "traits" - no sensitive PII stored on-chain
    struct VerifiedIdentity {
        // Cryptographic identifiers (sybil resistance)
        bytes32 identifierHash;         // keccak256 hash of uniqueIdentifier string from ZKPassport
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
        bytes32 identifierHash,         // keccak256 hash of uniqueIdentifier (not PII)
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
        bytes32 identifierHash
    );

    /// @notice Self-mint a passport using verification results (ONLY minting path)
    /// @param uniqueIdentifier String identifier directly from ZKPassport SDK (hashed internally)
    /// @param personhoodProof Nullifier from ZKPassport verification
    /// @param sanctionsPassed Whether sanctions check passed
    /// @param isOver18 Whether age verification (18+) passed
    /// @param faceMatchPassed Whether face match verification passed
    /// @param ipfsMetadataHash IPFS hash for the NFT metadata (tier-specific)
    /// @return tokenId The minted token ID
    /// @dev This is the ONLY way to mint a Convexo Passport.
    ///      Enforces: 1 human → 1 ZKPassport → 1 NFT → 1 wallet
    ///      The uniqueIdentifier string is hashed internally using keccak256
    function safeMintWithVerification(
        string calldata uniqueIdentifier,
        bytes32 personhoodProof,
        bool sanctionsPassed,
        bool isOver18,
        bool faceMatchPassed,
        string calldata ipfsMetadataHash
    ) external returns (uint256 tokenId);

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

    /// @notice Check if a unique identifier string has been used
    /// @param uniqueIdentifier The identifier string from ZKPassport SDK
    /// @return used Whether the identifier has been used
    /// @dev This is the SINGLE source of truth for sybil resistance
    ///      The string is hashed internally using keccak256
    function isIdentifierUsed(string calldata uniqueIdentifier) external view returns (bool used);

    /// @notice Get the total number of active passports
    /// @return count The number of active passports
    function getActivePassportCount() external view returns (uint256 count);
}


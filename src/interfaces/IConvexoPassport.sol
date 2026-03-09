// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ProofVerificationParams} from "./IZKPassportVerifier.sol";

/// @title IConvexoPassport
/// @notice Interface for Convexo_Passport NFT contract (v3.17 — trustless ZKPassport)
interface IConvexoPassport {
    /// @notice Verified identity stored for each passport holder
    /// @dev Privacy-compliant: boolean traits only, zero PII on-chain
    struct VerifiedIdentity {
        bytes32 identifierHash;      // uniqueIdentifier from ZKPassport verifier (Poseidon2 hash)
        bytes32 personhoodProof;     // vkeyHash from proof (circuit identifier)
        uint256 verifiedAt;          // block.timestamp at mint
        uint256 zkPassportTimestamp; // proof generation timestamp from getProofTimestamp()
        bool isActive;
        bool kycVerified;            // sanctionsPassed && isOver18
        bool sanctionsPassed;        // isSanctionsRootValid()
        bool isOver18;               // isAgeAboveOrEqual(18)
        bool nationalityCompliant;   // isNationalityOut(SANCTIONED_COUNTRIES)
    }

    /// @notice Emitted when a passport is minted
    event PassportMinted(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 identifierHash,
        bytes32 personhoodProof,
        bool kycVerified,
        bool sanctionsPassed,
        bool isOver18
    );

    /// @notice Emitted when a passport is revoked
    event PassportRevoked(
        address indexed holder,
        uint256 indexed tokenId,
        bytes32 identifierHash
    );

    /// @notice Self-claim a Convexo Passport by submitting a ZKPassport ZK proof
    /// @dev The ONLY minting path. No admin can mint on behalf of a user.
    ///      Proof is verified on-chain by the ZKPassport verifier contract.
    ///      msg.sender and block.chainid must be bound in the proof (anti-replay).
    /// @param zkParams Proof parameters from zkPassport.getSolidityVerifierParameters()
    /// @param isIDCard True if document is ID card, false if passport
    /// @param ipfsMetadataHash IPFS hash for the NFT metadata
    /// @return tokenId The minted token ID
    function claimPassport(
        ProofVerificationParams calldata zkParams,
        bool isIDCard,
        string calldata ipfsMetadataHash
    ) external returns (uint256 tokenId);

    /// @notice Revoke a passport (REVOKER_ROLE only)
    function revokePassport(uint256 tokenId) external;

    /// @notice Check if address holds an active passport
    function holdsActivePassport(address holder) external view returns (bool);

    /// @notice Get verified identity for an address
    function getVerifiedIdentity(address holder) external view returns (VerifiedIdentity memory);

    /// @notice Check if a uniqueIdentifier bytes32 has been used (sybil resistance)
    function isIdentifierUsed(bytes32 identifierHash) external view returns (bool);

    /// @notice Total active passports
    function getActivePassportCount() external view returns (uint256);
}

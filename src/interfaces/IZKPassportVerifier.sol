// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IZKPassportVerifier
/// @notice Interface for ZKPassport on-chain verifier
/// @dev Defines the structs and interface for interacting with ZKPassport verification system

/// @notice Parameters required for proof verification
struct ProofVerificationParams {
    bytes32 publicKey;
    bytes32 nullifier;
    bytes proof;
    uint256 attestationId;
    bytes32 scope;
    uint256 currentDate;
}

/// @notice Data that is cryptographically bound to the proof
struct BoundData {
    bytes32 publicKey;
    bytes32 scope;
}

/// @notice Verification results from ZKPassport (boolean traits only, no PII)
/// @dev Privacy-compliant: stores only verification status, not personal data
struct DisclosedData {
    // Verification results (boolean traits)
    bool kycVerified;           // Overall KYC verification passed
    bool faceMatchPassed;       // Face match verification result
    bool sanctionsPassed;       // Sanctions check result (US, UK, EU, Switzerland)
    bool isOver18;              // Age verification result
    // Timestamp
    uint256 verifiedAt;         // When ZKPassport verification occurred
}

/// @title IZKPassportVerifier
/// @notice Main verifier interface for ZKPassport proofs
interface IZKPassportVerifier {
    /// @notice Verify a ZKPassport proof
    /// @param params The proof verification parameters
    /// @param isIDCard Whether the proof is from an ID card (vs passport)
    /// @return success Whether the proof was successfully verified
    /// @return disclosedData The data disclosed in the proof
    function verifyProof(
        ProofVerificationParams calldata params,
        bool isIDCard
    ) external view returns (bool success, DisclosedData memory disclosedData);
}

/// @title IZKPassportHelper
/// @notice Helper interface for additional ZKPassport functionality
interface IZKPassportHelper {
    /// @notice Get the unique identifier for a proof
    /// @param params The proof parameters
    /// @return identifier The unique identifier (hash of public key + scope)
    function getUniqueIdentifier(
        ProofVerificationParams calldata params
    ) external pure returns (bytes32 identifier);
}

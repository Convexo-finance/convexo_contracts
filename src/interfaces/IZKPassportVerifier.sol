// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IZKPassportVerifier
/// @notice Official ZKPassport on-chain verifier interface
/// @dev Verifier deployed at 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8
///      on Ethereum Mainnet, Ethereum Sepolia, and Base Mainnet.
///      Source: https://docs.zkpassport.id/verification/onchain-verification

// ─── Structs ───────────────────────────────────────────────────────────────

/// @notice Proof parameters produced by zkPassport.getSolidityVerifierParameters()
struct ProofVerificationParams {
    bytes32 version;
    ProofVerificationData proofVerificationData;
    bytes committedInputs;
    ServiceConfig serviceConfig;
}

struct ProofVerificationData {
    bytes32 vkeyHash;
    bytes proof;
    bytes32[] publicInputs;
}

struct ServiceConfig {
    uint256 validityPeriodInSeconds;
    string domain;
    string scope;
    bool devMode;
}

/// @notice Data cryptographically bound to the proof (anti-replay + anti-impersonation)
struct BoundData {
    address senderAddress; // must equal msg.sender in claimPassport
    uint256 chainId;       // must equal block.chainid
    string customData;     // unused by Convexo — verified to be empty
}

/// @notice Data disclosed by the proof (no PII stored on-chain — only used transiently)
struct DisclosedData {
    string name;
    string issuingCountry;
    string nationality;
    string gender;
    string birthDate;
    string expiryDate;
    string documentNumber;
    string documentType;
}

enum FaceMatchMode { NONE, REGULAR, STRICT }
enum OS { ANY, IOS, ANDROID }

// ─── Interfaces ────────────────────────────────────────────────────────────

/// @notice Main ZKPassport verifier interface
interface IZKPassportVerifier {
    /// @notice Verify a ZKPassport ZK proof on-chain
    /// @param params Proof parameters from getSolidityVerifierParameters() in the SDK
    /// @return verified True if the proof is cryptographically valid
    /// @return uniqueIdentifier Poseidon2(ID_data + domain + scope) — sybil resistance key
    /// @return helper Helper contract for querying proven attributes
    function verify(ProofVerificationParams calldata params)
        external
        returns (bool verified, bytes32 uniqueIdentifier, IZKPassportHelper helper);
}

/// @notice Helper for extracting verified attributes from ZK proof inputs
/// @dev All functions are pure — no state reads, safe to call in view context
interface IZKPassportHelper {
    /// @notice Verify proof was generated for the given domain and scope
    function verifyScopes(
        bytes32[] calldata publicInputs,
        string calldata domain,
        string calldata scope
    ) external view returns (bool);

    /// @notice Decode bound data embedded in committedInputs
    function getBoundData(bytes calldata committedInputs)
        external view returns (BoundData memory);

    /// @notice Get data disclosed by the proof
    function getDisclosedData(bytes calldata committedInputs, bool isIDCard)
        external pure returns (DisclosedData memory);

    // ── Age ──────────────────────────────────────────────────────────────

    function isAgeAboveOrEqual(uint8 minAge, bytes calldata committedInputs) external view returns (bool);
    function isAgeAbove(uint8 minAge, bytes calldata committedInputs) external pure returns (bool);
    function isAgeBetween(uint8 minAge, uint8 maxAge, bytes calldata committedInputs) external pure returns (bool);
    function isAgeBelowOrEqual(uint8 maxAge, bytes calldata committedInputs) external pure returns (bool);
    function isAgeBelow(uint8 maxAge, bytes calldata committedInputs) external pure returns (bool);
    function isAgeEqual(uint8 age, bytes calldata committedInputs) external pure returns (bool);

    // ── Birthdate ─────────────────────────────────────────────────────────

    function isBirthdateAfterOrEqual(uint256 minDate, bytes calldata committedInputs) external pure returns (bool);
    function isBirthdateAfter(uint256 minDate, bytes calldata committedInputs) external pure returns (bool);
    function isBirthdateBetween(uint256 minDate, uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isBirthdateBeforeOrEqual(uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isBirthdateBefore(uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isBirthdateEqual(uint256 date, bytes calldata committedInputs) external pure returns (bool);

    // ── Expiry date ───────────────────────────────────────────────────────

    function isExpiryDateAfterOrEqual(uint256 minDate, bytes calldata committedInputs) external view returns (bool);
    function isExpiryDateAfter(uint256 minDate, bytes calldata committedInputs) external pure returns (bool);
    function isExpiryDateBetween(uint256 minDate, uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isExpiryDateBeforeOrEqual(uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isExpiryDateBefore(uint256 maxDate, bytes calldata committedInputs) external pure returns (bool);
    function isExpiryDateEqual(uint256 date, bytes calldata committedInputs) external pure returns (bool);

    // ── Nationality ───────────────────────────────────────────────────────

    /// @notice Country list MUST be sorted alphabetically
    function isNationalityIn(string[] memory countryList, bytes calldata committedInputs) external pure returns (bool);
    function isIssuingCountryIn(string[] memory countryList, bytes calldata committedInputs) external pure returns (bool);
    /// @notice Country list MUST be sorted alphabetically
    function isNationalityOut(string[] memory countryList, bytes calldata committedInputs) external view returns (bool);
    function isIssuingCountryOut(string[] memory countryList, bytes calldata committedInputs) external pure returns (bool);

    // ── Sanctions ─────────────────────────────────────────────────────────

    /// @notice Validate sanctions root against US/UK/EU/CH sanction lists
    /// @param currentTimestamp Use proof timestamp (getProofTimestamp), not block.timestamp
    function isSanctionsRootValid(uint256 currentTimestamp, bool isStrict, bytes calldata committedInputs)
        external view returns (bool);

    function enforceSanctionsRoot(uint256 currentTimestamp, bool isStrict, bytes calldata committedInputs)
        external view;

    // ── Face match ────────────────────────────────────────────────────────

    function isFaceMatchVerified(FaceMatchMode faceMatchMode, OS os, bytes calldata committedInputs)
        external pure returns (bool);

    // ── Timestamp ─────────────────────────────────────────────────────────

    /// @notice Extract proof generation timestamp from public inputs
    function getProofTimestamp(bytes32[] calldata publicInputs) external view returns (uint256);
}

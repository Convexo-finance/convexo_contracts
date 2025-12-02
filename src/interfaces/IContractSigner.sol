// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IContractSigner
/// @notice Interface for ContractSigner to allow vaults to verify contract status
interface IContractSigner {
    /// @notice Agreement types supported by the system
    enum AgreementType {
        Loan,
        Credit,
        InvoiceFactoring,
        TokenizedBondCredits
    }

    /// @notice Contract document metadata
    struct ContractDocument {
        bytes32 documentHash;
        AgreementType agreementType;
        address initiator;
        uint256 createdAt;
        uint256 expiresAt;
        bool isExecuted;
        bool isCancelled;
        string ipfsHash;
        uint256 nftReputationTier;
        uint256 vaultId;
    }

    /// @notice Get contract document by hash
    /// @param documentHash The hash of the contract document
    /// @return The contract document
    function getContract(bytes32 documentHash) external view returns (ContractDocument memory);

    /// @notice Get the number of signatures for a contract
    /// @param documentHash The hash of the contract document
    /// @return The number of signatures
    function getSignatureCount(bytes32 documentHash) external view returns (uint256);

    /// @notice Get the list of required signers for a contract
    /// @param documentHash The hash of the contract document
    /// @return The array of required signer addresses
    function getRequiredSigners(bytes32 documentHash) external view returns (address[] memory);

    /// @notice Check if an address has signed a contract
    /// @param documentHash The hash of the contract document
    /// @param signer The address to check
    /// @return True if the address has signed
    function hasSigned(bytes32 documentHash, address signer) external view returns (bool);
}


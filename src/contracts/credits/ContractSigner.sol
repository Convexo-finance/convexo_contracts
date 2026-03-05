// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title ContractSigner
/// @notice Manages on-chain contract signing with document hashes stored on-chain
/// @dev Stores document hashes and signatures, with full documents stored off-chain (IPFS/Supabase)
contract ContractSigner is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice Agreement types supported by the system
    enum AgreementType {
        Loan,
        Credit,
        InvoiceFactoring,
        TokenizedBondCredits
    }

    /// @notice Signature information
    struct Signature {
        address signer;
        bytes signature;
        uint256 timestamp;
        bool isValid;
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
        string ipfsHash; // IPFS CID for off-chain document
        uint256 nftReputationTier; // 0, 1, or 2
        uint256 vaultId; // Linked vault ID (0 if not created yet)
    }

    /// @notice Mapping from document hash to contract document
    mapping(bytes32 => ContractDocument) public contracts;

    /// @notice Mapping from document hash to array of signatures
    mapping(bytes32 => Signature[]) public signatures;

    /// @notice Mapping from document hash to required signers
    mapping(bytes32 => address[]) public requiredSigners;

    /// @notice Mapping to check if an address has signed a document
    mapping(bytes32 => mapping(address => bool)) public hasSigned;

    /// @notice Array of all document hashes for enumeration
    bytes32[] public documentHashes;

    /// @notice Mapping to check if a document exists
    mapping(bytes32 => bool) public documentExists;

    /// @notice Emitted when a new contract is created
    event ContractCreated(
        bytes32 indexed documentHash,
        address indexed initiator,
        AgreementType agreementType,
        string ipfsHash,
        uint256 nftReputationTier
    );

    /// @notice Emitted when a contract is signed
    event ContractSigned(
        bytes32 indexed documentHash, address indexed signer, uint256 timestamp, uint256 signatureCount
    );

    /// @notice Emitted when a contract is executed
    event ContractExecuted(bytes32 indexed documentHash, uint256 vaultId);

    /// @notice Emitted when a contract is cancelled
    event ContractCancelled(bytes32 indexed documentHash, address indexed canceller);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
    }

    /// @notice Create a new contract for signing
    /// @param documentHash The hash of the contract document
    /// @param agreementType The type of agreement
    /// @param requiredSignersList The list of addresses that must sign
    /// @param ipfsHash The IPFS CID of the full document
    /// @param nftReputationTier The reputation tier of the initiator (0, 1, or 2)
    /// @param expiryDuration The duration in seconds before the contract expires
    function createContract(
        bytes32 documentHash,
        AgreementType agreementType,
        address[] memory requiredSignersList,
        string memory ipfsHash,
        uint256 nftReputationTier,
        uint256 expiryDuration
    ) external {
        require(!documentExists[documentHash], "Contract already exists");
        require(requiredSignersList.length > 0, "Must have at least one required signer");
        require(nftReputationTier <= 2, "Invalid reputation tier");
        require(bytes(ipfsHash).length > 0, "IPFS hash required");

        contracts[documentHash] = ContractDocument({
            documentHash: documentHash,
            agreementType: agreementType,
            initiator: msg.sender,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + expiryDuration,
            isExecuted: false,
            isCancelled: false,
            ipfsHash: ipfsHash,
            nftReputationTier: nftReputationTier,
            vaultId: 0
        });

        requiredSigners[documentHash] = requiredSignersList;
        documentHashes.push(documentHash);
        documentExists[documentHash] = true;

        emit ContractCreated(documentHash, msg.sender, agreementType, ipfsHash, nftReputationTier);
    }

    /// @notice Sign a contract
    /// @param documentHash The hash of the contract to sign
    /// @param signature The ECDSA signature of the document hash
    function signContract(bytes32 documentHash, bytes memory signature) external {
        require(documentExists[documentHash], "Contract does not exist");
        require(!contracts[documentHash].isExecuted, "Contract already executed");
        require(!contracts[documentHash].isCancelled, "Contract cancelled");
        require(block.timestamp <= contracts[documentHash].expiresAt, "Contract expired");
        require(!hasSigned[documentHash][msg.sender], "Already signed");

        // Verify that msg.sender is in the required signers list
        bool isRequiredSigner = false;
        address[] memory signers = requiredSigners[documentHash];
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == msg.sender) {
                isRequiredSigner = true;
                break;
            }
        }
        require(isRequiredSigner, "Not a required signer");

        // Verify the signature
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(documentHash);
        address recoveredSigner = ECDSA.recover(ethSignedHash, signature);
        require(recoveredSigner == msg.sender, "Invalid signature");

        // Store the signature
        signatures[documentHash].push(
            Signature({signer: msg.sender, signature: signature, timestamp: block.timestamp, isValid: true})
        );

        hasSigned[documentHash][msg.sender] = true;

        emit ContractSigned(documentHash, msg.sender, block.timestamp, signatures[documentHash].length);
    }

    /// @notice Execute a contract after all required signatures are collected
    /// @param documentHash The hash of the contract to execute
    /// @param vaultId The ID of the created vault (set by VaultFactory)
    function executeContract(bytes32 documentHash, uint256 vaultId) external onlyRole(VERIFIER_ROLE) {
        require(documentExists[documentHash], "Contract does not exist");
        require(!contracts[documentHash].isExecuted, "Contract already executed");
        require(!contracts[documentHash].isCancelled, "Contract cancelled");
        require(isFullySigned(documentHash), "Not all parties have signed");

        contracts[documentHash].isExecuted = true;
        contracts[documentHash].vaultId = vaultId;

        emit ContractExecuted(documentHash, vaultId);
    }

    /// @notice Cancel a contract
    /// @param documentHash The hash of the contract to cancel
    function cancelContract(bytes32 documentHash) external {
        require(documentExists[documentHash], "Contract does not exist");
        require(!contracts[documentHash].isExecuted, "Contract already executed");
        require(
            msg.sender == contracts[documentHash].initiator || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not authorized to cancel"
        );

        contracts[documentHash].isCancelled = true;

        emit ContractCancelled(documentHash, msg.sender);
    }

    /// @notice Check if a contract is fully signed
    /// @param documentHash The hash of the contract to check
    /// @return True if all required signers have signed
    function isFullySigned(bytes32 documentHash) public view returns (bool) {
        require(documentExists[documentHash], "Contract does not exist");

        address[] memory signers = requiredSigners[documentHash];
        for (uint256 i = 0; i < signers.length; i++) {
            if (!hasSigned[documentHash][signers[i]]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Get contract information
    /// @param documentHash The hash of the contract
    /// @return Contract document struct
    function getContract(bytes32 documentHash) external view returns (ContractDocument memory) {
        require(documentExists[documentHash], "Contract does not exist");
        return contracts[documentHash];
    }

    /// @notice Get all signatures for a contract
    /// @param documentHash The hash of the contract
    /// @return Array of signatures
    function getSignatures(bytes32 documentHash) external view returns (Signature[] memory) {
        require(documentExists[documentHash], "Contract does not exist");
        return signatures[documentHash];
    }

    /// @notice Get required signers for a contract
    /// @param documentHash The hash of the contract
    /// @return Array of required signer addresses
    function getRequiredSigners(bytes32 documentHash) external view returns (address[] memory) {
        require(documentExists[documentHash], "Contract does not exist");
        return requiredSigners[documentHash];
    }

    /// @notice Get total number of contracts
    /// @return The number of contracts
    function getContractCount() external view returns (uint256) {
        return documentHashes.length;
    }

    /// @notice Get document hash at a specific index
    /// @param index The index to query
    /// @return The document hash at that index
    function getDocumentHashAtIndex(uint256 index) external view returns (bytes32) {
        require(index < documentHashes.length, "Index out of bounds");
        return documentHashes[index];
    }
}

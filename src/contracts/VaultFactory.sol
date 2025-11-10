// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TokenizedBondVault} from "./TokenizedBondVault.sol";
import {ContractSigner} from "./ContractSigner.sol";

/// @title VaultFactory
/// @notice Factory contract for creating TokenizedBondVault instances
/// @dev Triggers vault creation after successful contract signing
contract VaultFactory is AccessControl {
    bytes32 public constant VAULT_CREATOR_ROLE = keccak256("VAULT_CREATOR_ROLE");

    /// @notice Counter for vault IDs
    uint256 private _nextVaultId;

    /// @notice USDC token address
    address public immutable usdc;

    /// @notice Protocol fee collector
    address public protocolFeeCollector;

    /// @notice Contract signer reference
    ContractSigner public immutable contractSigner;

    /// @notice Mapping from vault ID to vault address
    mapping(uint256 => address) public vaults;

    /// @notice Mapping from contract hash to vault ID
    mapping(bytes32 => uint256) public contractHashToVaultId;

    /// @notice Array of all vault addresses
    address[] public vaultAddresses;

    /// @notice Emitted when a vault is created
    event VaultCreated(
        uint256 indexed vaultId,
        address indexed vaultAddress,
        address indexed borrower,
        bytes32 contractHash,
        uint256 principalAmount
    );

    /// @notice Emitted when protocol fee collector is updated
    event ProtocolFeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);

    constructor(address admin, address _usdc, address _protocolFeeCollector, ContractSigner _contractSigner) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CREATOR_ROLE, admin);
        usdc = _usdc;
        protocolFeeCollector = _protocolFeeCollector;
        contractSigner = _contractSigner;
    }

    /// @notice Create a new vault after contract signing
    /// @param borrower The address of the borrower
    /// @param contractHash The hash of the signed contract
    /// @param principalAmount The principal amount in USDC
    /// @param interestRate The interest rate in basis points (e.g., 1200 = 12%)
    /// @param protocolFeeRate The protocol fee rate in basis points (e.g., 200 = 2%)
    /// @param maturityDate The maturity date timestamp
    /// @param name The name of the vault token
    /// @param symbol The symbol of the vault token
    /// @return vaultId The ID of the created vault
    /// @return vaultAddress The address of the created vault
    function createVault(
        address borrower,
        bytes32 contractHash,
        uint256 principalAmount,
        uint256 interestRate,
        uint256 protocolFeeRate,
        uint256 maturityDate,
        string memory name,
        string memory symbol
    ) external onlyRole(VAULT_CREATOR_ROLE) returns (uint256 vaultId, address vaultAddress) {
        require(borrower != address(0), "Invalid borrower address");
        require(principalAmount > 0, "Principal amount must be greater than 0");
        require(maturityDate > block.timestamp, "Maturity date must be in the future");
        require(contractHashToVaultId[contractHash] == 0, "Vault already exists for this contract");

        // Verify contract is fully signed and executed
        ContractSigner.ContractDocument memory contractDoc = contractSigner.getContract(contractHash);
        require(contractDoc.isExecuted, "Contract not executed");
        require(!contractDoc.isCancelled, "Contract cancelled");

        vaultId = _nextVaultId++;

        // Deploy new vault
        TokenizedBondVault vault = new TokenizedBondVault(
            vaultId,
            borrower,
            contractHash,
            principalAmount,
            interestRate,
            protocolFeeRate,
            maturityDate,
            usdc,
            msg.sender, // Admin
            protocolFeeCollector,
            name,
            symbol
        );

        vaultAddress = address(vault);
        vaults[vaultId] = vaultAddress;
        contractHashToVaultId[contractHash] = vaultId;
        vaultAddresses.push(vaultAddress);

        // Execute contract in ContractSigner
        contractSigner.executeContract(contractHash, vaultId);

        emit VaultCreated(vaultId, vaultAddress, borrower, contractHash, principalAmount);

        return (vaultId, vaultAddress);
    }

    /// @notice Update protocol fee collector
    /// @param newCollector The new protocol fee collector address
    function updateProtocolFeeCollector(address newCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newCollector != address(0), "Invalid collector address");
        address oldCollector = protocolFeeCollector;
        protocolFeeCollector = newCollector;
        emit ProtocolFeeCollectorUpdated(oldCollector, newCollector);
    }

    /// @notice Get vault address by vault ID
    /// @param vaultId The vault ID
    /// @return The vault address
    function getVault(uint256 vaultId) external view returns (address) {
        require(vaultId < _nextVaultId, "Vault does not exist");
        return vaults[vaultId];
    }

    /// @notice Get vault address by contract hash
    /// @param contractHash The contract hash
    /// @return The vault address
    function getVaultByContractHash(bytes32 contractHash) external view returns (address) {
        uint256 vaultId = contractHashToVaultId[contractHash];
        require(vaultId != 0 || contractHashToVaultId[contractHash] == 0, "Vault not found");
        return vaults[vaultId];
    }

    /// @notice Get total number of vaults
    /// @return The number of vaults
    function getVaultCount() external view returns (uint256) {
        return _nextVaultId;
    }

    /// @notice Get vault address at a specific index
    /// @param index The index to query
    /// @return The vault address at that index
    function getVaultAddressAtIndex(uint256 index) external view returns (address) {
        require(index < vaultAddresses.length, "Index out of bounds");
        return vaultAddresses[index];
    }

    /// @notice Check if a vault exists for a contract hash
    /// @param contractHash The contract hash
    /// @return True if vault exists
    function vaultExistsForContract(bytes32 contractHash) external view returns (bool) {
        return contractHashToVaultId[contractHash] != 0;
    }
}

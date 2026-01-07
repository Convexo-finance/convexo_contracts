// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TokenizedBondVault} from "./TokenizedBondVault.sol";
import {ContractSigner} from "./ContractSigner.sol";
import {ReputationManager} from "./ReputationManager.sol";

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

    /// @notice Reputation manager reference
    ReputationManager public immutable reputationManager;

    /// @notice Mapping from vault ID to vault address
    mapping(uint256 => address) public vaults;

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

    constructor(
        address admin,
        address _usdc,
        address _protocolFeeCollector,
        ContractSigner _contractSigner,
        ReputationManager _reputationManager
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CREATOR_ROLE, admin);
        usdc = _usdc;
        protocolFeeCollector = _protocolFeeCollector;
        contractSigner = _contractSigner;
        reputationManager = _reputationManager;
    }

    /// @notice Create a new vault (borrower must have Tier 3 NFT)
    /// @param principalAmount The principal amount in USDC
    /// @param interestRate The interest rate in basis points (e.g., 1200 = 12%)
    /// @param protocolFeeRate The protocol fee rate in basis points (e.g., 200 = 2%)
    /// @param maturityDate The maturity date timestamp
    /// @param name The name of the vault token
    /// @param symbol The symbol of the vault token
    /// @return vaultId The ID of the created vault
    /// @return vaultAddress The address of the created vault
    function createVault(
        uint256 principalAmount,
        uint256 interestRate,
        uint256 protocolFeeRate,
        uint256 maturityDate,
        string memory name,
        string memory symbol
    ) external returns (uint256 vaultId, address vaultAddress) {
        // Verify borrower has Tier 3 NFT (VaultCreator)
        require(
            reputationManager.canCreateVaults(msg.sender),
            "Must have Tier 3 NFT (Convexo_Vaults)"
        );
        require(principalAmount > 0, "Principal amount must be greater than 0");
        require(maturityDate > block.timestamp, "Maturity date must be in the future");
        require(interestRate > 0 && interestRate <= 10000, "Invalid interest rate");
        require(protocolFeeRate <= 1000, "Protocol fee too high");

        vaultId = _nextVaultId++;

        // Deploy new vault without contract hash (will be attached later)
        TokenizedBondVault vault = new TokenizedBondVault(
            vaultId,
            msg.sender, // Borrower is the caller
            bytes32(0), // No contract hash yet
            principalAmount,
            interestRate,
            protocolFeeRate,
            maturityDate,
            usdc,
            address(contractSigner),
            msg.sender, // Borrower gets admin role initially
            protocolFeeCollector,
            reputationManager,
            name,
            symbol
        );

        vaultAddress = address(vault);
        vaults[vaultId] = vaultAddress;
        vaultAddresses.push(vaultAddress);

        emit VaultCreated(vaultId, vaultAddress, msg.sender, bytes32(0), principalAmount);

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
}

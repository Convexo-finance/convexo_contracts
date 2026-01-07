// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TreasuryVault} from "./TreasuryVault.sol";
import {ReputationManager} from "./ReputationManager.sol";

/// @title TreasuryFactory
/// @notice Factory contract for creating TreasuryVault instances
/// @dev Requires Tier 1+ (Passport or higher) to create treasuries
contract TreasuryFactory {
    /// @notice USDC token address
    address public immutable usdc;

    /// @notice Reputation manager reference
    ReputationManager public immutable reputationManager;

    /// @notice Counter for treasury IDs
    uint256 private _nextTreasuryId;

    /// @notice Mapping from treasury ID to treasury address
    mapping(uint256 => address) public treasuries;

    /// @notice Mapping from owner address to treasury IDs
    mapping(address => uint256[]) public treasuriesByOwner;

    /// @notice Array of all treasury addresses
    address[] public treasuryAddresses;

    /// @notice Emitted when a treasury is created
    event TreasuryCreated(
        uint256 indexed treasuryId,
        address indexed treasuryAddress,
        address indexed owner,
        uint256 signaturesRequired,
        uint256 signerCount
    );

    constructor(address _usdc, ReputationManager _reputationManager) {
        require(_usdc != address(0), "Invalid USDC address");
        require(address(_reputationManager) != address(0), "Invalid reputation manager");
        usdc = _usdc;
        reputationManager = _reputationManager;
    }

    /// @notice Create a new treasury (requires Tier 1+)
    /// @param signers Array of authorized signers (empty for single-sig)
    /// @param signaturesRequired Number of signatures required for withdrawals
    /// @return treasuryId The ID of the created treasury
    /// @return treasuryAddress The address of the created treasury
    function createTreasury(
        address[] memory signers,
        uint256 signaturesRequired
    ) external returns (uint256 treasuryId, address treasuryAddress) {
        // Verify user has Tier 1+ (Passport or higher)
        require(
            reputationManager.canCreateTreasury(msg.sender),
            "Must have Tier 1+ (Convexo_Passport or higher)"
        );

        treasuryId = _nextTreasuryId++;

        // Deploy new treasury
        TreasuryVault treasury = new TreasuryVault(
            msg.sender,
            usdc,
            signers,
            signaturesRequired
        );

        treasuryAddress = address(treasury);
        treasuries[treasuryId] = treasuryAddress;
        treasuriesByOwner[msg.sender].push(treasuryId);
        treasuryAddresses.push(treasuryAddress);

        emit TreasuryCreated(
            treasuryId,
            treasuryAddress,
            msg.sender,
            signaturesRequired,
            signers.length > 0 ? signers.length : 1
        );

        return (treasuryId, treasuryAddress);
    }

    /// @notice Get treasury address by treasury ID
    /// @param treasuryId The treasury ID
    /// @return The treasury address
    function getTreasury(uint256 treasuryId) external view returns (address) {
        require(treasuryId < _nextTreasuryId, "Treasury does not exist");
        return treasuries[treasuryId];
    }

    /// @notice Get total number of treasuries
    /// @return The number of treasuries
    function getTreasuryCount() external view returns (uint256) {
        return _nextTreasuryId;
    }

    /// @notice Get treasury address at a specific index
    /// @param index The index to query
    /// @return The treasury address at that index
    function getTreasuryAddressAtIndex(uint256 index) external view returns (address) {
        require(index < treasuryAddresses.length, "Index out of bounds");
        return treasuryAddresses[index];
    }

    /// @notice Get all treasury IDs owned by an address
    /// @param owner The owner address
    /// @return Array of treasury IDs
    function getTreasuriesByOwner(address owner) external view returns (uint256[] memory) {
        return treasuriesByOwner[owner];
    }

    /// @notice Get the number of treasuries owned by an address
    /// @param owner The owner address
    /// @return The count of treasuries
    function getTreasuryCountByOwner(address owner) external view returns (uint256) {
        return treasuriesByOwner[owner].length;
    }
}

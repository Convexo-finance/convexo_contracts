// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title PoolRegistry
/// @notice Tracks Uniswap V4 pools that are gated by CompliantLPHook
/// @dev Admin can register and manage pool associations with hooks
contract PoolRegistry is AccessControl {
    bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");

    /// @notice Pool information structure
    struct PoolInfo {
        address poolAddress;
        address token0;
        address token1;
        address hookAddress;
        bool isActive;
        string description;
    }

    /// @notice Mapping of pool ID to pool information
    mapping(bytes32 => PoolInfo) public pools;

    /// @notice Array of all pool IDs for enumeration
    bytes32[] public poolIds;

    /// @notice Mapping to check if a pool exists
    mapping(bytes32 => bool) public poolExists;

    /// @notice Emitted when a pool is registered
    event PoolRegistered(
        bytes32 indexed poolId,
        address indexed poolAddress,
        address indexed hookAddress,
        address token0,
        address token1,
        string description
    );

    /// @notice Emitted when a pool is updated
    event PoolUpdated(bytes32 indexed poolId, bool isActive);

    /// @notice Emitted when a pool is removed
    event PoolRemoved(bytes32 indexed poolId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(POOL_MANAGER_ROLE, admin);
    }

    /// @notice Register a new pool
    /// @param poolAddress The Uniswap V4 pool address
    /// @param token0 The first token in the pool
    /// @param token1 The second token in the pool
    /// @param hookAddress The CompliantLPHook address for this pool
    /// @param description A description of the pool (e.g., "USDC/ECOP")
    /// @return poolId The generated pool ID
    function registerPool(
        address poolAddress,
        address token0,
        address token1,
        address hookAddress,
        string memory description
    ) external onlyRole(POOL_MANAGER_ROLE) returns (bytes32 poolId) {
        require(poolAddress != address(0), "Invalid pool address");
        require(token0 != address(0), "Invalid token0 address");
        require(token1 != address(0), "Invalid token1 address");
        require(hookAddress != address(0), "Invalid hook address");

        poolId = keccak256(abi.encodePacked(poolAddress, token0, token1));
        require(!poolExists[poolId], "Pool already registered");

        pools[poolId] = PoolInfo({
            poolAddress: poolAddress,
            token0: token0,
            token1: token1,
            hookAddress: hookAddress,
            isActive: true,
            description: description
        });

        poolIds.push(poolId);
        poolExists[poolId] = true;

        emit PoolRegistered(poolId, poolAddress, hookAddress, token0, token1, description);
    }

    /// @notice Update pool active status
    /// @param poolId The pool ID to update
    /// @param isActive The new active status
    function updatePoolStatus(bytes32 poolId, bool isActive) external onlyRole(POOL_MANAGER_ROLE) {
        require(poolExists[poolId], "Pool not found");
        pools[poolId].isActive = isActive;
        emit PoolUpdated(poolId, isActive);
    }

    /// @notice Remove a pool from the registry
    /// @param poolId The pool ID to remove
    function removePool(bytes32 poolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(poolExists[poolId], "Pool not found");

        // Remove from mapping
        delete pools[poolId];
        delete poolExists[poolId];

        // Remove from array (by finding and swapping with last element)
        for (uint256 i = 0; i < poolIds.length; i++) {
            if (poolIds[i] == poolId) {
                poolIds[i] = poolIds[poolIds.length - 1];
                poolIds.pop();
                break;
            }
        }

        emit PoolRemoved(poolId);
    }

    /// @notice Get pool information
    /// @param poolId The pool ID to query
    /// @return Pool information struct
    function getPool(bytes32 poolId) external view returns (PoolInfo memory) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId];
    }

    /// @notice Get total number of registered pools
    /// @return The number of pools
    function getPoolCount() external view returns (uint256) {
        return poolIds.length;
    }

    /// @notice Get pool ID at a specific index
    /// @param index The index to query
    /// @return The pool ID at that index
    function getPoolIdAtIndex(uint256 index) external view returns (bytes32) {
        require(index < poolIds.length, "Index out of bounds");
        return poolIds[index];
    }

    /// @notice Check if a pool is active
    /// @param poolId The pool ID to check
    /// @return True if pool is active, false otherwise
    function isPoolActive(bytes32 poolId) external view returns (bool) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId].isActive;
    }

    /// @notice Get hook address for a pool
    /// @param poolId The pool ID to query
    /// @return The hook address
    function getHookAddress(bytes32 poolId) external view returns (address) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId].hookAddress;
    }
}


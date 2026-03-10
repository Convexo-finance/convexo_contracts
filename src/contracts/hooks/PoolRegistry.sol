// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";

/// @title PoolRegistry
/// @notice Tracks Uniswap V4 pools gated by PassportGatedHook.
///
/// In Uniswap V4, pools do NOT have their own contract addresses — they live as
/// state inside the PoolManager, uniquely identified by PoolId (keccak256 of the
/// full PoolKey: currency0, currency1, fee, tickSpacing, hooks).
/// We use PoolId as the canonical pool identifier here.
contract PoolRegistry is AccessControl {
    using PoolIdLibrary for PoolKey;

    bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");

    struct PoolInfo {
        PoolKey key;        // Full V4 PoolKey (source of truth for the pool ID)
        address hook;       // Hook address (mirrors key.hooks for quick reads)
        bool isActive;
        string description;
    }

    mapping(PoolId => PoolInfo) public pools;
    PoolId[] public poolIds;
    mapping(PoolId => bool) public poolExists;

    event PoolRegistered(PoolId indexed poolId, address indexed hook, string description);
    event PoolStatusUpdated(PoolId indexed poolId, bool isActive);
    event PoolRemoved(PoolId indexed poolId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(POOL_MANAGER_ROLE, admin);
    }

    /// @notice Register a pool using its full PoolKey.
    /// @param key         The Uniswap V4 PoolKey (must match the initialized pool exactly)
    /// @param description Human-readable label, e.g. "USDC/ECOP 0.3%"
    /// @return poolId     The canonical PoolId (keccak256 of the PoolKey)
    function registerPool(PoolKey calldata key, string calldata description)
        external
        onlyRole(POOL_MANAGER_ROLE)
        returns (PoolId poolId)
    {
        require(address(key.hooks) != address(0), "Pool must have a hook");

        poolId = key.toId();
        require(!poolExists[poolId], "Pool already registered");

        pools[poolId] = PoolInfo({
            key: key,
            hook: address(key.hooks),
            isActive: true,
            description: description
        });
        poolIds.push(poolId);
        poolExists[poolId] = true;

        emit PoolRegistered(poolId, address(key.hooks), description);
    }

    /// @notice Toggle a pool's active status.
    function updatePoolStatus(PoolId poolId, bool isActive) external onlyRole(POOL_MANAGER_ROLE) {
        require(poolExists[poolId], "Pool not found");
        pools[poolId].isActive = isActive;
        emit PoolStatusUpdated(poolId, isActive);
    }

    /// @notice Remove a pool from the registry (admin only).
    function removePool(PoolId poolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(poolExists[poolId], "Pool not found");

        delete pools[poolId];
        delete poolExists[poolId];

        uint256 len = poolIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (PoolId.unwrap(poolIds[i]) == PoolId.unwrap(poolId)) {
                poolIds[i] = poolIds[len - 1];
                poolIds.pop();
                break;
            }
        }

        emit PoolRemoved(poolId);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    function getPool(PoolId poolId) external view returns (PoolInfo memory) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId];
    }

    function getPoolCount() external view returns (uint256) {
        return poolIds.length;
    }

    function getPoolIdAtIndex(uint256 index) external view returns (PoolId) {
        require(index < poolIds.length, "Index out of bounds");
        return poolIds[index];
    }

    function isPoolActive(PoolId poolId) external view returns (bool) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId].isActive;
    }

    function getHookAddress(PoolId poolId) external view returns (address) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId].hook;
    }
}

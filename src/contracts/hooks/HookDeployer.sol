// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {PassportGatedHook} from "./PassportGatedHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";

/// @title HookDeployer
/// @notice Deploys PassportGatedHook via CREATE2 for a deterministic address.
///
/// Uniswap V4 encodes hook permissions in the bottom 14 bits of the hook address.
/// PassportGatedHook requires: beforeAddLiquidity (bit 11), beforeRemoveLiquidity (bit 9), beforeSwap (bit 7).
/// Required bit pattern: 0b_00_1010_1000_0000 = 0xA80
///
/// Workflow:
///   1. Call findSalt() off-chain to get a salt that produces the correct address.
///   2. Call deploy() with that salt to deploy at the validated address.
contract HookDeployer {
    event PassportGatedHookDeployed(
        address indexed hook,
        address indexed poolManager,
        address indexed reputationManager,
        bytes32 salt
    );

    // Required bits: beforeAddLiquidity (11), beforeRemoveLiquidity (9), beforeSwap (7)
    uint160 private constant REQUIRED_MASK =
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG;

    // All other hook bits must be zero
    uint160 private constant FORBIDDEN_MASK = uint160((1 << 14) - 1) & ~REQUIRED_MASK;

    /// @notice Deploy a PassportGatedHook with CREATE2.
    /// @param poolManager       Uniswap V4 PoolManager address
    /// @param reputationManager Convexo ReputationManager address
    /// @param admin             Admin for router allowlisting
    /// @param salt              CREATE2 salt (find with findSalt())
    /// @return hook             Deployed hook address
    function deploy(IPoolManager poolManager, ReputationManager reputationManager, address admin, bytes32 salt)
        external
        returns (PassportGatedHook hook)
    {
        hook = new PassportGatedHook{salt: salt}(poolManager, reputationManager, admin);
        emit PassportGatedHookDeployed(address(hook), address(poolManager), address(reputationManager), salt);
    }

    /// @notice Predict the address of a PassportGatedHook before deployment.
    function computeAddress(IPoolManager poolManager, ReputationManager reputationManager, address admin, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(PassportGatedHook).creationCode,
                abi.encode(poolManager, reputationManager, admin)
            )
        );
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /// @notice Find a salt whose CREATE2 address has the correct permission bits.
    /// @param poolManager       Uniswap V4 PoolManager address
    /// @param reputationManager Convexo ReputationManager address
    /// @param admin             Admin address (affects bytecode hash)
    /// @param startingSalt      Starting point for iteration
    /// @param maxIterations     Maximum salts to try before reverting
    /// @return salt             Valid salt
    /// @return hookAddress      Resulting hook address
    function findSalt(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        address admin,
        bytes32 startingSalt,
        uint256 maxIterations
    ) external view returns (bytes32 salt, address hookAddress) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(PassportGatedHook).creationCode,
                abi.encode(poolManager, reputationManager, admin)
            )
        );

        uint256 current = uint256(startingSalt);
        for (uint256 i = 0; i < maxIterations; i++) {
            bytes32 s = bytes32(current + i);
            address predicted = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), s, bytecodeHash))))
            );
            if (_hasValidPermissions(predicted)) {
                return (s, predicted);
            }
        }
        revert("No valid salt found within iteration limit");
    }

    /// @notice Check whether an address has the exact required permission bits.
    function isValidHookAddress(address hookAddress) external pure returns (bool) {
        return _hasValidPermissions(hookAddress);
    }

    // ─── Internal ─────────────────────────────────────────────────────────────

    function _hasValidPermissions(address addr) internal pure returns (bool) {
        uint160 bits = uint160(addr);
        return (bits & REQUIRED_MASK) == REQUIRED_MASK && (bits & FORBIDDEN_MASK) == 0;
    }
}

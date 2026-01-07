// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {PassportGatedHook} from "./PassportGatedHook.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {ReputationManager} from "../contracts/ReputationManager.sol";

/// @title HookDeployer
/// @notice Deploys Uniswap V4 hooks using CREATE2 for deterministic addresses
/// @dev Hook permissions are encoded in the hook address per Uniswap V4 spec.
///      The address must have specific bit patterns to indicate which hooks are enabled.
///      Bits 159-150 encode: beforeInitialize, afterInitialize, beforeAddLiquidity, 
///      afterAddLiquidity, beforeRemoveLiquidity, afterRemoveLiquidity, beforeSwap, 
///      afterSwap, beforeDonate, afterDonate
///
///      This deployer creates PassportGatedHook which allows LP pool access to users
///      who hold either Convexo Passport (ZKPassport) OR Convexo LPs (Veriff) NFT.
contract HookDeployer {
    // ============ Events ============

    /// @notice Emitted when a PassportGatedHook is deployed
    event PassportGatedHookDeployed(
        address indexed hook,
        address indexed poolManager,
        address indexed reputationManager,
        bytes32 salt
    );

    // ============ PassportGatedHook Deployment ============

    /// @notice Deploy a PassportGatedHook with CREATE2
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param reputationManager The ReputationManager contract address
    /// @param salt The salt for CREATE2 deployment
    /// @return hook The deployed hook address
    function deployPassportGatedHook(IPoolManager poolManager, ReputationManager reputationManager, bytes32 salt)
        external
        returns (PassportGatedHook hook)
    {
        hook = new PassportGatedHook{salt: salt}(poolManager, reputationManager);
        emit PassportGatedHookDeployed(address(hook), address(poolManager), address(reputationManager), salt);
    }

    /// @notice Compute the address of a PassportGatedHook before deployment
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param reputationManager The ReputationManager contract address
    /// @param salt The salt for CREATE2 deployment
    /// @return The predicted hook address
    function computePassportGatedHookAddress(IPoolManager poolManager, ReputationManager reputationManager, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(PassportGatedHook).creationCode, abi.encode(poolManager, reputationManager))
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    // ============ Salt Finding Functions ============

    /// @notice Find a salt that produces a PassportGatedHook address with the correct permissions
    /// @dev For PassportGatedHook, we need: beforeAddLiquidity (157), beforeRemoveLiquidity (155), beforeSwap (153)
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param reputationManager The ReputationManager contract address
    /// @param startingSalt The starting salt to iterate from
    /// @param maxIterations The maximum number of iterations to try
    /// @return salt The salt that produces the correct address
    /// @return hookAddress The resulting hook address
    function findPassportGatedHookSalt(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        bytes32 startingSalt,
        uint256 maxIterations
    ) external view returns (bytes32 salt, address hookAddress) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(PassportGatedHook).creationCode, abi.encode(poolManager, reputationManager))
        );

        uint256 currentSalt = uint256(startingSalt);

        for (uint256 i = 0; i < maxIterations; i++) {
            bytes32 saltToTry = bytes32(currentSalt + i);

            address predicted = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltToTry, bytecodeHash))))
            );

            if (_validateHookPermissions(predicted)) {
                return (saltToTry, predicted);
            }
        }

        revert("No valid salt found within iteration limit");
    }

    /// @notice Validate that an address has the correct hook permission bits set
    /// @dev Checks bits for: beforeAddLiquidity (157), beforeRemoveLiquidity (155), beforeSwap (153)
    ///      And ensures no other permission bits are set
    /// @param predicted The address to validate
    /// @return isValid True if the address has correct permission bits
    function _validateHookPermissions(address predicted) internal pure returns (bool isValid) {
        uint160 addr = uint160(predicted);

        // Required permissions
        bool hasBeforeAddLiquidity = (addr & (1 << 157)) != 0;
        bool hasBeforeRemoveLiquidity = (addr & (1 << 155)) != 0;
        bool hasBeforeSwap = (addr & (1 << 153)) != 0;

        // Unwanted permissions (should NOT be set)
        bool noBeforeInitialize = (addr & (1 << 159)) == 0;
        bool noAfterInitialize = (addr & (1 << 158)) == 0;
        bool noAfterAddLiquidity = (addr & (1 << 156)) == 0;
        bool noAfterRemoveLiquidity = (addr & (1 << 154)) == 0;
        bool noAfterSwap = (addr & (1 << 152)) == 0;
        bool noBeforeDonate = (addr & (1 << 151)) == 0;
        bool noAfterDonate = (addr & (1 << 150)) == 0;

        return hasBeforeAddLiquidity && hasBeforeRemoveLiquidity && hasBeforeSwap && noBeforeInitialize
            && noAfterInitialize && noAfterAddLiquidity && noAfterRemoveLiquidity && noAfterSwap && noBeforeDonate
            && noAfterDonate;
    }

    /// @notice Check if an address has valid hook permissions
    /// @param hookAddress The address to check
    /// @return isValid True if the address has valid hook permissions
    function isValidHookAddress(address hookAddress) external pure returns (bool isValid) {
        return _validateHookPermissions(hookAddress);
    }

    // ============ Legacy Functions (Kept for Backward Compatibility) ============

    /// @notice Deploy a PassportGatedHook with CREATE2 (legacy function name)
    function deploy(IPoolManager poolManager, ReputationManager reputationManager, bytes32 salt)
        external
        returns (PassportGatedHook hook)
    {
        hook = new PassportGatedHook{salt: salt}(poolManager, reputationManager);
        emit PassportGatedHookDeployed(address(hook), address(poolManager), address(reputationManager), salt);
    }

    /// @notice Compute the address of a PassportGatedHook before deployment (legacy function name)
    function computeAddress(IPoolManager poolManager, ReputationManager reputationManager, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(PassportGatedHook).creationCode, abi.encode(poolManager, reputationManager))
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /// @notice Find a salt for PassportGatedHook (legacy function name)
    function findSalt(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        bytes32 startingSalt,
        uint256 maxIterations
    ) external view returns (bytes32 salt, address hookAddress) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(PassportGatedHook).creationCode, abi.encode(poolManager, reputationManager))
        );

        uint256 currentSalt = uint256(startingSalt);

        for (uint256 i = 0; i < maxIterations; i++) {
            bytes32 saltToTry = bytes32(currentSalt + i);

            address predicted = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltToTry, bytecodeHash))))
            );

            if (_validateHookPermissions(predicted)) {
                return (saltToTry, predicted);
            }
        }

        revert("No valid salt found within iteration limit");
    }
}


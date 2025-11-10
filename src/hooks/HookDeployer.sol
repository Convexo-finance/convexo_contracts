// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {CompliantLPHook} from "./CompliantLPHook.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IConvexoLPs} from "../interfaces/IConvexoLPs.sol";

/// @title HookDeployer
/// @notice Deploys CompliantLPHook using CREATE2 for deterministic addresses
/// @dev Hook permissions are encoded in the hook address per Uniswap V4 spec
contract HookDeployer {
    /// @notice Emitted when a hook is deployed
    event HookDeployed(address indexed hook, address indexed poolManager, address indexed convexoLPs, bytes32 salt);

    /// @notice Deploy a CompliantLPHook with CREATE2
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param convexoLPs The Convexo_LPs NFT contract address
    /// @param salt The salt for CREATE2 deployment
    /// @return hook The deployed hook address
    function deploy(IPoolManager poolManager, IConvexoLPs convexoLPs, bytes32 salt)
        external
        returns (CompliantLPHook hook)
    {
        hook = new CompliantLPHook{salt: salt}(poolManager, convexoLPs);
        emit HookDeployed(address(hook), address(poolManager), address(convexoLPs), salt);
    }

    /// @notice Compute the address of a hook before deployment
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param convexoLPs The Convexo_LPs NFT contract address
    /// @param salt The salt for CREATE2 deployment
    /// @return The predicted hook address
    function computeAddress(IPoolManager poolManager, IConvexoLPs convexoLPs, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash =
            keccak256(abi.encodePacked(type(CompliantLPHook).creationCode, abi.encode(poolManager, convexoLPs)));

        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /// @notice Find a salt that produces a hook address with the correct permissions
    /// @dev Hook permissions are encoded in the address:
    /// - Bit 159: beforeInitialize
    /// - Bit 158: afterInitialize
    /// - Bit 157: beforeAddLiquidity
    /// - Bit 156: afterAddLiquidity
    /// - Bit 155: beforeRemoveLiquidity
    /// - Bit 154: afterRemoveLiquidity
    /// - Bit 153: beforeSwap
    /// - Bit 152: afterSwap
    /// - Bit 151: beforeDonate
    /// - Bit 150: afterDonate
    /// @param poolManager The Uniswap V4 PoolManager address
    /// @param convexoLPs The Convexo_LPs NFT contract address
    /// @param startingSalt The starting salt to iterate from
    /// @param maxIterations The maximum number of iterations to try
    /// @return salt The salt that produces the correct address
    /// @return hookAddress The resulting hook address
    function findSalt(IPoolManager poolManager, IConvexoLPs convexoLPs, bytes32 startingSalt, uint256 maxIterations)
        external
        view
        returns (bytes32 salt, address hookAddress)
    {
        // Required permissions: beforeAddLiquidity, beforeRemoveLiquidity, beforeSwap
        // This corresponds to bits 157, 155, and 153 being set
        // Binary: 10101000... (in the high bits)
        // This means the address should have specific bit patterns

        bytes32 bytecodeHash =
            keccak256(abi.encodePacked(type(CompliantLPHook).creationCode, abi.encode(poolManager, convexoLPs)));

        uint256 currentSalt = uint256(startingSalt);

        for (uint256 i = 0; i < maxIterations; i++) {
            bytes32 saltToTry = bytes32(currentSalt + i);

            address predicted = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltToTry, bytecodeHash))))
            );

            // Check if the address has the correct permission bits
            // For our hook: beforeAddLiquidity (157), beforeRemoveLiquidity (155), beforeSwap (153)
            uint160 addr = uint160(predicted);

            bool hasBeforeAddLiquidity = (addr & (1 << 157)) != 0;
            bool hasBeforeRemoveLiquidity = (addr & (1 << 155)) != 0;
            bool hasBeforeSwap = (addr & (1 << 153)) != 0;

            // Check that unwanted permissions are NOT set
            bool noBeforeInitialize = (addr & (1 << 159)) == 0;
            bool noAfterInitialize = (addr & (1 << 158)) == 0;
            bool noAfterAddLiquidity = (addr & (1 << 156)) == 0;
            bool noAfterRemoveLiquidity = (addr & (1 << 154)) == 0;
            bool noAfterSwap = (addr & (1 << 152)) == 0;
            bool noBeforeDonate = (addr & (1 << 151)) == 0;
            bool noAfterDonate = (addr & (1 << 150)) == 0;

            if (
                hasBeforeAddLiquidity && hasBeforeRemoveLiquidity && hasBeforeSwap && noBeforeInitialize
                    && noAfterInitialize && noAfterAddLiquidity && noAfterRemoveLiquidity && noAfterSwap && noBeforeDonate
                    && noAfterDonate
            ) {
                return (saltToTry, predicted);
            }
        }

        revert("No valid salt found within iteration limit");
    }
}

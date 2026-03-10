// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ConvexoPoolHook} from "./ConvexoPoolHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";
import {PriceFeedManager} from "../oracles/PriceFeedManager.sol";

/// @title ConvexoHookDeployer
/// @notice Deploys ConvexoPoolHook via CREATE2 for a deterministic address.
///
/// ConvexoPoolHook requires permission bits:
///   afterInitialize (12) + beforeAddLiquidity (11) +
///   beforeRemoveLiquidity (9) + beforeSwap (7)
///   = 0x1000 | 0x0800 | 0x0200 | 0x0080 = 0x1A80
///
/// Workflow:
///   1. Call findSalt() off-chain to find a salt giving address bits == 0x1A80
///   2. Call deploy() with that salt
contract ConvexoHookDeployer {
    event ConvexoPoolHookDeployed(
        address indexed hook,
        address indexed poolManager,
        address indexed reputationManager,
        bytes32 salt
    );

    // Required bits: afterInitialize(12), beforeAddLiquidity(11),
    //                beforeRemoveLiquidity(9), beforeSwap(7)
    uint160 private constant REQUIRED_MASK =
        Hooks.AFTER_INITIALIZE_FLAG
        | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
        | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        | Hooks.BEFORE_SWAP_FLAG;

    // All 14 hook bits minus the 4 we need must be zero
    uint160 private constant FORBIDDEN_MASK = uint160((1 << 14) - 1) & ~REQUIRED_MASK;

    /// @notice Deploy ConvexoPoolHook via CREATE2.
    function deploy(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        PriceFeedManager priceFeedManager,
        PriceFeedManager.CurrencyPair currencyPair,
        uint8 localTokenDecimals,
        bool token0IsBase,
        uint24 bandBps,
        address admin,
        bytes32 salt
    ) external returns (ConvexoPoolHook hook) {
        hook = new ConvexoPoolHook{salt: salt}(
            poolManager,
            reputationManager,
            priceFeedManager,
            currencyPair,
            localTokenDecimals,
            token0IsBase,
            bandBps,
            admin
        );
        emit ConvexoPoolHookDeployed(address(hook), address(poolManager), address(reputationManager), salt);
    }

    /// @notice Predict the deployed address without deploying.
    function computeAddress(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        PriceFeedManager priceFeedManager,
        PriceFeedManager.CurrencyPair currencyPair,
        uint8 localTokenDecimals,
        bool token0IsBase,
        uint24 bandBps,
        address admin,
        bytes32 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(ConvexoPoolHook).creationCode,
                abi.encode(poolManager, reputationManager, priceFeedManager, currencyPair, localTokenDecimals, token0IsBase, bandBps, admin)
            )
        );
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /// @notice Find a CREATE2 salt whose resulting address has exactly bits 0x1A80 set.
    function findSalt(
        IPoolManager poolManager,
        ReputationManager reputationManager,
        PriceFeedManager priceFeedManager,
        PriceFeedManager.CurrencyPair currencyPair,
        uint8 localTokenDecimals,
        bool token0IsBase,
        uint24 bandBps,
        address admin,
        bytes32 startingSalt,
        uint256 maxIterations
    ) external view returns (bytes32 salt, address hookAddress) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(ConvexoPoolHook).creationCode,
                abi.encode(poolManager, reputationManager, priceFeedManager, currencyPair, localTokenDecimals, token0IsBase, bandBps, admin)
            )
        );

        uint256 current = uint256(startingSalt);
        for (uint256 i; i < maxIterations; i++) {
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

    function isValidHookAddress(address hookAddress) external pure returns (bool) {
        return _hasValidPermissions(hookAddress);
    }

    function _hasValidPermissions(address addr) internal pure returns (bool) {
        uint160 bits = uint160(addr);
        return (bits & REQUIRED_MASK) == REQUIRED_MASK && (bits & FORBIDDEN_MASK) == 0;
    }
}

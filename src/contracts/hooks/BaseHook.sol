// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";

/// @title BaseHook
/// @notice Base contract for Uniswap V4 hooks using official v4-core types.
///         Validates address bits in the constructor. Child contracts override
///         only the internal hook functions they need; all others revert.
abstract contract BaseHook is IHooks {
    using BeforeSwapDeltaLibrary for BeforeSwapDelta;

    error HookNotImplemented();
    error OnlyPoolManager();

    IPoolManager public immutable poolManager;

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        // Validates that this contract's address has the correct permission bits
        // per Uniswap V4 Hooks library encoding. Reverts at deploy time if wrong.
        Hooks.validateHookPermissions(IHooks(address(this)), getHookPermissions());
    }

    /// @notice Returns enabled hook permissions. Must be overridden by child contracts.
    function getHookPermissions() public pure virtual returns (Hooks.Permissions memory);

    // ─── External callbacks (called by PoolManager only) ─────────────────────

    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external virtual onlyPoolManager returns (bytes4)
    {
        return _beforeInitialize(sender, key, sqrtPriceX96);
    }

    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external virtual onlyPoolManager returns (bytes4)
    {
        return _afterInitialize(sender, key, sqrtPriceX96, tick);
    }

    function beforeAddLiquidity(
        address sender, PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeAddLiquidity(sender, key, params, hookData);
    }

    function afterAddLiquidity(
        address sender, PoolKey calldata key, ModifyLiquidityParams calldata params,
        BalanceDelta delta, BalanceDelta feesAccrued, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function beforeRemoveLiquidity(
        address sender, PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function afterRemoveLiquidity(
        address sender, PoolKey calldata key, ModifyLiquidityParams calldata params,
        BalanceDelta delta, BalanceDelta feesAccrued, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterRemoveLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external virtual onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24)
    {
        return _beforeSwap(sender, key, params, hookData);
    }

    function afterSwap(
        address sender, PoolKey calldata key, SwapParams calldata params,
        BalanceDelta delta, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function beforeDonate(
        address sender, PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeDonate(sender, key, amount0, amount1, hookData);
    }

    function afterDonate(
        address sender, PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _afterDonate(sender, key, amount0, amount1, hookData);
    }

    // ─── Internal hooks (override only what you enable) ──────────────────────

    function _beforeInitialize(address, PoolKey calldata, uint160) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function _afterInitialize(address, PoolKey calldata, uint160, int24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function _beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal virtual returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterAddLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function _beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal virtual returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterRemoveLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal virtual returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal virtual returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    function _beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal virtual returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal virtual returns (bytes4)
    {
        revert HookNotImplemented();
    }
}

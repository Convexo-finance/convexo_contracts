// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {
    IHooks,
    BeforeSwapDelta,
    PoolKey,
    BalanceDelta,
    ModifyLiquidityParams,
    SwapParams,
    Permissions
} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";

/// @title BaseHook
/// @notice Base contract for Uniswap V4 hooks following v4-periphery patterns
/// @dev Provides default implementations that revert for all hook functions.
///      Child contracts should override the internal hook functions (_beforeSwap, etc.)
///      Based on Uniswap V4 documentation: https://docs.uniswap.org/contracts/v4/quickstart/hooks/swap
abstract contract BaseHook is IHooks {

    error HookNotImplemented();
    error OnlyPoolManager();
    error InvalidHookAddress();

    /// @notice The address of the PoolManager
    IPoolManager public immutable poolManager;

    /// @notice Modifier to restrict access to only the PoolManager
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) {
            revert OnlyPoolManager();
        }
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    /// @notice Returns the hook permissions
    /// @dev Must be overridden by child contracts to specify which hooks are implemented
    /// @return The Permissions struct indicating enabled hooks
    function getHookPermissions() public pure virtual returns (Permissions memory);

    // ============ External Hook Functions ============
    // These are called by the PoolManager and delegate to internal implementations

    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external
        virtual
        onlyPoolManager
        returns (bytes4)
    {
        return _beforeInitialize(sender, key, sqrtPriceX96);
    }

    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        virtual
        onlyPoolManager
        returns (bytes4)
    {
        return _afterInitialize(sender, key, sqrtPriceX96, tick);
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeAddLiquidity(sender, key, params, hookData);
    }

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterRemoveLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        virtual
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        return _beforeSwap(sender, key, params, hookData);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _beforeDonate(sender, key, amount0, amount1, hookData);
    }

    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external virtual onlyPoolManager returns (bytes4) {
        return _afterDonate(sender, key, amount0, amount1, hookData);
    }

    // ============ Internal Hook Functions ============
    // These should be overridden by child contracts

    function _beforeInitialize(address, PoolKey calldata, uint160) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function _afterInitialize(address, PoolKey calldata, uint160, int24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function _beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function _beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    function _beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function _afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {
    IHooks, BeforeSwapDelta, PoolKey, BalanceDelta, ModifyLiquidityParams, SwapParams
} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";

/// @notice Base contract for Uniswap V4 hooks
/// @dev Provides default implementations that revert for all hook functions
abstract contract BaseHook is IHooks {
    error HookNotImplemented();

    /// @notice The address of the PoolManager
    IPoolManager public immutable poolManager;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    /// @notice Helper function to get hook permissions from address
    function getHookPermissions() public pure virtual returns (Permissions memory);

    /// @notice Struct to define which hooks are implemented
    struct Permissions {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeAddLiquidity;
        bool afterAddLiquidity;
        bool beforeRemoveLiquidity;
        bool afterRemoveLiquidity;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
    }

    function beforeInitialize(address, PoolKey calldata, uint160) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    function beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        external
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    function afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        external
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}

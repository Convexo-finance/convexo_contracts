// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {PoolKey, BalanceDelta, ModifyLiquidityParams, SwapParams} from "./IHooks.sol";

/// @notice Interface for the Uniswap V4 PoolManager
interface IPoolManager {

    /// @notice Initialize a new pool
    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick);

    /// @notice Modify liquidity for a position
    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) external returns (BalanceDelta, BalanceDelta);

    /// @notice Swap tokens in a pool
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta);
}


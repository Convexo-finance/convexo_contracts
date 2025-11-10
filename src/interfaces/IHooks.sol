// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @notice The PoolKey struct for identifying a pool
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

/// @notice Balance delta type
type BalanceDelta is int256;

/// @notice Parameters for modifying liquidity
struct ModifyLiquidityParams {
    int24 tickLower;
    int24 tickUpper;
    int256 liquidityDelta;
    bytes32 salt;
}

/// @notice Parameters for swapping
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

/// @notice Interface for Uniswap V4 Hooks
interface IHooks {
    /// @notice Hook called before initializing a pool
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96) external returns (bytes4);

    /// @notice Hook called after initializing a pool
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        returns (bytes4);

    /// @notice Hook called before adding liquidity to a pool
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Hook called after adding liquidity to a pool
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice Hook called before removing liquidity from a pool
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Hook called after removing liquidity from a pool
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice Hook called before a swap is executed
    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (bytes4, BeforeSwapDelta, uint24);

    /// @notice Hook called after a swap is executed
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128);

    /// @notice Hook called before donating to a pool
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Hook called after donating to a pool
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}

/// @notice Delta for beforeSwap hook
type BeforeSwapDelta is int256;

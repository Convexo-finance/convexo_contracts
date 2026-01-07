// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {BaseHook} from "./BaseHook.sol";
import {IHooks, PoolKey, BeforeSwapDelta, ModifyLiquidityParams, SwapParams} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IConvexoPassport} from "../interfaces/IConvexoPassport.sol";

/// @title CompliantLPHook
/// @notice Uniswap V4 hook that gates LP access to Convexo Passport NFT holders only
/// @dev Only addresses holding an active Convexo Passport NFT can swap, add, or remove liquidity.
///      This ensures KYC compliance as Passport holders have verified identity via ZKPassport.
///      Based on Uniswap V4 Hooks: https://docs.uniswap.org/contracts/v4/quickstart/hooks/swap
contract CompliantLPHook is BaseHook {
    /// @notice The Convexo Passport NFT contract
    IConvexoPassport public immutable convexoPassport;

    /// @notice Emitted when a user is granted access to pool operations
    event AccessGranted(address indexed user, string operation);

    /// @notice Error thrown when user doesn't hold an active Convexo Passport
    error MustHoldActivePassport();

    /// @notice Error thrown when passport contract address is invalid
    error InvalidPassportContract();

    /// @notice Constructor
    /// @param _poolManager The Uniswap V4 PoolManager address
    /// @param _convexoPassport The Convexo Passport NFT contract address
    constructor(IPoolManager _poolManager, IConvexoPassport _convexoPassport) BaseHook(_poolManager) {
        if (address(_convexoPassport) == address(0)) {
            revert InvalidPassportContract();
        }
        convexoPassport = _convexoPassport;
    }

    /// @notice Returns the hook permissions
    /// @dev Enables beforeSwap, beforeAddLiquidity, and beforeRemoveLiquidity hooks
    function getHookPermissions() public pure override returns (Permissions memory) {
        return Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,    // Gate adding liquidity
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true, // Gate removing liquidity
            afterRemoveLiquidity: false,
            beforeSwap: true,            // Gate swapping
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    /// @notice Check if user holds an active Convexo Passport
    /// @param user The address to check
    /// @dev Reverts if user doesn't hold an active passport
    function _checkPassportAccess(address user) internal view {
        if (!convexoPassport.holdsActivePassport(user)) {
            revert MustHoldActivePassport();
        }
    }

    /// @notice External function to check if a user has passport access
    /// @param user The address to check
    /// @return hasAccess True if user holds an active passport
    function hasPassportAccess(address user) external view returns (bool hasAccess) {
        return convexoPassport.holdsActivePassport(user);
    }

    /// @notice Hook called before a swap is executed
    /// @param sender The address initiating the swap
    function beforeSwap(address sender, PoolKey calldata, SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        _checkPassportAccess(sender);
        emit AccessGranted(sender, "swap");
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    /// @notice Hook called before liquidity is added to a pool
    /// @param sender The address adding liquidity
    function beforeAddLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        _checkPassportAccess(sender);
        emit AccessGranted(sender, "addLiquidity");
        return IHooks.beforeAddLiquidity.selector;
    }

    /// @notice Hook called before liquidity is removed from a pool
    /// @param sender The address removing liquidity
    function beforeRemoveLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        _checkPassportAccess(sender);
        emit AccessGranted(sender, "removeLiquidity");
        return IHooks.beforeRemoveLiquidity.selector;
    }
}

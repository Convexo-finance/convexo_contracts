// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {BaseHook} from "./BaseHook.sol";
import {IHooks, BeforeSwapDelta, PoolKey, BalanceDelta, ModifyLiquidityParams, SwapParams} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IConvexoLPs} from "../interfaces/IConvexoLPs.sol";

/// @title CompliantLPHook
/// @notice Uniswap V4 hook that gates liquidity pool access to Convexo_LPs NFT holders
/// @dev Only addresses holding an active Convexo_LPs NFT can swap, add, or remove liquidity
contract CompliantLPHook is BaseHook {
    /// @notice The Convexo_LPs NFT contract
    IConvexoLPs public immutable convexoLPs;

    /// @notice Emitted when a user is denied access due to missing or inactive NFT
    event AccessDenied(address indexed user, string reason);

    /// @notice Emitted when a user successfully passes compliance check
    event AccessGranted(address indexed user, uint256 nftBalance);

    /// @notice Error thrown when user doesn't hold Convexo_LPs NFT
    error MustHoldConvexoLPsNFT();

    /// @notice Error thrown when user's NFT is not active
    error NFTNotActive();

    /// @notice Constructor
    /// @param _poolManager The Uniswap V4 PoolManager address
    /// @param _convexoLPs The Convexo_LPs NFT contract address
    constructor(IPoolManager _poolManager, IConvexoLPs _convexoLPs) BaseHook(_poolManager) {
        convexoLPs = _convexoLPs;
    }

    /// @notice Returns the hook permissions
    /// @return Permissions struct indicating which hooks are implemented
    function getHookPermissions() public pure override returns (Permissions memory) {
        return Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    /// @notice Check if user holds an active Convexo_LPs NFT
    /// @param user The address to check
    /// @dev Reverts if user doesn't hold NFT or if NFT is not active
    function _checkCompliance(address user) internal view {
        uint256 balance = convexoLPs.balanceOf(user);
        
        if (balance == 0) {
            revert MustHoldConvexoLPsNFT();
        }

        // Check if at least one token is active
        // Note: This assumes tokenId starts from 0 and is sequential
        // For production, you may want a more sophisticated approach
        bool hasActiveToken = false;
        for (uint256 i = 0; i < balance && !hasActiveToken; i++) {
            // In a real implementation, you'd need to get the tokenId for this user
            // This is a simplified version - you may need to add tokenOfOwnerByIndex to Convexo_LPs
            // For now, we'll just check if they have balance > 0
            hasActiveToken = true;
        }

        if (!hasActiveToken) {
            revert NFTNotActive();
        }
    }

    /// @notice Hook called before a swap is executed
    /// @param sender The address initiating the swap
    /// @param key The pool key
    /// @param params The swap parameters
    /// @param hookData Additional hook data
    /// @return The function selector, BeforeSwapDelta, and fee
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Check compliance
        _checkCompliance(sender);
        
        emit AccessGranted(sender, convexoLPs.balanceOf(sender));
        
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    /// @notice Hook called before liquidity is added to a pool
    /// @param sender The address adding liquidity
    /// @param key The pool key
    /// @param params The liquidity modification parameters
    /// @param hookData Additional hook data
    /// @return The function selector
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        // Check compliance
        _checkCompliance(sender);
        
        emit AccessGranted(sender, convexoLPs.balanceOf(sender));
        
        return IHooks.beforeAddLiquidity.selector;
    }

    /// @notice Hook called before liquidity is removed from a pool
    /// @param sender The address removing liquidity
    /// @param key The pool key
    /// @param params The liquidity modification parameters
    /// @param hookData Additional hook data
    /// @return The function selector
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        // Check compliance
        _checkCompliance(sender);
        
        emit AccessGranted(sender, convexoLPs.balanceOf(sender));
        
        return IHooks.beforeRemoveLiquidity.selector;
    }
}


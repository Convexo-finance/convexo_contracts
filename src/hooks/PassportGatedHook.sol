// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {BaseHook} from "./BaseHook.sol";
import {IHooks, PoolKey, BeforeSwapDelta, ModifyLiquidityParams, SwapParams, Permissions} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {ReputationManager} from "../contracts/ReputationManager.sol";

/// @title PassportGatedHook
/// @notice Uniswap V4 hook that gates LP pool access to verified KYC/KYB holders
/// @dev Allows access to users who hold ANY of:
///      - Convexo_Passport NFT (ZKPassport - International KYC) - Tier 1
///      - Limited_Partners_Individuals NFT (Veriff - Individual KYC) - Tier 2
///      - Limited_Partners_Business NFT (Sumsub - Business KYB) - Tier 2
///      - Ecreditscoring NFT (AI Credit Score) - Tier 3
///      
///      This ensures all LP pool participants have completed verification
///      through one of the supported verification methods.
///
///      Access Matrix:
///      | NFT                  | Can Swap | Can Add Liquidity | Can Remove Liquidity |
///      |----------------------|----------|-------------------|----------------------|
///      | None                 | ✗        | ✗                 | ✗                    |
///      | Passport (Tier 1)    | ✓        | ✓                 | ✓                    |
///      | LP Individual (T2)   | ✓        | ✓                 | ✓                    |
///      | LP Business (T2)     | ✓        | ✓                 | ✓                    |
///      | Ecreditscoring (T3)  | ✓        | ✓                 | ✓                    |
contract PassportGatedHook is BaseHook {
    /// @notice The ReputationManager contract for checking KYC status
    ReputationManager public immutable reputationManager;

    /// @notice Emitted when a user is granted access to pool operations
    event AccessGranted(address indexed user, string operation, ReputationManager.ReputationTier tier);

    /// @notice Error thrown when user doesn't have required KYC (no Passport or LPs NFT)
    error MustHaveKYCVerification();

    /// @notice Error thrown when reputation manager address is invalid
    error InvalidReputationManager();

    /// @notice Constructor
    /// @param _poolManager The Uniswap V4 PoolManager address
    /// @param _reputationManager The ReputationManager contract address
    constructor(IPoolManager _poolManager, ReputationManager _reputationManager) BaseHook(_poolManager) {
        if (address(_reputationManager) == address(0)) {
            revert InvalidReputationManager();
        }
        reputationManager = _reputationManager;
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

    /// @notice Check if user has KYC verification (Passport OR LPs NFT)
    /// @param user The address to check
    /// @dev Reverts if user doesn't have Tier 1+ (no KYC verification)
    function _checkKYCAccess(address user) internal view {
        if (!reputationManager.canAccessLPPools(user)) {
            revert MustHaveKYCVerification();
        }
    }

    /// @notice External function to check if a user has LP pool access
    /// @param user The address to check
    /// @return hasAccess True if user has Passport OR LPs NFT
    function hasLPPoolAccess(address user) external view returns (bool hasAccess) {
        return reputationManager.canAccessLPPools(user);
    }

    /// @notice Get the reputation tier of a user
    /// @param user The address to check
    /// @return tier The user's reputation tier
    function getUserTier(address user) external view returns (ReputationManager.ReputationTier tier) {
        return reputationManager.getReputationTier(user);
    }

    /// @notice Hook called before a swap is executed
    /// @param sender The address initiating the swap
    function beforeSwap(address sender, PoolKey calldata, SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        _checkKYCAccess(sender);
        emit AccessGranted(sender, "swap", reputationManager.getReputationTier(sender));
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    /// @notice Hook called before liquidity is added to a pool
    /// @param sender The address adding liquidity
    function beforeAddLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        _checkKYCAccess(sender);
        emit AccessGranted(sender, "addLiquidity", reputationManager.getReputationTier(sender));
        return IHooks.beforeAddLiquidity.selector;
    }

    /// @notice Hook called before liquidity is removed from a pool
    /// @param sender The address removing liquidity
    function beforeRemoveLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        _checkKYCAccess(sender);
        emit AccessGranted(sender, "removeLiquidity", reputationManager.getReputationTier(sender));
        return IHooks.beforeRemoveLiquidity.selector;
    }
}


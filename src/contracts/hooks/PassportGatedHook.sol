// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {BaseHook} from "./BaseHook.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title PassportGatedHook
/// @notice Uniswap V4 hook that gates LP pool access to verified KYC/KYB holders.
///
/// Access tiers (any of the following grants access):
///   - Tier 1: Convexo Passport NFT (ZKPassport)
///   - Tier 2: LP_Individuals NFT (Veriff KYC) or LP_Business NFT (Sumsub KYB)
///   - Tier 3: ECreditScoring NFT (AI credit score)
///
/// SECURITY — sender vs. user:
///   In Uniswap V4, `sender` is the address that called poolManager.unlock() — the
///   router or aggregator, NOT the end user. We gate on `sender` as a router allowlist
///   and read the actual user from `hookData` (encoded by the trusted router).
///   Any router that wants to interact with these pools must be explicitly allowed.
contract PassportGatedHook is BaseHook, AccessControl {
    bytes32 public constant ROUTER_ADMIN_ROLE = keccak256("ROUTER_ADMIN_ROLE");

    ReputationManager public immutable reputationManager;

    /// @notice Routers allowed to submit KYC'd user transactions to this pool.
    ///         The router is responsible for passing the real user address in hookData.
    mapping(address => bool) public allowedRouters;

    event RouterAllowed(address indexed router);
    event RouterRevoked(address indexed router);
    event AccessGranted(address indexed user, string operation, ReputationManager.ReputationTier tier);

    error RouterNotAllowed();
    error MustHaveKYCVerification();
    error InvalidReputationManager();

    /// @param _poolManager    Uniswap V4 PoolManager address
    /// @param _reputationManager   Convexo ReputationManager (NFT tier checker)
    /// @param admin           Address granted ROUTER_ADMIN_ROLE (can add/remove routers)
    constructor(IPoolManager _poolManager, ReputationManager _reputationManager, address admin)
        BaseHook(_poolManager)
    {
        if (address(_reputationManager) == address(0)) revert InvalidReputationManager();
        reputationManager = _reputationManager;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ROUTER_ADMIN_ROLE, admin);
    }

    /// @notice Hook permissions: gate swap, addLiquidity, removeLiquidity.
    ///         Deploy address must have bits 11 (beforeAddLiquidity), 9 (beforeRemoveLiquidity),
    ///         7 (beforeSwap) set — use HookDeployer.findPassportGatedHookSalt().
    function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ─── Router management ────────────────────────────────────────────────────

    function allowRouter(address router) external onlyRole(ROUTER_ADMIN_ROLE) {
        allowedRouters[router] = true;
        emit RouterAllowed(router);
    }

    function revokeRouter(address router) external onlyRole(ROUTER_ADMIN_ROLE) {
        allowedRouters[router] = false;
        emit RouterRevoked(router);
    }

    // ─── View helpers ─────────────────────────────────────────────────────────

    function hasLPPoolAccess(address user) external view returns (bool) {
        return reputationManager.canAccessLPPools(user);
    }

    function getUserTier(address user) external view returns (ReputationManager.ReputationTier) {
        return reputationManager.getReputationTier(user);
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    /// @dev Decodes the real user from hookData and validates their KYC tier.
    ///      hookData must be abi.encode(address user) supplied by the trusted router.
    function _checkAccess(address router, bytes calldata hookData)
        internal
        returns (ReputationManager.ReputationTier tier)
    {
        if (!allowedRouters[router]) revert RouterNotAllowed();
        address user = abi.decode(hookData, (address));
        tier = reputationManager.getReputationTier(user);
        if (tier == ReputationManager.ReputationTier.None) revert MustHaveKYCVerification();
    }

    // ─── Hook implementations ─────────────────────────────────────────────────

    function _beforeSwap(address sender, PoolKey calldata, SwapParams calldata, bytes calldata hookData)
        internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {
        ReputationManager.ReputationTier tier = _checkAccess(sender, hookData);
        address user = abi.decode(hookData, (address));
        emit AccessGranted(user, "swap", tier);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _beforeAddLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata hookData)
        internal virtual override returns (bytes4)
    {
        ReputationManager.ReputationTier tier = _checkAccess(sender, hookData);
        address user = abi.decode(hookData, (address));
        emit AccessGranted(user, "addLiquidity", tier);
        return IHooks.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(address sender, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata hookData)
        internal virtual override returns (bytes4)
    {
        ReputationManager.ReputationTier tier = _checkAccess(sender, hookData);
        address user = abi.decode(hookData, (address));
        emit AccessGranted(user, "removeLiquidity", tier);
        return IHooks.beforeRemoveLiquidity.selector;
    }
}

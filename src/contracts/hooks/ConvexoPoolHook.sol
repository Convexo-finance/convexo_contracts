// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PassportGatedHook} from "./PassportGatedHook.sol";
import {PriceFeedManager} from "../oracles/PriceFeedManager.sol";
import {OracleMath} from "./libraries/OracleMath.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";

/// @title ConvexoPoolHook
/// @notice Uniswap V4 hook for the USDC/ECOP pool.
///
/// Combines two responsibilities (V4 only allows one hook per pool):
///
///   1. KYC gate — inherited from PassportGatedHook
///      - Only allowlisted routers can interact
///      - Router must pass real user address in hookData
///      - User must hold a Convexo verification NFT (Passport / LP / ECreditScoring)
///
///   2. Oracle price band — added here
///      - Reads USDC/COP rate from PriceFeedManager
///      - Rejects swaps that would push the pool price more than `bandBps` from oracle
///      - Validates pool is initialized near oracle price
///      - Keeper-triggered rebalance snaps pool back to oracle when it drifts
///
/// Phase 1 (MVP): PriceFeedManager uses ManualPriceAggregator (admin sets price daily).
/// Phase 2:       Replace ManualPriceAggregator with real Chainlink aggregator address.
///                No changes to this contract needed.
///
/// Hook permission bits: afterInitialize(12) + beforeAddLiquidity(11) +
///                       beforeRemoveLiquidity(9) + beforeSwap(7) = 0x1A80
/// Deploy via ConvexoHookDeployer.findSalt() + .deploy()
contract ConvexoPoolHook is PassportGatedHook, IUnlockCallback {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // ─── Roles ────────────────────────────────────────────────────────────────

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // ─── Immutables ───────────────────────────────────────────────────────────

    PriceFeedManager public immutable priceFeedManager;
    PriceFeedManager.CurrencyPair public immutable currencyPair;

    /// @notice Decimals of the local-currency token (token1, ECOP = 18)
    uint8 public immutable localTokenDecimals;

    /// @notice true = token0 is the base (USDC), Chainlink gives token1 per token0
    bool public immutable token0IsBase;

    // ─── Configurable state ───────────────────────────────────────────────────

    /// @notice Maximum pool deviation from oracle price, in basis points.
    ///         Default: 200 (2%). Admin can tighten or widen.
    uint24 public bandBps;

    /// @notice Minimum seconds between rebalance calls (prevents keeper spam).
    uint256 public rebalanceCooldown;

    /// @notice Timestamp of last successful rebalance.
    uint256 public lastRebalanceAt;

    // ─── Errors ───────────────────────────────────────────────────────────────

    error InitPriceTooFarFromOracle(uint160 initSqrt, uint160 oracleSqrt, uint256 deviationBps);
    error SwapExceedsPriceBand(uint160 poolSqrt, uint160 oracleSqrt, uint256 deviationBps, uint24 bandBps);
    error RebalanceCooldownActive(uint256 nextAllowedAt);
    error OnlyPoolManagerCallback();
    error SqrtPriceLimitRequired();

    // ─── Events ───────────────────────────────────────────────────────────────

    event PoolRebalanced(
        PoolId indexed poolId,
        uint160 fromSqrtPrice,
        uint160 toSqrtPrice,
        bool zeroForOne
    );
    event BandBpsUpdated(uint24 oldBps, uint24 newBps);
    event RebalanceCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event ReserveDeposited(address indexed token, uint256 amount);
    event ReserveWithdrawn(address indexed token, uint256 amount, address indexed to);

    // ─── Rebalance context (transient — only set during unlockCallback) ────────

    PoolKey private _rebalanceKey;
    bool private _rebalanceInProgress;

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _poolManager        Uniswap V4 PoolManager
    /// @param _reputationManager  Convexo ReputationManager
    /// @param _priceFeedManager   Convexo PriceFeedManager (holds oracle or manual price)
    /// @param _currencyPair       Which pair to read (e.g. USDC_COP)
    /// @param _localTokenDecimals Decimals of the local token (ECOP = 18)
    /// @param _token0IsBase       true if token0 is USDC (Chainlink gives COP per USDC)
    /// @param _bandBps            Initial price band in basis points (e.g. 200 = 2%)
    /// @param admin               Admin address (gets all roles)
    constructor(
        IPoolManager _poolManager,
        ReputationManager _reputationManager,
        PriceFeedManager _priceFeedManager,
        PriceFeedManager.CurrencyPair _currencyPair,
        uint8 _localTokenDecimals,
        bool _token0IsBase,
        uint24 _bandBps,
        address admin
    )
        PassportGatedHook(_poolManager, _reputationManager, admin)
    {
        priceFeedManager = _priceFeedManager;
        currencyPair = _currencyPair;
        localTokenDecimals = _localTokenDecimals;
        token0IsBase = _token0IsBase;
        bandBps = _bandBps;
        rebalanceCooldown = 1 hours;
        _grantRole(KEEPER_ROLE, admin);
    }

    // ─── Hook permissions ─────────────────────────────────────────────────────

    /// @notice Adds afterInitialize to PassportGatedHook's permissions.
    ///         Bit mask: 0x1A80 (bits 12, 11, 9, 7)
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,              // NEW — validates init price vs oracle
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

    // ─── afterInitialize: validate pool starts near oracle price ──────────────

    function _afterInitialize(address, PoolKey calldata, uint160 sqrtPriceX96, int24)
        internal
        override
        returns (bytes4)
    {
        uint160 oracleSqrt = _getOracleSqrtPrice();
        uint256 dev = OracleMath.deviationBps(sqrtPriceX96, oracleSqrt);
        if (dev > bandBps) {
            revert InitPriceTooFarFromOracle(sqrtPriceX96, oracleSqrt, dev);
        }
        return IHooks.afterInitialize.selector;
    }

    // ─── _beforeSwap: KYC gate + price band ──────────────────────────────────

    /// @dev Runs two checks in order:
    ///      1. KYC gate (router allowlist + user NFT tier) — from PassportGatedHook
    ///      2. Price band (current pool price vs oracle) — added here
    ///
    ///      The rebalance swap (triggered by this hook itself) bypasses this callback
    ///      because Hooks.sol skips beforeSwap when msg.sender == address(hook).
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // 1. KYC gate (inherited logic)
        ReputationManager.ReputationTier tier = _checkAccess(sender, hookData);
        address user = abi.decode(hookData, (address));
        emit AccessGranted(user, "swap", tier);

        // 2. Price band guard
        // Require caller sets sqrtPriceLimitX96 so we have a worst-case post-swap price.
        // Routers to this pool must always provide a price limit.
        if (params.sqrtPriceLimitX96 == 0) revert SqrtPriceLimitRequired();

        PoolId poolId = key.toId();
        (uint160 poolSqrt,,,) = poolManager.getSlot0(poolId);
        uint160 oracleSqrt = _getOracleSqrtPrice();

        // Check worst-case post-swap price (the limit price the caller accepts)
        uint160 worstCaseSqrt = params.sqrtPriceLimitX96;
        if (OracleMath.exceedsBand(worstCaseSqrt, oracleSqrt, bandBps)) {
            uint256 dev = OracleMath.deviationBps(worstCaseSqrt, oracleSqrt);
            revert SwapExceedsPriceBand(poolSqrt, oracleSqrt, dev, bandBps);
        }

        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // ─── Rebalance ────────────────────────────────────────────────────────────

    /// @notice Bring the pool price back to the oracle price.
    ///         Call when the pool has drifted outside the band (user swaps blocked).
    ///
    ///         The hook must hold enough token0 OR token1 to execute the corrective swap.
    ///         Fund via depositReserve() before calling.
    ///
    /// @param key  The PoolKey of the pool to rebalance
    function rebalance(PoolKey calldata key) external onlyRole(KEEPER_ROLE) {
        if (block.timestamp < lastRebalanceAt + rebalanceCooldown) {
            revert RebalanceCooldownActive(lastRebalanceAt + rebalanceCooldown);
        }

        _rebalanceKey = key;
        _rebalanceInProgress = true;

        // Initiates the V4 unlock pattern — poolManager calls back unlockCallback()
        poolManager.unlock(abi.encode(key.toId()));
    }

    /// @notice Called by PoolManager after unlock(). Executes the corrective swap.
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert OnlyPoolManagerCallback();
        require(_rebalanceInProgress, "No rebalance in progress");

        PoolKey memory key = _rebalanceKey;
        _rebalanceInProgress = false;

        PoolId poolId = abi.decode(data, (PoolId));
        (uint160 currentSqrt,,,) = poolManager.getSlot0(poolId);
        uint160 oracleSqrt = _getOracleSqrtPrice();

        // Direction: if pool price > oracle, we need to sell token0 (zeroForOne=true)
        //            if pool price < oracle, we need to buy token0 (zeroForOne=false)
        bool zeroForOne = currentSqrt > oracleSqrt;

        // Execute corrective swap targeting exactly the oracle sqrt price
        SwapParams memory params = SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: type(int256).min, // exactInput, large — oracle limit stops us
            sqrtPriceLimitX96: oracleSqrt
        });

        // hookData encodes this contract as the "user" — bypasses KYC check
        // (Hooks.beforeSwap is skipped when sender == address(this), so this is moot,
        //  but we encode correctly for any future validation)
        bytes memory hookData = abi.encode(address(this));

        BalanceDelta delta = poolManager.swap(key, params, hookData);

        // Settle deltas: pay what we owe, take what we're owed
        _settleDeltas(key, delta);

        lastRebalanceAt = block.timestamp;
        emit PoolRebalanced(poolId, currentSqrt, oracleSqrt, zeroForOne);

        return "";
    }

    // ─── Reserve management ───────────────────────────────────────────────────

    /// @notice Deposit tokens for the keeper to use during rebalance swaps.
    ///         Admin must pre-fund with both USDC and ECOP for rebalances to work.
    function depositReserve(address token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit ReserveDeposited(token, amount);
    }

    /// @notice Withdraw tokens from the rebalance reserve.
    function withdrawReserve(address token, uint256 amount, address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransfer(to, amount);
        emit ReserveWithdrawn(token, amount, to);
    }

    // ─── Admin config ─────────────────────────────────────────────────────────

    /// @notice Update the price band. Larger band = more drift allowed before swap blocked.
    function setBandBps(uint24 newBandBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit BandBpsUpdated(bandBps, newBandBps);
        bandBps = newBandBps;
    }

    /// @notice Update keeper rebalance cooldown.
    function setRebalanceCooldown(uint256 newCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit RebalanceCooldownUpdated(rebalanceCooldown, newCooldown);
        rebalanceCooldown = newCooldown;
    }

    // ─── View ─────────────────────────────────────────────────────────────────

    /// @notice Get the oracle-derived sqrtPriceX96 for the current Chainlink/manual price.
    function getOracleSqrtPrice() external view returns (uint160) {
        return _getOracleSqrtPrice();
    }

    /// @notice Get current pool sqrtPriceX96 and deviation from oracle.
    function getPoolPriceStatus(PoolKey calldata key)
        external
        view
        returns (uint160 poolSqrt, uint160 oracleSqrt, uint256 currentDeviationBps, bool needsRebalance)
    {
        (poolSqrt,,,) = poolManager.getSlot0(key.toId());
        oracleSqrt = _getOracleSqrtPrice();
        currentDeviationBps = OracleMath.deviationBps(poolSqrt, oracleSqrt);
        needsRebalance = currentDeviationBps > bandBps;
    }

    // ─── Internal ─────────────────────────────────────────────────────────────

    function _getOracleSqrtPrice() internal view returns (uint160) {
        (int256 price, uint8 dec) = priceFeedManager.getLatestPrice(currencyPair);
        return OracleMath.oracleToSqrtPriceX96(
            price,
            dec,
            6,                  // USDC decimals (token0)
            localTokenDecimals, // ECOP decimals (token1) = 18
            token0IsBase        // true: Chainlink gives COP per USDC
        );
    }

    function _settleDeltas(PoolKey memory key, BalanceDelta delta) internal {
        int128 delta0 = delta.amount0();
        int128 delta1 = delta.amount1();

        // Negative delta = we owe tokens to the pool.
        // V4 settlement pattern: sync() → transfer → settle()
        //   sync()    records the PoolManager's current balance of the token
        //   transfer  physically increases PoolManager's balance
        //   settle()  PoolManager computes the increase and credits our account
        if (delta0 < 0) {
            uint256 amount = uint256(uint128(-delta0));
            poolManager.sync(key.currency0);
            IERC20(Currency.unwrap(key.currency0)).safeTransfer(address(poolManager), amount);
            poolManager.settle();
        }
        if (delta1 < 0) {
            uint256 amount = uint256(uint128(-delta1));
            poolManager.sync(key.currency1);
            IERC20(Currency.unwrap(key.currency1)).safeTransfer(address(poolManager), amount);
            poolManager.settle();
        }

        // Positive delta = pool owes us tokens — take() pulls them to this contract
        if (delta0 > 0) {
            poolManager.take(key.currency0, address(this), uint256(uint128(delta0)));
        }
        if (delta1 > 0) {
            poolManager.take(key.currency1, address(this), uint256(uint128(delta1)));
        }
    }
}

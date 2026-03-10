// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {PriceFeedManager} from "../src/contracts/oracles/PriceFeedManager.sol";
import {ManualPriceAggregator} from "../src/contracts/oracles/ManualPriceAggregator.sol";

contract PriceFeedManagerTest is Test {
    PriceFeedManager pfm;
    ManualPriceAggregator aggregator;

    address admin    = address(0x1);
    address stranger = address(0x2);

    /// @dev 26-hour heartbeat — matches MVP documentation in ManualPriceAggregator.sol
    uint256 constant HEARTBEAT = 26 hours;

    function setUp() public {
        pfm        = new PriceFeedManager(admin);
        aggregator = new ManualPriceAggregator(admin, 8, "USDC / COP");
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /// @dev Register the aggregator for USDC_COP with HEARTBEAT seconds.
    function _registerFeed() internal {
        vm.prank(admin);
        pfm.setPriceFeed(PriceFeedManager.CurrencyPair.USDC_COP, address(aggregator), HEARTBEAT);
    }

    /// @dev Set a price on the aggregator as admin.
    function _setPrice(int256 price) internal {
        vm.prank(admin);
        aggregator.setPrice(price);
    }

    // ─── getLatestPrice before feed registered ────────────────────────────────

    function test_getLatestPrice_revertsBeforeFeedSet() public {
        vm.expectRevert(PriceFeedManager.PriceFeedNotActive.selector);
        pfm.getLatestPrice(PriceFeedManager.CurrencyPair.USDC_COP);
    }

    // ─── setPriceFeed ─────────────────────────────────────────────────────────

    function test_setPriceFeed_adminLinksAggregatorToPair() public {
        _registerFeed();

        PriceFeedManager.PriceFeed memory feed =
            pfm.getPriceFeed(PriceFeedManager.CurrencyPair.USDC_COP);

        assertTrue(feed.isActive);
        assertEq(address(feed.aggregator), address(aggregator));
        assertEq(feed.decimals, 8);
        assertEq(feed.description, "USDC / COP");
        assertEq(feed.heartbeat, HEARTBEAT);
    }

    function test_setPriceFeed_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert(); // AccessControl revert
        pfm.setPriceFeed(
            PriceFeedManager.CurrencyPair.USDC_COP,
            address(aggregator),
            HEARTBEAT
        );
    }

    // ─── getLatestPrice after price set ──────────────────────────────────────

    function test_getLatestPrice_returnsCorrectPriceAndDecimals() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        (int256 price, uint8 decimals) =
            pfm.getLatestPrice(PriceFeedManager.CurrencyPair.USDC_COP);

        assertEq(price, 420_000_000_000);
        assertEq(decimals, 8);
    }

    // ─── Staleness check ──────────────────────────────────────────────────────

    function test_getLatestPrice_revertsAfterHeartbeatExpires() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        // Warp past heartbeat — 27 hours > 26 hours
        vm.warp(block.timestamp + 27 hours);

        vm.expectRevert(PriceFeedManager.StalePriceData.selector);
        pfm.getLatestPrice(PriceFeedManager.CurrencyPair.USDC_COP);
    }

    function test_getLatestPrice_succeedsJustBeforeHeartbeatExpires() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        // Warp to exactly 1 second before expiry — should still be valid
        vm.warp(block.timestamp + HEARTBEAT - 1);

        (int256 price,) = pfm.getLatestPrice(PriceFeedManager.CurrencyPair.USDC_COP);
        assertEq(price, 420_000_000_000);
    }

    // ─── convertUSDCToLocal ───────────────────────────────────────────────────

    /// @notice 1 USDC (1e6) at 4200 COP/USDC (8 dec) → 4200 * 1e6 / 1e8 * 1e18 ...
    ///         The contract formula: localAmount = usdcAmount * price / 10^decimals
    ///         = 1e6 * 420_000_000_000 / 1e8
    ///         = 1e6 * 4200
    ///         = 4_200_000_000  (4200 local units with 6 decimal places, same as USDC)
    ///
    /// Note: ECOP has 18 dec but convertUSDCToLocal is a pure numeric conversion —
    ///       it does NOT re-scale for token1 decimals. The caller is responsible for
    ///       any further decimal adjustment.
    function test_convertUSDCToLocal_oneUSDC() public {
        _registerFeed();
        _setPrice(420_000_000_000); // 4200.00000000

        uint256 localAmount =
            pfm.convertUSDCToLocal(PriceFeedManager.CurrencyPair.USDC_COP, 1e6);

        // 1e6 * 420_000_000_000 / 1e8 = 4_200_000_000
        assertEq(localAmount, 4_200_000_000);
    }

    function test_convertUSDCToLocal_largeAmount() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        // 1000 USDC (1000e6) → should return 4_200_000_000_000
        uint256 localAmount =
            pfm.convertUSDCToLocal(PriceFeedManager.CurrencyPair.USDC_COP, 1000e6);

        assertEq(localAmount, 4_200_000_000_000);
    }

    // ─── convertLocalToUSDC ───────────────────────────────────────────────────

    /// @notice Inverse: localAmount = 4_200_000_000, price = 420_000_000_000 (8 dec)
    ///         usdcAmount = 4_200_000_000 * 1e8 / 420_000_000_000 = 1e6
    function test_convertLocalToUSDC_roundTrip() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        uint256 usdcAmount =
            pfm.convertLocalToUSDC(PriceFeedManager.CurrencyPair.USDC_COP, 4_200_000_000);

        assertEq(usdcAmount, 1e6);
    }

    // ─── deactivatePriceFeed ──────────────────────────────────────────────────

    function test_deactivatePriceFeed_preventsGetLatestPrice() public {
        _registerFeed();
        _setPrice(420_000_000_000);

        vm.prank(admin);
        pfm.deactivatePriceFeed(PriceFeedManager.CurrencyPair.USDC_COP);

        vm.expectRevert(PriceFeedManager.PriceFeedNotActive.selector);
        pfm.getLatestPrice(PriceFeedManager.CurrencyPair.USDC_COP);
    }

    // ─── isPriceFeedActive ────────────────────────────────────────────────────

    function test_isPriceFeedActive_falseBeforeRegistration() public view {
        assertFalse(pfm.isPriceFeedActive(PriceFeedManager.CurrencyPair.USDC_COP));
    }

    function test_isPriceFeedActive_trueAfterRegistration() public {
        _registerFeed();
        assertTrue(pfm.isPriceFeedActive(PriceFeedManager.CurrencyPair.USDC_COP));
    }

    // ─── getPriceWithTimestamp ────────────────────────────────────────────────

    function test_getPriceWithTimestamp_returnsUpdatedAt() public {
        _registerFeed();
        uint256 ts = block.timestamp;
        _setPrice(420_000_000_000);

        (int256 price, uint8 decimals, uint256 updatedAt) =
            pfm.getPriceWithTimestamp(PriceFeedManager.CurrencyPair.USDC_COP);

        assertEq(price, 420_000_000_000);
        assertEq(decimals, 8);
        assertEq(updatedAt, ts);
    }

    // ─── Events ───────────────────────────────────────────────────────────────

    function test_setPriceFeed_emitsPriceFeedUpdatedEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit PriceFeedManager.PriceFeedUpdated(
            PriceFeedManager.CurrencyPair.USDC_COP,
            address(aggregator),
            "USDC / COP"
        );
        pfm.setPriceFeed(
            PriceFeedManager.CurrencyPair.USDC_COP,
            address(aggregator),
            HEARTBEAT
        );
    }
}

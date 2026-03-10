// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {ManualPriceAggregator} from "../src/contracts/oracles/ManualPriceAggregator.sol";

contract ManualPriceAggregatorTest is Test {
    ManualPriceAggregator aggregator;

    address admin    = address(0x1);
    address priceSetter = address(0x2);
    address stranger = address(0x3);

    function setUp() public {
        aggregator = new ManualPriceAggregator(admin, 8, "USDC / COP");
    }

    // ─── Metadata ─────────────────────────────────────────────────────────────

    function test_decimals_returns8() public view {
        assertEq(aggregator.decimals(), 8);
    }

    function test_description_returnsLabel() public view {
        assertEq(aggregator.description(), "USDC / COP");
    }

    function test_version_returns1() public view {
        assertEq(aggregator.version(), 1);
    }

    // ─── latestRoundData before price set ─────────────────────────────────────

    function test_latestRoundData_revertsBeforePriceSet() public {
        vm.expectRevert(ManualPriceAggregator.PriceNotSet.selector);
        aggregator.latestRoundData();
    }

    // ─── setPrice access control ──────────────────────────────────────────────

    function test_setPrice_revertsForStranger() public {
        vm.prank(stranger);
        // AccessControl reverts with a non-trivial bytes selector; use low-level catch
        vm.expectRevert();
        aggregator.setPrice(420_000_000_000);
    }

    function test_setPrice_revertsOnZeroPrice() public {
        vm.prank(admin);
        vm.expectRevert(ManualPriceAggregator.PriceMustBePositive.selector);
        aggregator.setPrice(0);
    }

    function test_setPrice_revertsOnNegativePrice() public {
        vm.prank(admin);
        vm.expectRevert(ManualPriceAggregator.PriceMustBePositive.selector);
        aggregator.setPrice(-1);
    }

    // ─── setPrice happy path ──────────────────────────────────────────────────

    function test_setPrice_incrementsRoundId() public {
        vm.prank(admin);
        aggregator.setPrice(420_000_000_000);

        (uint80 roundId, int256 answer,, uint256 updatedAt,) = aggregator.latestRoundData();

        assertEq(roundId, 1);
        assertEq(answer, 420_000_000_000);
        assertEq(updatedAt, block.timestamp);
    }

    function test_setPrice_multipleCallsIncrementRoundId() public {
        vm.startPrank(admin);
        aggregator.setPrice(420_000_000_000);
        aggregator.setPrice(430_000_000_000);
        aggregator.setPrice(440_000_000_000);
        vm.stopPrank();

        (uint80 roundId, int256 answer,,,) = aggregator.latestRoundData();
        assertEq(roundId, 3);
        assertEq(answer, 440_000_000_000);
    }

    // ─── Role management ──────────────────────────────────────────────────────

    function test_admin_canGrantPriceSetterRole() public {
        // Read the role constant before the prank so the staticcall does not
        // consume the single-use prank context.
        bytes32 role = aggregator.PRICE_SETTER_ROLE();

        vm.prank(admin);
        aggregator.grantRole(role, priceSetter);

        // priceSetter should now succeed
        vm.prank(priceSetter);
        aggregator.setPrice(420_000_000_000);

        (,int256 answer,,,) = aggregator.latestRoundData();
        assertEq(answer, 420_000_000_000);
    }

    // ─── getRoundData ─────────────────────────────────────────────────────────

    function test_getRoundData_returnsCorrectDataForLatestRound() public {
        vm.prank(admin);
        aggregator.setPrice(420_000_000_000);

        uint256 ts = block.timestamp;
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            aggregator.getRoundData(1);

        assertEq(roundId, 1);
        assertEq(answer, 420_000_000_000);
        assertEq(startedAt, ts);
        assertEq(updatedAt, ts);
        assertEq(answeredInRound, 1);
    }

    function test_getRoundData_revertsForUnknownRound() public {
        vm.prank(admin);
        aggregator.setPrice(420_000_000_000);

        // Round 2 does not exist yet
        vm.expectRevert("Round not available");
        aggregator.getRoundData(2);
    }

    // ─── Events ───────────────────────────────────────────────────────────────

    function test_setPrice_emitsPriceUpdatedEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit ManualPriceAggregator.PriceUpdated(1, 420_000_000_000, block.timestamp);
        aggregator.setPrice(420_000_000_000);
    }
}

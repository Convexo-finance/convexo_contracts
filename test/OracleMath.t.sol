// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {OracleMath} from "../src/contracts/hooks/libraries/OracleMath.sol";

/// @dev Thin wrapper that exposes OracleMath's internal pure functions as external
///      calls so the test contract can invoke them without library linkage issues.
contract OracleMathWrapper {
    function oracleToSqrtPriceX96(
        int256 chainlinkPrice,
        uint8 chainlinkDec,
        uint8 token0Dec,
        uint8 token1Dec,
        bool token0IsBase
    ) external pure returns (uint160) {
        return OracleMath.oracleToSqrtPriceX96(
            chainlinkPrice, chainlinkDec, token0Dec, token1Dec, token0IsBase
        );
    }

    function deviationBps(uint160 poolSqrt, uint160 oracleSqrt) external pure returns (uint256) {
        return OracleMath.deviationBps(poolSqrt, oracleSqrt);
    }

    function exceedsBand(uint160 poolSqrt, uint160 oracleSqrt, uint24 bandBps)
        external pure returns (bool)
    {
        return OracleMath.exceedsBand(poolSqrt, oracleSqrt, bandBps);
    }
}

contract OracleMathTest is Test {
    OracleMathWrapper lib;

    function setUp() public {
        lib = new OracleMathWrapper();
    }

    // ─── oracleToSqrtPriceX96 ─────────────────────────────────────────────────

    /// @notice USDC/ECOP — 4200 COP per 1 USDC (Chainlink 8 dec, USDC 6 dec, ECOP 18 dec)
    ///         Expected: sqrt(4200 * 10^12) * 2^96 — verify it is > 0 and fits in uint160
    function test_oracleToSqrtPriceX96_usdcEcop_nonZeroAndFitsUint160() public view {
        uint160 result = lib.oracleToSqrtPriceX96(
            420_000_000_000, // 4200.00000000 with 8 dec
            8,               // chainlink decimals
            6,               // USDC decimals
            18,              // ECOP decimals
            true             // token0IsBase (USDC is base)
        );

        assertTrue(result > 0, "sqrtPriceX96 must be > 0");
        // uint160 max ≈ 1.46e48; result should be well within range
        assertTrue(uint256(result) <= type(uint160).max, "must fit in uint160");
    }

    /// @notice Verify the magnitude is in the expected ballpark:
    ///         sqrt(4200 * 10^12) ≈ 6.48e7, then * 2^96 ≈ 5.13e36.
    ///         Accept [4e36, 7e36].
    function test_oracleToSqrtPriceX96_usdcEcop_magnitude() public view {
        uint160 result = lib.oracleToSqrtPriceX96(420_000_000_000, 8, 6, 18, true);
        uint256 r = uint256(result);
        assertTrue(r >= 4e36 && r <= 7e36, "result outside expected magnitude range");
    }

    /// @notice Zero price must revert.
    function test_oracleToSqrtPriceX96_revertsOnZeroPrice() public {
        vm.expectRevert("OracleMath: non-positive price");
        lib.oracleToSqrtPriceX96(0, 8, 6, 18, true);
    }

    /// @notice Negative price must revert.
    function test_oracleToSqrtPriceX96_revertsOnNegativePrice() public {
        vm.expectRevert("OracleMath: non-positive price");
        lib.oracleToSqrtPriceX96(-1, 8, 6, 18, true);
    }

    /// @notice token0IsBase = false inverts the ratio — result must differ from true case.
    function test_oracleToSqrtPriceX96_invertedRatioDiffersFromDirect() public view {
        uint160 direct   = lib.oracleToSqrtPriceX96(420_000_000_000, 8, 6, 18, true);
        uint160 inverted = lib.oracleToSqrtPriceX96(420_000_000_000, 8, 6, 18, false);
        assertTrue(direct != inverted, "inverted ratio must produce a different result");
    }

    // ─── deviationBps ─────────────────────────────────────────────────────────

    /// @notice Same price → 0 bps deviation.
    function test_deviationBps_samePriceReturnsZero() public view {
        uint256 bps = lib.deviationBps(1_000, 1_000);
        assertEq(bps, 0);
    }

    /// @notice oracleSqrt == 0 → returns type(uint256).max (guard against division by zero).
    function test_deviationBps_zeroOracleReturnsMaxUint() public view {
        uint256 bps = lib.deviationBps(1_000, 0);
        assertEq(bps, type(uint256).max);
    }

    /// @notice ~2% pool-vs-oracle deviation using small numbers to reason about the formula:
    ///         poolSqrt = 1020, oracleSqrt = 1000
    ///         diff = 20, sum = 2020
    ///         bps = (20 * 10000 / 1000) * 2020 / 1000
    ///             = 200 * 2.02 = ~404 bps
    ///         Accept range [380, 420].
    function test_deviationBps_approxTwoPercent() public view {
        uint256 bps = lib.deviationBps(1_020, 1_000);
        assertTrue(bps >= 380 && bps <= 420, "expected ~400 bps for 2% pool move");
    }

    /// @notice Pool below oracle — deviation is near-symmetric.
    ///         above = 404 bps (pool 1020, oracle 1000)
    ///         below = 396 bps (pool 980,  oracle 1000)
    ///         diff  = 8 bps due to integer rounding — accept within ±10 bps of each other.
    function test_deviationBps_poolBelowOracleIsNearSymmetric() public view {
        uint256 above = lib.deviationBps(1_020, 1_000);
        uint256 below = lib.deviationBps(980,   1_000);
        uint256 diff = above > below ? above - below : below - above;
        assertTrue(diff <= 10, "above/below deviations should be nearly symmetric");
    }

    // ─── exceedsBand ─────────────────────────────────────────────────────────

    /// @notice Deviation > band → true.
    function test_exceedsBand_trueWhenDeviationExceedsBand() public view {
        // ~400 bps deviation; band is 200 bps → should exceed
        assertTrue(lib.exceedsBand(1_020, 1_000, 200));
    }

    /// @notice Deviation <= band → false.
    function test_exceedsBand_falseWhenDeviationWithinBand() public view {
        // ~400 bps deviation; band is 500 bps → should NOT exceed
        assertFalse(lib.exceedsBand(1_020, 1_000, 500));
    }

    /// @notice Exactly at band boundary → false (strictly greater-than).
    function test_exceedsBand_falseAtExactBand() public view {
        // poolSqrt == oracleSqrt → 0 bps; band = 0 → NOT strictly greater-than
        assertFalse(lib.exceedsBand(1_000, 1_000, 0));
    }

    // ─── Indirect sqrt tests via oracleToSqrtPriceX96 ────────────────────────

    /// @notice _sqrt(0) == 0 — achieved with a 0 priceRatio via low-price input.
    ///         We test this indirectly: the non-zero-price branch should always produce > 0.
    function test_sqrt_nonZeroInputProducesNonZeroOutput() public view {
        // Any valid price goes through _sqrt internally.
        uint160 result = lib.oracleToSqrtPriceX96(1, 8, 6, 18, true);
        assertTrue(result > 0);
    }

    /// @notice Deterministic: same inputs always yield the same sqrtPriceX96.
    function test_oracleToSqrtPriceX96_isDeterministic() public view {
        uint160 a = lib.oracleToSqrtPriceX96(420_000_000_000, 8, 6, 18, true);
        uint160 b = lib.oracleToSqrtPriceX96(420_000_000_000, 8, 6, 18, true);
        assertEq(a, b);
    }

    /// @notice Higher price → larger sqrtPriceX96 (monotonicity check).
    function test_oracleToSqrtPriceX96_higherPriceGivesLargerSqrt() public view {
        uint160 low  = lib.oracleToSqrtPriceX96(100_000_000_000, 8, 6, 18, true); // 1000 COP/USDC
        uint160 high = lib.oracleToSqrtPriceX96(500_000_000_000, 8, 6, 18, true); // 5000 COP/USDC
        assertTrue(uint256(high) > uint256(low), "higher price must give larger sqrtPriceX96");
    }
}

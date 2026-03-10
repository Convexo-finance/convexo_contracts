// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title OracleMath
/// @notice Converts Chainlink oracle prices to Uniswap V4 sqrtPriceX96 format
///         and computes pool-vs-oracle price deviations.
///
/// ── Math background ──────────────────────────────────────────────────────────
///
/// Uniswap V4 stores pool price as:
///   sqrtPriceX96 = sqrt(token1_units / token0_units) * 2^96
///
/// Chainlink gives: localCurrency per base (e.g. 4200 COP per 1 USDC)
///   with chainlinkDec decimal places.
///
/// For USDC/ECOP pool (token0=USDC 6dec, token1=ECOP 18dec, Chainlink 8dec):
///
///   priceRatio = chainlinkPrice * 10^(token1Dec - token0Dec) / 10^chainlinkDec
///              = 420000000000  * 10^(18 - 6)              / 10^8
///              = 4200 * 10^12
///              = 4.2e15   (ECOP raw units per USDC raw unit)
///
///   sqrtPriceX96 = sqrt(4.2e15) * 2^96
///                ≈ 64,807,407 * 2^96
///                ≈ 5.13e36   (fits in uint160, max ~1.46e48 ✓)
///
/// ─────────────────────────────────────────────────────────────────────────────
library OracleMath {
    uint256 internal constant Q96 = 1 << 96;

    // ─── sqrtPriceX96 conversion ──────────────────────────────────────────────

    /// @notice Convert a Chainlink price feed value to Uniswap V4 sqrtPriceX96.
    ///
    /// @param chainlinkPrice  Raw answer from latestRoundData() — must be > 0
    /// @param chainlinkDec    Decimal places of the Chainlink feed (typically 8)
    /// @param token0Dec       Decimals of token0 in the V4 pool (USDC = 6)
    /// @param token1Dec       Decimals of token1 in the V4 pool (ECOP = 18)
    /// @param token0IsBase    true  → Chainlink gives token1 per token0 (e.g. COP per USDC)
    ///                        false → Chainlink gives token0 per token1 (invert the ratio)
    ///
    /// @return sqrtPriceX96   Uniswap V4 pool price, uint160
    function oracleToSqrtPriceX96(
        int256 chainlinkPrice,
        uint8 chainlinkDec,
        uint8 token0Dec,
        uint8 token1Dec,
        bool token0IsBase
    ) internal pure returns (uint160 sqrtPriceX96) {
        require(chainlinkPrice > 0, "OracleMath: non-positive price");

        uint256 price = uint256(chainlinkPrice);

        // priceRatio = chainlinkPrice * 10^token1Dec / (10^chainlinkDec * 10^token0Dec)
        //
        // Avoid overflow: multiply numerator decimals first if larger than denominator,
        // divide first if smaller.
        //
        // numExp   = token1Dec           (if token0IsBase)
        // denExp   = chainlinkDec + token0Dec
        //
        // ratioX192 = priceRatio * Q96^2
        //           = price * 10^numExp / 10^denExp * Q96^2
        //           = price * Q96^2 * 10^numExp / 10^denExp

        uint256 numExp = token0IsBase ? token1Dec : token0Dec;
        uint256 denExp = token0IsBase
            ? uint256(chainlinkDec) + token0Dec
            : uint256(chainlinkDec) + token1Dec;

        // Build ratioX192 = price * Q96 * Q96 * 10^numExp / 10^denExp
        // Order of operations chosen to stay within uint256 throughout:
        //   max price ≈ 1e12 (realistic FX), Q96 ≈ 7.9e28
        //   price * Q96 ≈ 7.9e40 → safe
        //   * Q96 again ≈ 6.3e69 → safe (uint256 max ≈ 1.16e77)
        //   * 10^numExp (up to 10^18) ≈ 6.3e87 → OVERFLOW risk for large tokens
        //
        // Safe strategy: multiply by 10^numExp before Q96^2 when numExp > denExp,
        //                divide by 10^denExp after Q96^2 otherwise.

        uint256 ratioX192;
        if (numExp >= denExp) {
            uint256 scaleFactor = _pow10(numExp - denExp);
            // price * scaleFactor * Q96 * Q96
            // Concrete: 420000000000 * 10000 * Q96 * Q96 ≈ 2.63e73 ✓
            ratioX192 = price * scaleFactor * Q96 * Q96;
        } else {
            uint256 scaleFactor = _pow10(denExp - numExp);
            // (price * Q96 / scaleFactor) * Q96
            // Divide before second Q96 multiply to stay in range.
            ratioX192 = (price * Q96 / scaleFactor) * Q96;
        }

        // sqrtPriceX96 = sqrt(ratioX192) = sqrt(priceRatio * Q96^2) = sqrt(priceRatio) * Q96
        uint256 sq = _sqrt(ratioX192);

        if (!token0IsBase) {
            // Chainlink price was token0 per token1 → sqrtPrice was for inverted ratio.
            // Invert: sqrtPriceX96_correct = Q96^2 / sqrtPriceX96_inverted
            sq = (Q96 * Q96) / sq;
        }

        sqrtPriceX96 = uint160(sq);
    }

    // ─── Deviation ────────────────────────────────────────────────────────────

    /// @notice Compute price deviation between pool and oracle in basis points.
    ///
    /// Uses: |p_pool - p_oracle| / p_oracle * 10000
    ///     = |(s_pool^2 - s_oracle^2)| / s_oracle^2 * 10000
    ///     = |(s_pool - s_oracle)(s_pool + s_oracle)| / s_oracle^2 * 10000
    ///
    /// @param poolSqrt    Current pool sqrtPriceX96 (from StateLibrary.getSlot0)
    /// @param oracleSqrt  Oracle sqrtPriceX96 (from oracleToSqrtPriceX96)
    /// @return bps        Deviation in basis points (200 = 2.00%)
    function deviationBps(uint160 poolSqrt, uint160 oracleSqrt) internal pure returns (uint256 bps) {
        if (oracleSqrt == 0) return type(uint256).max;

        uint256 p = uint256(poolSqrt);
        uint256 o = uint256(oracleSqrt);

        uint256 diff = p > o ? p - o : o - p;
        uint256 sum  = p + o;

        // diff * sum * 10000 / (o * o)
        // Max values: diff ≈ o (100% deviation), sum ≈ 2*o
        // diff * sum * 10000 ≈ o * 2o * 10000 = 20000 * o^2
        // o = sqrtPriceX96 ≈ 5e36 for our pool → o^2 ≈ 2.5e73
        // 20000 * 2.5e73 = 5e77 > uint256 max (1.16e77) — potential overflow for extreme cases.
        //
        // Safe: (diff * 10000 / o) * sum / o — rearranging to divide first.
        bps = (diff * 10_000 / o) * sum / o;
    }

    /// @notice True if pool price deviates from oracle by more than bandBps.
    function exceedsBand(uint160 poolSqrt, uint160 oracleSqrt, uint24 bandBps)
        internal pure returns (bool)
    {
        return deviationBps(poolSqrt, oracleSqrt) > bandBps;
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    /// @dev Babylonian integer sqrt. Returns floor(sqrt(x)).
    function _sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 y = (x >> 1) + 1;
        while (y < z) {
            z = y;
            y = (x / y + y) >> 1;
        }
    }

    /// @dev 10^n. Supports n up to 36 (covers all realistic decimal combinations).
    function _pow10(uint256 n) internal pure returns (uint256 result) {
        result = 1;
        for (uint256 i; i < n; i++) {
            result *= 10;
        }
    }
}

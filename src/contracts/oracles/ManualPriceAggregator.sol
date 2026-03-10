// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";

/// @title ManualPriceAggregator
/// @notice IAggregatorV3-compatible price source where admin sets the price manually.
///
/// Phase 1 (MVP): Admin sets USDC/COP price daily (or on significant moves).
/// Phase 2: This contract is replaced by a real Chainlink aggregator address.
///          PriceFeedManager.setPriceFeed(pair, chainlinkAddress, heartbeat)
///          — no other code changes needed.
///
/// Usage:
///   1. Deploy ManualPriceAggregator(admin, 8, "USDC / COP")
///   2. Call priceFeedManager.setPriceFeed(USDC_COP, address(this), 26 hours)
///   3. Call setPrice(420000000000) to set 4,200.00000000 COP per USDC
///   4. Call setPrice(newPrice) whenever rate changes
contract ManualPriceAggregator is IAggregatorV3, AccessControl {
    bytes32 public constant PRICE_SETTER_ROLE = keccak256("PRICE_SETTER_ROLE");

    uint8 private immutable _decimals;
    string private _description;  // not immutable — strings are reference types

    int256 private _latestAnswer;
    uint256 private _latestTimestamp;
    uint80 private _latestRound;

    event PriceUpdated(uint80 indexed roundId, int256 price, uint256 timestamp);

    error PriceMustBePositive();
    error PriceNotSet();

    /// @param admin          Address that can set prices and manage roles
    /// @param decimals_      Decimal places for the price (use 8 to match Chainlink standard)
    /// @param description_   Human-readable label, e.g. "USDC / COP"
    constructor(address admin, uint8 decimals_, string memory description_) {
        _decimals = decimals_;
        _description = description_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PRICE_SETTER_ROLE, admin);
    }

    /// @notice Update the price. Call this whenever the USDC/COP rate changes.
    /// @param price New price with `decimals()` decimal places.
    ///              Example: 4,200 COP/USDC with 8 decimals → 420000000000
    function setPrice(int256 price) external onlyRole(PRICE_SETTER_ROLE) {
        if (price <= 0) revert PriceMustBePositive();
        _latestRound++;
        _latestAnswer = price;
        _latestTimestamp = block.timestamp;
        emit PriceUpdated(_latestRound, price, block.timestamp);
    }

    // ─── IAggregatorV3 ────────────────────────────────────────────────────────

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        if (_latestRound == 0) revert PriceNotSet();
        return (_latestRound, _latestAnswer, _latestTimestamp, _latestTimestamp, _latestRound);
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // Single-round storage — only latest round available
        require(_roundId == _latestRound, "Round not available");
        return (_latestRound, _latestAnswer, _latestTimestamp, _latestTimestamp, _latestRound);
    }
}

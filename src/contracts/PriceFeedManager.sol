// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

/// @title PriceFeedManager
/// @notice Manages Chainlink price feeds for currency conversions
/// @dev Integrates USDC/COP and USDC/CHF feeds for multi-currency pricing
contract PriceFeedManager is AccessControl {
    bytes32 public constant PRICE_UPDATER_ROLE = keccak256("PRICE_UPDATER_ROLE");

    /// @notice Price feed information
    struct PriceFeed {
        IAggregatorV3 aggregator;
        uint8 decimals;
        string description;
        bool isActive;
        uint256 heartbeat; // Maximum time between updates
    }

    /// @notice Supported currency pairs
    enum CurrencyPair {
        USDC_COP, // Colombian Peso
        USDC_CHF, // Swiss Franc
        USDC_ARS, // Argentine Peso
        USDC_MXN // Mexican Peso
    }

    /// @notice Mapping from currency pair to price feed
    mapping(CurrencyPair => PriceFeed) public priceFeeds;

    /// @notice Maximum price staleness allowed (in seconds)
    uint256 public constant MAX_STALENESS = 1 hours;

    /// @notice Emitted when a price feed is added or updated
    event PriceFeedUpdated(CurrencyPair indexed pair, address indexed aggregator, string description);

    /// @notice Emitted when a price feed is deactivated
    event PriceFeedDeactivated(CurrencyPair indexed pair);

    /// @notice Error when price is stale
    error StalePriceData();

    /// @notice Error when price feed is not active
    error PriceFeedNotActive();

    /// @notice Error when price is invalid
    error InvalidPrice();

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PRICE_UPDATER_ROLE, admin);
    }

    /// @notice Set a price feed for a currency pair
    /// @param pair The currency pair
    /// @param aggregatorAddress The Chainlink aggregator address
    /// @param heartbeat The maximum time between updates in seconds
    function setPriceFeed(CurrencyPair pair, address aggregatorAddress, uint256 heartbeat)
        external
        onlyRole(PRICE_UPDATER_ROLE)
    {
        require(aggregatorAddress != address(0), "Invalid aggregator address");

        IAggregatorV3 aggregator = IAggregatorV3(aggregatorAddress);
        uint8 decimals = aggregator.decimals();
        string memory description = aggregator.description();

        priceFeeds[pair] = PriceFeed({
            aggregator: aggregator,
            decimals: decimals,
            description: description,
            isActive: true,
            heartbeat: heartbeat
        });

        emit PriceFeedUpdated(pair, aggregatorAddress, description);
    }

    /// @notice Deactivate a price feed
    /// @param pair The currency pair to deactivate
    function deactivatePriceFeed(CurrencyPair pair) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceFeeds[pair].isActive = false;
        emit PriceFeedDeactivated(pair);
    }

    /// @notice Get the latest price for a currency pair
    /// @param pair The currency pair
    /// @return price The latest price
    /// @return decimals The number of decimals in the price
    function getLatestPrice(CurrencyPair pair) public view returns (int256 price, uint8 decimals) {
        PriceFeed memory feed = priceFeeds[pair];
        if (!feed.isActive) revert PriceFeedNotActive();

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.aggregator.latestRoundData();

        // Check if price is stale
        if (block.timestamp - updatedAt > feed.heartbeat) revert StalePriceData();

        // Check if price is valid
        if (answer <= 0) revert InvalidPrice();
        if (answeredInRound < roundId) revert StalePriceData();

        return (answer, feed.decimals);
    }

    /// @notice Convert USDC amount to local currency
    /// @param pair The currency pair
    /// @param usdcAmount The amount in USDC (6 decimals)
    /// @return localAmount The amount in local currency
    function convertUSDCToLocal(CurrencyPair pair, uint256 usdcAmount) external view returns (uint256 localAmount) {
        (int256 price, uint8 decimals) = getLatestPrice(pair);

        // USDC has 6 decimals
        // Price is in local currency per USDC
        // localAmount = usdcAmount * price / (10^decimals)
        localAmount = (usdcAmount * uint256(price)) / (10 ** decimals);
    }

    /// @notice Convert local currency amount to USDC
    /// @param pair The currency pair
    /// @param localAmount The amount in local currency
    /// @return usdcAmount The amount in USDC (6 decimals)
    function convertLocalToUSDC(CurrencyPair pair, uint256 localAmount) external view returns (uint256 usdcAmount) {
        (int256 price, uint8 decimals) = getLatestPrice(pair);

        // USDC has 6 decimals
        // Price is in local currency per USDC
        // usdcAmount = localAmount * (10^decimals) / price
        usdcAmount = (localAmount * (10 ** decimals)) / uint256(price);
    }

    /// @notice Get price feed information
    /// @param pair The currency pair
    /// @return Price feed struct
    function getPriceFeed(CurrencyPair pair) external view returns (PriceFeed memory) {
        return priceFeeds[pair];
    }

    /// @notice Check if a price feed is active
    /// @param pair The currency pair
    /// @return True if active, false otherwise
    function isPriceFeedActive(CurrencyPair pair) external view returns (bool) {
        return priceFeeds[pair].isActive;
    }

    /// @notice Get price with timestamp
    /// @param pair The currency pair
    /// @return price The latest price
    /// @return decimals The number of decimals
    /// @return updatedAt The timestamp of the last update
    function getPriceWithTimestamp(CurrencyPair pair)
        external
        view
        returns (int256 price, uint8 decimals, uint256 updatedAt)
    {
        PriceFeed memory feed = priceFeeds[pair];
        if (!feed.isActive) revert PriceFeedNotActive();

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) =
            feed.aggregator.latestRoundData();

        // Check if price is valid
        if (answer <= 0) revert InvalidPrice();
        if (answeredInRound < roundId) revert StalePriceData();

        return (answer, feed.decimals, timestamp);
    }
}


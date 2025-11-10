// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {PriceFeedManager} from "../src/contracts/PriceFeedManager.sol";

contract DeployPriceFeedManager is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (PriceFeedManager) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        PriceFeedManager priceFeedManager = new PriceFeedManager(ADMIN);

        vm.stopBroadcast();

        return priceFeedManager;
    }
}

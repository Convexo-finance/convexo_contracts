// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {TokenizedBondCredits} from "../src/contracts/TokenizedBondCredits.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {PriceFeedManager} from "../src/contracts/PriceFeedManager.sol";

contract DeployTokenizedBondCredits is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (TokenizedBondCredits) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address reputationManager = vm.envAddress("REPUTATION_MANAGER_ADDRESS");
        address priceFeedManager = vm.envAddress("PRICE_FEED_MANAGER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        TokenizedBondCredits tokenizedBondCredits = new TokenizedBondCredits(
            ADMIN,
            ReputationManager(reputationManager),
            PriceFeedManager(priceFeedManager)
        );
        console.log("TokenizedBondCredits deployed at:", address(tokenizedBondCredits));
        
        vm.stopBroadcast();
        
        return tokenizedBondCredits;
    }
}

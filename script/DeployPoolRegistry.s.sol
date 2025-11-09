// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {PoolRegistry} from "../src/contracts/PoolRegistry.sol";

contract DeployPoolRegistry is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (PoolRegistry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        PoolRegistry poolRegistry = new PoolRegistry(ADMIN);
        console.log("PoolRegistry deployed at:", address(poolRegistry));
        
        vm.stopBroadcast();
        
        return poolRegistry;
    }
}

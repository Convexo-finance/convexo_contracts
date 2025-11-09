// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {HookDeployer} from "../src/hooks/HookDeployer.sol";

contract DeployHookDeployer is Script {
    function run() public returns (HookDeployer) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        HookDeployer hookDeployer = new HookDeployer();
        console.log("HookDeployer deployed at:", address(hookDeployer));
        
        vm.stopBroadcast();
        
        return hookDeployer;
    }
}

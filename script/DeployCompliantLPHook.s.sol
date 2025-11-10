// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {CompliantLPHook} from "../src/hooks/CompliantLPHook.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";

contract DeployCompliantLPHook is Script {
    function run() public returns (CompliantLPHook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address convexoLPs = vm.envAddress("CONVEXO_LPS_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        CompliantLPHook hook = new CompliantLPHook(IPoolManager(poolManager), IConvexoLPs(convexoLPs));
        console.log("CompliantLPHook deployed at:", address(hook));

        vm.stopBroadcast();

        return hook;
    }
}

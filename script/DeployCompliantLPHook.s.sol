// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {CompliantLPHook} from "../src/hooks/CompliantLPHook.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";

/// @title DeployCompliantLPHook
/// @notice Deploys the CompliantLPHook for gating LP access to Passport holders
contract DeployCompliantLPHook is Script {
    function run() public returns (CompliantLPHook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address convexoPassport = vm.envAddress("CONVEXO_PASSPORT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        CompliantLPHook hook = new CompliantLPHook(
            IPoolManager(poolManager),
            IConvexoPassport(convexoPassport)
        );
        console.log("CompliantLPHook deployed at:", address(hook));
        console.log("Using PoolManager:", poolManager);
        console.log("Using ConvexoPassport:", convexoPassport);

        vm.stopBroadcast();

        return hook;
    }
}

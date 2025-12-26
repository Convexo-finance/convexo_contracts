// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";

contract DeployReputationManager is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (ReputationManager) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address convexoLPs = vm.envAddress("CONVEXO_LPS_ADDRESS");
        address convexoVaults = vm.envAddress("CONVEXO_VAULTS_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Note: This script needs Convexo_Passport address for full deployment
        // For now, using a placeholder address
        address convexoPassport = address(0x1234567890123456789012345678901234567890);
        
        ReputationManager reputationManager = new ReputationManager(
            IConvexoLPs(convexoLPs),
            IConvexoVaults(convexoVaults),
            IConvexoPassport(convexoPassport)
        );

        vm.stopBroadcast();

        return reputationManager;
    }
}

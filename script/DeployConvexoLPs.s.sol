// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {Convexo_LPs} from "../src/convexolps.sol";

contract DeployConvexoLPs is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (Convexo_LPs) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.envAddress("MINTER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        Convexo_LPs nft = new Convexo_LPs(ADMIN, minter);

        vm.stopBroadcast();

        return nft;
    }
}


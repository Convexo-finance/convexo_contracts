// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {Convexo_Vaults} from "../src/convexovaults.sol";

contract DeployConvexoVaults is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (Convexo_Vaults) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.envAddress("MINTER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        Convexo_Vaults nft = new Convexo_Vaults(ADMIN, minter);

        vm.stopBroadcast();

        return nft;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {InvoiceFactoring} from "../src/contracts/InvoiceFactoring.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";

contract DeployInvoiceFactoring is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (InvoiceFactoring) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address reputationManager = vm.envAddress("REPUTATION_MANAGER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        InvoiceFactoring invoiceFactoring = new InvoiceFactoring(
            ADMIN,
            ReputationManager(reputationManager)
        );
        console.log("InvoiceFactoring deployed at:", address(invoiceFactoring));
        
        vm.stopBroadcast();
        
        return invoiceFactoring;
    }
}

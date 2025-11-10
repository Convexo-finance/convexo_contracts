// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";

contract DeployContractSigner is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (ContractSigner) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ContractSigner contractSigner = new ContractSigner(ADMIN);
        console.log("ContractSigner deployed at:", address(contractSigner));

        vm.stopBroadcast();

        return contractSigner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";

contract DeployVaultFactory is Script {
    address public constant ADMIN = 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8;

    function run() public returns (VaultFactory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address contractSigner = vm.envAddress("CONTRACT_SIGNER_ADDRESS");
        address usdc = vm.envAddress("USDC_ADDRESS");
        address protocolFeeCollector = vm.envAddress("PROTOCOL_FEE_COLLECTOR");

        vm.startBroadcast(deployerPrivateKey);

        VaultFactory vaultFactory = new VaultFactory(ADMIN, usdc, protocolFeeCollector, ContractSigner(contractSigner));
        console.log("VaultFactory deployed at:", address(vaultFactory));

        vm.stopBroadcast();

        return vaultFactory;
    }
}

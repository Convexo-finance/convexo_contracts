// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Limited_Partners_Individuals} from "../src/contracts/identity/Limited_Partners_Individuals.sol";

/// @title MintTestNFT
/// @notice Mints an LP_Individuals NFT to the deployer wallet on testnet.
///
/// PURPOSE: testnet only. The deployer needs a Convexo tier NFT to interact with
/// PassportGatedHook pools (add liquidity, swap). In production, users earn NFTs
/// via Veriff KYC. On testnet the admin can self-mint using MINTER_ROLE.
///
/// MINTER_ROLE is held by the deployer (MINTER_ADDRESS in deploy script = admin).
///
/// Usage:
///   LP_INDIVIDUALS_ADDRESS=<from addresses.json> \
///   RECIPIENT=<wallet to receive NFT, defaults to deployer> \
///   forge script script/MintTestNFT.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
///
/// To mint on multiple chains, run once per chain with the right RPC + address.
contract MintTestNFT is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer  = vm.addr(deployerPrivateKey);
        address lpAddress = vm.envAddress("LP_INDIVIDUALS_ADDRESS");
        address recipient = vm.envOr("RECIPIENT", deployer);

        console.log("\n========================================");
        console.log("MINT TEST LP_INDIVIDUALS NFT");
        console.log("========================================");
        console.log("Network:", block.chainid);
        console.log("LP_Individuals contract:", lpAddress);
        console.log("Minter (deployer):", deployer);
        console.log("Recipient:", recipient);

        Limited_Partners_Individuals lp = Limited_Partners_Individuals(lpAddress);

        // Check if recipient already holds the NFT
        if (lp.balanceOf(recipient) > 0) {
            console.log("Recipient already holds LP_Individuals NFT. Skipping.");
            return;
        }

        vm.broadcast(deployerPrivateKey);
        lp.safeMint(
            recipient,
            "testnet-verification-id",   // verificationId — not validated on testnet
            ""                           // tokenURI — empty for testnet
        );

        console.log("LP_Individuals NFT minted to:", recipient);
        console.log("Recipient can now add liquidity and swap via PassportGatedHook.");
        console.log("========================================\n");
    }
}

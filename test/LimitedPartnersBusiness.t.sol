// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";

contract LimitedPartnersBusinessTest is Test {
    Limited_Partners_Business public nft;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    function setUp() public {
        nft = new Limited_Partners_Business(admin, minter);
    }

    function test_Mint() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            "ipfs://metadata"
        );

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertTrue(nft.getTokenState(tokenId));
        assertEq(nft.getCompanyName(tokenId), "Acme Corp");
    }

    function test_MintFails_NotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );
    }

    function test_Soulbound_TransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );

        vm.prank(user1);
        vm.expectRevert(Limited_Partners_Business.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_GetBusinessInfo_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            "Acme Corp",
            "REG123456",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );

        vm.prank(admin);
        Limited_Partners_Business.BusinessInfo memory info = nft.getBusinessInfo(tokenId);
        assertEq(info.companyName, "Acme Corp");
        assertEq(info.registrationNumber, "REG123456");
    }
}


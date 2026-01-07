// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";

contract LimitedPartnersIndividualsTest is Test {
    Limited_Partners_Individuals public nft;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    string public constant VERIFF_SESSION = "veriff_session_123";
    string public constant TOKEN_URI = "ipfs://metadata";

    function setUp() public {
        nft = new Limited_Partners_Individuals(admin, minter);
    }

    function test_Mint() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.tokenURI(tokenId), TOKEN_URI);
        assertTrue(nft.getTokenState(tokenId));
    }

    function test_MintFails_NotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);
    }

    function test_Soulbound_TransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Limited_Partners_Individuals.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_SetTokenState_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        assertTrue(nft.getTokenState(tokenId));

        vm.prank(admin);
        nft.setTokenState(tokenId, false);
        assertFalse(nft.getTokenState(tokenId));
    }

    function test_GetVerificationId_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, VERIFF_SESSION, TOKEN_URI);

        vm.prank(admin);
        string memory vId = nft.getVerificationId(tokenId);
        assertEq(vId, VERIFF_SESSION);
    }

    function test_SupportsInterface() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
    }
}


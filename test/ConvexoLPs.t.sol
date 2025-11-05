// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Convexo_LPs} from "../src/convexolps.sol";

contract ConvexoLPsTest is Test {
    Convexo_LPs public nft;
    address public admin = address(0x3f9b734394FC1E96afe9523c69d30D227dF4ffca);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    string public constant COMPANY_ID = "COMP123456";
    string public constant TOKEN_URI = "ipfs://bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em";

    function setUp() public {
        nft = new Convexo_LPs(admin, minter);
    }

    function test_Mint() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.tokenURI(tokenId), TOKEN_URI);
        assertTrue(nft.getTokenState(tokenId));
    }

    function test_MintFails_NotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(user1, COMPANY_ID, TOKEN_URI);
    }

    function test_Soulbound_TransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Convexo_LPs.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_Soulbound_SafeTransferFromReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Convexo_LPs.SoulboundToken.selector);
        nft.safeTransferFrom(user1, user2, tokenId);
    }

    function test_Soulbound_SafeTransferFromWithDataReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Convexo_LPs.SoulboundToken.selector);
        nft.safeTransferFrom(user1, user2, tokenId, "");
    }

    function test_Soulbound_ApproveReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Convexo_LPs.SoulboundToken.selector);
        nft.approve(user2, tokenId);
    }

    function test_Soulbound_SetApprovalForAllReverts() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert(Convexo_LPs.SoulboundToken.selector);
        nft.setApprovalForAll(user2, true);
    }

    function test_SetTokenState_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        assertTrue(nft.getTokenState(tokenId));

        vm.prank(admin);
        nft.setTokenState(tokenId, false);
        assertFalse(nft.getTokenState(tokenId));

        vm.prank(admin);
        nft.setTokenState(tokenId, true);
        assertTrue(nft.getTokenState(tokenId));
    }

    function test_SetTokenState_Fails_NotAdmin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert();
        nft.setTokenState(tokenId, false);
    }

    function test_SetTokenState_Fails_NonExistentToken() public {
        vm.prank(admin);
        vm.expectRevert();
        nft.setTokenState(999, false);
    }

    function test_GetCompanyId_Admin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(admin);
        string memory companyId = nft.getCompanyId(tokenId);
        assertEq(companyId, COMPANY_ID);
    }

    function test_GetCompanyId_Fails_NotAdmin() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        vm.expectRevert();
        nft.getCompanyId(tokenId);
    }

    function test_GetCompanyId_Fails_NonExistentToken() public {
        vm.prank(admin);
        vm.expectRevert();
        nft.getCompanyId(999);
    }

    function test_GetTokenState() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        assertTrue(nft.getTokenState(tokenId));

        vm.prank(admin);
        nft.setTokenState(tokenId, false);
        assertFalse(nft.getTokenState(tokenId));
    }

    function test_GetTokenState_Fails_NonExistentToken() public {
        vm.expectRevert();
        nft.getTokenState(999);
    }

    function test_MultipleMints() public {
        vm.startPrank(minter);
        uint256 tokenId1 = nft.safeMint(user1, "COMP001", TOKEN_URI);
        uint256 tokenId2 = nft.safeMint(user2, "COMP002", TOKEN_URI);
        uint256 tokenId3 = nft.safeMint(user1, "COMP003", TOKEN_URI);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId1), user1);
        assertEq(nft.ownerOf(tokenId2), user2);
        assertEq(nft.ownerOf(tokenId3), user1);
        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
    }

    function test_Burn() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(user1, COMPANY_ID, TOKEN_URI);

        vm.prank(user1);
        nft.burn(tokenId);

        vm.expectRevert();
        nft.ownerOf(tokenId);
    }

    function test_SupportsInterface() public {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(nft.supportsInterface(0x5b5e139f)); // ERC721Metadata
        assertTrue(nft.supportsInterface(0x7965db0b)); // AccessControl
    }
}


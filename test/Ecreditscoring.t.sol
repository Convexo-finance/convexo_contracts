// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Ecreditscoring} from "../src/contracts/Ecreditscoring.sol";
import {Limited_Partners_Individuals} from "../src/contracts/Limited_Partners_Individuals.sol";
import {Limited_Partners_Business} from "../src/contracts/Limited_Partners_Business.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EcreditscoringTest is Test {
    Ecreditscoring public nft;
    Limited_Partners_Individuals public lpIndividuals;
    Limited_Partners_Business public lpBusiness;
    
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3); // Individual LP holder
    address public user2 = address(0x4); // Business LP holder
    address public user3 = address(0x5); // No LP holder

    function setUp() public {
        // Deploy LP NFTs
        lpIndividuals = new Limited_Partners_Individuals(admin, minter);
        lpBusiness = new Limited_Partners_Business(admin, minter);
        
        // Deploy Ecreditscoring
        nft = new Ecreditscoring(
            admin,
            minter,
            IERC721(address(lpIndividuals)),
            IERC721(address(lpBusiness))
        );
        
        // Mint LP NFTs to users
        vm.startPrank(minter);
        lpIndividuals.safeMint(user1, "veriff_123", "");
        lpBusiness.safeMint(
            user2,
            "Acme Corp",
            "REG123",
            "US-DE",
            Limited_Partners_Business.BusinessType.Corporation,
            "sumsub_123",
            ""
        );
        vm.stopPrank();
    }

    function test_MintToIndividualLP() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            750, // score
            Ecreditscoring.CreditTier.Gold,
            1000000e6, // max loan amount
            "ref_123",
            "ipfs://metadata"
        );

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        
        Ecreditscoring.CreditInfo memory info = nft.getCreditInfo(tokenId);
        assertEq(info.score, 750);
        assertEq(uint(info.tier), uint(Ecreditscoring.CreditTier.Gold));
    }

    function test_MintToBusinessLP() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user2,
            850,
            Ecreditscoring.CreditTier.Platinum,
            5000000e6,
            "ref_456",
            ""
        );

        assertEq(nft.ownerOf(tokenId), user2);
    }

    function test_MintFails_NoLPNFT() public {
        vm.prank(minter);
        vm.expectRevert(Ecreditscoring.MustHoldLPNFT.selector);
        nft.safeMint(
            user3, // no LP NFT
            500,
            Ecreditscoring.CreditTier.Bronze,
            100000e6,
            "ref_789",
            ""
        );
    }

    function test_HasLPStatus() public view {
        assertTrue(nft.hasLPStatus(user1));
        assertTrue(nft.hasLPStatus(user2));
        assertFalse(nft.hasLPStatus(user3));
    }

    function test_CanReceiveEcreditscoringNFT() public view {
        assertTrue(nft.canReceiveEcreditscoringNFT(user1));
        assertTrue(nft.canReceiveEcreditscoringNFT(user2));
        assertFalse(nft.canReceiveEcreditscoringNFT(user3));
    }

    function test_UpdateCreditInfo() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            700,
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            ""
        );

        vm.prank(minter);
        nft.updateCreditInfo(
            tokenId,
            850,
            Ecreditscoring.CreditTier.Platinum,
            2000000e6,
            "ref_updated"
        );

        Ecreditscoring.CreditInfo memory info = nft.getCreditInfo(tokenId);
        assertEq(info.score, 850);
        assertEq(uint(info.tier), uint(Ecreditscoring.CreditTier.Platinum));
    }

    function test_Soulbound() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            700,
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            ""
        );

        vm.prank(user1);
        vm.expectRevert(Ecreditscoring.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }
}


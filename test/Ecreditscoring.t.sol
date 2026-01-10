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
        // Deploy LP NFTs (with address(0) verifier for basic tests)
        lpIndividuals = new Limited_Partners_Individuals(admin, minter, address(0));
        lpBusiness = new Limited_Partners_Business(admin, minter, address(0));
        
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
            75, // score (0-100 scale)
            Ecreditscoring.CreditTier.Gold,
            1000000e6, // max loan amount
            "ref_123",
            "ipfs://metadata"
        );

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);

        Ecreditscoring.CreditInfo memory info = nft.getCreditInfo(tokenId);
        assertEq(info.score, 75);
        assertEq(uint(info.tier), uint(Ecreditscoring.CreditTier.Gold));
    }

    function test_MintToBusinessLP() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user2,
            85, // score (0-100 scale)
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
            50, // score (0-100 scale)
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
            70, // score (0-100 scale)
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            ""
        );

        uint256 originalTimestamp = block.timestamp;
        Ecreditscoring.CreditInfo memory infoBefore = nft.getCreditInfo(tokenId);
        assertEq(infoBefore.scoredAt, originalTimestamp);

        // Move forward in time
        vm.warp(block.timestamp + 30 days);
        uint256 newTimestamp = block.timestamp;

        vm.prank(minter);
        nft.updateCreditInfo(
            tokenId,
            85, // updated score (0-100 scale)
            Ecreditscoring.CreditTier.Platinum,
            2000000e6,
            "ref_updated",
            newTimestamp // editable validation date
        );

        Ecreditscoring.CreditInfo memory info = nft.getCreditInfo(tokenId);
        assertEq(info.score, 85);
        assertEq(uint(info.tier), uint(Ecreditscoring.CreditTier.Platinum));
        assertEq(info.scoredAt, newTimestamp);
        assertEq(info.maxLoanAmount, 2000000e6);
        assertEq(info.referenceId, "ref_updated");
    }

    function test_Soulbound() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            70, // score (0-100 scale)
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            ""
        );

        vm.prank(user1);
        vm.expectRevert(Ecreditscoring.SoulboundToken.selector);
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_OneNFTPerAddress_SecondMintFails() public {
        // Mint first Ecreditscoring NFT to user1 (who has LP Individual NFT)
        vm.prank(minter);
        nft.safeMint(
            user1,
            75, // score (0-100 scale)
            Ecreditscoring.CreditTier.Gold,
            1000000e6,
            "ref_123",
            "ipfs://metadata"
        );

        // Try to mint second Ecreditscoring NFT to same user1 - should fail
        vm.prank(minter);
        vm.expectRevert(Ecreditscoring.AlreadyHoldsNFT.selector);
        nft.safeMint(
            user1,
            85, // score (0-100 scale)
            Ecreditscoring.CreditTier.Platinum,
            2000000e6,
            "ref_456",
            "ipfs://metadata2"
        );
    }

    function test_OneNFTPerAddress_DifferentUsersCanMint() public {
        // Mint Ecreditscoring NFT to user1 (Individual LP holder)
        vm.prank(minter);
        uint256 tokenId1 = nft.safeMint(
            user1,
            75, // score (0-100 scale)
            Ecreditscoring.CreditTier.Gold,
            1000000e6,
            "ref_123",
            "ipfs://metadata"
        );

        // Mint Ecreditscoring NFT to user2 (Business LP holder) - should succeed
        vm.prank(minter);
        uint256 tokenId2 = nft.safeMint(
            user2,
            85, // score (0-100 scale)
            Ecreditscoring.CreditTier.Platinum,
            5000000e6,
            "ref_456",
            "ipfs://metadata2"
        );

        assertEq(nft.ownerOf(tokenId1), user1);
        assertEq(nft.ownerOf(tokenId2), user2);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
    }

    function test_OneNFTPerAddress_AfterBurnCanMintAgain() public {
        // Mint first Ecreditscoring NFT to user1
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            70, // score (0-100 scale)
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            "ipfs://metadata"
        );

        // Burn the NFT
        vm.prank(user1);
        nft.burn(tokenId);

        assertEq(nft.balanceOf(user1), 0);

        // Mint new Ecreditscoring NFT to user1 - should succeed after burn
        vm.prank(minter);
        uint256 newTokenId = nft.safeMint(
            user1,
            90, // score (0-100 scale)
            Ecreditscoring.CreditTier.Platinum,
            3000000e6,
            "ref_789",
            "ipfs://metadata3"
        );

        assertEq(nft.ownerOf(newTokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function test_MintFails_ScoreAbove100() public {
        vm.prank(minter);
        vm.expectRevert("Credit score must be between 0 and 100");
        nft.safeMint(
            user1,
            150, // Invalid score > 100
            Ecreditscoring.CreditTier.Platinum,
            5000000e6,
            "ref_invalid",
            ""
        );
    }

    function test_UpdateCreditInfo_FailsScoreAbove100() public {
        vm.prank(minter);
        uint256 tokenId = nft.safeMint(
            user1,
            70,
            Ecreditscoring.CreditTier.Silver,
            500000e6,
            "ref_123",
            ""
        );

        vm.prank(minter);
        vm.expectRevert("Credit score must be between 0 and 100");
        nft.updateCreditInfo(
            tokenId,
            150, // Invalid score > 100
            Ecreditscoring.CreditTier.Platinum,
            2000000e6,
            "ref_updated",
            block.timestamp
        );
    }
}


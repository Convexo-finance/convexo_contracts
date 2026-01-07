// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Ecreditscoring NFT
/// @notice Soulbound NFT for users with AI Credit Score approval
/// @dev Tier 3 NFT - Required to create loan vaults and tokenized bonds
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// PREREQUISITES FOR MINTING:
/// ═══════════════════════════════════════════════════════════════════════════════
/// 1. User must hold EITHER:
///    - Limited_Partners_Individuals NFT (Veriff verified individual), OR
///    - Limited_Partners_Business NFT (Sumsub verified business)
/// 2. User must pass AI Credit Scoring process
/// 3. Backend calls safeMint after both conditions are met
///
/// MINTING FLOW:
/// 1. Limited Partner requests credit scoring
/// 2. AI Credit Scoring service analyzes creditworthiness
/// 3. On approval, backend mints Ecreditscoring NFT
/// 4. User can now create loan vaults and tokenized bonds
///
/// ACCESS GRANTED:
/// - All Tier 2 benefits (LP Pools, Treasury, Investment)
/// - Create and manage loan vaults
/// - Create tokenized bonds
/// ═══════════════════════════════════════════════════════════════════════════════
contract Ecreditscoring is ERC721, ERC721Burnable, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;

    /// @notice The Limited Partners Individuals NFT contract
    IERC721 public immutable lpIndividuals;
    
    /// @notice The Limited Partners Business NFT contract
    IERC721 public immutable lpBusiness;

    enum TokenState {
        Active,
        NonActive
    }

    /// @notice Credit score tier
    enum CreditTier {
        None,       // 0 - Not scored
        Bronze,     // 1 - Basic credit
        Silver,     // 2 - Good credit
        Gold,       // 3 - Excellent credit
        Platinum    // 4 - Premium credit
    }

    /// @notice Credit score information
    struct CreditInfo {
        CreditTier tier;
        uint256 score;          // 0-1000 scale
        uint256 maxLoanAmount;  // Maximum loan amount in USDC (6 decimals)
        uint256 scoredAt;       // Timestamp of scoring
        string referenceId;     // External reference ID
    }

    /// @notice Mapping from token ID to token state
    mapping(uint256 => TokenState) private _tokenStates;
    
    /// @notice Mapping from token ID to credit information
    mapping(uint256 => CreditInfo) private _creditInfo;

    error SoulboundToken();
    error MustHoldLPNFT();

    /// @notice Constructor
    /// @param defaultAdmin Address to receive DEFAULT_ADMIN_ROLE
    /// @param minter Address to receive MINTER_ROLE (backend credit scoring service)
    /// @param _lpIndividuals Limited Partners Individuals NFT contract address
    /// @param _lpBusiness Limited Partners Business NFT contract address
    constructor(
        address defaultAdmin,
        address minter,
        IERC721 _lpIndividuals,
        IERC721 _lpBusiness
    ) ERC721("Ecreditscoring", "ECREDIT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        lpIndividuals = _lpIndividuals;
        lpBusiness = _lpBusiness;
    }

    /// @notice Check if an address holds any LP NFT (Individual or Business)
    /// @param user Address to check
    /// @return True if user holds any LP NFT
    function hasLPStatus(address user) public view returns (bool) {
        return lpIndividuals.balanceOf(user) > 0 || lpBusiness.balanceOf(user) > 0;
    }

    /// @notice Check if an address can receive an Ecreditscoring NFT
    /// @param user Address to check
    /// @return True if user holds any LP NFT
    function canReceiveEcreditscoringNFT(address user) external view returns (bool) {
        return hasLPStatus(user);
    }

    /// @notice Mint a new Ecreditscoring NFT
    /// @param to Address to mint to (must hold LP NFT)
    /// @param score Credit score (0-1000)
    /// @param tier Credit tier
    /// @param maxLoanAmount Maximum loan amount allowed
    /// @param referenceId External reference ID from credit scoring service
    /// @param uri Token metadata URI
    /// @return tokenId The minted token ID
    function safeMint(
        address to,
        uint256 score,
        CreditTier tier,
        uint256 maxLoanAmount,
        string memory referenceId,
        string memory uri
    )
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        // Require user to have LP NFT (Individual or Business)
        if (!hasLPStatus(to)) {
            revert MustHoldLPNFT();
        }
        
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenStates[tokenId] = TokenState.Active;
        _creditInfo[tokenId] = CreditInfo({
            tier: tier,
            score: score,
            maxLoanAmount: maxLoanAmount,
            scoredAt: block.timestamp,
            referenceId: referenceId
        });
        return tokenId;
    }

    /// @notice Set token state (active/inactive)
    /// @param tokenId Token ID to update
    /// @param isActive True for active, false for inactive
    function setTokenState(uint256 tokenId, bool isActive) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _tokenStates[tokenId] = isActive ? TokenState.Active : TokenState.NonActive;
    }

    /// @notice Get token state
    /// @param tokenId Token ID to query
    /// @return True if active, false if inactive
    function getTokenState(uint256 tokenId) public view returns (bool) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenStates[tokenId] == TokenState.Active;
    }

    /// @notice Get credit information for a token
    /// @param tokenId Token ID to query
    /// @return info The credit information
    function getCreditInfo(uint256 tokenId) public view returns (CreditInfo memory info) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _creditInfo[tokenId];
    }

    /// @notice Get credit tier for a token
    /// @param tokenId Token ID to query
    /// @return The credit tier
    function getCreditTier(uint256 tokenId) public view returns (CreditTier) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _creditInfo[tokenId].tier;
    }

    /// @notice Get maximum loan amount for a token
    /// @param tokenId Token ID to query
    /// @return The maximum loan amount
    function getMaxLoanAmount(uint256 tokenId) public view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _creditInfo[tokenId].maxLoanAmount;
    }

    /// @notice Update credit information for a token (for re-scoring)
    /// @param tokenId Token ID to update
    /// @param score New credit score
    /// @param tier New credit tier
    /// @param maxLoanAmount New maximum loan amount
    /// @param referenceId New reference ID
    function updateCreditInfo(
        uint256 tokenId,
        uint256 score,
        CreditTier tier,
        uint256 maxLoanAmount,
        string memory referenceId
    ) public onlyRole(MINTER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _creditInfo[tokenId] = CreditInfo({
            tier: tier,
            score: score,
            maxLoanAmount: maxLoanAmount,
            scoredAt: block.timestamp,
            referenceId: referenceId
        });
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // SOULBOUND: Override transfer functions to prevent transfers
    // ═══════════════════════════════════════════════════════════════════════════════

    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert SoulboundToken();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721, IERC721) {
        revert SoulboundToken();
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert SoulboundToken();
    }

    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert SoulboundToken();
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // REQUIRED OVERRIDES
    // ═══════════════════════════════════════════════════════════════════════════════

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}


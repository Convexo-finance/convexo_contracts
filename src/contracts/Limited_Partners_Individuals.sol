// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Limited Partners Individuals NFT
/// @notice Soulbound NFT for individual Limited Partners verified via Veriff
/// @dev Tier 2 NFT - Individual KYC verification
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// MINTING FLOW:
/// ═══════════════════════════════════════════════════════════════════════════════
/// 1. Individual completes Veriff identity verification
/// 2. Backend receives verification result
/// 3. VeriffVerifier contract calls safeMint on approval
/// 4. User receives Limited Partners Individuals NFT
///
/// ACCESS GRANTED:
/// - LP Pools (via PassportGatedHook)
/// - Treasury creation and management
/// - Investment in vaults
/// - Can request Credit Score for Ecreditscoring NFT (Tier 3)
/// ═══════════════════════════════════════════════════════════════════════════════
contract Limited_Partners_Individuals is ERC721, ERC721Burnable, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;

    enum TokenState {
        Active,
        NonActive
    }

    /// @notice Mapping from token ID to token state
    mapping(uint256 => TokenState) private _tokenStates;
    
    /// @notice Mapping from token ID to verification ID (Veriff session ID)
    mapping(uint256 => string) private _verificationIds;

    error SoulboundToken();

    /// @notice Constructor
    /// @param defaultAdmin Address to receive DEFAULT_ADMIN_ROLE
    /// @param minter Address to receive MINTER_ROLE (typically VeriffVerifier contract)
    constructor(address defaultAdmin, address minter) ERC721("Limited_Partners_Individuals", "LPI") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Mint a new Limited Partners Individuals NFT
    /// @param to Address to mint to
    /// @param verificationId The Veriff session ID used for verification
    /// @param uri Token metadata URI
    /// @return tokenId The minted token ID
    function safeMint(address to, string memory verificationId, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenStates[tokenId] = TokenState.Active;
        _verificationIds[tokenId] = verificationId;
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

    /// @notice Get verification ID for a token (admin only)
    /// @param tokenId Token ID to query
    /// @return The Veriff session ID
    function getVerificationId(uint256 tokenId) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _verificationIds[tokenId];
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


// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Convexo_Vaults is ERC721, ERC721Burnable, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;

    enum TokenState {
        Active,
        NonActive
    }

    mapping(uint256 => TokenState) private _tokenStates;
    mapping(uint256 => string) private _companyIds;

    error SoulboundToken();

    constructor(address defaultAdmin, address minter)
        ERC721("Convexo_vaults", "CNXVaults")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function safeMint(
        address to,
        string memory companyId,
        string memory uri
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenStates[tokenId] = TokenState.Active;
        _companyIds[tokenId] = companyId;
        return tokenId;
    }

    function setTokenState(uint256 tokenId, bool isActive)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _tokenStates[tokenId] = isActive ? TokenState.Active : TokenState.NonActive;
    }

    function getTokenState(uint256 tokenId) public view returns (bool) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenStates[tokenId] == TokenState.Active;
    }

    function getCompanyId(uint256 tokenId)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (string memory)
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _companyIds[tokenId];
    }

    // Soulbound: Override transfer functions to prevent transfers
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

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
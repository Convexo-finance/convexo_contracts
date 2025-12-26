// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IConvexoPassport} from "../interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, ProofVerificationParams, DisclosedData} from "../interfaces/IZKPassportVerifier.sol";

/// @title Convexo_Passport
/// @notice Soulbound NFT for individual investors verified via ZKPassport
/// @dev Non-transferable ERC721 NFT that represents verified identity for Tier 3 (Passport) access
contract Convexo_Passport is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl, IConvexoPassport {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");

    /// @notice The ZKPassport verifier contract
    IZKPassportVerifier public immutable zkPassportVerifier;

    /// @notice Counter for token IDs
    uint256 private _nextTokenId;

    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    /// @notice Mapping from unique identifier to address (prevents duplicate passports)
    mapping(bytes32 => address) private passportIdentifierToAddress;

    /// @notice Mapping from address to verified identity
    mapping(address => VerifiedIdentity) private verifiedUsers;

    /// @notice Total number of active passports
    uint256 private activePassportCount;

    /// @notice Error thrown when trying to transfer a soulbound token
    error SoulboundTokenCannotBeTransferred();

    /// @notice Error thrown when ZKPassport proof verification fails
    error ProofVerificationFailed();

    /// @notice Error thrown when user already has a passport
    error AlreadyHasPassport();

    /// @notice Error thrown when unique identifier is already used
    error IdentifierAlreadyUsed();

    /// @notice Error thrown when user doesn't meet age requirements
    error MustBeOver18();

    /// @notice Error thrown when passport is not active
    error PassportNotActive();

    /// @notice Constructor
    /// @param admin The admin address
    /// @param _zkPassportVerifier The ZKPassport verifier contract address
    /// @param initialBaseURI The initial base URI for token metadata
    constructor(
        address admin,
        address _zkPassportVerifier,
        string memory initialBaseURI
    ) ERC721("Convexo Passport", "CPASS") {
        require(admin != address(0), "Invalid admin address");
        require(_zkPassportVerifier != address(0), "Invalid verifier address");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(REVOKER_ROLE, admin);

        zkPassportVerifier = IZKPassportVerifier(_zkPassportVerifier);
        _baseTokenURI = initialBaseURI;
    }

    /// @inheritdoc IConvexoPassport
    function safeMintWithZKPassport(
        ProofVerificationParams calldata params,
        bool isIDCard
    ) external returns (uint256 tokenId) {
        // Check if user already has a passport
        if (balanceOf(msg.sender) > 0) {
            revert AlreadyHasPassport();
        }

        // Verify the ZKPassport proof
        (bool success, DisclosedData memory disclosedData) = zkPassportVerifier.verifyProof(params, isIDCard);
        if (!success) {
            revert ProofVerificationFailed();
        }

        // Check age requirement
        if (!disclosedData.isOver18) {
            revert MustBeOver18();
        }

        // Generate unique identifier (hash of public key + scope)
        bytes32 uniqueIdentifier = keccak256(abi.encodePacked(params.publicKey, params.scope));

        // Check if identifier has been used
        if (passportIdentifierToAddress[uniqueIdentifier] != address(0)) {
            revert IdentifierAlreadyUsed();
        }

        // Mint the passport NFT
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseTokenURI, "/", _toString(tokenId))));

        // Store verified identity
        verifiedUsers[msg.sender] = VerifiedIdentity({
            uniqueIdentifier: uniqueIdentifier,
            verifiedAt: block.timestamp,
            isActive: true,
            nationality: disclosedData.nationality
        });

        // Map identifier to address
        passportIdentifierToAddress[uniqueIdentifier] = msg.sender;

        // Increment active passport count
        activePassportCount++;

        emit PassportMinted(msg.sender, tokenId, uniqueIdentifier, disclosedData.nationality);
    }

    /// @inheritdoc IConvexoPassport
    function safeMint(address to, string memory uri) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        require(to != address(0), "Cannot mint to zero address");
        
        if (balanceOf(to) > 0) {
            revert AlreadyHasPassport();
        }

        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Create a basic verified identity for admin-minted passports
        bytes32 uniqueIdentifier = keccak256(abi.encodePacked(to, block.timestamp));
        verifiedUsers[to] = VerifiedIdentity({
            uniqueIdentifier: uniqueIdentifier,
            verifiedAt: block.timestamp,
            isActive: true,
            nationality: "ADMIN_MINT"
        });

        passportIdentifierToAddress[uniqueIdentifier] = to;
        activePassportCount++;

        emit PassportMinted(to, tokenId, uniqueIdentifier, "ADMIN_MINT");
    }

    /// @inheritdoc IConvexoPassport
    function revokePassport(uint256 tokenId) external onlyRole(REVOKER_ROLE) {
        address holder = ownerOf(tokenId);
        VerifiedIdentity storage identity = verifiedUsers[holder];

        if (!identity.isActive) {
            revert PassportNotActive();
        }

        identity.isActive = false;
        activePassportCount--;

        emit PassportRevoked(holder, tokenId, identity.uniqueIdentifier);
    }

    /// @inheritdoc IConvexoPassport
    function holdsActivePassport(address holder) external view returns (bool) {
        return balanceOf(holder) > 0 && verifiedUsers[holder].isActive;
    }

    /// @inheritdoc IConvexoPassport
    function getVerifiedIdentity(address holder) external view returns (VerifiedIdentity memory) {
        return verifiedUsers[holder];
    }

    /// @inheritdoc IConvexoPassport
    function isIdentifierUsed(bytes32 uniqueIdentifier) external view returns (bool) {
        return passportIdentifierToAddress[uniqueIdentifier] != address(0);
    }

    /// @inheritdoc IConvexoPassport
    function getActivePassportCount() external view returns (uint256) {
        return activePassportCount;
    }

    /// @notice Override to make tokens soulbound (non-transferable)
    function _update(address to, uint256 tokenId, address auth) 
        internal 
        override(ERC721)
        returns (address) 
    {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0)) and burning (to == address(0))
        // But prevent transfers between addresses
        if (from != address(0) && to != address(0)) {
            revert SoulboundTokenCannotBeTransferred();
        }
        
        return super._update(to, tokenId, auth);
    }

    /// @notice Set base URI for token metadata
    /// @param newBaseURI The new base URI
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseURI;
    }

    /// @notice Get base URI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Override required by Solidity for multiple inheritance
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Helper function to convert uint to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

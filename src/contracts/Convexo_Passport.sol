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
/// @dev Non-transferable ERC721 NFT that represents verified identity for Tier 1 (Passport) access
///      Privacy-compliant: stores only verification results (traits), no PII stored on-chain.
///      ZKPassport verification is the source of truth - we store the boolean verification results.
///      
///      STORED TRAITS (non-PII):
///      - kycVerified: Overall KYC verification passed
///      - faceMatchPassed: Face match verification result  
///      - sanctionsPassed: Sanctions check result (US, UK, EU, Switzerland)
///      - isOver18: Age verification result
///      
///      DIFFERENT FROM:
///      - Convexo_LPs (Tier 2): Verified via Veriff/Sumsub human KYC → VeriffVerifier contract
///      - Convexo_Vaults (Tier 3): Verified via KYB Sumsub for businesses → allows vault creation
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

    /// @notice Mapping from address to verified identity (stores ZKPassport outputs)
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
    /// @dev Verifies ZKPassport proof and stores verification results (traits) only.
    ///      Privacy-compliant: no PII stored, only boolean verification results.
    ///      Stored traits: kycVerified, faceMatchPassed, sanctionsPassed, isOver18
    function safeMintWithZKPassport(
        ProofVerificationParams calldata params,
        bool isIDCard
    ) external returns (uint256 tokenId) {
        // Check if user already has a passport
        if (balanceOf(msg.sender) > 0) {
            revert AlreadyHasPassport();
        }

        // Verify the ZKPassport proof - this is the ONLY validation needed
        // ZKPassport handles all identity verification (face match, sanctions, age)
        (bool success, DisclosedData memory disclosedData) = zkPassportVerifier.verifyProof(params, isIDCard);
        if (!success) {
            revert ProofVerificationFailed();
        }

        // Generate unique identifier from ZKPassport proof params
        // UNIQUE ID = hash(publicKey + scope) - ensures 1 person = 1 passport
        bytes32 uniqueIdentifier = keccak256(abi.encodePacked(params.publicKey, params.scope));

        // Check if identifier has been used (sybil resistance)
        if (passportIdentifierToAddress[uniqueIdentifier] != address(0)) {
            revert IdentifierAlreadyUsed();
        }

        // Mint the passport NFT
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseTokenURI, "/", _toString(tokenId))));

        // Store ZKPassport verification results as traits (no PII)
        verifiedUsers[msg.sender] = VerifiedIdentity({
            // Cryptographic identifiers (sybil resistance)
            uniqueIdentifier: uniqueIdentifier,
            personhoodProof: params.nullifier,
            // Timestamps
            verifiedAt: block.timestamp,
            zkPassportTimestamp: disclosedData.verifiedAt,
            // Status
            isActive: true,
            // ZKPassport verification results (boolean traits - no PII)
            kycVerified: disclosedData.kycVerified,
            faceMatchPassed: disclosedData.faceMatchPassed,
            sanctionsPassed: disclosedData.sanctionsPassed,
            isOver18: disclosedData.isOver18
        });

        // Map identifier to address (sybil resistance)
        passportIdentifierToAddress[uniqueIdentifier] = msg.sender;

        // Increment active passport count
        activePassportCount++;

        // Emit privacy-compliant event (only verification traits, no PII)
        emit PassportMinted(
            msg.sender, 
            tokenId, 
            uniqueIdentifier, 
            params.nullifier,
            disclosedData.kycVerified,
            disclosedData.faceMatchPassed,
            disclosedData.sanctionsPassed,
            disclosedData.isOver18
        );
    }

    /// @notice Self-mint a passport using unique identifier from ZKPassport (simplified approach)
    /// @param uniqueIdentifier The unique identifier from ZKPassport verification (off-chain)
    /// @return tokenId The minted token ID
    /// @dev This function allows users to mint after off-chain ZKPassport verification
    ///      The unique identifier ensures: 1 wallet = 1 unique identifier
    ///      All verification traits assumed true for off-chain verified users
    function safeMintWithIdentifier(bytes32 uniqueIdentifier) external returns (uint256 tokenId) {
        // Check if user already has a passport
        if (balanceOf(msg.sender) > 0) {
            revert AlreadyHasPassport();
        }

        // Check if identifier has been used (prevents duplicate passports)
        if (passportIdentifierToAddress[uniqueIdentifier] != address(0)) {
            revert IdentifierAlreadyUsed();
        }

        // Mint the passport NFT
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseTokenURI, "/", _toString(tokenId))));

        // Store verified identity (off-chain verification - all traits assumed true)
        verifiedUsers[msg.sender] = VerifiedIdentity({
            uniqueIdentifier: uniqueIdentifier,
            personhoodProof: bytes32(0),
            verifiedAt: block.timestamp,
            zkPassportTimestamp: 0,
            isActive: true,
            // Off-chain verified: assume all checks passed
            kycVerified: true,
            faceMatchPassed: true,
            sanctionsPassed: true,
            isOver18: true
        });

        // Map identifier to address (1 wallet = 1 unique identifier)
        passportIdentifierToAddress[uniqueIdentifier] = msg.sender;

        // Increment active passport count
        activePassportCount++;

        // Emit with all traits as true (off-chain verified)
        emit PassportMinted(msg.sender, tokenId, uniqueIdentifier, bytes32(0), true, true, true, true);
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
            personhoodProof: bytes32(0), // Admin mint - no ZKPassport proof
            verifiedAt: block.timestamp,
            zkPassportTimestamp: 0,
            isActive: true,
            // Admin mint: assume all checks passed
            kycVerified: true,
            faceMatchPassed: true,
            sanctionsPassed: true,
            isOver18: true
        });

        passportIdentifierToAddress[uniqueIdentifier] = to;
        activePassportCount++;

        // Emit with all traits as true (admin verified)
        emit PassportMinted(to, tokenId, uniqueIdentifier, bytes32(0), true, true, true, true);
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

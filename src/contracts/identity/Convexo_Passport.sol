// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IConvexoPassport} from "../../interfaces/IConvexoPassport.sol";
import {IZKPassportVerifier, IZKPassportHelper, ProofVerificationParams, BoundData} from "../../interfaces/IZKPassportVerifier.sol";

/// @title Convexo_Passport
/// @notice Soulbound NFT for identity-verified investors — trustless ZKPassport self-claim
/// @dev Non-transferable ERC721. The ONLY minting path is claimPassport() which
///      submits a ZKPassport ZK proof verified on-chain. No admin can mint on behalf of a user.
///
///      Security guarantees:
///      - uniqueIdentifier from verifier (cryptographic sybil resistance, not caller input)
///      - msg.sender bound in proof (no proxy minting)
///      - block.chainid bound in proof (no cross-chain replay)
///      - Age >= 18 verified by ZK circuit (no birthdate stored)
///      - Sanctions validated against US/UK/EU/CH lists
///      - Nationality not in sanctioned countries (alphabetically sorted list)
///      - Passport/ID not expired
///      Privacy-compliant: only boolean traits stored on-chain, zero PII.
contract Convexo_Passport is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl, IConvexoPassport {
    // ─── Roles ────────────────────────────────────────────────────────────

    bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");

    // ─── ZKPassport ───────────────────────────────────────────────────────

    /// @notice ZKPassport verifier: 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8
    IZKPassportVerifier public immutable ZKPASSPORT_VERIFIER;

    /// @notice Service domain bound into every proof (must match SDK queryBuilder domain)
    string public constant APP_DOMAIN = "protocol.convexo.xyz";

    /// @notice Service scope bound into every proof (must match SDK request scope)
    string public constant APP_SCOPE = "convexo-passport-identity";

    // ─── State ────────────────────────────────────────────────────────────

    uint256 private _nextTokenId;
    string private _baseTokenURI;

    /// @notice uniqueIdentifier → holder address (sybil resistance)
    mapping(bytes32 => address) private passportIdentifierToAddress;

    /// @notice holder → verified identity traits
    mapping(address => VerifiedIdentity) private verifiedUsers;

    uint256 private activePassportCount;

    // ─── Errors ───────────────────────────────────────────────────────────

    error SoulboundTokenCannotBeTransferred();
    error ProofVerificationFailed();
    error InvalidScope();
    error InvalidSender();
    error InvalidChain();
    error AgeVerificationFailed();
    error SanctionsCheckFailed();
    error NationalityNotCompliant();
    error PassportExpired();
    error AlreadyHasPassport();
    error IdentifierAlreadyUsed();
    error PassportNotActive();

    // ─── Constructor ──────────────────────────────────────────────────────

    constructor(
        address admin,
        string memory initialBaseURI,
        address _zkPassportVerifier
    ) ERC721("Convexo Passport", "CPASS") {
        require(admin != address(0), "Invalid admin");
        require(_zkPassportVerifier != address(0), "Invalid verifier");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REVOKER_ROLE, admin);

        _baseTokenURI = initialBaseURI;
        ZKPASSPORT_VERIFIER = IZKPassportVerifier(_zkPassportVerifier);
    }

    // ─── Core: trustless self-claim ───────────────────────────────────────

    /// @inheritdoc IConvexoPassport
    function claimPassport(
        ProofVerificationParams calldata zkParams,
        bool isIDCard,
        string calldata ipfsMetadataHash
    ) external returns (uint256 tokenId) {
        // 1. On-chain ZK proof verification
        (bool verified, bytes32 uniqueIdentifier, IZKPassportHelper helper) =
            ZKPASSPORT_VERIFIER.verify(zkParams);
        if (!verified) revert ProofVerificationFailed();

        // 2. Domain + scope binding (proof is for Convexo, not another service)
        if (!helper.verifyScopes(
            zkParams.proofVerificationData.publicInputs,
            APP_DOMAIN,
            APP_SCOPE
        )) revert InvalidScope();

        // 3. Sender binding (proof belongs to exactly this caller — no proxy minting)
        BoundData memory bound = helper.getBoundData(zkParams.committedInputs);
        if (bound.senderAddress != msg.sender) revert InvalidSender();

        // 4. Chain binding (no cross-chain replay attacks)
        if (bound.chainId != block.chainid) revert InvalidChain();

        // 5. Age >= 18 (ZK-proven, no birthdate disclosed)
        bool isOver18 = helper.isAgeAboveOrEqual(18, zkParams.committedInputs);
        if (!isOver18) revert AgeVerificationFailed();

        // 6. Sanctions check (US, UK, EU, CH lists) — use proof timestamp not block.timestamp
        uint256 proofTimestamp = helper.getProofTimestamp(
            zkParams.proofVerificationData.publicInputs
        );
        bool sanctionsPassed = helper.isSanctionsRootValid(
            proofTimestamp,
            false, // non-strict: standard sanctions lists
            zkParams.committedInputs
        );
        if (!sanctionsPassed) revert SanctionsCheckFailed();

        // 7. Nationality exclusion — not from a sanctioned country
        //    List MUST be sorted alphabetically (ZKPassport requirement)
        bool nationalityCompliant = helper.isNationalityOut(
            _getSanctionedCountries(),
            zkParams.committedInputs
        );
        if (!nationalityCompliant) revert NationalityNotCompliant();

        // 8. Document not expired
        if (!helper.isExpiryDateAfterOrEqual(block.timestamp, zkParams.committedInputs)) {
            revert PassportExpired();
        }

        // 9. Sybil resistance — uniqueIdentifier from verifier (cryptographic, not caller input)
        if (passportIdentifierToAddress[uniqueIdentifier] != address(0)) revert IdentifierAlreadyUsed();
        if (balanceOf(msg.sender) > 0) revert AlreadyHasPassport();

        // 10. Mint
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        if (bytes(ipfsMetadataHash).length > 0) {
            _setTokenURI(
                tokenId,
                string(abi.encodePacked(
                    "https://lime-famous-condor-7.mypinata.cloud/ipfs/",
                    ipfsMetadataHash
                ))
            );
        }

        // 11. Store enriched identity (4-doc coverage: personhood + age + kyc + nationality)
        verifiedUsers[msg.sender] = VerifiedIdentity({
            identifierHash:      uniqueIdentifier,
            personhoodProof:     zkParams.proofVerificationData.vkeyHash,
            verifiedAt:          block.timestamp,
            zkPassportTimestamp: proofTimestamp,
            isActive:            true,
            kycVerified:         sanctionsPassed && isOver18,
            sanctionsPassed:     sanctionsPassed,
            isOver18:            isOver18,
            nationalityCompliant: nationalityCompliant
        });

        passportIdentifierToAddress[uniqueIdentifier] = msg.sender;
        activePassportCount++;

        emit PassportMinted(
            msg.sender,
            tokenId,
            uniqueIdentifier,
            zkParams.proofVerificationData.vkeyHash,
            sanctionsPassed && isOver18,
            sanctionsPassed,
            isOver18
        );
    }

    // ─── Admin ────────────────────────────────────────────────────────────

    /// @inheritdoc IConvexoPassport
    function revokePassport(uint256 tokenId) external onlyRole(REVOKER_ROLE) {
        address holder = ownerOf(tokenId);
        VerifiedIdentity storage identity = verifiedUsers[holder];
        if (!identity.isActive) revert PassportNotActive();
        identity.isActive = false;
        activePassportCount--;
        emit PassportRevoked(holder, tokenId, identity.identifierHash);
    }

    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseURI;
    }

    /// @notice Clear a passport identifier mapping (DEFAULT_ADMIN_ROLE only).
    /// @dev Needed for testnet: all ZKPassport devMode proofs produce uniqueIdentifier = bytes32(1).
    ///      Once any address mints with a mock passport, the identifier is permanently locked and
    ///      no other mock passport can ever mint. This lets admin clear it for re-testing.
    ///      On mainnet, each real passport has a cryptographically unique identifier and
    ///      this function is never needed.
    function clearIdentifier(bytes32 identifierHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete passportIdentifierToAddress[identifierHash];
    }

    // ─── Views ────────────────────────────────────────────────────────────

    /// @inheritdoc IConvexoPassport
    function holdsActivePassport(address holder) external view returns (bool) {
        return balanceOf(holder) > 0 && verifiedUsers[holder].isActive;
    }

    /// @inheritdoc IConvexoPassport
    function getVerifiedIdentity(address holder) external view returns (VerifiedIdentity memory) {
        return verifiedUsers[holder];
    }

    /// @inheritdoc IConvexoPassport
    function isIdentifierUsed(bytes32 identifierHash) external view returns (bool) {
        return passportIdentifierToAddress[identifierHash] != address(0);
    }

    /// @inheritdoc IConvexoPassport
    function getActivePassportCount() external view returns (uint256) {
        return activePassportCount;
    }

    // ─── Sanctioned countries list ────────────────────────────────────────

    /// @notice Returns the sanctioned countries list sorted alphabetically (ZKPassport requirement)
    /// @dev Matches SANCTIONED_COUNTRIES from @zkpassport/sdk
    function _getSanctionedCountries() internal pure returns (string[] memory) {
        string[] memory countries = new string[](20);
        countries[0]  = "AFG";
        countries[1]  = "BLR";
        countries[2]  = "CAF";
        countries[3]  = "COD";
        countries[4]  = "CUB";
        countries[5]  = "IRN";
        countries[6]  = "IRQ";
        countries[7]  = "LBY";
        countries[8]  = "MLI";
        countries[9]  = "MMR";
        countries[10] = "NIC";
        countries[11] = "PRK";
        countries[12] = "RUS";
        countries[13] = "SDN";
        countries[14] = "SOM";
        countries[15] = "SSD";
        countries[16] = "SYR";
        countries[17] = "VEN";
        countries[18] = "YEM";
        countries[19] = "ZWE";
        return countries;
    }

    // ─── Soulbound overrides ──────────────────────────────────────────────

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) revert SoulboundTokenCannotBeTransferred();
        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert SoulboundTokenCannotBeTransferred();
    }

    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert SoulboundTokenCannotBeTransferred();
    }

    // ─── ERC721 overrides ─────────────────────────────────────────────────

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IConvexoPassport} from "../interfaces/IConvexoPassport.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ReputationManager
/// @notice Manages NFT-based reputation tiers for users
/// @dev Checks all 4 NFT types to determine user access level
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// NFT SYSTEM (4 NFTs) - Progressive Verification Flow:
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// 1. CONVEXO PASSPORT (Tier 1) - Convexo_Passport.sol
///    └─ Verification: ZKPassport (International KYC)
///    └─ Purpose: Basic identity verification for international users
///    └─ Access: LP pools, Treasury, Invest in vaults
///
/// 2. LIMITED PARTNERS - INDIVIDUALS (Tier 2) - Limited_Partners_Individuals.sol
///    └─ Verification: Veriff (Individual KYC)
///    └─ Purpose: Verified individuals who can request loans
///    └─ Access: LP pools, Treasury, Invest + Can REQUEST Credit Score
///
/// 3. LIMITED PARTNERS - BUSINESS (Tier 2) - Limited_Partners_Business.sol
///    └─ Verification: Sumsub (Business KYB)
///    └─ Purpose: Verified businesses who can request loans
///    └─ Access: LP pools, Treasury, Invest + Can REQUEST Credit Score
///
/// 4. ECREDITSCORING (Tier 3) - Ecreditscoring.sol
///    └─ Verification: AI Credit Scoring
///    └─ Prerequisite: MUST hold LP NFT first (Individual OR Business)
///    └─ Purpose: Can CREATE loan vaults and tokenized bonds
///    └─ Access: All Tier 2 benefits + Vault/Bond creation
///
/// ═══════════════════════════════════════════════════════════════════════════════
/// ACCESS MATRIX:
/// ═══════════════════════════════════════════════════════════════════════════════
/// | NFT                  | LP Pools | Treasury | Invest | Request Credit | Create Vaults |
/// |----------------------|----------|----------|--------|----------------|---------------|
/// | Passport             | ✓        | ✓        | ✓      | ✗              | ✗             |
/// | LP Individuals       | ✓        | ✓        | ✓      | ✓              | ✗             |
/// | LP Business          | ✓        | ✓        | ✓      | ✓              | ✗             |
/// | Ecreditscoring       | ✓        | ✓        | ✓      | ✓              | ✓             |
/// ═══════════════════════════════════════════════════════════════════════════════
contract ReputationManager {
    /// @notice Reputation tiers - Progressive verification system
    /// Tier 0: No NFTs - No access
    /// Tier 1: Passport NFT - ZKPassport (International KYC)
    /// Tier 2: LP NFT - Veriff (Individual) OR Sumsub (Business)
    /// Tier 3: Ecreditscoring NFT - AI Credit Score (Can create vaults)
    enum ReputationTier {
        None,            // 0 - No NFTs
        Passport,        // 1 - Convexo_Passport (ZKPassport - International KYC)
        LimitedPartner,  // 2 - LP Individual OR LP Business (Can request loans)
        VaultCreator     // 3 - Ecreditscoring (Can create vaults)
    }

    /// @notice Convexo Passport NFT contract (Tier 1 - ZKPassport)
    IERC721 public immutable convexoPassport;
    
    /// @notice Limited Partners Individuals NFT contract (Tier 2 - Veriff)
    IERC721 public immutable lpIndividuals;
    
    /// @notice Limited Partners Business NFT contract (Tier 2 - Sumsub)
    IERC721 public immutable lpBusiness;
    
    /// @notice Ecreditscoring NFT contract (Tier 3 - AI Credit Score)
    IERC721 public immutable ecreditscoring;

    /// @notice Emitted when reputation is checked
    event ReputationChecked(
        address indexed user,
        ReputationTier tier,
        uint256 passportBalance,
        uint256 lpIndividualsBalance,
        uint256 lpBusinessBalance,
        uint256 ecreditscoringBalance
    );

    /// @notice Constructor
    /// @param _convexoPassport Convexo Passport NFT contract address
    /// @param _lpIndividuals Limited Partners Individuals NFT contract address
    /// @param _lpBusiness Limited Partners Business NFT contract address
    /// @param _ecreditscoring Ecreditscoring NFT contract address
    constructor(
        IERC721 _convexoPassport,
        IERC721 _lpIndividuals,
        IERC721 _lpBusiness,
        IERC721 _ecreditscoring
    ) {
        convexoPassport = _convexoPassport;
        lpIndividuals = _lpIndividuals;
        lpBusiness = _lpBusiness;
        ecreditscoring = _ecreditscoring;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // TIER DETERMINATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Get the reputation tier for a user
    /// @dev Highest tier wins - allows progressive verification
    /// @param user The address to check
    /// @return The reputation tier
    function getReputationTier(address user) public view returns (ReputationTier) {
        // Tier 3: Ecreditscoring NFT (highest - can create vaults)
        if (ecreditscoring.balanceOf(user) > 0) {
            return ReputationTier.VaultCreator;
        }

        // Tier 2: LP NFT (Individual OR Business)
        if (lpIndividuals.balanceOf(user) > 0 || lpBusiness.balanceOf(user) > 0) {
            return ReputationTier.LimitedPartner;
        }

        // Tier 1: Passport NFT
        if (convexoPassport.balanceOf(user) > 0) {
            return ReputationTier.Passport;
        }

        // Tier 0: No NFTs
        return ReputationTier.None;
    }

    /// @notice Get the numeric reputation tier (0, 1, 2, or 3)
    /// @param user The address to check
    /// @return The numeric reputation tier
    function getReputationTierNumeric(address user) external view returns (uint256) {
        return uint256(getReputationTier(user));
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ACCESS CHECKS
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Check if user can access LP pools (Tier 1+)
    /// @param user The address to check
    /// @return True if user has any NFT (Passport, LP, or Ecreditscoring)
    function canAccessLPPools(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user can create treasuries (Tier 1+)
    /// @param user The address to check
    /// @return True if user has Tier 1 or higher
    function canCreateTreasury(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user can invest in vaults (Tier 1+)
    /// @param user The address to check
    /// @return True if user has Tier 1 or higher
    function canInvestInVaults(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user can request credit scoring (Tier 2 - LP status required)
    /// @param user The address to check
    /// @return True if user has LP NFT (Individual or Business)
    function canRequestCreditScore(address user) external view returns (bool) {
        return lpIndividuals.balanceOf(user) > 0 || lpBusiness.balanceOf(user) > 0;
    }

    /// @notice Check if user can create vaults (Tier 3)
    /// @param user The address to check
    /// @return True if user has Ecreditscoring NFT
    function canCreateVaults(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // NFT BALANCE CHECKS
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Check if user holds Convexo Passport NFT
    /// @param user The address to check
    /// @return True if user holds at least one Passport NFT
    function holdsPassport(address user) external view returns (bool) {
        return convexoPassport.balanceOf(user) > 0;
    }

    /// @notice Check if user holds Limited Partners Individuals NFT
    /// @param user The address to check
    /// @return True if user holds at least one LP Individuals NFT
    function holdsLPIndividuals(address user) external view returns (bool) {
        return lpIndividuals.balanceOf(user) > 0;
    }

    /// @notice Check if user holds Limited Partners Business NFT
    /// @param user The address to check
    /// @return True if user holds at least one LP Business NFT
    function holdsLPBusiness(address user) external view returns (bool) {
        return lpBusiness.balanceOf(user) > 0;
    }

    /// @notice Check if user holds any LP NFT (Individual or Business)
    /// @param user The address to check
    /// @return True if user holds any LP NFT
    function holdsAnyLP(address user) external view returns (bool) {
        return lpIndividuals.balanceOf(user) > 0 || lpBusiness.balanceOf(user) > 0;
    }

    /// @notice Check if user holds Ecreditscoring NFT
    /// @param user The address to check
    /// @return True if user holds at least one Ecreditscoring NFT
    function holdsEcreditscoring(address user) external view returns (bool) {
        return ecreditscoring.balanceOf(user) > 0;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // TIER ACCESS CHECKS
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Check if user has at least Passport tier (Tier 1+)
    /// @param user The address to check
    /// @return True if user has Tier 1 or higher
    function hasPassportAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user has at least LimitedPartner tier (Tier 2+)
    /// @param user The address to check
    /// @return True if user has Tier 2 or higher
    function hasLimitedPartnerAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.LimitedPartner;
    }

    /// @notice Check if user has VaultCreator tier (Tier 3)
    /// @param user The address to check
    /// @return True if user has Tier 3
    function hasVaultCreatorAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // DETAILED INFO
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Get detailed reputation information for a user
    /// @param user The address to check
    /// @return tier The reputation tier
    /// @return passportBalance Number of Passport NFTs held
    /// @return lpIndividualsBalance Number of LP Individuals NFTs held
    /// @return lpBusinessBalance Number of LP Business NFTs held
    /// @return ecreditscoringBalance Number of Ecreditscoring NFTs held
    function getReputationDetails(address user)
        external
        view
        returns (
            ReputationTier tier,
            uint256 passportBalance,
            uint256 lpIndividualsBalance,
            uint256 lpBusinessBalance,
            uint256 ecreditscoringBalance
        )
    {
        passportBalance = convexoPassport.balanceOf(user);
        lpIndividualsBalance = lpIndividuals.balanceOf(user);
        lpBusinessBalance = lpBusiness.balanceOf(user);
        ecreditscoringBalance = ecreditscoring.balanceOf(user);
        tier = getReputationTier(user);

        return (tier, passportBalance, lpIndividualsBalance, lpBusinessBalance, ecreditscoringBalance);
    }

    /// @notice Check reputation and emit event
    /// @param user The address to check
    /// @return tier The reputation tier
    function checkReputationWithEvent(address user) external returns (ReputationTier tier) {
        uint256 passportBalance = convexoPassport.balanceOf(user);
        uint256 lpIndividualsBalance = lpIndividuals.balanceOf(user);
        uint256 lpBusinessBalance = lpBusiness.balanceOf(user);
        uint256 ecreditscoringBalance = ecreditscoring.balanceOf(user);
        tier = getReputationTier(user);

        emit ReputationChecked(
            user,
            tier,
            passportBalance,
            lpIndividualsBalance,
            lpBusinessBalance,
            ecreditscoringBalance
        );

        return tier;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // REQUIRE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Require that a user has at least Passport tier (Tier 1+)
    /// @param user The address to check
    function requirePassportAccess(address user) external view {
        require(getReputationTier(user) >= ReputationTier.Passport, "Must have Passport tier or higher");
    }

    /// @notice Require that a user has at least LimitedPartner tier (Tier 2+)
    /// @param user The address to check
    function requireLimitedPartnerAccess(address user) external view {
        require(getReputationTier(user) >= ReputationTier.LimitedPartner, "Must have LimitedPartner tier or higher");
    }

    /// @notice Require that a user has VaultCreator tier (Tier 3)
    /// @param user The address to check
    function requireVaultCreatorAccess(address user) external view {
        require(getReputationTier(user) == ReputationTier.VaultCreator, "Must have VaultCreator tier");
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // DEPRECATED - Kept for backward compatibility
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice DEPRECATED: Use hasLimitedPartnerAccess() instead
    function hasCompliantAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.LimitedPartner;
    }

    /// @notice DEPRECATED: Use hasVaultCreatorAccess() instead
    function hasCreditscoreAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    /// @notice DEPRECATED: Use requireLimitedPartnerAccess() instead
    function requireCompliantAccess(address user) external view {
        require(getReputationTier(user) >= ReputationTier.LimitedPartner, "Must have LimitedPartner tier or higher");
    }

    /// @notice DEPRECATED: Use requireVaultCreatorAccess() instead
    function requireCreditscoreAccess(address user) external view {
        require(getReputationTier(user) == ReputationTier.VaultCreator, "Must have VaultCreator tier");
    }
}

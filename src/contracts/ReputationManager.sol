// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IConvexoLPs} from "../interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../interfaces/IConvexoPassport.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ReputationManager
/// @notice Manages NFT-based reputation tiers for users
/// @dev Checks Convexo_LPs, Convexo_Vaults, and Convexo_Passport NFT ownership to calculate reputation
contract ReputationManager {
    /// @notice Reputation tiers (UPDATED: Tier hierarchy reversed)
    /// Tier 0: No NFTs - No access
    /// Tier 1: Passport NFT - Individual: Treasury creation + Vault investments
    /// Tier 2: LPs NFT - Limited Partner: LP pools + Vault investments
    /// Tier 3: Vaults NFT - Vault Creator: Vault creation + All Tier 2 privileges
    enum ReputationTier {
        None,            // 0 - No NFTs
        Passport,        // 1 - Convexo_Passport (Individual - Treasury + Investments)
        LimitedPartner,  // 2 - Convexo_LPs (LP - Pools + Investments)
        VaultCreator     // 3 - Convexo_Vaults (Business - Vault Creation + All)
    }

    /// @notice The Convexo_LPs NFT contract (Business Tier 1)
    IConvexoLPs public immutable convexoLPs;

    /// @notice The Convexo_Vaults NFT contract (Business Tier 2)
    IConvexoVaults public immutable convexoVaults;

    /// @notice The Convexo_Passport NFT contract (Individual Tier 3)
    IConvexoPassport public immutable convexoPassport;

    /// @notice Emitted when reputation is checked
    event ReputationChecked(
        address indexed user,
        ReputationTier tier,
        uint256 lpsBalance,
        uint256 vaultsBalance,
        uint256 passportBalance
    );

    constructor(
        IConvexoLPs _convexoLPs,
        IConvexoVaults _convexoVaults,
        IConvexoPassport _convexoPassport
    ) {
        convexoLPs = _convexoLPs;
        convexoVaults = _convexoVaults;
        convexoPassport = _convexoPassport;
    }

    /// @notice Get the reputation tier for a user
    /// @dev NEW: Highest tier wins, no mutual exclusivity (allows progressive KYC)
    /// @param user The address to check
    /// @return The reputation tier
    function getReputationTier(address user) public view returns (ReputationTier) {
        // Handle case where NFT contracts are not deployed (address(0))
        uint256 lpsBalance = address(convexoLPs) != address(0) 
            ? convexoLPs.balanceOf(user) 
            : 0;
        uint256 vaultsBalance = address(convexoVaults) != address(0) 
            ? convexoVaults.balanceOf(user) 
            : 0;
        uint256 passportBalance = address(convexoPassport) != address(0) 
            ? IERC721(address(convexoPassport)).balanceOf(user) 
            : 0;

        // NEW APPROACH: Highest tier wins (no mutual exclusivity)
        // This allows users to upgrade from individual (Passport) to business (LPs/Vaults)

        // Tier 3: Vaults NFT (highest privilege - can create vaults + all Tier 2 benefits)
        if (vaultsBalance > 0) {
            return ReputationTier.VaultCreator;
        }

        // Tier 2: LPs NFT (can access LP pools + invest in vaults)
        if (lpsBalance > 0) {
            return ReputationTier.LimitedPartner;
        }

        // Tier 1: Passport NFT (can create treasuries + invest in vaults)
        if (passportBalance > 0) {
            return ReputationTier.Passport;
        }

        // Tier 0: No NFTs
        return ReputationTier.None;
    }

    /// @notice Get the numeric reputation tier (0, 1, or 2)
    /// @param user The address to check
    /// @return The numeric reputation tier
    function getReputationTierNumeric(address user) external view returns (uint256) {
        return uint256(getReputationTier(user));
    }

    /// @notice Check if user can create treasuries (Tier 1+)
    /// @param user The address to check
    /// @return True if user has Tier 1 (Passport) or higher
    function canCreateTreasury(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user can invest in vaults (Tier 1+)
    /// @param user The address to check
    /// @return True if user has Tier 1 (Passport) or higher
    function canInvestInVaults(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Passport;
    }

    /// @notice Check if user can access LP pools (Tier 2+)
    /// @param user The address to check
    /// @return True if user has Tier 2 (LimitedPartner) or higher
    function canAccessLPPools(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.LimitedPartner;
    }

    /// @notice Check if user can create vaults (Tier 3)
    /// @param user The address to check
    /// @return True if user has Tier 3 (VaultCreator)
    function canCreateVaults(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    /// @notice Check if a user has at least LimitedPartner tier (Tier 2) - RENAMED
    /// @param user The address to check
    /// @return True if user has Tier 2 or higher
    function hasLimitedPartnerAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.LimitedPartner;
    }

    /// @notice Check if a user has VaultCreator tier (Tier 3) - RENAMED
    /// @param user The address to check
    /// @return True if user has Tier 3
    function hasVaultCreatorAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    /// @notice DEPRECATED: Use hasLimitedPartnerAccess() instead
    /// @dev Kept for backward compatibility
    function hasCompliantAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.LimitedPartner;
    }

    /// @notice DEPRECATED: Use hasVaultCreatorAccess() instead
    /// @dev Kept for backward compatibility
    function hasCreditscoreAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.VaultCreator;
    }

    /// @notice Check if a user holds a Convexo_LPs NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_LPs NFT
    function holdsConvexoLPs(address user) external view returns (bool) {
        if (address(convexoLPs) == address(0)) {
            return false;
        }
        return convexoLPs.balanceOf(user) > 0;
    }

    /// @notice Check if a user holds a Convexo_Vaults NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_Vaults NFT
    function holdsConvexoVaults(address user) external view returns (bool) {
        if (address(convexoVaults) == address(0)) {
            return false;
        }
        return convexoVaults.balanceOf(user) > 0;
    }

    /// @notice Check if a user holds a Convexo_Passport NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_Passport NFT
    function holdsConvexoPassport(address user) external view returns (bool) {
        if (address(convexoPassport) == address(0)) {
            return false;
        }
        return IERC721(address(convexoPassport)).balanceOf(user) > 0;
    }

    /// @notice Check if a user has Passport access (Tier 3)
    /// @param user The address to check
    /// @return True if user has Passport tier
    function hasPassportAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.Passport;
    }

    /// @notice Get detailed reputation information for a user
    /// @param user The address to check
    /// @return tier The reputation tier
    /// @return lpsBalance The number of Convexo_LPs NFTs held
    /// @return vaultsBalance The number of Convexo_Vaults NFTs held
    /// @return passportBalance The number of Convexo_Passport NFTs held
    function getReputationDetails(address user)
        external
        view
        returns (
            ReputationTier tier,
            uint256 lpsBalance,
            uint256 vaultsBalance,
            uint256 passportBalance
        )
    {
        lpsBalance = address(convexoLPs) != address(0) 
            ? convexoLPs.balanceOf(user) 
            : 0;
        vaultsBalance = address(convexoVaults) != address(0) 
            ? convexoVaults.balanceOf(user) 
            : 0;
        passportBalance = address(convexoPassport) != address(0) 
            ? IERC721(address(convexoPassport)).balanceOf(user) 
            : 0;
        tier = getReputationTier(user);

        return (tier, lpsBalance, vaultsBalance, passportBalance);
    }

    /// @notice Check reputation and emit event
    /// @param user The address to check
    /// @return tier The reputation tier
    function checkReputationWithEvent(address user) external returns (ReputationTier tier) {
        uint256 lpsBalance = address(convexoLPs) != address(0) 
            ? convexoLPs.balanceOf(user) 
            : 0;
        uint256 vaultsBalance = address(convexoVaults) != address(0) 
            ? convexoVaults.balanceOf(user) 
            : 0;
        uint256 passportBalance = address(convexoPassport) != address(0) 
            ? IERC721(address(convexoPassport)).balanceOf(user) 
            : 0;
        tier = getReputationTier(user);

        emit ReputationChecked(user, tier, lpsBalance, vaultsBalance, passportBalance);

        return tier;
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

    /// @notice DEPRECATED: Use requireLimitedPartnerAccess() instead
    /// @dev Kept for backward compatibility
    function requireCompliantAccess(address user) external view {
        require(getReputationTier(user) >= ReputationTier.LimitedPartner, "Must have LimitedPartner tier or higher");
    }

    /// @notice DEPRECATED: Use requireVaultCreatorAccess() instead
    /// @dev Kept for backward compatibility
    function requireCreditscoreAccess(address user) external view {
        require(getReputationTier(user) == ReputationTier.VaultCreator, "Must have VaultCreator tier");
    }
}

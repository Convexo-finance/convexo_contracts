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
    /// @notice Reputation tiers
    /// Tier 0: No NFTs - Limited access
    /// Tier 1: 1 NFT (Compliant) - Business: Liquidity pools access
    /// Tier 2: 2 NFTs (Creditscore) - Business: Pools + Vault creation
    /// Tier 3: Passport NFT - Individual: Vault investments only
    enum ReputationTier {
        None,          // 0 - No NFTs
        Compliant,     // 1 - Convexo_LPs (Business - Pools)
        Creditscore,   // 2 - LPs + Vaults (Business - Full)
        Passport       // 3 - Convexo_Passport (Individual - Investor)
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
    /// @param user The address to check
    /// @return The reputation tier
    function getReputationTier(address user) public view returns (ReputationTier) {
        uint256 lpsBalance = convexoLPs.balanceOf(user);
        uint256 vaultsBalance = convexoVaults.balanceOf(user);
        uint256 passportBalance = IERC721(address(convexoPassport)).balanceOf(user);

        // Check for Passport NFT (Individual investor path - Tier 3)
        // Passport holders cannot have business NFTs (mutually exclusive)
        if (passportBalance > 0) {
            require(lpsBalance == 0 && vaultsBalance == 0, "Cannot hold both business and individual NFTs");
            return ReputationTier.Passport;
        }

        // Business path (Tiers 1 & 2)
        if (lpsBalance > 0 && vaultsBalance > 0) {
            return ReputationTier.Creditscore; // Tier 2: Both business NFTs
        } else if (lpsBalance > 0) {
            return ReputationTier.Compliant; // Tier 1: LPs NFT only
        } else {
            return ReputationTier.None; // Tier 0: No NFTs
        }
    }

    /// @notice Get the numeric reputation tier (0, 1, or 2)
    /// @param user The address to check
    /// @return The numeric reputation tier
    function getReputationTierNumeric(address user) external view returns (uint256) {
        return uint256(getReputationTier(user));
    }

    /// @notice Check if a user has at least Compliant tier (Tier 1)
    /// @param user The address to check
    /// @return True if user has Tier 1 or higher
    function hasCompliantAccess(address user) external view returns (bool) {
        return getReputationTier(user) >= ReputationTier.Compliant;
    }

    /// @notice Check if a user has Creditscore tier (Tier 2)
    /// @param user The address to check
    /// @return True if user has Tier 2
    function hasCreditscoreAccess(address user) external view returns (bool) {
        return getReputationTier(user) == ReputationTier.Creditscore;
    }

    /// @notice Check if a user holds a Convexo_LPs NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_LPs NFT
    function holdsConvexoLPs(address user) external view returns (bool) {
        return convexoLPs.balanceOf(user) > 0;
    }

    /// @notice Check if a user holds a Convexo_Vaults NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_Vaults NFT
    function holdsConvexoVaults(address user) external view returns (bool) {
        return convexoVaults.balanceOf(user) > 0;
    }

    /// @notice Check if a user holds a Convexo_Passport NFT
    /// @param user The address to check
    /// @return True if user holds at least one Convexo_Passport NFT
    function holdsConvexoPassport(address user) external view returns (bool) {
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
        lpsBalance = convexoLPs.balanceOf(user);
        vaultsBalance = convexoVaults.balanceOf(user);
        passportBalance = IERC721(address(convexoPassport)).balanceOf(user);
        tier = getReputationTier(user);

        return (tier, lpsBalance, vaultsBalance, passportBalance);
    }

    /// @notice Check reputation and emit event
    /// @param user The address to check
    /// @return tier The reputation tier
    function checkReputationWithEvent(address user) external returns (ReputationTier tier) {
        uint256 lpsBalance = convexoLPs.balanceOf(user);
        uint256 vaultsBalance = convexoVaults.balanceOf(user);
        uint256 passportBalance = IERC721(address(convexoPassport)).balanceOf(user);
        tier = getReputationTier(user);

        emit ReputationChecked(user, tier, lpsBalance, vaultsBalance, passportBalance);

        return tier;
    }

    /// @notice Require that a user has at least Compliant tier
    /// @param user The address to check
    function requireCompliantAccess(address user) external view {
        require(getReputationTier(user) >= ReputationTier.Compliant, "Must have Compliant tier or higher");
    }

    /// @notice Require that a user has Creditscore tier
    /// @param user The address to check
    function requireCreditscoreAccess(address user) external view {
        require(getReputationTier(user) == ReputationTier.Creditscore, "Must have Creditscore tier");
    }
}

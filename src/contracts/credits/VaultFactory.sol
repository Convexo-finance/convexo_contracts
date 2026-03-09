// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TokenizedBondVault} from "./TokenizedBondVault.sol";
import {ContractSigner} from "./ContractSigner.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";

/// @title VaultFactory
/// @notice Factory for creating TokenizedBondVault instances.
///         Only Tier 3 holders (canCreateVaults) may create vaults.
///
/// @dev Vault economics set by the borrower at creation:
///   - principalAmount : Total USDC to raise
///   - interestRate    : Return rate in bps (e.g. 1200 = 12%)
///   - protocolFeeRate : Protocol fee in bps (e.g. 200 = 2%)
///   - totalShareSupply: Number of whole shares (e.g. 1000)
///     → initialSharePrice = principalAmount / totalShareSupply
///   - minInvestment   : Minimum USDC per investor deposit (borrower-settable)
contract VaultFactory is AccessControl {
    bytes32 public constant VAULT_CREATOR_ROLE = keccak256("VAULT_CREATOR_ROLE");

    uint256 private _nextVaultId;

    address public immutable usdc;
    address public protocolFeeCollector;
    ContractSigner public immutable contractSigner;
    ReputationManager public immutable reputationManager;

    mapping(uint256 => address) public vaults;
    address[] public vaultAddresses;

    event VaultCreated(
        uint256 indexed vaultId,
        address indexed vaultAddress,
        address indexed borrower,
        uint256 principalAmount,
        uint256 totalShareSupply,
        uint256 initialSharePrice
    );
    event ProtocolFeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);

    constructor(
        address admin,
        address _usdc,
        address _protocolFeeCollector,
        ContractSigner _contractSigner,
        ReputationManager _reputationManager
    ) {
        require(admin != address(0), "Invalid admin");
        require(_usdc != address(0), "Invalid USDC");
        require(_protocolFeeCollector != address(0), "Invalid fee collector");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CREATOR_ROLE, admin);
        usdc = _usdc;
        protocolFeeCollector = _protocolFeeCollector;
        contractSigner = _contractSigner;
        reputationManager = _reputationManager;
    }

    /// @notice Create a new TokenizedBondVault (borrower must hold Tier 3 NFT)
    /// @param principalAmount  Total USDC to raise (6 decimals, e.g. 100_000e6 = $100k)
    /// @param interestRate     Interest rate in bps (e.g. 1200 = 12%)
    /// @param protocolFeeRate  Protocol fee in bps (e.g. 200 = 2%)
    /// @param maturityDate     Timestamp deadline for full repayment
    /// @param totalShareSupply Number of whole shares to issue (e.g. 1000)
    ///                         → initialSharePrice = principalAmount / totalShareSupply
    /// @param minInvestment    Minimum USDC per deposit (6 decimals, e.g. 100e6 = $100)
    /// @param name             ERC-20 share token name
    /// @param symbol           ERC-20 share token symbol
    /// @return vaultId      Sequential vault ID
    /// @return vaultAddress Deployed vault address
    function createVault(
        uint256 principalAmount,
        uint256 interestRate,
        uint256 protocolFeeRate,
        uint256 maturityDate,
        uint256 totalShareSupply,
        uint256 minInvestment,
        string memory name,
        string memory symbol
    ) external returns (uint256 vaultId, address vaultAddress) {
        require(reputationManager.canCreateVaults(msg.sender), "Must have Tier 3 NFT to create vaults");
        require(principalAmount > 0, "Principal must be > 0");
        require(totalShareSupply > 0, "Share supply must be > 0");
        require(principalAmount >= totalShareSupply * 1e6, "Share price must be at least $1 (principal/shares >= 1e6)");
        require(maturityDate > block.timestamp, "Maturity must be in the future");
        require(interestRate > 0 && interestRate <= 10000, "Invalid interest rate (1-10000 bps)");
        require(protocolFeeRate <= 1000, "Protocol fee too high (max 10%)");
        require(minInvestment > 0, "Min investment must be > 0");

        vaultId = _nextVaultId++;

        TokenizedBondVault vault = new TokenizedBondVault(
            vaultId,
            msg.sender,          // borrower
            principalAmount,
            interestRate,
            protocolFeeRate,
            maturityDate,
            totalShareSupply,
            minInvestment,
            usdc,
            address(contractSigner),
            msg.sender,          // admin (borrower controls vault initially)
            protocolFeeCollector,
            reputationManager,
            name,
            symbol
        );

        vaultAddress = address(vault);
        vaults[vaultId] = vaultAddress;
        vaultAddresses.push(vaultAddress);

        // initialSharePrice in USDC (6 decimals) = principalAmount / totalShareSupply
        uint256 initialSharePrice = principalAmount / totalShareSupply;

        emit VaultCreated(vaultId, vaultAddress, msg.sender, principalAmount, totalShareSupply, initialSharePrice);
        return (vaultId, vaultAddress);
    }

    /// @notice Update protocol fee collector (DEFAULT_ADMIN_ROLE)
    function updateProtocolFeeCollector(address newCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newCollector != address(0), "Invalid address");
        address old = protocolFeeCollector;
        protocolFeeCollector = newCollector;
        emit ProtocolFeeCollectorUpdated(old, newCollector);
    }

    function getVault(uint256 vaultId) external view returns (address) {
        require(vaultId < _nextVaultId, "Vault does not exist");
        return vaults[vaultId];
    }

    function getVaultCount() external view returns (uint256) {
        return _nextVaultId;
    }

    function getVaultAddressAtIndex(uint256 index) external view returns (address) {
        require(index < vaultAddresses.length, "Index out of bounds");
        return vaultAddresses[index];
    }
}

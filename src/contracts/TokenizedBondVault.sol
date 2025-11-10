// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TokenizedBondVault
/// @notice Core vault contract for tokenized bonds with ERC20 share tokens
/// @dev Implements 12% returns for LPs, 2% protocol fee, and 10% interest paid by SME
contract TokenizedBondVault is ERC20, AccessControl {
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    /// @notice Vault state enum
    enum VaultState {
        Pending,
        Active,
        Repaying,
        Completed,
        Defaulted
    }

    /// @notice Vault information
    struct VaultInfo {
        uint256 vaultId;
        address borrower;
        bytes32 contractHash;
        uint256 principalAmount; // USDC (6 decimals)
        uint256 interestRate; // Basis points (e.g., 1200 = 12%)
        uint256 protocolFeeRate; // Basis points (e.g., 200 = 2%)
        uint256 maturityDate;
        VaultState state;
        uint256 totalRaised;
        uint256 totalRepaid;
        uint256 createdAt;
    }

    /// @notice The vault information
    VaultInfo public vaultInfo;

    /// @notice The USDC token
    IERC20 public immutable usdc;

    /// @notice Protocol fee collector address
    address public protocolFeeCollector;

    /// @notice Total protocol fees collected
    uint256 public protocolFeesCollected;

    /// @notice Emitted when shares are purchased
    event SharesPurchased(address indexed investor, uint256 amount, uint256 shares);

    /// @notice Emitted when a repayment is made
    event RepaymentMade(uint256 amount, uint256 totalRepaid);

    /// @notice Emitted when shares are redeemed
    event SharesRedeemed(address indexed investor, uint256 shares, uint256 amount);

    /// @notice Emitted when vault state changes
    event VaultStateChanged(VaultState newState);

    /// @notice Emitted when protocol fees are collected
    event ProtocolFeesCollected(uint256 amount);

    constructor(
        uint256 _vaultId,
        address _borrower,
        bytes32 _contractHash,
        uint256 _principalAmount,
        uint256 _interestRate,
        uint256 _protocolFeeRate,
        uint256 _maturityDate,
        address _usdc,
        address _admin,
        address _protocolFeeCollector,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        vaultInfo = VaultInfo({
            vaultId: _vaultId,
            borrower: _borrower,
            contractHash: _contractHash,
            principalAmount: _principalAmount,
            interestRate: _interestRate,
            protocolFeeRate: _protocolFeeRate,
            maturityDate: _maturityDate,
            state: VaultState.Pending,
            totalRaised: 0,
            totalRepaid: 0,
            createdAt: block.timestamp
        });

        usdc = IERC20(_usdc);
        protocolFeeCollector = _protocolFeeCollector;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VAULT_MANAGER_ROLE, _admin);
    }

    /// @notice Purchase vault shares by depositing USDC
    /// @param amount The amount of USDC to deposit
    function purchaseShares(uint256 amount) external {
        require(
            vaultInfo.state == VaultState.Pending || vaultInfo.state == VaultState.Active,
            "Vault not accepting deposits"
        );
        require(amount > 0, "Amount must be greater than 0");
        require(vaultInfo.totalRaised + amount <= vaultInfo.principalAmount, "Exceeds principal amount");

        // Transfer USDC from investor
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        // Mint shares 1:1 with USDC
        _mint(msg.sender, amount);

        vaultInfo.totalRaised += amount;

        emit SharesPurchased(msg.sender, amount, amount);

        // If fully funded, activate vault
        if (vaultInfo.totalRaised == vaultInfo.principalAmount) {
            vaultInfo.state = VaultState.Active;
            emit VaultStateChanged(VaultState.Active);
        }
    }

    /// @notice Disburse loan to borrower
    function disburseLoan() external onlyRole(VAULT_MANAGER_ROLE) {
        require(vaultInfo.state == VaultState.Active, "Vault not active");
        require(vaultInfo.totalRaised == vaultInfo.principalAmount, "Vault not fully funded");

        // Transfer principal to borrower
        require(usdc.transfer(vaultInfo.borrower, vaultInfo.principalAmount), "USDC transfer failed");

        vaultInfo.state = VaultState.Repaying;
        emit VaultStateChanged(VaultState.Repaying);
    }

    /// @notice Make a repayment
    /// @param amount The amount to repay in USDC
    function makeRepayment(uint256 amount) external {
        require(vaultInfo.state == VaultState.Repaying, "Vault not in repaying state");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer USDC from borrower
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        vaultInfo.totalRepaid += amount;

        emit RepaymentMade(amount, vaultInfo.totalRepaid);

        // Calculate total due (principal + interest)
        uint256 totalDue = vaultInfo.principalAmount + (vaultInfo.principalAmount * vaultInfo.interestRate / 10000);

        // Check if fully repaid
        if (vaultInfo.totalRepaid >= totalDue) {
            vaultInfo.state = VaultState.Completed;
            emit VaultStateChanged(VaultState.Completed);

            // Collect protocol fees
            uint256 protocolFee = (vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000);
            if (protocolFee > 0) {
                require(usdc.transfer(protocolFeeCollector, protocolFee), "Protocol fee transfer failed");
                protocolFeesCollected += protocolFee;
                emit ProtocolFeesCollected(protocolFee);
            }
        }
    }

    /// @notice Redeem shares for USDC
    /// @param shares The number of shares to redeem
    function redeemShares(uint256 shares) external {
        require(vaultInfo.state == VaultState.Completed, "Vault not completed");
        require(shares > 0, "Shares must be greater than 0");
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");

        // Calculate redemption amount
        // After protocol fees, LPs get their principal + 12% returns
        uint256 totalAvailable = vaultInfo.totalRepaid - protocolFeesCollected;
        uint256 redemptionAmount = (shares * totalAvailable) / totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        // Transfer USDC
        require(usdc.transfer(msg.sender, redemptionAmount), "USDC transfer failed");

        emit SharesRedeemed(msg.sender, shares, redemptionAmount);
    }

    /// @notice Mark vault as defaulted
    function markAsDefaulted() external onlyRole(VAULT_MANAGER_ROLE) {
        require(vaultInfo.state == VaultState.Repaying, "Vault not in repaying state");
        require(block.timestamp > vaultInfo.maturityDate, "Vault has not matured yet");

        vaultInfo.state = VaultState.Defaulted;
        emit VaultStateChanged(VaultState.Defaulted);
    }

    /// @notice Get vault balance
    /// @return The USDC balance of the vault
    function getVaultBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /// @notice Calculate share value
    /// @return The current value of one share in USDC (6 decimals)
    function getShareValue() external view returns (uint256) {
        if (totalSupply() == 0) return 1e6; // 1 USDC initially
        uint256 totalAvailable = usdc.balanceOf(address(this));
        return (totalAvailable * 1e6) / totalSupply(); // Normalized to 6 decimals
    }

    /// @notice Get total accrued interest (like Aave shows APY)
    /// @return accruedInterest The interest accrued so far
    /// @return remainingInterest The interest still to be paid
    function getAccruedInterest() external view returns (uint256 accruedInterest, uint256 remainingInterest) {
        if (vaultInfo.state != VaultState.Repaying) {
            return (0, 0);
        }

        // Total interest = principal * 12% (or interestRate)
        uint256 totalInterest = (vaultInfo.principalAmount * vaultInfo.interestRate) / 10000;

        // Accrued = what's been repaid minus principal
        if (vaultInfo.totalRepaid > vaultInfo.principalAmount) {
            accruedInterest = vaultInfo.totalRepaid - vaultInfo.principalAmount;
        } else {
            accruedInterest = 0;
        }

        // Remaining = total interest minus accrued
        if (totalInterest > accruedInterest) {
            remainingInterest = totalInterest - accruedInterest;
        } else {
            remainingInterest = 0;
        }

        return (accruedInterest, remainingInterest);
    }

    /// @notice Get investor's current return (like Aave dashboard)
    /// @param investor The investor address
    /// @return invested The amount invested
    /// @return currentValue The current value of their shares
    /// @return profit The profit earned (currentValue - invested)
    /// @return apy The effective APY based on time elapsed
    function getInvestorReturn(address investor)
        external
        view
        returns (uint256 invested, uint256 currentValue, uint256 profit, uint256 apy)
    {
        uint256 shares = balanceOf(investor);
        if (shares == 0) {
            return (0, 0, 0, 0);
        }

        // Invested = shares owned (1:1 with USDC initially)
        invested = shares;

        // Current value = shares * current share price
        uint256 sharePrice = this.getShareValue();
        currentValue = (shares * sharePrice) / 1e6;

        // Profit = current value - invested
        if (currentValue > invested) {
            profit = currentValue - invested;
        } else {
            profit = 0;
        }

        // APY calculation based on time elapsed
        if (vaultInfo.state == VaultState.Repaying && profit > 0) {
            uint256 timeElapsed = block.timestamp - vaultInfo.createdAt;
            if (timeElapsed > 0) {
                // APY = (profit / invested) * (365 days / timeElapsed) * 100
                apy = (profit * 1e4 * 365 days) / (invested * timeElapsed);
            }
        } else {
            apy = 0;
        }

        return (invested, currentValue, profit, apy);
    }

    /// @notice Get vault metrics (for dashboard display)
    /// @return totalShares Total shares minted
    /// @return sharePrice Current price per share
    /// @return totalValueLocked Total USDC in vault
    /// @return targetAmount Target amount to reach
    /// @return fundingProgress Funding progress in basis points (10000 = 100%)
    /// @return currentAPY Current APY for investors
    function getVaultMetrics()
        external
        view
        returns (
            uint256 totalShares,
            uint256 sharePrice,
            uint256 totalValueLocked,
            uint256 targetAmount,
            uint256 fundingProgress,
            uint256 currentAPY
        )
    {
        totalShares = totalSupply();
        sharePrice = this.getShareValue();
        totalValueLocked = usdc.balanceOf(address(this));
        targetAmount = vaultInfo.principalAmount;

        // Funding progress (0-10000, where 10000 = 100%)
        if (targetAmount > 0) {
            fundingProgress = (vaultInfo.totalRaised * 10000) / targetAmount;
        } else {
            fundingProgress = 0;
        }

        // Current APY = interest rate for this vault
        currentAPY = vaultInfo.interestRate; // e.g., 1200 = 12%

        return (totalShares, sharePrice, totalValueLocked, targetAmount, fundingProgress, currentAPY);
    }

    /// @notice Get repayment status (for borrower dashboard)
    /// @return totalDue Total amount due (principal + interest)
    /// @return totalPaid Amount paid so far
    /// @return remaining Amount still to pay
    /// @return protocolFee Protocol fee amount
    function getRepaymentStatus()
        external
        view
        returns (uint256 totalDue, uint256 totalPaid, uint256 remaining, uint256 protocolFee)
    {
        // Total due = principal + 12% interest
        totalDue = vaultInfo.principalAmount + (vaultInfo.principalAmount * vaultInfo.interestRate / 10000);

        // Total paid
        totalPaid = vaultInfo.totalRepaid;

        // Remaining
        if (totalDue > totalPaid) {
            remaining = totalDue - totalPaid;
        } else {
            remaining = 0;
        }

        // Protocol fee (2%)
        protocolFee = (vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000);

        return (totalDue, totalPaid, remaining, protocolFee);
    }
}

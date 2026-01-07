// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IContractSigner} from "../interfaces/IContractSigner.sol";
import {ReputationManager} from "./ReputationManager.sol";

/// @title TokenizedBondVault
/// @notice Core vault contract for tokenized bonds with ERC20 share tokens
/// @dev Implements 12% returns for LPs, 2% protocol fee, and 10% interest paid by SME
contract TokenizedBondVault is ERC20, AccessControl, ReentrancyGuard {
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    /// @notice Vault state enum
    enum VaultState {
        Pending,           // Accepting investments
        Funded,            // Fully funded, awaiting contract signatures
        Active,            // Contract signed, can withdraw
        Repaying,          // Funds withdrawn, making repayments
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
        uint256 fundedAt;        // Timestamp when vault was fully funded
        uint256 contractAttachedAt; // Timestamp when contract was attached
        uint256 fundsWithdrawnAt;   // Timestamp when borrower withdrew funds
    }

    /// @notice Array of investor addresses
    address[] private investors;

    /// @notice Mapping to track if an address is already an investor
    mapping(address => bool) private isInvestor;

    /// @notice The vault information
    VaultInfo public vaultInfo;

    /// @notice The USDC token
    IERC20 public immutable usdc;

    /// @notice Contract signer reference for verification
    address public immutable contractSigner;

    /// @notice Reputation manager reference for access control
    ReputationManager public immutable reputationManager;

    /// @notice Protocol fee collector address
    address public protocolFeeCollector;

    /// @notice Total protocol fees withdrawn by collector
    uint256 public protocolFeesWithdrawn;

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

    /// @notice Emitted when vault is fully funded
    event VaultFullyFunded(uint256 indexed vaultId, uint256 timestamp);

    /// @notice Emitted when contract is attached to vault
    event ContractAttached(uint256 indexed vaultId, bytes32 contractHash);

    /// @notice Emitted when borrower withdraws funds
    event FundsWithdrawn(address indexed borrower, uint256 amount);

    constructor(
        uint256 _vaultId,
        address _borrower,
        bytes32 _contractHash,
        uint256 _principalAmount,
        uint256 _interestRate,
        uint256 _protocolFeeRate,
        uint256 _maturityDate,
        address _usdc,
        address _contractSigner,
        address _admin,
        address _protocolFeeCollector,
        ReputationManager _reputationManager,
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
            createdAt: block.timestamp,
            fundedAt: 0,
            contractAttachedAt: 0,
            fundsWithdrawnAt: 0
        });

        usdc = IERC20(_usdc);
        contractSigner = _contractSigner;
        reputationManager = _reputationManager;
        protocolFeeCollector = _protocolFeeCollector;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VAULT_MANAGER_ROLE, _admin);
    }

    /// @notice Purchase vault shares by depositing USDC
    /// @param amount The amount of USDC to deposit
    function purchaseShares(uint256 amount) external nonReentrant {
        // Require Tier 1+ (Passport or higher) to invest
        require(
            reputationManager.canInvestInVaults(msg.sender),
            "Must have Tier 1+ (Convexo_Passport or higher) to invest"
        );
        require(vaultInfo.state == VaultState.Pending, "Vault not accepting deposits");
        require(amount > 0, "Amount must be greater than 0");
        require(vaultInfo.totalRaised + amount <= vaultInfo.principalAmount, "Exceeds principal amount");

        // Track investor if not already tracked
        if (!isInvestor[msg.sender]) {
            investors.push(msg.sender);
            isInvestor[msg.sender] = true;
        }

        // Transfer USDC from investor
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        // Mint shares 1:1 with USDC
        _mint(msg.sender, amount);

        vaultInfo.totalRaised += amount;

        emit SharesPurchased(msg.sender, amount, amount);

        // If fully funded, change to Funded state (awaiting contract)
        if (vaultInfo.totalRaised == vaultInfo.principalAmount) {
            vaultInfo.state = VaultState.Funded;
            vaultInfo.fundedAt = block.timestamp;
            emit VaultStateChanged(VaultState.Funded);
            emit VaultFullyFunded(vaultInfo.vaultId, block.timestamp);
        }
    }

    /// @notice Attach contract hash to vault after contract is created and signed
    /// @param _contractHash The hash of the signed contract
    function attachContract(bytes32 _contractHash) external onlyRole(VAULT_MANAGER_ROLE) {
        require(vaultInfo.state == VaultState.Funded, "Vault not funded");
        require(vaultInfo.contractHash == bytes32(0), "Contract already attached");
        require(_contractHash != bytes32(0), "Invalid contract hash");

        vaultInfo.contractHash = _contractHash;
        vaultInfo.contractAttachedAt = block.timestamp;
        vaultInfo.state = VaultState.Active;
        emit ContractAttached(vaultInfo.vaultId, _contractHash);
        emit VaultStateChanged(VaultState.Active);
    }

    /// @notice Borrower withdraws funds after contract is fully signed
    function withdrawFunds() external nonReentrant {
        require(msg.sender == vaultInfo.borrower, "Only borrower");
        require(vaultInfo.state == VaultState.Active, "Vault not active");
        require(vaultInfo.contractHash != bytes32(0), "No contract attached");
        require(vaultInfo.totalRaised == vaultInfo.principalAmount, "Vault not fully funded");

        // Verify contract is fully signed
        IContractSigner.ContractDocument memory doc = IContractSigner(contractSigner).getContract(
            vaultInfo.contractHash
        );
        require(doc.isExecuted, "Contract not fully signed");
        require(!doc.isCancelled, "Contract cancelled");

        // Transfer principal to borrower
        require(usdc.transfer(vaultInfo.borrower, vaultInfo.principalAmount), "USDC transfer failed");

        vaultInfo.state = VaultState.Repaying;
        vaultInfo.fundsWithdrawnAt = block.timestamp;
        emit FundsWithdrawn(vaultInfo.borrower, vaultInfo.principalAmount);
        emit VaultStateChanged(VaultState.Repaying);
    }

    /// @notice Disburse loan to borrower (DEPRECATED - use withdrawFunds instead)
    /// @dev Kept for backward compatibility but should not be used
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
    function makeRepayment(uint256 amount) external nonReentrant {
        require(vaultInfo.state == VaultState.Repaying, "Vault not in repaying state");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer USDC from borrower
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        vaultInfo.totalRepaid += amount;

        emit RepaymentMade(amount, vaultInfo.totalRepaid);

        // Note: Vault state changes to Completed only when all funds are withdrawn
        // This is checked in _checkVaultCompletion() called by redeemShares() and withdrawProtocolFees()
    }

    /// @notice Redeem shares for USDC
    /// @param shares The number of shares to redeem
    /// @dev Can redeem partially or fully at any time after borrower withdraws funds
    function redeemShares(uint256 shares) external nonReentrant {
        require(
            vaultInfo.state == VaultState.Repaying || vaultInfo.state == VaultState.Completed || vaultInfo.state == VaultState.Funded || vaultInfo.state == VaultState.Active,
            "Invalid state for redemption"
        );
        require(shares > 0, "Shares must be greater than 0");
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");

        // Allow withdrawal if contract is not yet fully signed/executed (Funded/Active state)
        // This enables investors to withdraw if deal falls through before borrower withdrawal
        if (vaultInfo.state == VaultState.Funded || vaultInfo.state == VaultState.Active) {
            // Check if contract is signed/executed to be safe, though state check handles most cases
            // If active, contract is attached but funds not withdrawn. Investor can exit.
            // If funded, contract might not even be attached. Investor can exit.
            
            // Calculate 1:1 redemption (since no interest/fees generated yet)
            // Principal only
            uint256 earlyRedemptionAmount = shares; // 1 share = 1 USDC initially
            
            require(usdc.balanceOf(address(this)) >= earlyRedemptionAmount, "Insufficient vault balance");

            // Burn shares
            _burn(msg.sender, shares);

            // Transfer USDC
            require(usdc.transfer(msg.sender, earlyRedemptionAmount), "USDC transfer failed");
            
            vaultInfo.totalRaised -= earlyRedemptionAmount;
            
            // If total raised drops below principal, go back to Pending
            if (vaultInfo.totalRaised < vaultInfo.principalAmount) {
                vaultInfo.state = VaultState.Pending;
                // Reset timestamps if we go back to pending
                vaultInfo.fundedAt = 0;
                vaultInfo.contractAttachedAt = 0; 
                vaultInfo.contractHash = bytes32(0); // Detach contract if any
            }

            emit SharesRedeemed(msg.sender, shares, earlyRedemptionAmount);
            emit VaultStateChanged(vaultInfo.state);
            return;
        }

        // --- Standard Redemption Logic (Repaying/Completed) ---

        // SECURITY UPGRADE: Prevent full redemption until debt is fully repaid
        // This prevents the "last man standing" issue where early exiters leave dust for others
        // if the borrower hasn't fully repaid yet.
        
        // Calculate total due (principal + interest + protocol fee)
        uint256 interestAmount = vaultInfo.principalAmount * vaultInfo.interestRate / 10000;
        uint256 protocolFee = vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000;
        uint256 totalDue = vaultInfo.principalAmount + interestAmount + protocolFee;
        
        bool isFullyRepaid = vaultInfo.totalRepaid >= totalDue;

        // If not fully repaid, allow redemption ONLY proportional to what has been repaid
        // Actually, the request said: "enabling only redem when repayment is done totally"
        // But preventing ANY redemption until 100% repayment is very strict and hurts liquidity.
        // However, the prompt says: "We wil use the prevent by enabling only redem when repayment is done totally."
        // So I will implement strict check as requested.
        
        if (vaultInfo.state == VaultState.Repaying) {
             require(isFullyRepaid, "Cannot redeem until full repayment");
        }

        // Get available funds for investors (excluding reserved protocol fees)
        uint256 availableForInvestors = getAvailableForInvestors();
        require(availableForInvestors > 0, "No funds available for redemption");
        
        // Calculate redemption amount proportional to shares
        uint256 redemptionAmount = (shares * availableForInvestors) / totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        // Transfer USDC
        require(usdc.transfer(msg.sender, redemptionAmount), "USDC transfer failed");

        emit SharesRedeemed(msg.sender, shares, redemptionAmount);
        
        // Check if vault can be marked as completed (all funds distributed)
        _checkVaultCompletion();
    }

    /// @notice Withdraw protocol fees (only callable by protocol fee collector)
    /// @dev Can be called at any time after repayments start, withdraws proportional fees
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeCollector, "Only protocol fee collector");
        require(vaultInfo.state == VaultState.Repaying || vaultInfo.state == VaultState.Completed, "No repayments yet");
        
        // Calculate how much protocol fee is available based on repayments made
        uint256 interestAmount = vaultInfo.principalAmount * vaultInfo.interestRate / 10000;
        uint256 totalProtocolFee = vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000;
        uint256 totalDue = vaultInfo.principalAmount + interestAmount + totalProtocolFee;
        
        // Calculate proportional protocol fee based on repayments
        // If fully repaid, all protocol fees are available
        uint256 earnedProtocolFee;
        if (vaultInfo.totalRepaid >= totalDue) {
            earnedProtocolFee = totalProtocolFee;
        } else {
            earnedProtocolFee = (vaultInfo.totalRepaid * totalProtocolFee) / totalDue;
        }
        
        uint256 availableFees = earnedProtocolFee > protocolFeesWithdrawn 
            ? earnedProtocolFee - protocolFeesWithdrawn 
            : 0;
        
        require(availableFees > 0, "No fees to collect");

        protocolFeesWithdrawn += availableFees;

        require(usdc.transfer(protocolFeeCollector, availableFees), "Protocol fee transfer failed");
        
        emit ProtocolFeesCollected(availableFees);
        
        // Check if vault can be marked as completed (all funds distributed)
        _checkVaultCompletion();
    }

    /// @notice Calculate protocol fees that are earned but not yet withdrawn
    /// @return The amount of USDC reserved for protocol fees
    function _calculateReservedProtocolFees() internal view returns (uint256) {
        // Calculate total due
        uint256 interestAmount = vaultInfo.principalAmount * vaultInfo.interestRate / 10000;
        uint256 totalProtocolFee = vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000;
        uint256 totalDue = vaultInfo.principalAmount + interestAmount + totalProtocolFee;
        
        // Calculate earned protocol fee based on repayments
        uint256 earnedProtocolFee;
        if (vaultInfo.totalRepaid >= totalDue) {
            earnedProtocolFee = totalProtocolFee;
        } else {
            earnedProtocolFee = (vaultInfo.totalRepaid * totalProtocolFee) / totalDue;
        }
        
        // Return reserved amount (earned but not withdrawn)
        return earnedProtocolFee > protocolFeesWithdrawn 
            ? earnedProtocolFee - protocolFeesWithdrawn 
            : 0;
    }

    /// @notice Get available funds for investors (excluding reserved protocol fees)
    /// @return The amount available for investor redemptions
    function getAvailableForInvestors() public view returns (uint256) {
        uint256 vaultBalance = usdc.balanceOf(address(this));
        uint256 reservedProtocolFees = _calculateReservedProtocolFees();
        
        return vaultBalance > reservedProtocolFees 
            ? vaultBalance - reservedProtocolFees 
            : 0;
    }

    /// @notice Internal function to check if vault should be marked as completed
    /// @dev Vault is completed when all debt is repaid AND all funds are withdrawn (balance is 0 or dust)
    function _checkVaultCompletion() internal {
        if (vaultInfo.state != VaultState.Repaying) {
            return; // Only check when in Repaying state
        }
        
        // Calculate total due (principal + interest + protocol fee)
        uint256 interestAmount = vaultInfo.principalAmount * vaultInfo.interestRate / 10000;
        uint256 protocolFee = vaultInfo.principalAmount * vaultInfo.protocolFeeRate / 10000;
        uint256 totalDue = vaultInfo.principalAmount + interestAmount + protocolFee;
        
        // Check if all debt is repaid
        bool debtFullyRepaid = vaultInfo.totalRepaid >= totalDue;
        
        // Check if all funds have been withdrawn (allowing for dust/rounding errors)
        uint256 vaultBalance = usdc.balanceOf(address(this));
        bool allFundsWithdrawn = vaultBalance < 100; // Less than 0.0001 USDC (dust)
        
        // Mark as completed only if debt is repaid AND all funds distributed
        if (debtFullyRepaid && allFundsWithdrawn) {
            vaultInfo.state = VaultState.Completed;
            emit VaultStateChanged(VaultState.Completed);
        }
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

    /// @notice Get list of all investors in this vault
    /// @return Array of investor addresses
    function getInvestors() external view returns (address[] memory) {
        return investors;
    }

    /// @notice Check if an address is an investor
    /// @param account The address to check
    /// @return True if the address is an investor
    function isInvestorAddress(address account) external view returns (bool) {
        return isInvestor[account];
    }

    /// @notice Get vault state
    /// @return The current state of the vault
    function getVaultState() external view returns (VaultState) {
        return vaultInfo.state;
    }

    /// @notice Get vault borrower
    /// @return The borrower address
    function getVaultBorrower() external view returns (address) {
        return vaultInfo.borrower;
    }

    /// @notice Get vault principal amount
    /// @return The principal amount
    function getVaultPrincipalAmount() external view returns (uint256) {
        return vaultInfo.principalAmount;
    }

    /// @notice Get vault total raised
    /// @return The total amount raised
    function getVaultTotalRaised() external view returns (uint256) {
        return vaultInfo.totalRaised;
    }

    /// @notice Get vault contract hash
    /// @return The contract hash
    function getVaultContractHash() external view returns (bytes32) {
        return vaultInfo.contractHash;
    }

    /// @notice Get vault creation timestamp
    /// @return The timestamp when vault was created
    function getVaultCreatedAt() external view returns (uint256) {
        return vaultInfo.createdAt;
    }

    /// @notice Get vault funded timestamp
    /// @return The timestamp when vault was fully funded (0 if not funded)
    function getVaultFundedAt() external view returns (uint256) {
        return vaultInfo.fundedAt;
    }

    /// @notice Get contract attached timestamp
    /// @return The timestamp when contract was attached (0 if not attached)
    function getVaultContractAttachedAt() external view returns (uint256) {
        return vaultInfo.contractAttachedAt;
    }

    /// @notice Get funds withdrawn timestamp
    /// @return The timestamp when borrower withdrew funds (0 if not withdrawn)
    function getVaultFundsWithdrawnAt() external view returns (uint256) {
        return vaultInfo.fundsWithdrawnAt;
    }

    /// @notice Calculate actual due date based on withdrawal timestamp
    /// @return The actual due date (fundsWithdrawnAt + duration)
    function getActualDueDate() external view returns (uint256) {
        if (vaultInfo.fundsWithdrawnAt == 0) {
            return 0; // Funds not withdrawn yet
        }
        return vaultInfo.fundsWithdrawnAt + (vaultInfo.maturityDate - vaultInfo.createdAt);
    }
}
